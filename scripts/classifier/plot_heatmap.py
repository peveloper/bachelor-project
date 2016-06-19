import sys
import getopt
import cv2
import os
import numpy as np
import warnings
from sklearn.externals import joblib

# silence warnings
warnings.filterwarnings("ignore")

heightmap_path = "../../data/heightmaps/"
heatmap_path = "../../data/heatmaps/"
brain_path = "../../data/brains/"


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


def get_img_size(img):
    height, width, channels = img.shape
    return (width, height, channels)


def get_image(img_path):
    return cv2.imread(img_path)


def toradians(degrees):
    return degrees * 0.0174533


def main(argv):
    usage = 'plot_heatmap.py -i <input_image> -t <trained_model> -d <distance> -v <direction>'
    try:
        opts, args = getopt.getopt(argv, "hi:t:d:v:", ["input=","trained=", "distance=", "vector"])
    except getopt.GetoptError:
        print usage
        sys.exit(2)
    for opt, arg in opts:
        if opt == '-h':
            print usage
            sys.exit()
        elif opt in ("-i", "--input"):
            heightmap_filename = arg
        elif opt in ("-t", "--trained"):
            brain_filename = arg
        elif opt in ("-d", "--dist"):
            d = int(arg)
        elif opt in ("-v", "--vect"):
            r = int(arg)

    heightmap = heightmap_path + heightmap_filename
    brain = brain_path + brain_filename

    # check if directories exist, otherwise create it new
    if not os.path.exists(heatmap_path):
        os.makedirs(heatmap_path)

    # load heightmap
    img = get_image(heightmap)

    # load trained model
    instance = joblib.load(brain)
    clf = instance["model"]

    # get image size
    img_size = get_img_size(img)
    img_width = img_size[0]
    img_height = img_size[1]

    # n divisions is equal to the length of the terrain in VREP
    divisions = 10

    # length in pixels
    side = img_width / (divisions)
    width = (img_width * d) / divisions
    height = width

    # create a new empty image and color each cell with the probability given by the classifier
    heat = np.zeros((img_height, img_width,3), np.uint8)

    y_c = side / 2

    for y in range(0, divisions):
        x_c = side / 2
        for x in range(0, divisions):
            if (y != 0 and x !=0 and y!= (divisions - 1) and (x!= divisions -1)):
                x_c += side
                center = [x_c, y_c]
                cell = extract_patch(img, center, toradians(r), width, height)
                mean, var = get_mean_variance(cell)
                ddepth = cv2.CV_16S
                grad_x = cv2.Scharr(cell, ddepth, 1, 0)
                grad_y = cv2.Scharr(cell, ddepth, 0, 1)
                mean_grad_x, var_grad_x = get_mean_variance(grad_x)
                mean_grad_y, var_grad_y = get_mean_variance(grad_y)
                data = np.array([mean, var, mean_grad_x, var_grad_x, mean_grad_y, var_grad_y])
                traversed = int(clf.predict(data)[0])
                prob = clf.predict_proba(data)[0].tolist()[1] if traversed else clf.predict_proba(data)[0].tolist()[0]
                color = (0,255 * prob ,0) if traversed else (0,0,255 * prob)
                cv2.rectangle(heat, (int(x_c - (side / 2)), int(y_c - (side / 2))), (int(x_c + (side / 2)), int(y_c + (side / 2))), color, -1)
        y_c += side


    # save image in heatmaps folder
    file_with_ext = os.path.basename(heightmap_filename)
    output_dir = heatmap_path + os.path.splitext(file_with_ext)[0] + "/"

    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    dst = cv2.addWeighted(img, 0.7, heat, 0.3, 0)
    dst_path = (output_dir + "heatmap" + str(r) + ".png")
    cv2.imwrite(dst_path, dst)


if __name__ == "__main__":
    main(sys.argv[1:])
