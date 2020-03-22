from joblib import load

from sklearn.pipeline import Pipeline
from sklearn.feature_extraction.text import CountVectorizer
from sklearn import linear_model
import numpy as np
import pandas as pd
import os

file = './nlp/linear_regression.joblib'
model = load(file)

def predict(txt):    

    text = pd.DataFrame([[txt]])
    
    pred = model.predict(text[0])

    return np.round(pred[0] * 100)