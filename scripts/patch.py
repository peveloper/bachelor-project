#!/usr/bin/python
import sys, getopt
from PIL import Image
import numpy as np
import csv

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

def remove_quotes(field):
    if '"' in field:
        field = field.replace('"', '')
        field = field.replace(' ', '')
    return field

def parse_record(row):
    row = [remove_quotes(field) for field in row ]
    return row

def main(argv):
    csv_file = ""
    input_img = ""
    patch = ""
    try:
        opts, args = getopt.getopt(argv, "hc:i:o:", ["ifile=", "ofile="])
    except getopt.GetoptError:
        print 'patch.py -c <csv_file> -i <input_image> -p <output_patch>'
        sys.exit(2)
    for opt, arg in opts:
        if opt == '-h':
            print 'patch.py -c <csv_file> -i <input_image> -p <output_patch>'
            sys.exit()
        elif opt in ("-c", "--csv"):
            csv_file = arg
        elif opt in ("-i", "--img"):
            input_img = arg
        elif opt in ("-p", "--patch"):
            patch = arg

    with open(csv_file, 'rb') as f:
        reader = csv.reader(f)
        for row in reader:
            row = parse_record(row)
            # for each row now process data as required
    # my_data = genfromtxt(csv, skip_header=2, dtype=None, delimiter=',')
    # print my_data
    # for record in my_data:
    #     remove_quotes(record)
    # print my_data
    # p0 = [0,-1]
    # p1 = [1,0]
    # v0 = np.array(p0)
    # v1 = np.array(p1)
    # print(signed_angle(v0,v1))
    # print my_data

if __name__ == "__main__":
    main(sys.argv[1:])


# Need to specify the path of the directory that will contain the heightmaps, pass the name of the heigthmap as parameter

# Perform a rotate/translation of the patch

# Also need to connect to the numpy db to see coords and if the patch was traversed or not
