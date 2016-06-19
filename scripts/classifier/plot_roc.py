import numpy as np
import os
import sys
import getopt
import pickle
import matplotlib.pyplot as plt
import sklearn.svm
import sklearn
import sklearn.neighbors
from sklearn.metrics import roc_curve, auc
from sklearn.externals import joblib

dataset_path = "../../data/datasets/"
brain_path = "../../data/brains/"
roc_path = "../../data/roc_auc/"

def main(argv):
    usage = 'plot_roc.py -t <trained_model> -e <testing_dataset> -c <cross_validation_method>'
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

    clf = instance["model"]
    actual = y

    if(cross_method):
        # Use 100 random splits for cross validation
        cv = sklearn.cross_validation.ShuffleSplit(X.shape[0], n_iter=100, test_size=0.10, random_state=0)
        predictions = sklearn.cross_validation.cross_val_predict(clf, X, y, None)
    else:
        # Use training/testing split for cross validation (works because datasets have the same size)
        cv = sklearn.cross_validation.KFold(X.shape[0], n_folds=2, shuffle=False)
        predictions = sklearn.cross_validation.cross_val_predict(clf, X, y, cv)

    false_positive_rate, true_positive_rate, thresholds = roc_curve(actual, predictions)
    roc_auc = auc(false_positive_rate, true_positive_rate)

    if not os.path.exists(roc_path):
        os.makedirs(roc_path)

    file_with_ext = os.path.basename(brain_filename)
    out_file = roc_path + os.path.splitext(file_with_ext)[0]
    plt.title('Receiver Operating Characteristic')
    plt.plot(false_positive_rate, true_positive_rate, 'b',
    label='AUC = %0.2f'% roc_auc)
    plt.legend(loc='lower right')
    plt.plot([0,1],[0,1],'r--')
    plt.xlim([-0.1,1.2])
    plt.ylim([-0.1,1.2])
    plt.ylabel('True Positive Rate')
    plt.xlabel('False Positive Rate')
    plt.savefig(out_file + ".png")
    plt.show()


if __name__ == "__main__":
    main(sys.argv[1:])
