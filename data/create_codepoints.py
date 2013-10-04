# read block ranges
import csv
blocks = []

for line in filter(lambda line: len(line)==2 and not line[0].startswith('#'), csv.reader(open('Blocks.txt'), delimiter=';', skipinitialspace=True)):
    range_strings = line[0].split('..')
    blocks.append({'range': [int(range_strings[0],16), int(range_strings[1],16)], 'name': line[1]})
    
# convert to diagram coordinates
def codepoint2cartesian(c):
    return ((int(c/16)%256+256*int(c/65536))%1024, (c%16+16*int(c/4096))%256+256*int(c/(4*65536)))
    
# output a CSV file with a WKT field representing the geometry
print 'GEOMETRY;block'

for c in xrange(0x110000):
    # find in which block this codepoint is
    block_name = ''
    for block in blocks:
        if block['range'][0] <= c <= block['range'][1]:
            block_name = block['name']
            break
            
    x, y = codepoint2cartesian(c)
    print 'MULTIPOLYGON (((%d %d,%d %d,%d %d,%d %d,%d %d)));%s' % (x, -y, x, -y-1, x+1, -y-1, x+1, -y, x, -y, block_name)
    