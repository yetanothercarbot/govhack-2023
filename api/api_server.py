import asyncio
import asyncpg
import json
import aioftp
import aiofiles
import traceback
from aiohttp import web, ClientSession
from aiocache import cached, Cache
from import_data import read_csv_by_line
import xml.etree.ElementTree as ET

import shapely.geometry
import shapely.wkb
from shapely.geometry.base import BaseGeometry
from shapely.geometry import Point

GOOGLE_API_URL = "https://maps.googleapis.com/maps/api/geocode/json"

SENSOR_DATA_URL = "https://www.data.brisbane.qld.gov.au/data/dataset/01af4647-dd69-4061-9c68-64fa43bfaac7/resource/78c37b45-ecb5-4a99-86b2-f7a514f0f447/download/gauge-data-20230819t125703.csv"

FIRE_DATA_URL = "/anon/gen/fwo/IDQ13016.xml"

FIRE_DATA_FILENAME = "IDQ13016.xml"

BOM_FTP_URL = "ftp.bom.gov.au"

FLOOD_RISK_DIFFERENCE = 0.25

settings = {}

with open('settings.json') as json_file:
    settings = json.load(json_file)

class Webserver:
    def __init__(self, pool, loop):
        self.pool = pool
        self.loop = loop

        # Web session
        self.session = ClientSession(raise_for_status=True)

    @staticmethod
    def get_addr_component(address, component_name):
        for component in address['address_components']:
            if (component_name in component['types']):
                return component

        return {'short_name': "err", 'long_name': "err"}

    @cached(ttl=1800)
    async def sensordata(self):
        async for data in read_csv_by_line(SENSOR_DATA_URL):
            return data


    @cached(ttl=1800)
    async def getfirerisk(self):
        async with aioftp.Client.context(BOM_FTP_URL, 21, "anonymous", "") as client:
            await client.download(FIRE_DATA_URL)

        async with aiofiles.open(FIRE_DATA_FILENAME, mode='r') as f:
            contents = await f.read()

        root = ET.fromstring(contents)

        for area in root.find('forecast').findall('area'):
            if area.get('description') == "Southeast Coast":
                return int(area.findall('forecast-period')[0].find('element').text)

    '''
    Returns the following to show server is up:

    {
    success: 1,
    }
    '''
    async def ping(self, request):
        return web.json_response({'success': 1}, status=200, headers={'Access-Control-Allow-Origin': '*'})

    '''
    Returns risk and location data given lat/long
    '''
    async def riskdata(self, request):
        latitude = request.rel_url.query['lat']
        longitude = request.rel_url.query['long']

        # Get address details from google api
        # Example params
        # ?latlng=-27.5574965,152.943113&sensor=true&key=
        params = {'latlng': latitude+','+longitude, 'sensor': 'true', 'key': settings['google_api_key']}
        async with self.session.get(GOOGLE_API_URL, params=params) as resp:
            address = (await resp.json())['results'][0]

        sensors = await self.sensordata()

        sql_flooddata = """
        SELECT fm.HistoricalFloodRisk, fm.FloodLevel
        FROM FloodRiskMetrics fm
        INNER JOIN (
            SELECT lp.LotPlan
            FROM LotPlan lp
            WHERE
                lp.CorridorName = $1 AND
                lp.CorridorSuffix = $2 AND
                lp.HouseNumber = $3 AND
                lp.PostCode = $4
            LIMIT 1
        ) addr
        ON fm.LotPlan = addr.LotPlan
        """

        sql_sensor = """
        SELECT SensorID
        FROM Sensors
        ORDER BY ST_DistanceSphere(Location::geometry, ST_GeomFromText($1)) DESC
        LIMIT 1
        """

        resp = None

        try:
            async with self.pool.acquire() as con:
                flooddata = await con.fetch(sql_flooddata,
                    ' '.join(self.get_addr_component(address, 'route')['short_name'].split(' ')[:-1]).upper(),
                    ' '.join(self.get_addr_component(address, 'route')['short_name'].split(' ')[-1:]).upper(),
                    self.get_addr_component(address, 'street_number')['long_name'].upper(),
                    int(self.get_addr_component(address, 'postal_code')['long_name']))
                sensorid = await con.fetch(sql_sensor, Point(float(longitude), float(latitude)).wkt)

            print(' '.join(self.get_addr_component(address, 'route')['short_name'].split(' ')[:-1]).upper(),
                    ' '.join(self.get_addr_component(address, 'route')['short_name'].split(' ')[-1:]).upper(),
                    self.get_addr_component(address, 'street_number')['long_name'].upper(),
                    int(self.get_addr_component(address, 'postal_code')['long_name']))

            #print(sensors, sensorid[0])

            stream_height = int(sensors[sensorid[0][0]]) if sensors[sensorid[0][0]].isnumeric() else 0
            hist_flood_risk = flooddata[0][0] if flooddata[0][0] is not None else 0
            flood_risk_height = flooddata[0][1]
            flood_risk_curr = stream_height - flood_risk_height >= FLOOD_RISK_DIFFERENCE if flood_risk_height is not None else False

            #  Create GeoJson
            resp = {
              "flood_risk": hist_flood_risk,
              "flood_risk_curr": flood_risk_curr,
              "fire_index": await self.getfirerisk(),
              "corridor_name": self.get_addr_component(address, 'route')['long_name'],
              "corridor_long_name": address['formatted_address'],
              "postcode": self.get_addr_component(address, 'postal_code')['long_name'],
              "state": self.get_addr_component(address, 'administrative_area_level_1')['long_name'],
              "postcode": self.get_addr_component(address, 'country')['long_name'],
            }
        except Exception as e:
            traceback.print_exc()
            resp = {
              "flood_risk": 3,
              "flood_risk_curr": False,
              "fire_index": await self.getfirerisk(),
              "corridor_name": self.get_addr_component(address, 'route')['long_name'],
              "corridor_long_name": address['formatted_address'],
              "postcode": self.get_addr_component(address, 'postal_code')['long_name'],
              "state": self.get_addr_component(address, 'administrative_area_level_1')['long_name'],
              "country": self.get_addr_component(address, 'country')['long_name'],
            }

        return web.json_response(resp, status=200, headers={'Access-Control-Allow-Origin': '*'})

    '''
    Build the web server and setup routes
    '''
    async def build_server(self, address, port):
        app = web.Application(loop=self.loop)
        app.router.add_route('GET', "/ping", self.ping)
        app.router.add_route('GET', "/riskdata", self.riskdata)

        return await self.loop.create_server(app.make_handler(), address, port)

async def start_webserver(loop):
    async def init_connection(conn):
        def encode_geometry(geometry):
            if not hasattr(geometry, '__geo_interface__'):
                raise TypeError('{g} does not conform to '
                                'the geo interface'.format(g=geometry))
            shape = shapely.geometry.asShape(geometry)
            return shapely.wkb.dumps(shape)

        def decode_geometry(wkb):
            return shapely.wkb.loads(wkb)

        await conn.set_type_codec(
            'geometry',
            encoder=encode_geometry,
            decoder=decode_geometry,
            format='binary',
        )

    pool = await asyncpg.create_pool(user=settings['psql_user'], password=settings['psql_pass'],
        database=settings['psql_dbname'], host=settings['psql_host'], init=init_connection)

    webserver = Webserver(pool, loop)
    await webserver.build_server('localhost', 9898)

if __name__ == '__main__':
    loop = asyncio.get_event_loop()
    loop.run_until_complete(start_webserver(loop))
    print("Server ready!")

    try:
        loop.run_forever()
    except KeyboardInterrupt:
        print("Shutting Down!")
        loop.close()