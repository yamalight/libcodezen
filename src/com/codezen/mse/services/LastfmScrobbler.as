package com.codezen.mse.services
{	
	import com.codezen.helper.WebWorker;
	import com.codezen.util.MD5;
	
	import flash.desktop.NativeApplication;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	
	public class LastfmScrobbler extends WebWorker
	{		
		private var username:String;
		private var pass:String;
		
		private var apiKey:String;
		private var secretKey:String;
		
		private var sessionKey:String;
		
		private var inited:Boolean;
		
		public function LastfmScrobbler(api:String, secret:String)
		{
			this.apiKey = api;
			this.secretKey = secret;
			
			inited = false;
		}
		
		public function get isInitialized():Boolean
		{
			return inited;
		}

		public function auth(user:String, pwd:String):void{
			username = user;
			pass = pwd; 
			
			init();
		}
		
		public function doScrobble(artist:String, song:String, time:String):void{
			time = time.substr(0, 10);
			
			var signature:String = MD5.encrypt("api_key"+apiKey+"artist[0]"+artist+"methodtrack.scrobble"+"sk"+sessionKey+"timestamp[0]"+time+"track[0]"+song+secretKey);
			
			var variables:URLVariables = new URLVariables();
			variables["sk"] = sessionKey;
			variables["artist[0]"] = artist;
			variables["track[0]"] = song;
			variables["timestamp[0]"] = time;
			variables["api_key"] = apiKey;
			variables["api_sig"] = signature;
			variables["method"] = "track.scrobble";
			
			
			var urlRequest:URLRequest = new URLRequest("http://ws.audioscrobbler.com/2.0/");
			urlRequest.data = variables;
			urlRequest.method = URLRequestMethod.POST;
			
			myLoader.addEventListener(Event.COMPLETE, onScrobble);
			myLoader.load(urlRequest);
		}
		
		private function onScrobble(e:Event):void{	
			trace(myLoader.data);
		}
		
		private function init():void{
			var authToken:String = MD5.encrypt(username + MD5.encrypt(pass));
			var signature:String = MD5.encrypt("api_key"+apiKey+"authToken"+authToken+"methodauth.getMobileSessionusername"+username+secretKey);
			
			// add event listener and load url
			myLoader.addEventListener(Event.COMPLETE, onInit);
			myLoader.load(
				new URLRequest("http://ws.audioscrobbler.com/2.0/?method=auth.getMobileSession&username="+username+"&authToken="+authToken+"&api_key="+apiKey+"&api_sig="+signature)
			);
		}
		
		private function onInit(e:Event):void{
			myLoader.removeEventListener(Event.COMPLETE, onInit);
			
			var xml:XML = new XML(myLoader.data);
			
			sessionKey = xml.session.key.text();
			
			inited = true;
			
			dispatchEvent(new Event(Event.INIT));
		}
		

	}
}