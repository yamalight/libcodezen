package com.codezen.vkontakte.api.service
{
	import com.codezen.helper.Worker;
	
	import flash.display.NativeWindow;
	import flash.display.NativeWindowInitOptions;
	import flash.display.NativeWindowType;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	
	import mx.controls.HTML;
	import mx.core.Window;
	import mx.utils.ObjectUtil;

	public class Base extends Worker
	{
		// app data
		protected var appID:String;
		protected var appKey:String;
		private var silentInit:Boolean;
		
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
		protected var html:HTML;
		protected var window:Window;
		
		public function Base(appID:String, appKey:String, silentInit:Boolean){
			this.appID = appID;
			this.appKey = appKey;
			this.silentInit = silentInit;
			createClass();
		}
		
		protected function createClass():void
		{
			// init state
			initialized = false;
			
			// init request and loader
			urlRequest = new URLRequest();
			myLoader = new URLLoader();
			// set params and add error event listener
			//urlRequest.requestHeaders['Referer'] = "http://vkontakte.ru/";
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
			//trace('VkBase init start');			
			// create window
			window = new Window();
			window.width = 600;
			window.height = 500;
			window.title = "Vkonatke.ru Authorization";
			window.alwaysInFront = true;
			window.resizable = false;
			window.showStatusBar = false;
			
			// init html
			html = new HTML();
			html.x = 0;
			html.y = 0;
			html.width = 600;
			html.height = 500;
			html.location = "http://vkontakte.ru/login.php?app="+appID+"&layout=popup&type=browser&settings=16383";
			html.addEventListener(Event.LOCATION_CHANGE, onLocationChange);
			window.addElement( html );
			
			// show window
			if( silentInit ){
				window.visible = false;
			}
			
			window.open(true);
			
			//html.htmlLoader.load( new URLRequest("http://vkontakte.ru/login.php?app="+appID+"&layout=popup&type=browser&settings=16363") );
		}
		
		/**
		 * 
		 * @param e
		 * 
		 * On recieve index page of vkontakte.ru
		 */
		protected function onLocationChange(e:Event):void{
			trace(html.location);
			// check status 
			if (html.location.indexOf("login_success") > 0 ){
				// remove event litener
				html.removeEventListener(Event.LOCATION_CHANGE, onLocationChange);
				
				//{"mid":47636,"sid":"d292cbef2e5f9a32c15f840ea26c035e58a9d1d4a50b9d22b535f0bfa0bf83","secret":"7ad0d2063b","expire":0,"sig":"ecfc74e26c8350626ffebc6b81621acd"}
				var re:RegExp = new RegExp(/{"mid":(.+?),"sid":"(.+?)","secret":"(.+?)","expire":(.+?),"sig":"(.+?)"}/gs);
				// var re:RegExp = new RegExp(/{"mid":(.+?),"secret":"(.+?)","sid":"(.+?)","expire":(.+?)}/gs);
				// 7.2.2011 - {"mid":47636,"secret":"0eafe29608","sid":"fe30000f3d1174ab3f72e8b92ed49e47c818787c6ab7a75623aa90c896a9fc","expire":0}
				var res:Array = re.exec( decodeURIComponent(html.location) );
				
				mid = res[1];
				sid = res[2];
				secret = res[3];
				expire = res[4];
				sig = res[5];
				
				initialized = true;
				window.close();
				
				window = null;
				html = null;
				
				end();
			}else if( html.location.indexOf("login_failure") > 0 ){
				// remove event litener
				html.removeEventListener(Event.LOCATION_CHANGE, onLocationChange);
				
				
				window.close();
				
				window = null;
				html = null;
				
				dispatchError("Login error!");
			}
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