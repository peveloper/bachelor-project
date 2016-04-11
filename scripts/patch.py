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


def midpoint(v):
    return (v[1:] + v[:-1]) / 2


def signed_angle(v0,v1):
    angle = np.math.atan2(np.linalg.det([v0,v1]),np.dot(v0,v1))
    return np.degrees(angle)


def remove_quotes(field):
    if '"' in field:
        field = field.replace('"', '')
        field = field.replace(' ', '')
    return field

def to_pixel_coords(field, mul):
    return int(field * mul) if (field > 0) else int(field * (-mul))


def parse_record(row, width, height):
    row = [remove_quotes(field) for field in row ]
    for i in range(len(row)):
        if i < 2:
            continue
        elif i % 2 == 0:
            row[i] = to_pixel_coords(float(row[i]), width)
        else:
            row[i] = to_pixel_coords(float(row[i]), height)
    return row


def get_image_size(image_reader):
    width, height = image_reader.size
    return (width, height)


def get_image(input_img):
    return Image.open(input_img)


def main(argv):
    csv_file = ""
    input_img = ""
    output_img = ""
    try:
        opts, args = getopt.getopt(argv, "hc:i:o:", ["ifile=", "ofile="])
    except getopt.GetoptError:
        print 'patch.py -c <csv_file> -i <input_img> -p <output_img>'
        sys.exit(2)
    for opt, arg in opts:
        if opt == '-h':
            print 'patch.py -c <csv_file> -i <input_img> -p <output_img>'
            sys.exit()
        elif opt in ("-c", "--csv"):
            csv_file = arg
        elif opt in ("-i", "--img"):
            input_img = arg
        elif opt in ("-p", "--patch"):
            output_img = arg

    input_img_reader = get_image(input_img)
    input_img_size = get_image_size(input_img_reader)
    input_img_width = input_img_size[0]
    input_img_height = input_img_size[1]

    print input_img_size[0], input_img_size[1]

    with open(csv_file, 'rb') as f:
        reader = csv.reader(f)
        line = 2
        for row in reader:
            if line == 0:
                row = parse_record(row, input_img_width, input_img_height)
            print row
            line-= 1
            # then find the midpoint and the patch coords,
            # then rotate, crop colour and construct a new image placing the patch in its corresponding coords.


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
