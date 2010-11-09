package com.codezen.vkontakte.api
{
	import com.codezen.util.MD5;
	
	import flash.events.Event;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;

	public class News extends Base
	{
		public function News(appID:String, appKey:String)
		{
			super(appID, appKey);
		}
		
		public function getStatuses():void{
			if(!initialized) return;
			
			var activity:String = "friends.get";
			
			// generate hash
			var md5hash:String =  MD5.encrypt(
				mid+
				"api_id="+appID+
				//format+
				"method="+activity+
				"v=3.0"+
				secret);
			
			var vars:URLVariables = new URLVariables();
			vars.api_id = appID;
			vars.method = activity;
			vars.sig = md5hash;
			vars.v = "3.0";
			vars.sid = sid;//+'&'+format;
			
			
			// assign url
			urlRequest.url =  'http://api.vkontakte.ru/api.php';
			urlRequest.method = URLRequestMethod.POST;
			urlRequest.data = vars;
			
			myLoader.addEventListener(Event.COMPLETE, function():void{
				trace(myLoader.data);
			});
			myLoader.load(urlRequest);
		}
	}
}