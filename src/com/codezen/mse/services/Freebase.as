package com.codezen.mse.services {
import com.codezen.helper.WebWorker;
import com.codezen.mse.models.Artist;

import flash.events.Event;
import flash.utils.describeType;

import mx.utils.ObjectUtil;

public class Freebase extends WebWorker {
        // music artist properties
        private static var TYPE:String = "/music/artist";
        private static var validProperties:Array = ["active_start","active_end","name","home_page","acquire_webpage"];
        private static var validArrays:Array = ["origin","label","genre","album","contribution","track","track_contributions","concert_tours","supporting_artists"];

        // query endpoint
        private static var endpoint:String = "http://api.freebase.com/api/service/mqlread?query=";

        // limit
        private static var LIMIT:int = 10;

        // query vars
        private var query:Object;
        private var queryWrap:Object;

        /*
        http://api.freebase.com/api/service/mqlread?query={"query":{"type":"/music/artist","name":"The Police","album":[]}}

        MQL docs: http://www.freebase.com/docs/mql

        query example:
        [{
          "type":"/music/artist",
          "name": null,
          "genre": "Indie pop",
          "origin": "United Kingdom",
          "active_start": null
        }]​

         */

        public function Freebase() {
            super();
        }

        public function initQuery(artist:Artist):void{
            query = {"type":TYPE, "id":null, "limit":LIMIT};

            // parse input
            var def:XML = describeType(artist);
            var props:XMLList = def..variable.@name;
            for each (var prop:String in props) {
                if( validProperties.indexOf(prop) != -1 ){
                    trace('adding '+prop + ": " + artist[prop]);
                    if(artist[prop] != null){
                        query[prop] = null;
                        if( artist[prop] != null && artist[prop] != "[result]"){
                            query[prop+"~="] = artist[prop];
                        }
                    }
                }else if( validArrays.indexOf(prop) != -1 ){
                    trace('adding array '+prop + ": " + artist[prop]);
                    if(artist[prop] != null){
                        if(artist[prop][0] != "[result]"){
                            query[prop] = artist[prop];
                        }else if(artist[prop][0] == "[result]"){
                            query[prop] = [];
                        }
                    }
                }
            }
        }

        public function execQuery():void{
            queryWrap = {"query":[query]};

            //trace( JSON.encode(queryWrap) );

            // request here
            urlRequest.url = endpoint+encodeURIComponent(JSON.stringify(queryWrap));
            myLoader.addEventListener(Event.COMPLETE, onResult);
            myLoader.load(urlRequest);
        }

        private function onResult(e:Event):void{
            trace(myLoader.data);
        }

    }
}
