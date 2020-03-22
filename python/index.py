import pymongo
from pymongo import MongoClient
import pprint
client = pymongo.MongoClient("mongodb+srv://hackaton:R8kiR0e3XhIqaVqp@cluster0.yiba8.mongodb.net/ki?retryWrites=true&w=majority")
db = client.ki

from nlp.nlp_api import classify_text

#####################################################
# Scripte Bitte hier einbinden.....
# Bitte mit updateJob(dict,quellen) Job Beenden....
# quellen= [{
#  quelle:1,
#  link:"https://web.de",
#  percent:0.8,
#  stand: new Date() 
#}]
#####################################################

def startSearch(txt,dic):
    print(txt)

    result = classify_text(txt)
   
    updateJob(dic,result["quellen"], result["percent"])


#############################################################

def updateJob(dic,quellen,percent):

    db.jobs.update_one({
            '_id': dic.get("_id")
        },{
            '$set': {
            'ans': {
                'percent':percent,
                'quellen':quellen
            },
            'status':3
        }
    }, upsert=False)






try:
    with db.jobs.watch() as stream:
        for insert_change in stream:
            if insert_change.get('operationType')== 'insert':
               if(insert_change.get('fullDocument').get("status")==2): 
                    print("insert")
                    startSearch(insert_change.get('fullDocument').get("text"),insert_change.get('fullDocument'))
            if insert_change.get('operationType') == 'update':
          
                for record in db.jobs.find():
                     if(record.get("status")==2): 
                         startSearch(record.get("text"),record)

except pymongo.errors.PyMongoError:
    # The ChangeStream encountered an unrecoverable error or the
    # resume attempt failed to recreate the cursor.
    logging.error('...')





