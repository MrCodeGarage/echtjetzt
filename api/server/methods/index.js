import { Meteor } from "meteor/meteor";

var Future = require("fibers/future");



Meteor.methods({
    sendToUrlService(id, url) {
        return "Juhu"
    }
});