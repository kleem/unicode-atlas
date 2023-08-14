import csv
from shapely.geometry import Polygon

i = 0
with open('data/2_spatialization/Codepoints.wkt.csv', newline='') as csvfile:
    reader = csv.DictReader(csvfile, delimiter=';')
    for row in reader:
        print(row['code'])
        i += 1
        if i > 100:
            break