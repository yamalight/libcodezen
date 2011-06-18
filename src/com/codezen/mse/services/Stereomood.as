package com.codezen.mse.services
{
	import com.adobe.crypto.MD5;
	import com.adobe.crypto.SHA1;
	/*import com.coderanger.OAuthEvent;
	import com.coderanger.OAuthManager;
	import com.coderanger.QueryString;*/
	import com.codezen.helper.WebWorker;
	
	import flash.events.Event;
	
	import mx.controls.Alert;
	import mx.utils.ObjectUtil;
	
	public final class Stereomood extends WebWorker
	{
		private var _moodsList:Array;
		
		public function Stereomood()
		{
			super();
			// TODO: figure out how to work with stereomood without user account
			return;
		}
		
		
		public function get moodsList():Array
		{
			return _moodsList;
		}
		
		public function findMood(query:String):void{
			return;
		}
		
		private function onLoad(e:Event):void{
			trace(myLoader.data);
		}

	}
}