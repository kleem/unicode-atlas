# read block ranges
import csv
blocks = []

for line in filter(lambda line: len(line)==2 and not line[0].startswith('#'), csv.reader(open('Blocks.txt'), delimiter=';', skipinitialspace=True)):
    range_strings = line[0].split('..')
    blocks.append({'range': [int(range_strings[0],16), int(range_strings[1],16)], 'name': line[1]})
    
# read unicode data (all codepoints)
codepoints = {}

RANGE_STARTS = ('3400','4E00','AC00','D800','DB80','DC00','E000','20000','2A700','2B740','F0000','100000')
RANGE_ENDS =   ('4DB5','9FCC','D7A3','DB7F','DBFF','DFFF','F8FF','2A6D6','2B734','2B81D','FFFFD','10FFFD')

for line in csv.reader(open('UnicodeData.txt'), delimiter=';'):
    # save range start
    if line[0] in RANGE_STARTS:
        last_start = line[0]
        continue
        
    # enumerate codepoints in ranges
    # CJK ideograph extension A + CJK ideograph + Hangul syllable + CJK ideograph extension B, C, D
    if line[0] in RANGE_ENDS and last_start in ('3400','4E00','AC00','20000','2A700','2B740'):
        for c in xrange(int(last_start,16), int(line[0],16)+1):
            codepoints[c] = {
                'code': '%d' % c,
                'general_cat_1': 'L',
                'general_cat': 'Lo'
            }
        continue
        
    # emit single codepoint found in UnicodeData.txt
    codepoints[int(line[0],16)] = {
        'code': line[0],
        'general_cat_1': line[2][0],
        'general_cat': line[2]
    }
        
# convert to diagram coordinates
def codepoint2cartesian(c):
    return ((int(c/16)%256+256*int(c/65536))%1024, (c%16+16*int(c/4096))%256+256*int(c/(4*65536)))
    
# output a CSV file with a WKT field representing the geometry
print 'GEOMETRY;code;block;general_cat_1;general_cat'

for c in xrange(0x110000):
    # find in which block this codepoint is
    block_name = ''
    for block in blocks:
        if block['range'][0] <= c <= block['range'][1]:
            block_name = block['name']
            break
            
    x, y = codepoint2cartesian(c)
    
    if c in codepoints:
        data_fields = ';%s;%s;%s;%s' % (codepoints[c]['code'], block_name, codepoints[c]['general_cat_1'], codepoints[c]['general_cat'])
    else:
        data_fields = ';;%s;;' % (block_name)
        
    print 'MULTIPOLYGON (((%d %d,%d %d,%d %d,%d %d,%d %d)))%s' % (x, -y, x, -y-1, x+1, -y-1, x+1, -y, x, -y, data_fields)
    