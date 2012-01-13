package com.codezen.odnoklassniki
{
	import com.adobe.crypto.MD5;
	import com.codezen.odnoklassniki.service.Base;
	
	import flash.events.Event;
	import flash.net.URLRequest;

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
		
		private function getSignature(method:String, fields:String = null, uids:String = null):String{
			/*
				calculated by string 
				application_key=CBAJLPABABABABABA
				client_id=964608
				client_secret=9119317BAF4BE87ABEAB0897
				code=d9488CO7S9743C2f.d70ahQ8v5df3e0jUc463c.4S33beFTfx2773mVeu26_a399afd0e3a3fdee43cfa0240e015ed5_1312472629
				fields=first_name,last_name,name,gender,birthday,pic_1,city,has_email
				grant_type=authorization_code
				method=users.getInfo
				redirect_uri=about:blank
				uids=116725928664********SECRET KEY*******</error_msg>
			*/
			
			
			var params:String = "application_key="+appPubKey;
			params += "client_id="+appID;
			params += "client_secret="+appKey;
			params += "code="+code;
			if( fields != null) params += "fields="+fields;
			params += "grant_type=authorization_code";
			params += "method="+method;
			params += "redirect_uri=about:blank";
			if( uids != null) params += "uids="+uids;
			params += MD5.hash(access_token + appKey);
			
			return MD5.hash( params );
		}
		
		public function logout():void{
			var url:String = "http://api.odnoklassniki.ru/fb.do?"
			url += "access_token="+access_token;
			url += "&application_key="+appPubKey;
			url += "&method=auth.expireSession";
			
			url += "&sig="+getSignature("auth.expireSession");
			
			myLoader.addEventListener(Event.COMPLETE, onLogout);
			myLoader.load(new URLRequest(url));
		}
		
		private function onLogout(e:Event):void{
			myLoader.removeEventListener(Event.COMPLETE, onLogout);
			
			trace( myLoader.data );
		}

		public function getUserId():void{
			var url:String = "http://api.odnoklassniki.ru/fb.do?"
			url += "access_token="+access_token;
			url += "&application_key="+appPubKey;
			url += "&method=users.getLoggedInUser";
			
			url += "&sig="+getSignature("users.getLoggedInUser");
			
			myLoader.addEventListener(Event.COMPLETE, onUserId);
			myLoader.load(new URLRequest(url));
		}
		
		private function onUserId(e:Event):void{
			myLoader.removeEventListener(Event.COMPLETE, onUserId);
			
			var xml:XML = new XML(myLoader.data);
			
			_userData.id = String(xml);
			_userData.token = code;
			
			endLoad();
		}
		
		public function getUserInfo():void{
			var fields:String = "first_name,last_name,name,gender,birthday,pic_1,city,has_email";
			
			var url:String = "http://api.odnoklassniki.ru/fb.do?"
			url += "access_token="+access_token;
			url += "&application_key="+appPubKey;
			url += "&fields="+fields;
			url += "&method=users.getInfo";
			url += "&uids="+_userData.id;
			
			url += "&sig="+getSignature("users.getInfo", fields, _userData.id);
			
			myLoader.addEventListener(Event.COMPLETE, onUserInfo);
			myLoader.load(new URLRequest(url));
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