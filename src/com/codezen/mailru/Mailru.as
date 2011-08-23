package com.codezen.mailru
{
	import com.codezen.util.MD5;
	
	import flash.events.Event;
	import flash.net.URLRequestMethod;
	
	import mx.utils.ObjectUtil;
	import com.codezen.mailru.service.Base;

	public final class Mailru extends Base
	{
		private var _userData:Object;
		
		public function Mailru(appID:String, appKey:String)
		{
			super(appID, appKey);
		}
		
		public function get userData():Object
		{
			return _userData;
		}

		public function getUserInfo():void{
			// generate hash
			var sig:String =  MD5.encrypt(
				user_id+
				"app_id="+appID+
				"format=xml"+
				"method=users.getInfo"+
				"secure=0"+
				"session_key="+access_token+
				"uid="+user_id+
				appKey);
			
			var url:String = "http://www.appsmail.ru/platform/api?method=users.getInfo";
			url += "&app_id="+appID;
			url += "&session_key="+access_token;
			url += "&uid="+user_id;
			url += "&sig="+sig;
			url += "&secure=0";
			url += "&format=xml";
			
			// assign url
			urlRequest.url =  url;
			
			trace('doing req');
			
			myLoader.addEventListener(Event.COMPLETE, onUserInfo);
			myLoader.load(urlRequest);
		}
		
		private function onUserInfo(e:Event):void{
			myLoader.removeEventListener(Event.COMPLETE, onUserInfo);

			var data:XML = new XML(myLoader.data);
			
			_userData = {
				'id': user_id,
				'bday': data.user.birthday.text(),
				'fname': data.user.first_name.text(),
				'lname': data.user.last_name.text(),
				'location': data.user.location.city.name.text(),
				'sex': data.user.sex.text(),
				'photo': data.user.pic.text(),
				'token': access_token
			}
				
			endLoad();
		}
	}
}