from pymongo import MongoClient
# pprint library is used to make the output look more pretty
from pprint import pprint

# connect to MongoDB, change the << MONGODB URL >> to reflect your own connection string
client = MongoClient("mongodb+srv://hackaton:R8kiR0e3XhIqaVqp@cluster0.yiba8.mongodb.net/ki?retryWrites=true&w=majority")


#db=client.admin
# Issue the serverStatus command and print the results
#serverStatusResult=db.command("serverStatus")
#pprint(serverStatusResult)

articles_ref = client.ki["articles"]

def get_articles():
    result_cursor = articles_ref.find({})
    result = []
    for doc in result_cursor:
        result.append(doc["content"])
    return result