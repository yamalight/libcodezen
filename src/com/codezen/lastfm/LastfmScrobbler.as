package com.codezen.lastfm
{	
	import com.codezen.util.MD5;
	
	import flash.desktop.NativeApplication;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	
	public class LastfmScrobbler extends EventDispatcher
	{
		// event dispatcher action
		public static var ERROR:String = "ScrobblerError";
		
		private var username:String;
		private var pass:String;
		
		private var client_id:String = "mie";//"msf";
		private var client_ver:String;
		
		private var sessionID:String;
		private var submissionURL:String;
		
		private var artist:String;
		private var song:String;
		private var timestart:String;
		private var songLenght:int;
		
		public var errorText:String = null;
		
		public function LastfmScrobbler(user:String, pwd:String)
		{
			username = user;
			pass = pwd;
			
			var appXML:XML = NativeApplication.nativeApplication.applicationDescriptor;  
    	 	var ns:Namespace = appXML.namespace();
    	 	client_ver = appXML.ns::version; 
						
			init();
		}
		
		public function doScrobble(art:String, track:String, time:String, len:int):void{
			if(errorText == null){
				artist = art;
				song = track;
				timestart = time.substr(0, 10);
				songLenght = len;
			
				scrobbleNow();
			}
		}
		
		public function reportError():String{
			return errorText;
		}
		
		private function init():void{
			var urlload:URLLoader= new URLLoader();
			var timestamp:String = new Date().getTime().toString();
			timestamp = timestamp.substr(0, 10);
			var auth:String = MD5.encrypt( MD5.encrypt(pass) + timestamp );
			var url:String = new String("http://post.audioscrobbler.com/?hs=true&p=1.2.1&c="+client_id+"&v="+client_ver+
										"&u="+username+"&t="+timestamp+"&a="+auth);
										
			var urlreq:URLRequest = new URLRequest(url);
			urlload.addEventListener(IOErrorEvent.IO_ERROR, onLastfmError);
			urlload.addEventListener(Event.COMPLETE, onRecieve);
			urlload.load(urlreq);
			trace('scrobble inited');
		}
		
		protected function onLastfmError(e:Event):void{			
			// call event
			dispatchEvent(new Event(Event.COMPLETE));
		}
		
		private function onRecieve(e:Event):void{
			var recieve:String = e.target.data;
			var res:Array = recieve.split('\n');
			
			var responseCode:String = res[0];
			trace("response from lastfm:"+res[0]);
			if(responseCode == "OK"){
				sessionID = res[1];
				submissionURL = res[3];
				errorText = null;
			}else{
				errorText = responseCode;
				dispatchEvent(new Event(LastfmScrobbler.ERROR));
			}
		}
		
		private function scrobbleNow():void{			
			var urlreq:URLRequest = new URLRequest(submissionURL);
			var variables:URLVariables = new URLVariables();
            variables["s"] = sessionID;
            variables["a[0]"] = artist;
            variables["t[0]"] = song;
            variables["i[0]"] = timestart;
            variables["o[0]"] = "P";
            variables["r[0]"] = "";
            variables["l[0]"] = songLenght;
            variables["b[0]"] = "";
            variables["n[0]"] = "";
            variables["m[0]"] = "";
            urlreq.data = variables;
			urlreq.method = URLRequestMethod.POST;
			var urlload:URLLoader = new URLLoader();
			urlload.addEventListener(Event.COMPLETE, onScrobble);
			urlload.load(urlreq);
		}
		
		
		
		
		private function onScrobble(e:Event):void{
			var recieve:String = e.target.data;
			
			trace(recieve);
		}

	}
}