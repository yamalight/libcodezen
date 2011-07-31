package com.codezen.odnoklassniki
{
	import com.adobe.crypto.MD5;
	import com.codezen.odnoklassniki.service.Base;
	
	import flash.events.Event;

	public class Odnoklassniki extends Base
	{
		private var _userData:Object;
		
		public function Odnoklassniki(appID:String, appKey:String, appPubKey:String)
		{
			super(appID, appKey, appPubKey);
			
			_userData = {};
		}
		
		public function get userData():Object
		{
			return _userData;
		}
		
		private function getSignature(method:String):String{
			var params:String = "application_key="+appPubKey;
			params += "client_id="+appID;
			params += "client_secret="+appKey;
			params += "code="+code;
			params += "grant_type=authorization_code";
			params += "method="+method;
			params += "redirect_uri=about:blank";
			params += MD5.hash(access_token + appKey);
			
			return MD5.hash( params );
		}

		public function getUserId():void{
			var url:String = "http://api.odnoklassniki.ru/fb.do?"
			url += "access_token="+access_token;
			url += "&application_key="+appPubKey;
			url += "&method=users.getLoggedInUser";
			
			url += "&sig="+getSignature("users.getLoggedInUser");
			
			urlRequest.url = url;
			
			myLoader.addEventListener(Event.COMPLETE, onUserId);
			myLoader.load(urlRequest);
		}
		
		private function onUserId(e:Event):void{
			myLoader.removeEventListener(Event.COMPLETE, onUserId);
			
			var xml:XML = new XML(myLoader.data);
			
			_userData.id = String(xml);
			_userData.token = code;
			
			endLoad();
		}
		
		public function getUserInfo():void{
			var url:String = "http://api.odnoklassniki.ru/fb.do?"
			url += "access_token="+access_token;
			url += "&application_key="+appPubKey;
			url += "&fields=first_name,last_name,name,gender,birthday,pic_1,city,has_email";
			url += "&method=users.getInfo";
			url += "&uids="+_userData.id;
			
			url += "&sig="+getSignature("users.getInfo");
			
			urlRequest.url = url;
			
			myLoader.addEventListener(Event.COMPLETE, onUserInfo);
			myLoader.load(urlRequest);
		}
		
		private function onUserInfo(e:Event):void{
			myLoader.removeEventListener(Event.COMPLETE, onUserInfo);
			
			var xml:XML = new XML(myLoader.data);
			
			trace(xml);
			
			/*_userData.id = String(xml);
			_userData.token = code;
			
			endLoad();*/
		}
	}
}