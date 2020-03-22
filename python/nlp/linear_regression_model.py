import pandas as pd
import numpy as np

from sklearn.pipeline import Pipeline
from sklearn.feature_extraction.text import CountVectorizer
from sklearn import linear_model
from sklearn.metrics import mean_squared_error
from sklearn.model_selection import train_test_split
import sklearn.utils


def initialize(dataset):
    
    #load data and split into test and train set
    data = pd.read_csv(dataset)

    train, test = train_test_split(data, test_size=0.2)

    train_x = train['text'].astype(str)
    train_y = train['label']

    test_x = test['text'].astype(str)
    test_y = test['label']

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

    return model

def predict(text):

    return model.predict(text)

