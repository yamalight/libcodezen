package com.codezen.helper
{
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLRequest;

	public final class URLArrayLoader extends WebWorker
	{
		private var _urls:Array;

		private var _onload:Function;
		
		private var urlsLength:int;
		private var index:int;
		
		public function URLArrayLoader(urls:Array)
		{
			super();
			
			_urls = urls;
			myLoader.addEventListener(Event.COMPLETE, onDataLoad);
		}
		
		public function set onload(value:Function):void
		{
			_onload = value;
		}
		
		public function loadURLs():void{
			index = 0;
			urlsLength = _urls.length;
			
			loadNextURL();
		}
		
		private function loadNextURL():void{
			var url:String = _urls[index];
//			trace('loading '+url);
			urlRequest.url = url;
			myLoader.load(urlRequest);
		}
		
		private function onDataLoad(e:Event):void{
//			trace('complete: '+String(myLoader.data).length);
			
			_onload(myLoader.data);
			
			checkEnd();
		}
		
		private function checkEnd():void{
			index++;
			
//			trace('check end index: '+index);
			
			if(index >= urlsLength){
//				trace('end load');
				endLoad();
			}else{
//				trace('loading next. '+ (urlsLength-index) +' left');
				loadNextURL();
			}
		}
		
		protected override function onError(e:ErrorEvent):void{
//			trace('error');
			
			checkEnd();
		}
	}
}