#!/usr/bin/python

import os
import pickle
import numpy as np
import sys
import getopt
import sklearn
import sklearn.svm
import sklearn.pipeline
import sklearn.naive_bayes
import sklearn.neighbors
import sklearn.dummy
from sklearn.externals import joblib

dataset_path = "../../data/datasets/"
brain_path = "../../data/brains/"

def main(argv):
    usage = sys.argv[0] + " -t <dataset_filename> -o <brain_filename>"
    try:
        opts, args = getopt.getopt(argv, "ht:o:", ["train=", "out="])
    except getopt.GetoptError:
        print usage
        sys.exit(2)
    for opt, arg, in opts:
        if opt == '-h':
            print usage
            sys.exit()
        elif opt in ("-t", "--train"):
            dataset_filename = arg
        elif opt in ("-o", "--out"):
            brain_filename = arg
            # check extension

    print "Training ... "

    dataset = dataset_path + dataset_filename
    brain = brain_path + brain_filename

    trdata = pickle.load(open(dataset, "rb"))

    models=[sklearn.neighbors.KNeighborsClassifier(3),
            sklearn.svm.SVC(C=0.01),
            sklearn.svm.SVC(C=1),
            sklearn.svm.SVC(C=100),
            sklearn.svm.LinearSVC(),
            sklearn.linear_model.LogisticRegression(),
            sklearn.naive_bayes.GaussianNB(),
            sklearn.dummy.DummyClassifier(strategy="most_frequent"),
            sklearn.dummy.DummyClassifier(strategy="stratified")]

    if not os.path.exists(brain_path):
        os.makedirs(brain_path)


    X = np.array(trdata["data"])
    y = np.array(trdata["target"])

    clf = models[0]
    clf.fit(X,y)
    joblib.dump({"model": clf, "trdata": {"data": X, "target": y}}, brain, compress=1)

    print "Training Complete. Model " + brain_filename + " saved"

if __name__ == "__main__":
    main(sys.argv[1:])
