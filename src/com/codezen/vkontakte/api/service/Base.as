package com.codezen.vkontakte.api.service
{
	import com.codezen.helper.Worker;
	
	import flash.display.NativeWindow;
	import flash.display.NativeWindowInitOptions;
	import flash.display.NativeWindowSystemChrome;
	import flash.display.NativeWindowType;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.LocationChangeEvent;
	import flash.events.TimerEvent;
	import flash.geom.Rectangle;
	import flash.media.StageWebView;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.Timer;

	public class Base extends Worker
	{
		// app data
		protected var appID:String;
		protected var appKey:String;
		protected var appPermissions:String;
		
		// auth data
		protected var expire:String;
		protected var mid:String;
		protected var secret:String;
		protected var sid:String;
		protected var sig:String;
		
		// initialized state
		protected var initialized:Boolean;
		
		// loader and request
		protected var urlRequest:URLRequest;
		protected var myLoader:URLLoader;
		
		// auth wnd
		protected var html:StageWebView;
		protected var window:NativeWindow;
		
		// timer
		private var windowTimer:Timer;
		
		public function Base(appID:String, appKey:String, appPermissions:String){
			this.appID = appID;
			this.appKey = appKey;
			this.appPermissions = appPermissions;
			createClass();
		}
		
		public function get sessionKey():String{
			return sid;
		}
		
		protected function createClass():void
		{
			// init state
			initialized = false;
			
			// init request and loader
			urlRequest = new URLRequest();
			myLoader = new URLLoader();
			// set params and add error event listener
			//urlRequest.requestHeaders['Referer'] = "http://vk.com/";
			//myLoader.dataFormat = URLLoaderDataFormat.TEXT;
			myLoader.dataFormat = URLLoaderDataFormat.BINARY;
			myLoader.addEventListener(IOErrorEvent.IO_ERROR, onError);
			// run init
			init();
		}
		
		/**
		 * If class is initialized 
		 * @return 
		 * 
		 */
		public function get isInitialized():Boolean{
			return initialized;
		}
		
		/**
		 * Initializes class: checks if user already logged in 
		 * and if not - logs in.
		 * Must be executed before search 
		 */
		public function init():void{
			// create window options
			var windowInitOptions:NativeWindowInitOptions = new NativeWindowInitOptions();
			windowInitOptions.type = NativeWindowType.NORMAL;
			windowInitOptions.minimizable = true;
			windowInitOptions.resizable = true;
			windowInitOptions.maximizable = false;
			windowInitOptions.systemChrome = NativeWindowSystemChrome.STANDARD;
			windowInitOptions.transparent = false;
			// window
			window = new NativeWindow(windowInitOptions);
			window.width = 600;
			window.height = 500;
			window.title = "Vk.com Authorization";
			window.alwaysInFront = true;
			window.addEventListener(Event.CLOSE, onWindowClose);
			//window.addEventListener(Event.ACTIVATE, onWindowActivate);
			
			// init html
			html = new StageWebView();
			html.stage = window.stage;
			html.viewPort = new Rectangle(0, 0, window.stage.stageWidth, window.stage.stageHeight);
			html.addEventListener(LocationChangeEvent.LOCATION_CHANGE, onLocationChange);
			html.addEventListener(Event.COMPLETE, onWindowActivate);
			//window.addElement( html );
			
			// init timer
			windowTimer = new Timer(2000,1);
			windowTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onTimer);
			
			// show window
			//if( silentInit ){
				//window.visible = false;
			//}
			
			//window.activate();
			//window.open(true);
			
			html.loadURL( "http://vk.com/login.php?app="+appID+"&layout=popup&type=browser&settings="+appPermissions );
			//html.htmlLoader.load( new URLRequest("http://vk.com/login.php?app="+appID+"&layout=popup&type=browser&settings=16363") );
		}
		
		private function onWindowActivate(e:Event):void{
			trace('redraw viewport')
			if(html)
				html.viewPort = new Rectangle(0, 0, window.stage.stageWidth, window.stage.stageHeight);
		}
		
		private function onWindowClose(e:Event):void{
			if(!initialized) dispatchError("Auth error");
		}
		
		/**
		 * 
		 * @param e
		 * 
		 * On recieve index page of vk.com
		 */
		protected function onLocationChange(e:Event):void{
			trace(html.location);
			// check status 
			if (html.location.indexOf("login_success") > 0 ){
				// remove event litener
				html.removeEventListener(LocationChangeEvent.LOCATION_CHANGE, onLocationChange);
				
				//{"mid":47636,"sid":"d292cbef2e5f9a32c15f840ea26c035e58a9d1d4a50b9d22b535f0bfa0bf83","secret":"7ad0d2063b","expire":0,"sig":"ecfc74e26c8350626ffebc6b81621acd"}
				var re:RegExp = new RegExp(/{"mid":(.+?),"sid":"(.+?)","secret":"(.+?)","expire":(.+?),"sig":"(.+?)"}/gs);
				var re2:RegExp = new RegExp(/{"mid":(.+?),"secret":"(.+?)","sid":"(.+?)","expire":(.+?)}/gs);
				// 7.2.2011 - {"mid":47636,"secret":"0eafe29608","sid":"fe30000f3d1174ab3f72e8b92ed49e47c818787c6ab7a75623aa90c896a9fc","expire":0}
				var res:Array = re.exec( decodeURIComponent(html.location) );
				
				if( res != null ){
					mid = res[1];
					sid = res[2];
					secret = res[3];
					expire = res[4];
					sig = res[5];
				}else{
					res = re2.exec( decodeURIComponent(html.location) );
					if( res != null ){
						mid = res[1];
						secret = res[2];
						sid = res[3];
						expire = res[4];
					}else{
						dispatchError("Cannot login correctly. Vkontakte server problems. Try later");
					}
				}
				
				initialized = true;
				window.close();
				windowTimer.stop();
				
				window = null;
				html = null;
				windowTimer = null;
				
				end();
			}else if( html.location.indexOf("login_failure") > 0 ){
				// remove event litener
				html.removeEventListener(Event.LOCATION_CHANGE, onLocationChange);
				
				windowTimer.stop();
				
				window.close();
				
				window = null;
				html = null;
				windowTimer = null;
				
				//dispatchError("Login error!");
			}else if(html.location.indexOf("/login.php?app=") > 0){
				windowTimer.start();
			}
		}
		
		private function onTimer(e:Event):void{
			window.activate();
		}
		
		/**
		 * Error parser
		 **/
		protected function onError(e:IOErrorEvent):void{
			dispatchError(e.text, "IO Error happened in VkNews class");
		}
		
		protected function end():void{
			endLoad();
		}
	}
}