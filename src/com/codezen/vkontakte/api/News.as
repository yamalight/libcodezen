package com.codezen.vkontakte.api
{
	import com.codezen.util.CUtils;
	import com.codezen.util.MD5;
	import com.codezen.vkontakte.api.data.NewsItem;
	import com.codezen.vkontakte.api.data.Photo;
	import com.codezen.vkontakte.api.data.User;
	import com.codezen.vkontakte.api.service.Base;
	
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.utils.Timer;
	
	import mx.collections.ArrayCollection;
	import mx.utils.ObjectUtil;
	
	public class News extends Base
	{
		// statuses result
		private var statuses:ArrayCollection;
		// users data
		private var users:ArrayCollection;
		// photos data
		private var photos:ArrayCollection;
		
		public function News(appID:String, appKey:String)
		{
			super(appID, appKey);
		}
		
		public function get statusList():ArrayCollection{
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
			
			// create new collections
			statuses = new ArrayCollection();
			users = new ArrayCollection();
			photos = new ArrayCollection();
			
			// get data
			var xml:XML = new XML(myLoader.data);
			var stats:XMLList = new XMLList(xml.activity);
			var item:Object;
			var newsItem:NewsItem;
			
			for each(item in stats){
				// reset item
				newsItem = new NewsItem();
				
				// append common data
				newsItem.id = item.id.text();
				newsItem.time = item.timestamp.text();
				// user data
				newsItem.user = new User();
				newsItem.user.id = item.uid.text();
				
				// add user to collection
				if( CUtils.getItemIndexByProperty(users, "id", newsItem.user.id) == -1 ){
					users.addItem({id: newsItem.user.id});
				} 
				
				// check for text
				if(String(item.text.text()).length > 0){
					// append data
					newsItem.text = item.text.text();
					newsItem.type = "text";
					
					// push to array
					statuses.addItem(newsItem);
					
					// check for photos
				}else if(item.media != null && item.media.type.text() == "photo"){
					// append data
					//newsItem.owner = item.media.owner_id.text();
					//newsItem.item = item.media.item_id.text();
					newsItem.type = "photo";
					newsItem.photo = new Photo();
					newsItem.photo.id = item.media.item_id.text();
					newsItem.photo.owner = item.media.owner_id.text();
					
					// add photo to collection
					if( CUtils.getItemIndexByProperty(photos, "id", newsItem.photo.id) == -1 ){
						photos.addItem({id: newsItem.photo.id, user:newsItem.photo.owner});
					} 
					
					// push to array
					statuses.addItem(newsItem);
					
					// chech for audio
				}else if(item.media != null && item.media.type.text() == "audio"){
					// append data
					newsItem.owner = item.media.owner_id.text();
					newsItem.item = item.media.item_id.text();
					newsItem.type = "audio";
					// push to array
					statuses.addItem(newsItem);
					
					// check for video
				}else if(item.media != null && item.media.type.text() == "video"){
					// append data
					newsItem.owner = item.media.owner_id.text();
					newsItem.item = item.media.item_id.text();
					newsItem.type = "video";
					// push to array
					statuses.addItem(newsItem);
				}
			}
			
			// cleanup
			xml = null;
			stats = null;
			item = null;
			newsItem = null;
			
			// get additional info
			//getInfoForNews();
			getUsersData();
		}
		
		private function getUsersData():void{
			var activity:String = "getProfiles";
			var fields:String = "first_name, last_name, nickname, sex, photo";
			var uid:String = "";
			
			var i:int;
			for(i = 0; i < users.length; i++){
				if( i+1 == users.length ){
					uid += users[i].id;
				}else{
					uid += users[i].id+",";
				}
			}
			
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
			urlRequest.url = "http://api.vkontakte.ru/api.php";
			urlRequest.method = URLRequestMethod.POST;
			urlRequest.data = vars;
			
			// load
			myLoader.addEventListener(Event.COMPLETE, onUsersData);
			myLoader.load(urlRequest);
		}
		
		private function onUsersData(e:Event):void{
			// remove event listener
			myLoader.removeEventListener(Event.COMPLETE, onUsersData);
			
			// get result
			var xml:XMLList = new XMLList( XML(myLoader.data).user );
			
			var user:Object;
			var ind:int;
			for each(user in xml){
				ind = CUtils.getItemIndexByProperty(users, "id", user.uid);
				if( ind != -1 ){
					users.removeItemAt(ind);
					
					users.addItem({
						id: user.uid,
						name: user.first_name.text(),
						nickname: user.nickname.text(),
						lastname: user.last_name.text(),
						sex: user.last_name.text(),
						photo: user.photo.text()
					});
				}
			}
			
			var item:NewsItem;
			for each(item in statuses){
				ind = CUtils.getItemIndexByProperty(users, "id", item.user.id);
				if( ind != -1 ){
					item.user.name = users[ind].name;
					item.user.nickname = users[ind].nickname;
					item.user.lastname = users[ind].lastname;
					item.user.sex = users[ind].sex;
					item.user.photo = users[ind].photo;
				}
			}
			
			//end();
			getPhotosData();
		}
		
		private function getPhotosData():void{			
			var activity:String = "photos.getById";
			var photosid:String = "";
			
			var i:int;
			for(i = 0; i < photos.length; i++){
				if( i+1 == photos.length ){
					photosid += photos[i].user+"_"+photos[i].id;
				}else{
					photosid += photos[i].user+"_"+photos[i].id+",";
				}
			}
			
			// generate hash
			var md5hash:String =  MD5.encrypt(
				mid+
				"api_id="+appID+
				"method="+activity+
				"photos="+photosid+
				"v=3.0"+
				secret);
			
			var vars:URLVariables = new URLVariables();
			vars.api_id = appID;
			vars.photos = photosid;
			vars.method = activity;
			vars.sig = md5hash;
			vars.v = "3.0";
			vars.sid = sid;
			
			// assign url
			urlRequest.url = "http://api.vkontakte.ru/api.php";
			urlRequest.method = URLRequestMethod.POST;
			urlRequest.data = vars;
			
			// load
			myLoader.addEventListener(Event.COMPLETE, onPhotosData);
			myLoader.load(urlRequest);
		}
		
		private function onPhotosData(e:Event):void{
			// remove event listener
			myLoader.removeEventListener(Event.COMPLETE, onPhotosData);
			
			// get result
			var xml:XMLList = new XMLList( XML(myLoader.data).photo );
			
			var photo:Object;
			var ind:int;
			for each(photo in xml){
				ind = CUtils.getItemIndexByProperty(photos, "id", photo.pid);
				if( ind != -1 ){
					photos.removeItemAt(ind);
					
					photos.addItem({
						id: photo.pid.text(),
						user: photo.owner_id.text(),
						src: photo.src.text(),
						src_big: photo.src_big.text(),
						src_small: photo.src_small.text()
					});
				}
			}
			
			var item:NewsItem;
			for each(item in statuses){
				if( item.photo != null ){
					ind = CUtils.getItemIndexByProperty(photos, "id", item.photo.id);
					if( ind != -1 ){
						item.photo.src = photos[ind].src;
						item.photo.src_big = photos[ind].src_big;
						item.photo.src_small = photos[ind].src_small;
					}
				}
			}
			
			end();
		}
	}
}















