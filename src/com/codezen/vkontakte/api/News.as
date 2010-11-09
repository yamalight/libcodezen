package com.codezen.vkontakte.api
{
	import com.codezen.util.MD5;
	import com.codezen.vkontakte.api.data.NewsItem;
	import com.codezen.vkontakte.api.service.Base;
	
	import flash.events.Event;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	
	import mx.collections.ArrayCollection;
	import mx.utils.ObjectUtil;

	public class News extends Base
	{
		// statuses result
		private var statuses:Vector.<NewsItem>;
		
		public function News(appID:String, appKey:String)
		{
			super(appID, appKey);
		}
		
		public function get statusList():Vector.<NewsItem>{
			return statuses;
		}
		
		public function getStatuses():void{
			if(!initialized) return;
			
			var activity:String = "activity.getNews";
			var count:String = "100";
			
			// generate hash
			var md5hash:String =  MD5.encrypt(
				mid+
				"api_id="+appID+
				"count="+count+
				"method="+activity+
				"v=3.0"+
				secret);
			
			var vars:URLVariables = new URLVariables();
			vars.api_id = appID;
			vars.count = count;
			vars.method = activity;
			vars.sig = md5hash;
			vars.v = "3.0";
			vars.sid = sid;//+'&'+format;
			
			// assign url
			urlRequest.url =  'http://api.vkontakte.ru/api.php';
			urlRequest.method = URLRequestMethod.POST;
			urlRequest.data = vars;
			
			myLoader.addEventListener(Event.COMPLETE, onStatusesRecieve);
			myLoader.load(urlRequest);
		}
		
		private function onStatusesRecieve(e:Event):void{
			// remove old listener
			myLoader.removeEventListener(Event.COMPLETE, onStatusesRecieve);
			
			// create new collection
			statuses = new Vector.<NewsItem>();
			
			// get data
			var xml:XML = new XML(myLoader.data);
			var stats:XMLList = new XMLList(xml.activity);
			var item:Object;
			var newsItem:NewsItem;
			
			for each(item in stats){
				// reset item
				newsItem = new NewsItem();
				// check for text
				if(String(item.text.text()).length > 0){
					// append data
					newsItem.id = item.id.text();
					newsItem.uid = item.uid.text();
					newsItem.text = item.text.text();
					newsItem.time = item.timestamp.text();
					newsItem.type = "text";
					// push to array
					statuses.push(newsItem);
				
				// check for photos
				}else if(item.media != null && item.media.type.text() == "photo"){
					// append data
					newsItem.id = item.id.text();
					newsItem.uid = item.uid.text();
					newsItem.time = item.timestamp.text();
					newsItem.owner = item.media.owner_id.text();
					newsItem.item = item.media.item_id.text();
					newsItem.type = "photo";
					// push to array
					statuses.push(newsItem);
					
				// chech for audio
				}else if(item.media != null && item.media.type.text() == "audio"){
					// append data
					newsItem.id = item.id.text();
					newsItem.uid = item.uid.text();
					newsItem.time = item.timestamp.text();
					newsItem.owner = item.media.owner_id.text();
					newsItem.item = item.media.item_id.text();
					newsItem.type = "audio";
					// push to array
					statuses.push(newsItem);
					
				// check for video
				}else if(item.media != null && item.media.type.text() == "video"){
					// append data
					newsItem.id = item.id.text();
					newsItem.uid = item.uid.text();
					newsItem.time = item.timestamp.text();
					newsItem.owner = item.media.owner_id.text();
					newsItem.item = item.media.item_id.text();
					newsItem.type = "video";
					// push to array
					statuses.push(newsItem);
				}
			}
			
			// cleanup
			xml = null;
			stats = null;
			item = null;
			newsItem = null;
			
			// get additional info
			getInfoForNews();
		}
		
		private function getInfoForNews():void{
			// create item
			var newsItem:NewsItem;
			
			// parse through all stuff
			for each(newsItem in statuses){
				// get user data
				getUserData(newsItem);
				
				// do stuff depending from item type
				switch(newsItem.type){
					// if text
					case "text": {
						//getUserData(newsItem);
						break;
					}
					
					default: {
						break;
					}
				}
			}
			
			end();
		}
		
		private function getUserData(item:NewsItem):void{
			var activity:String = "getProfiles";
			var uid:String = item.uid;
			var fields:String = "first_name, last_name, nickname, sex, photo_medium";
			
			// generate hash
			var md5hash:String =  MD5.encrypt(
				mid+
				"api_id="+appID+
				"fields="+fields+
				"method="+activity+
				"uids="+uid+
				"v=3.0"+
				secret);
			
			var vars:URLVariables = new URLVariables();
			vars.api_id = appID;
			vars.uids = uid;
			vars.fields = fields;
			vars.method = activity;
			vars.sig = md5hash;
			vars.v = "3.0";
			vars.sid = sid;//+'&'+format;
			
			// assign url
			var req:URLRequest = new URLRequest('http://api.vkontakte.ru/api.php');
			req.method = URLRequestMethod.POST;
			req.data = vars;
			
			var load:URLLoader = new URLLoader();
			load.addEventListener(Event.COMPLETE, function():void{
				//trace( load.data );
				var xml:XMLList = new XMLList( XML(load.data).user );
				
				//if ( String( xml.photo_medium.) ).length < 1 ){
					trace(xml);
					trace('-----------------------------------------------');
				//}
				
				// assign
				item.user_name = xml.first_name.text();
				item.user_nname = xml.nickname.text();
				item.user_lname = xml.last_name.text();
				item.user_sex = xml.sex.text();
				item.user_photo = xml.photo_medium.text();
			});
			load.load(req);
		}
	}
}















