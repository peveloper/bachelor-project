#!/usr/bin/python
import sys, getopt
from PIL import Image
import numpy as np

def rotate(inputfile, outputfile):
    try:
        image = Image.open(inputfile)
    except:
        print "Wrong path or unsupported file extension."
    image = image.rotate(45, expand=True)
    image.show()
    return image.save(outputfile)


def signed_angle(v0,v1):
    angle = np.math.atan2(np.linalg.det([v0,v1]),np.dot(v0,v1))
    return np.degrees(angle)

def main(argv):
    # inputfile = ""
    # outputfile = ""
    # try:
    #     opts, args = getopt.getopt(argv, "hi:o:", ["ifile=", "ofile="])
    # except getopt.GetoptError:
    #     print 'patch_extractor.py -i <inputfile> -o <outputfile>'
    #     sys.exit(2)
    # for opt, arg in opts:
    #     if opt == '-h':
    #         print 'test.py -i <inputfile> -o <outputfile>'
    #         sys.exit()
    #     elif opt in ("-i", "--ifile"):
    #         inputfile = arg
    #     elif opt in ("-o", "--ofile"):
    #         outputfile = arg
    # rotate(inputfile, outputfile)
    p0 = [0,-1]
    p1 = [1,0]
    v0 = np.array(p0)
    v1 = np.array(p1)
    print(signed_angle(v0,v1))
if __name__ == "__main__":
    main(sys.argv[1:])


# Need to specify the path of the directory that will contain the heightmaps, pass the name of the heigthmap as parameter

# Perform a rotate/translation of the patch

# Also need to connect to the numpy db to see coords and if the patch was traversed or not
