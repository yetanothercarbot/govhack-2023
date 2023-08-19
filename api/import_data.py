'''

'''
import json
import aiofiles
import asyncio
import asyncpg
import aiohttp
import datetime
import sys

import shapely.geometry
import shapely.wkb
from shapely.geometry.base import BaseGeometry
from shapely.geometry import Point

settings = {}

# Read SQL Auth data
with open('settings.json') as json_file:
    settings = json.load(json_file)

DATA_FLOOD_AWARENESS = r"https://www.spatial-data.brisbane.qld.gov.au/datasets/b5dd1159f3024397b8035239216fed1a_0.csv?outSR=%7B%22latestWkid%22%3A3857%2C%22wkid%22%3A102100%7D"

DATA_PROPERTY_BOUNDARIES = r"https://www.spatial-data.brisbane.qld.gov.au/datasets/fb05500e13c048c8ab84f8f426eaa74c_0.csv?outSR=%7B%22latestWkid%22%3A28356%2C%22wkid%22%3A28356%7D"

DATA_SENSOR_METADATA = r"https://www.data.brisbane.qld.gov.au/data/dataset/01af4647-dd69-4061-9c68-64fa43bfaac7/resource/117218af-4adc-4f8e-927a-0fe43c46cdb4/download/rainfall-and-stream-heights-metadata-20230819t110000.csv"

CREATE_FLOOD_RISK_METRICS_TABLE = """
CREATE TABLE IF NOT EXISTS FloodRiskMetrics (
    LotPlan VARCHAR(255) PRIMARY KEY, -- Record ID
    HistoricalFloodRisk INTEGER,
    FloodLevel REAL
);
"""

CREATE_LOTPLAN_TABLE = """
CREATE TABLE IF NOT EXISTS LotPlan (
    LotPlan VARCHAR(255) PRIMARY KEY,
    CorridorName TEXT NOT NULL,
    CorridorSuffix VARCHAR(255) NOT NULL,
    HouseNumber VARCHAR(255) NOT NULL,
    PostCode INTEGER NOT NULL
);
"""

CREATE_SENSORS_TABLE = """
CREATE TABLE IF NOT EXISTS Sensors (
    ID SERIAL PRIMARY KEY,
    SensorID VARCHAR(255),
    Location GEOMETRY NOT NULL
);
"""

FLOOD_RISK_MAPPING = {
    'FL_HIGH_RIVER': 4,
    'FL_MED_RIVER': 3,
    'FL_LOW_RIVER': 2,
    'FL_VLOW_RIVER': 1,
}

'''
Reads a line from a CSV, considering quotes

Reference: ChatGPT
'''
def parse_csv_line(line):
    fields = []
    field = ""
    inside_quotes = False

    for char in line:
        if char == '"':
            inside_quotes = not inside_quotes
        elif char == ',' and not inside_quotes:
            fields.append(field)
            field = ""
        else:
            field += char

    fields.append(field)  # Add the last field
    return fields

'''
CSV Line reader.
'''
async def read_csv_by_line(url):
    async with aiohttp.ClientSession(raise_for_status=True) as session:
        keys = None
        async with session.get(url) as r:
            async for line in r.content:
                await asyncio.sleep(0)
                dataline = parse_csv_line(line.decode("utf-8").strip())
                if keys == None:
                    keys = dataline
                else:
                    data = dict(zip(keys,dataline))
                    yield data

'''
Imports stream height sensor metadata
'''
async def import_sensors(db):
    insert_row = """
        INSERT INTO Sensors
        (
            SensorID,
            Location
        )
        VALUES
        (
            $1,
            $2
        );
    """
    stmt = await db.prepare(insert_row)

    queue = []
    num = 0
    async with db.transaction():
        async for data in read_csv_by_line(DATA_SENSOR_METADATA):
            try:
                if data['Sensor Type'] == "Stream Height AHD":
                    args = [
                        data['Sensor ID'],
                        Point(float(data['Longitude']), float(data['Latitude'])).wkt,
                    ]

                    queue.append(args)

                    sys.stdout.write("\r Processing record: %i" % num)
                    sys.stdout.flush()
                    num += 1
            except ValueError:
                pass
            except Exception as e:
                print(data)
                raise e

        await stmt.executemany(queue)
        queue = []

    print(f"Inserted all sensor metadata")

'''
Import flood risk metrics

Since only the lotplan will be gathered at this stage, we will
save the lotplan and associated risk metrics, then when performing
an api request, we will use the google maps api to convert Lat/Long
into a street address, which we can convert into a LotPlan number.
'''
async def import_flood_risk(db):
    insert_row = """
        INSERT INTO FloodRiskMetrics
        (
            LotPlan,
            HistoricalFloodRisk,
            FloodLevel
        )
        VALUES
        (
            $1,
            $2,
            $3
        )
        ON CONFLICT (LotPlan)
            DO UPDATE SET
                HistoricalFloodRisk = COALESCE($2, EXCLUDED.HistoricalFloodRisk),
                FloodLevel = COALESCE($3, EXCLUDED.FloodLevel)
    """
    stmt = await db.prepare(insert_row)

    queue = []
    num = 1
    async with db.transaction():
        async for data in read_csv_by_line(DATA_FLOOD_AWARENESS):
            try:
                args = [
                    data['LOTPLAN'],
                    FLOOD_RISK_MAPPING[data['METRIC']] if data['METRIC'] in FLOOD_RISK_MAPPING else None,
                    float(data['VALUE']) if data['METRIC'] == 'FL_DFL' else None,
                ]

                queue.append(args)

                # Don't allow the queue to grow above 100 records
                if len(queue) >= 10000:
                    await stmt.executemany(queue)
                    queue = []

                sys.stdout.write("\r Processing record: %i" % num)
                sys.stdout.flush()
                num += 1
            except ValueError:
                pass
            except Exception as e:
                print(data)
                raise e

        await stmt.executemany(queue)
        queue = []

    print(f"Inserted all risk data")

'''
Import Lot info.

Note we will only import rows which have all the required columns.
'''
async def import_lotplan(db):
    insert_row = """
        INSERT INTO LotPlan
        (
            LotPlan,
            CorridorName,
            CorridorSuffix,
            HouseNumber,
            PostCode
        )
        VALUES
        (
            $1,
            $2,
            $3,
            $4,
            $5
        )
        ON CONFLICT (LotPlan) DO NOTHING
    """
    stmt = await db.prepare(insert_row)

    queue = []
    num = 1
    async with db.transaction():
        async for data in read_csv_by_line(DATA_PROPERTY_BOUNDARIES):
            try:
                if (data['HOUSE_NUMBER'] != '' and
                    data['CORRIDOR_NAME'] != '' and
                    data['CORRIDOR_SUFFIX_CODE'] != '' and
                    data['POSTCODE'] != ''):
                    args = [
                        data['LOTPLAN'],
                        data['CORRIDOR_NAME'],
                        data['CORRIDOR_SUFFIX_CODE'],
                        data['HOUSE_NUMBER'],
                        int(data['POSTCODE'])
                    ]

                    queue.append(args)

                    # Don't allow the queue to grow above 100 records
                    if len(queue) >= 100:
                        await stmt.executemany(queue)
                        queue = []

                    sys.stdout.write("\r Processing record: %i" % num)
                    sys.stdout.flush()
                    num += 1
            except ValueError:
                pass
            except Exception as e:
                print(data)
                raise e

        await stmt.executemany(queue)
        queue = []

    print(f"Inserted all risk data")

async def run():
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
            'geography',
            encoder=encode_geometry,
            decoder=decode_geometry,
            format='binary',
        )

    pool = await asyncpg.create_pool(user=settings['psql_user'], password=settings['psql_pass'],
        database=settings['psql_dbname'], host=settings['psql_host'], init=init_connection)

    async with pool.acquire() as db:
        await db.execute(CREATE_SENSORS_TABLE)
        await db.execute(CREATE_LOTPLAN_TABLE)
        await db.execute(CREATE_FLOOD_RISK_METRICS_TABLE)

        await import_sensors(db)
        await import_lotplan(db)
        await import_flood_risk(db)

loop = asyncio.get_event_loop()
loop.run_until_complete(run())