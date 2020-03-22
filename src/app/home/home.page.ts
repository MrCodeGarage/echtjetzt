import { Component,NgZone } from '@angular/core';
import { Pipe, PipeTransform } from '@angular/core';

import { AnimationOptions } from 'ngx-lottie';
import {MongoService} from '../mongo.service';
declare var Meteor;


@Pipe({
  name: 'shortDomain'
})
export class ShortDomainPipe implements PipeTransform {

  transform(url: string, args?: any): any {
      if (url) {
          if (url.length > 3) {
              let result;
              let match;
              if (match = url.match(/^(?:https?:\/\/)?(?:www\.)?([^:\/\n?=]+)/im)) {
                  result = match[1];
                  if (match = result.match(/^[^.]+\.(.+\..+)$/))
                      result = match[1];
              }
              return result;
          }
          return url;
      }
      return url;
  }
}

@Component({
  selector: 'app-home',
  templateUrl: 'home.page.html',
  styleUrls: ['home.page.scss'],
})
export class HomePage {
  public inputText = "";
  public switchLongText = false;
  public switchResult   = 1;
  public currentId      = "";
  public switchMode     = 2;

  answer = {
    percent:50,
    quellen:[
      {
        quelle:1,
        link:"https://web.de",
        percent:0.8,
        stand:new Date()
      },
      {
        quelle:2,
        link:"https://spiegel.de",
        percent:0.6,
        stand:new Date()
      }
    ]
  }


  timi;
  onChange(){
    if(typeof this.timi !== "undefined"){
      clearTimeout(this.timi);
    }
    this.timi = setTimeout(() => {
        this.switchResult = 2;
        var isURL = this.validURL(this.inputText);
        console.log(isURL);
        if(isURL === true){
          this.mo.colObsJob.insert({ 
            "text" : this.inputText, 
            "isUrl" : true, 
            "link" : this.inputText, 
            "ans" : null, 
            "status" : 1.0,
            "crawler":null
          }).toPromise().then((data)=>{
            Meteor.call("sendToUrlService",data,this.inputText);
            this.getData(data);
          });
        }else{
          this.mo.colObsJob.insert({ 
            "text" : this.inputText, 
            "isUrl" : false, 
            "link" : "", 
            "ans" : null, 
            "status" : 2.0,
            "crawler":null
          }).toPromise().then((data)=>{
            this.getData(data);
          });
        }
    }, 1000);
  }

  constructor(public ngZone:NgZone, public mo:MongoService) {}


  paste(){
    navigator.clipboard.readText().then((data)=>{
      this.inputText = data;
      this.onChange();
      this.ngZone.run(() => {});

    });
  }

  public optionsLoader:AnimationOptions = {
    path: '/assets/loader.json',
    autoplay:true,
    loop:true

  }

   validURL(str) {
    var pattern = new RegExp('^(https?:\\/\\/)?'+ // protocol
      '((([a-z\\d]([a-z\\d-]*[a-z\\d])*)\\.)+[a-z]{2,}|'+ // domain name
      '((\\d{1,3}\\.){3}\\d{1,3}))'+ // OR ip (v4) address
      '(\\:\\d+)?(\\/[-a-z\\d%_.~+]*)*'+ // port and path
      '(\\?[;&a-z\\d%_.~+=-]*)?'+ // query string
      '(\\#[-a-z\\d_]*)?$','i'); // fragment locator
    return !!pattern.test(str);
  }


  subDpdData;
  subLocalData;
  timeData;
  getData(id){
    if (typeof this.subDpdData !== "undefined") {
      this.subDpdData.stop();
    }
    if (typeof this.subLocalData !== "undefined") {
      this.subLocalData.unsubscribe();
    }
    this.subDpdData = Meteor.subscribe("jobs",id,() => {
      this.subLocalData = this.mo.colObsJob.find({}).subscribe((data: any) => {
        this.timeData = setTimeout(() => {
          if(data.length > 0){
            this.answer = data[0].ans;
            this.switchResult = 3;
           // this.mo.colObsJob.remove({"_id":data[0]._id})
            this.ngZone.run(() => {});
          }
        },1000);
      });
    });

  }
}
