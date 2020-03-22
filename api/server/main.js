import { Meteor } from 'meteor/meteor';

Meteor.startup(() => {
  // code to run on server at startup

  Articles = new Mongo.Collection('articles');

  // Global API configuration
  var Api = new Restivus({
    version: 'v1',
    useDefaultAuth: true,
    prettyJson: true
  });

  Api.addCollection(Articles, {
    excludedEndpoints: ["delete", "post", "patch", "put"],
  });

});
