#!/usr/bin/python
import sys, getopt
import numpy as np
import cv2
import csv
import math


def midpoint(x0, y0, x1, y1):
    return [(x0 + x1) / 2, (y0 + y1) / 2]


def get_distance(x0, y0, x1, y1):
    return int(math.sqrt((y1 - y0) ** 2 + (x1 - x0) ** 2))


def remove_quotes(field):
    if '"' in field:
        field = field.replace('"', '')
        field = field.replace(' ', '')
    return field


def to_pixel_coords(field, mul):
    return int(field * mul) if (field > 0) else int(field * (-mul))


def extract_patch(image, center, theta, width, height):
    vx = (np.cos(theta), np.sin(theta))
    vy = (-np.sin(theta), np.cos(theta))
    sx = center[0] - vx[0] * (width / 2) - vy[0] * (height / 2)
    sy = center[1] - vx[1] * (width / 2) - vy[1] * (height / 2)

    mapping = np.array([[vx[0],vy[0], sx], [vx[1],vy[1], sy]])
    return cv2.warpAffine(image, mapping, (width, height), flags = cv2.WARP_INVERSE_MAP, borderMode = cv2.BORDER_REPLICATE)


def parse_record(row, line, width, height, img, output_img):
    row = [remove_quotes(field) for field in row ]

    for i in range(len(row)):
        if i < 2:
            continue
        elif i % 2 == 0:
            row[i] = to_pixel_coords(float(row[i]), width)
        else:
            row[i] = to_pixel_coords(float(row[i]), height)

    p0 = (row[2], row[3])
    p1 = (row[4], row[5])
    traversed = int(row[0])
    angle = math.atan2(p1[1] - p0[1], p1[0] - p0[0])

    if (angle < 0):
        angle += np.pi / 2

    center = midpoint(p0[0], p0[1], p1[0], p1[1])
    distance = get_distance(center[0], center[1], p0[0], p0[1])
    patch = extract_patch(img, (center[0], center[1]), angle, distance * 2, distance * 2)

    cv2.imwrite('../data/patches/patch_' + `line - 2` + '.jpg', patch)
    patch = cv2.imread('../data/patches/patch_' + `line - 2` + '.jpg', cv2.IMREAD_GRAYSCALE)
    color = cv2.COLORMAP_SUMMER if traversed else cv2.COLORMAP_AUTUMN
    patch_col = cv2.applyColorMap(patch, color)
    cv2.imwrite('../data/patches/patch_' + `line - 2` + '.jpg', patch_col);

    return row


def get_image_size(img):
    height, width, channels = img.shape
    return (width, height, channels)


def get_image(img_path):
    return cv2.imread(img_path)


def main(argv):

    csv_file = ''
    input_img = ''
    output_img = ''

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

    img = get_image(input_img)
    img_size = get_image_size(img)
    img_width = img_size[0]
    img_height = img_size[1]

    with open(csv_file, 'rb') as f:
        reader = csv.reader(f)
        line = 0
        for row in reader:
            if line > 1:
                row = parse_record(row, line, img_width, img_height, img, output_img)
            line +=1


if __name__ == "__main__":
    main(sys.argv[1:])
