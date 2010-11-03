package com.codezen.music.search
{
	import com.codezen.helper.Worker;
	import com.codezen.util.MD5;
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	
	public class VkApiMusic extends Worker implements ISearch
	{
		// api kaye
		private var apiId:String;
		private var apiKey:String;
		
		// result of search
		private var result:String;
		
		// limit of search
		private var limit:int;
		
		// limit of duration
		private var finddur:int;
		
		// loader and request
		private var urlRequest:URLRequest;
		private var myLoader:URLLoader;
		
		/**
		 * Constructor.
		 * Inits loader and request 
		 */
		public function VkApiMusic()
		{
			// init keys
			var apiKeys:Array = new Array();
			apiKeys[0] = "1878252:bWljxaglcm";
			apiKeys[1] = "1878257:iXeOzlqBqL";
			apiKeys[2] = "1878261:nrwqj8lvTH";
			apiKeys[3] = "1878262:QPQWOeSlJ7";
			apiKeys[4] = "1878263:tnIn7jFh4C";
			apiKeys[5] = "1878266:GkKToIOjGW";
			apiKeys[6] = "1878267:dBbcueh4JW";
			apiKeys[7] = "1878268:vOrc2D0oxh";
			apiKeys[8] = "1878269:NJTjZds8Rc";
			apiKeys[9] = "1878270:a0LUh2Kmrg";
			apiKeys[10] = "1878273:mv89KKdvly";
			apiKeys[11] = "1878274:DPtkr3dLdm";
			apiKeys[12] = "1878275:92vTCPHjbm";
			apiKeys[13] = "1878276:O3TJyO4Tmg";
			apiKeys[14] = "1878277:xH2j6KCvxi";
			apiKeys[15] = "1878286:pHpMrvogSs";
			apiKeys[16] = "1878287:k6BO29WRRS";
			apiKeys[17] = "1878289:Aq6ALH66zw";
			apiKeys[18] = "1878290:svh5NWj4EW";
			apiKeys[19] = "1878291:FTalzIN88Z";
			
			// get random key
			var i:int = Math.round(Math.random()*19);
			var resutArr:Array = apiKeys[i].toString().split(":");
			apiId = resutArr[0];
			apiKey = resutArr[1];
			
			// init request and loader
			urlRequest = new URLRequest();
			myLoader = new URLLoader();
			// set params and add error event listener
			urlRequest.requestHeaders['Referer'] = "http://vkontakte.ru/";
			myLoader.dataFormat = URLLoaderDataFormat.TEXT;
			//myLoader.dataFormat = URLLoaderDataFormat.BINARY;
			myLoader.addEventListener(IOErrorEvent.IO_ERROR, onError);
		}
		
		public function initAuth(login:String='', pass:String=''):void{};
		
		/**
		 * Get search result 
		 * @return mp3 url
		 * 
		 */
		public function get resultString():String
		{
			return result;
		}
		
		/**
		 * Returns search class name 
		 * @return class name (VkAPI)
		 * 
		 */
		public function get classAlias():String{
			return "VkApiMusic";
		}
		
		/**
		 * If class requires authentification 
		 * @return bool
		 * 
		 */
		public function get requireAuth():Boolean{
			return false;
		}
		
		/**
		 * Find url for given song 
		 * @param query search request
		 * @param limit result amount limit
		 * @param finddur song duration
		 * 
		 */
		public function findData(query:String, limit:int=1, finddur:int=0):void
		{
			// generate hash
			var md5hash:String =  MD5.encrypt('61745456api_id='+apiId+'count=10method=audio.searchq='+query+'test_mode=1'+apiKey);
			// assign url
			urlRequest.url =  'http://api.vkontakte.ru/api.php?api_id='+apiId+'&count=10&method=audio.search&sig='+md5hash+'&test_mode=1&q='+query;
			
			// assign complete event
			myLoader.addEventListener(Event.COMPLETE, onSearchComplete);
			// load request
			myLoader.load(urlRequest);
		}
		
		/**
		 * 
		 * @param evt
		 * Result parser on recieve
		 */
		private function onSearchComplete(evt:Event):void{
			trace('done search');
			// add event listener and load url
			myLoader.removeEventListener(Event.COMPLETE, onSearchComplete);
			
			// get result data
			var dataXML:XML = new XML(evt.target.data);
			var songsList:XMLList = dataXML.audio;
			
			if(songsList.length() > 0){
				result = songsList[0].url;
			}else{
				result = null;
			}
			
			// send end event
			endLoad();
		}
		
		/**
		 * Error parser
		 **/
		private function onError(e:IOErrorEvent):void{
			dispatchError(e.text, "IO Error happened in VkNews class");
		}
	}
}