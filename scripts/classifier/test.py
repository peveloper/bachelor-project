#!/usr/bin/python

import pickle
import numpy as np
import sys, getopt
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
    usage = 'test.py -t <brain_filename> -e <testing_dataset_filename> -c <cross_validation_method>'
    try:
        opts, args = getopt.getopt(argv, "ht:e:c:", ["trained=", "test=", "cross="])
    except getopt.GetoptError:
        print usage
        sys.exit(2)
    for opt, arg in opts:
        if opt == '-h':
            print usage
            sys.exit()
        elif opt in ("-t", "--trained"):
            brain_filename = arg
        elif opt in ("-e", "--test"):
            testing_dataset_filename = arg
        elif opt in ("-c", "--cross"):
            cross_method = int(arg)

    brain = brain_path + brain_filename
    testing_dataset = dataset_path + testing_dataset_filename

    instance = joblib.load(brain)
    trdata = instance["trdata"]

    tedata = pickle.load(open(testing_dataset, 'rb'))

    X=np.vstack((trdata["data"],tedata["data"]))
    y=np.concatenate((trdata["target"],tedata["target"])).astype(int)


    models=[sklearn.neighbors.KNeighborsClassifier(3),
            sklearn.svm.SVC(C=0.01),
            sklearn.svm.SVC(C=1),
            sklearn.svm.SVC(C=100),
            sklearn.svm.LinearSVC(),
            sklearn.linear_model.LogisticRegression(C=100),
            sklearn.naive_bayes.GaussianNB(),
            sklearn.dummy.DummyClassifier(strategy="most_frequent"),
            sklearn.dummy.DummyClassifier(strategy="stratified")]


    if(cross_method):
        # Use 100 random splits for cross validation
        cv = sklearn.cross_validation.ShuffleSplit(X.shape[0], n_iter=100, test_size=0.10, random_state=0)
    else:
        # Use training/testing split for cross validation (works because datasets have the same size)
        cv = sklearn.cross_validation.KFold(X.shape[0], n_folds=2, shuffle=False)

    for m in models:
        clf = sklearn.pipeline.make_pipeline(sklearn.preprocessing.StandardScaler(),m)
        auc = np.mean(sklearn.cross_validation.cross_val_score(clf, X, y, cv=cv, scoring="roc_auc"))
        acc = np.mean(sklearn.cross_validation.cross_val_score(clf, X, y, cv=cv, scoring="accuracy"))
        print("{}: auc {}; accuracy {}.".format(m,auc,acc))


if __name__ == "__main__":
    main(sys.argv[1:])
