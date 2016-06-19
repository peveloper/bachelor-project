#!/usr/bin/python

import sys
import getopt
import numpy as np
import os.path
import cv2
import csv
import math
import pickle

csv_path = "../../data/csv/"
heightmap_path = "../../data/heightmaps/"
segments_path = "../../data/segments/"
dataset_path = "../../data/datasets/"

dirs = [segments_path, dataset_path]

csv_filename = ''
heightmap_filename = ''
segments_filename = ''

def save_object(obj, filename):
    with open(filename, 'wb') as output:
        pickle.dump(obj, output, pickle.HIGHEST_PROTOCOL)


def get_image(img_path):
    return cv2.imread(img_path)


def get_image_size(img):
    height, width, channels = img.shape
    return (width, height, channels)


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

    mapping = np.array([[vx[0], vy[0], sx], [vx[1], vy[1], sy]])

    return cv2.warpAffine(image, mapping, (width, height), flags = cv2.WARP_INVERSE_MAP, borderMode = cv2.BORDER_REPLICATE)


def get_mean_variance(M):
    (mean, sigma) = cv2.meanStdDev(M)
    mean = mean[1][0]
    sigma = sigma[1][0]
    return mean, sigma ** 2


def parse_record(row, line, width, height, i_img_path, o_img, o_img_path, data, target, blank):
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
        angle += 2 * np.pi


    center = midpoint(p0[0], p0[1], p1[0], p1[1])
    distance = get_distance(center[0], center[1], p0[0], p0[1])
    color = (0, 255, 0) if traversed else (0, 0, 255)

    img_cpy = get_image(i_img_path)

    patch_w_l = extract_patch(img_cpy, (center[0], center[1]), angle, distance * 2, distance * 2)


    mean, var = get_mean_variance(patch_w_l)

    ddepth = cv2.CV_16S

    grad_x = cv2.Scharr(patch_w_l, ddepth, 1, 0)
    grad_y = cv2.Scharr(patch_w_l, ddepth, 0, 1)

    del patch_w_l

    mean_grad_x, var_grad_x = get_mean_variance(grad_x)
    mean_grad_y, var_grad_y = get_mean_variance(grad_y)



    data.append([mean, var, mean_grad_x, var_grad_x, mean_grad_y, var_grad_y])
    target.append(row[0])

    cv2.line(img_cpy, (p0[0], p0[1]), (p1[0], p1[1]), color, lineType = cv2.CV_AA)

    patch = extract_patch(img_cpy, (center[0], center[1]), angle, distance * 2, distance * 2)
    non_rotated = extract_patch(img_cpy, (center[0], center[1]), 0, distance * 2, distance * 2)
    cv2.imwrite('../data/patches/samples/patch_' + `line - 1` + '.jpg', non_rotated)
    cv2.imwrite('../data/patches/patch_' + `line - 1` + '.jpg', patch)

    cv2.line(o_img, (p0[0], p0[1]), (p1[0], p1[1]), color, lineType = cv2.CV_AA)
    cv2.imwrite(o_img_path, o_img)

    del img_cpy

    return row


def main(argv):
    usage = 'generate_dataset.py -c <csv_filename> -i <heightmap_filename> -o <segments_filename> -d <dataset_filename>'
    try:
        opts, args = getopt.getopt(argv, "hc:i:o:d:", ["ifile=", "ofile=", "dfile="])
    except getopt.GetoptError:
        print usage
        sys.exit(2)
    for opt, arg in opts:
        if opt == '-h':
            print usage
            sys.exit()
        elif opt in ("-c", "--csv"):
            csv_filename = arg
        elif opt in ("-i", "--img"):
            heightmap_filename = arg
        elif opt in ("-o", "--out"):
            segments_filename = arg
        elif opt in ("-d", "--data"):
            dataset_filename = arg

    CSV = csv_path + csv_filename
    heightmap = heightmap_path + heightmap_filename
    segments = segments_path + segments_filename
    dataset = dataset_path + dataset_filename

    i_img = get_image(heightmap)
    i_img_size = get_image_size(i_img)
    i_img_height = i_img_size[0]
    i_img_width = i_img_size[1]
    blank = np.zeros((i_img_height, i_img_width,3), np.uint8)

    for directory in dirs:
        if not os.path.exists(directory):
            os.makedirs(directory)

    if os.path.isfile(segments):
        o_img = get_image(segments)
    else:
        o_img = get_image(heightmap)

    print "Generating Dataset ..."

    with open(CSV, 'rb') as f:
        reader = csv.reader(f)
        line = 0
        data = []
        target = []
        npdataset = {}
        for row in reader:
            if line > 0:
                row = parse_record(row, line, i_img_width, i_img_height, heightmap, o_img, segments, data, target, blank)
            line +=1
        print "Done!"
        npdataset['data'] = np.array(data)
        npdataset['target'] = np.array(target)
        save_object(npdataset, dataset)


if __name__ == "__main__":
    main(sys.argv[1:])
