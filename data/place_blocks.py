import csv

print 'first;last;name'

for line in filter(lambda line: len(line)==2 and not line[0].startswith('#'), csv.reader(open('Blocks.txt'), delimiter=';', skipinitialspace=True)):
    print ';'.join(line[0].split('..') + [line[1]])
    