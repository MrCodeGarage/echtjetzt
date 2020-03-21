import { Component,NgZone } from '@angular/core';

@Component({
  selector: 'app-home',
  templateUrl: 'home.page.html',
  styleUrls: ['home.page.scss'],
})
export class HomePage {
  public inputText = "";
  public switchLongText = false;
  public switchResult   = 1;

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
        Meteor.call("checkText",()=>{
          this.switchResult = 3;
          this.ngZone.run(() => {});
        });
    }, 1000);
  }

  constructor(public ngZone:NgZone) {}

}
