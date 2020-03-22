from fastapi import FastAPI
from pydantic import BaseModel

from nlp.find_similar_doc import find_similar_doc
from db_api import getArticles

#pip install fastapi[all]
#pip install pymongo
#pip install sklearn

app = FastAPI(
    title="EchtJetzt NLP-REST-API"
)

class Article(BaseModel):
    text: str

#@app.get("/")
#async def root():
#    similar = find_similar_doc(["mein name ist paul"], ["corona ist sehr gefährlich","ich heiße john","wer ist paul","paul macht eine lange reise"])
#    return {"message": "Hello World", "similar": similar}

@app.post("/similar")
async def similar(article: Article):
    db_articles = getArticles()
    most_similar = find_similar_doc([article.text], db_articles)
    return {"most_similar": most_similar}