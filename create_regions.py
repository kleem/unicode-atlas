import csv
from shapely.geometry import Polygon
from shapely import coverage_union_all
from shapely import to_geojson
import geojson
from geojson import Feature, MultiPolygon, FeatureCollection

# read all codepoint locations and store the corresponding square polygon into the relevant layers
land_polygons = []
block_polygons = {}

with open('data/2_spatialization/Codepoints.csv', newline='') as csvfile:
    reader = csv.DictReader(csvfile, delimiter=';')
    for row in reader:
        x = int(row['x'])
        y = int(row['y'])
        polygon = Polygon([(x,-y), (x,-y-1), (x+1,-y-1), (x+1,-y), (x,-y)])

        if row['age'] != '': # land is wherever age is defined
            land_polygons.append(polygon)

        if row['block'] != '':
            if row['block'] not in block_polygons:
                block_polygons[row['block']] = []
            block_polygons[row['block']].append(polygon)

# merge all squares on a per-layer basis
land = coverage_union_all(land_polygons)
blocks = { block_name:coverage_union_all(polygons) for (block_name, polygons) in block_polygons.items() }

# read additional data
unidings_symbol = {}
with open('data/1_source/Unidings utf8.csv', newline='', encoding="utf-8") as csvfile:
    reader = csv.DictReader(csvfile, delimiter=';')
    for row in reader:
        unidings_symbol[row['block_name']] = row['symbol']

# write files as GeoJSON
with open('data/3_regions/Land.json', 'w') as file:
    file.write(to_geojson(land)) # MultiPolygon

with open('data/3_regions/Blocks.json', 'w', encoding="utf-8") as file:
    features = []
    for (block_name, multipolygon) in blocks.items():
        properties = {
            'name': block_name,
            'symbol': 'X'
        }
        if block_name in unidings_symbol:
            properties['symbol'] = unidings_symbol[block_name]
        feature = Feature(geometry=MultiPolygon(geojson.loads(to_geojson(multipolygon))), properties=properties)
        features.append(feature)
    collection = FeatureCollection(features)
    geojson.dump(collection, file, ensure_ascii=False) # FeatureCollection