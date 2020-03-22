from datetime import datetime
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn import metrics

from db_api import get_articles

from nlp.find_similar_doc import find_similar_doc

from nlp.linear_regression_predict import predict

def classify_text(text: str):
    percent = predict(text)

    articles = get_articles()
    nurText = dict(map(lambda el: el["text"], articles))
    print(nurText)
    similar_website, similarity_score = find_similar_doc([text], nurText)
    #print(similar_website, similarity_score)
        
    return {
        "percent": percent,
        "quellen": [{
            'quelle': 1,
            'link': similar_website[0],
            'percent': similarity_score[0]*100,
            'stand': datetime.today()
        }, {
            'quelle': 2,
            'link': similar_website[1],
            'percent': similarity_score[1]*100,
            'stand': datetime.today()
        }]
    }
