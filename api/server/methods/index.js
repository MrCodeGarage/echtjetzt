import { Meteor } from "meteor/meteor";

var Future = require("fibers/future");



Meteor.methods({
    checkText() {
        return "Juhu"
    }
});