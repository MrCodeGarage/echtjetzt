import pandas as pd
import numpy as np

from sklearn.pipeline import Pipeline
from sklearn.feature_extraction.text import CountVectorizer
from sklearn import linear_model
from sklearn.metrics import mean_squared_error
from sklearn.model_selection import train_test_split
import sklearn.utils

import argparse
from joblib import dump

def args():
    parser = argparse.ArgumentParser(description='parser for data set, source and target')

    parser.add_argument('--dataset', required=True, help=('data set that contains training data. Should be in .csv format'))
    parser.add_argument('--source', required=True, help=('name of the given variable'))
    parser.add_argument('--target', required=True, help=('name of the predicted variable'))

    args = parser.parse_args()

    return args


def train_model(dataset, source, target):
    
    #load data and split into test and train set
    data = pd.read_csv(dataset)

    train, test = train_test_split(data, test_size=0.2)

    train_x = train[source].astype(str)
    train_y = train[target]

    test_x = test[source].astype(str)
    test_y = test[target]

    #Preprocessing and training

    print('Start training...')
    model = Pipeline([('unigram_vectorizer', CountVectorizer(max_df=10000, min_df=100)),
                        ('ridge_reg', linear_model.Ridge())])

    model.fit(train_x, train_y)

    #validation

    pred_train_y = model.predict(train_x)

    print('Error over train set: ', mean_squared_error(train_y, pred_train_y))

    pred_test_y = model.predict(test_x)
    print('Error over test set:, ',mean_squared_error(test_y, pred_test_y))

    dump(model, '⁨KIBasierteErkennungVonFakeNews⁩/⁨python⁩/nlp⁩/linear_regression.joblib')


if __name__ == "__main__":
    args = args()

    dataset = args.dataset
    source = args.source
    target = args.target

    train_model(dataset, source, target)

