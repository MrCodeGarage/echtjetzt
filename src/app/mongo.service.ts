import { Injectable } from '@angular/core';
import { MongoObservable } from "meteor-rxjs";

declare var Meteor;

@Injectable({
  providedIn: 'root'
})
export class MongoService {
  public colMongoJob;
  public colObsJob;
  


  constructor() {
    Meteor.startup(() => {
      this.colMongoJob = new Meteor.Collection("jobs");
      this.colObsJob = new MongoObservable.Collection<any>(this.colMongoJob);
    });
  }
}
