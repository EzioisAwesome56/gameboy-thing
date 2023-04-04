import xml.etree.ElementTree as et
import sys
import os

# get raw CSV data out of the map tile file
def parse_xml(xml):
    # load xml from string
    root = et.fromstring(xml)
    # get our CSV data from the xml
    layer = root.find("layer")
    data = layer.find("data")
    return data.text

# convert csv into a list of numbers
def parse_csv(csv):
    tiles = list(map(int, csv.split(",")))
    return tiles

# compiles raw tile data into a map
def compile_map(mapdata):
    compiled = []
    for tile in mapdata:
        match tile:
            case 1:
                compiled.append(77)
            case 2:
                compiled.append(78)
            case 3:
                compiled.append(79)
            case 4:
                compiled.append(80)
            case 5:
                compiled.append(81)
    return compiled

# save the file
def save_file(data, outfilename):
    file = open(outfilename, "wb")
    file.write(bytearray(data))
    print("Map compiled to " + outfilename)

# did they provide enough arguments
if (len(sys.argv) < 2):
    print("Error: not enough arguments provided!")
    print("Syntax: mapcompiler.py <source file> <map label> <output file>")
    quit()

# check that the file actually exists
inputpath = sys.argv[1]
if (os.path.exists(inputpath) == False):
    print("Error: the file " + inputpath + " does not exist!")
    quit()
# open the source file
mapfile = open(inputpath)
# get csv information
csv = parse_xml(mapfile.read())
# get tile data
tiles = parse_csv(csv)
# compile the map
newmap = compile_map(tiles)
# save the map
save_file(newmap, sys.argv[2])




