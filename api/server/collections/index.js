import { MongoObservable } from "meteor-rxjs";
import { Meteor } from "meteor/meteor";
import { Mongo } from "meteor/mongo";


export const mongoJobs = new Mongo.Collection("jobs");
export const Jobs = new MongoObservable.Collection(mongoJobs);

Jobs.allow({
    insert(userId, doc) {

        return true;
    },
    update(userId, doc, fields, modifier) {
        if (!userId) {
            return;
        }
        return true;
    },
    remove(userId, doc) {

        return true;
    }
});