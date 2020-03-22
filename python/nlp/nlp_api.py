from datetime import datetime

from db_api import get_articles

from nlp.find_similar_doc import find_similar_doc

def classify_text(text: str):
    percent = 70
    similarDocs = find_similar_doc([text], get_articles())
    print(similarDocs)
        
    return {
        "percent": percent,
        "quellen": [{
            'quelle': 1,
            'link': 'https://web.de',
            'percent': 50,
            'stand': datetime.today()
        }, {
            'quelle': 2,
            'link': 'https://spiegel.de',
            'percent': 80,
            'stand': datetime.today()
        }]
    }
