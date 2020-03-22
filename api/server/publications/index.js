import { Meteor } from 'meteor/meteor';
import {
    Jobs
} from '../collections/index';
var Future = require('fibers/future');

/** 
 *  Allgemein
 */
Meteor.publish('jobs', function(id) {
    return Jobs.find({ "status": 3, "_id": id })
});

function makeid(length) {
    var result = '';
    var characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    var charactersLength = characters.length;
    for (var i = 0; i < length; i++) {
        result += characters.charAt(Math.floor(Math.random() * charactersLength));
    }
    return result;
};