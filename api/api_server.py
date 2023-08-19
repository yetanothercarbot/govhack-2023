import asyncio
import asyncpg
import json
from aiohttp import web
from aiocache import cached, Cache
from import_data import read_csv_by_line

import shapely.geometry
import shapely.wkb
from shapely.geometry.base import BaseGeometry
from shapely.geometry import Point

GOOGLE_API_URL = "https://maps.googleapis.com/maps/api/geocode/json"

SENSOR_DATA_URL = "https://www.data.brisbane.qld.gov.au/data/dataset/01af4647-dd69-4061-9c68-64fa43bfaac7/resource/78c37b45-ecb5-4a99-86b2-f7a514f0f447/download/gauge-data-20230819t125703.csv"

FIRE_DATA_URL = ""

FLOOD_RISK_DIFFERENCE = 0.25

settings = {}

with open('settings.json') as json_file:
    settings = json.load(json_file)

class Webserver:
    def __init__(self, pool, loop):
        self.pool = pool
        self.loop = loop

        # Web session
        self.session = aiohttp.ClientSession(raise_for_status=True)

    @staticmethod
    def get_addr_component(address, component_name):
        for component in address['address_components']:
            if (component_name in component['types']):
                return component['long_name']

    @cached(ttl=1800)
    async def sensordata(self):
        async for data in read_csv_by_line(SENSOR_DATA_URL):
            return data

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
        async with this.session.get(GOOGLE_API_URL, params=params) as resp:
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
        ORDER BY Distance(Location, $1) DESC
        LIMIT 1
        """

        async with self.pool.acquire() as con:
            flooddata = await con.fetch(sql_flooddata,
                ' '.join(this.get_addr_component(address, 'route')).split(' ')[:-1],
                ' '.join(this.get_addr_component(address, 'route')).split(' ')[-1:],
                this.get_addr_component(address, 'street_number'),
                this.get_addr_component(address, 'postal_code'))
            sensorid = await con.fetch(sql_sensor, Point(float(longitude), float(latitude).wkt))

        #  Create GeoJson
        resp = {
          "flood_risk": flooddata['HistoricalFloodRisk'],
          "flood_risk_curr": True if flooddata['HistoricalFloodRisk'] - sensordata[sensorid[0]] >= FLOOD_RISK_DIFFERENCE else False,
          "fire_index": 0,
          "corridor_name": this.get_addr_component(address, 'route'),
          "corridor_long_name": address['formatted_address'],
          "postcode": this.get_addr_component(address, 'postal_code'),
          "state": this.get_addr_component(address, 'administrative_area_level_1'),
          "postcode": this.get_addr_component(address, 'country'),
        }

        return web.json_response(resp, status=200, headers={'Access-Control-Allow-Origin': '*'})

    '''
    Build the web server and setup routes
    '''
    async def build_server(self, address, port):
        app = web.Application(loop=self.loop)
        app.router.add_route('POST', "/ping", self.ping)
        app.router.add_route('POST', "/riskdata", self.riskdata)

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