package com.codezen.vkontakte.api
{
	import com.codezen.helper.Worker;
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.utils.ByteArray;
	
	import mx.utils.ObjectUtil;
	import mx.utils.object_proxy;

	public class Base extends Worker
	{
		// app data
		protected var appID:String;
		protected var appKey:String;
		protected var format:String = "format=XML";
		
		// user data
		protected var login:String;
		protected var pass:String;
		
		// auth data
		protected var expire:String;
		protected var mid:String;
		protected var secret:String;
		protected var sid:String;		
		
		// initialized state
		protected var initialized:Boolean;
		
		// loader and request
		protected var urlRequest:URLRequest;
		protected var myLoader:URLLoader;
		
		public function Base(appID:String, appKey:String){
			this.appID = appID;
			this.appKey = appKey;
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
			//init();
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
		public function init(login:String, pass:String):void{
			this.login = login;
			this.pass = pass;
			//trace('VkBase init start');
			// init request
			urlRequest.url = "http://vkontakte.ru/login.php?app="+appID+"&layout=popup&type=browser&settings=16383";
			// add event listener and load url
			myLoader.addEventListener(Event.COMPLETE, onGetLogin);
			myLoader.load(urlRequest);
		}
		
		/**
		 * 
		 * @param e
		 * 
		 * On recieve index page of vkontakte.ru
		 */
		protected function onGetLogin(e:Event):void{
			// remove event litener
			myLoader.removeEventListener(Event.COMPLETE, onGetLogin);
			
			// get data
			var ba:ByteArray = myLoader.data as ByteArray;
			var data:String = /*myLoader.data;*/ new String(ba.readMultiByte(ba.length, 'windows-1251'));
			
			var re:RegExp = new RegExp('<form action="http://login.vk.com/" method="POST".+?name="app" value="(.+?)".+?name="app_hash" value="(.+?)".+?name="al_test" value="(.+?)"');
			var res:Array = re.exec(data);

			var vars:URLVariables = new URLVariables();
			vars.act = "login";
			vars.al_test = res[3];
			vars.app = res[1];
			vars.app_hash = res[2];
			vars.captcha_key = "";	
			vars.captcha_sid = "";	
			vars.email = login;
			vars.expire = "0";
			vars.pass = pass;
			vars.permanent = "1";
			vars.vk = "";
			
			// create request
			urlRequest.url = "http://login.vk.com/";
			urlRequest.method = URLRequestMethod.POST;
			urlRequest.requestHeaders.push(new URLRequestHeader('X-Requested-With','XMLHttpRequest'));
			urlRequest.data = vars;
			
			// load request
			myLoader.addEventListener(Event.COMPLETE, onFirstLoad);
			myLoader.load(urlRequest);
		}
		
		/**
		 * Result parser on reciev
		 **/
		protected function onFirstLoad(evt:Event):void{
			// add event listener and load url
			myLoader.removeEventListener(Event.COMPLETE, onFirstLoad);
			
			var ba:ByteArray = myLoader.data as ByteArray;
			var data:String = /*myLoader.data;/*/ new String(ba.readMultiByte(ba.length, 'windows-1251'));
			
			//trace('first load data: ' +data); return; 
			
			if( data.indexOf("onError") > 0 ){
				dispatchError("Неверный логин или пароль");
				return;
			}
			
			var vars:URLVariables = new URLVariables();
			var re:RegExp = new RegExp(/<input type=['|"]hidden['|"] name=['|"](.+?)['|"] value=['|"](.*?)['|"] \/>/gs);
			var res:Array = re.exec(data);
			while(res != null){
				vars[res[1]] = res[2];
				res = re.exec(data);
			}
			
			//trace(ObjectUtil.toString(vars)); return;
			
			// create urlrequester and urlloader
			urlRequest.url = "http://vkontakte.ru/login.php";
			urlRequest.requestHeaders['Referer'] = "http://login.vk.com/";
			urlRequest.method = URLRequestMethod.POST;
			urlRequest.requestHeaders.push(new URLRequestHeader('X-Requested-With','XMLHttpRequest'));
			urlRequest.data = vars;
			
			// add event listener and load url
			myLoader.addEventListener(Event.COMPLETE, onSecondLoad);
			myLoader.load(urlRequest);
		}
		
		/**
		 * Result parser on reciev
		 **/
		protected function onSecondLoad(evt:Event):void{
			// add event listener and load url
			myLoader.removeEventListener(Event.COMPLETE, onSecondLoad);
			
			var ba:ByteArray = myLoader.data as ByteArray;
			var data:String = /*myLoader.data;/*/new String(ba.readMultiByte(ba.length, 'windows-1251'));
			
			trace('second load data: ' +data); return; 
			
			var re:RegExp = new RegExp(/{"mid":(.+?),"sid":"(.+?)","secret":"(.+?)","expire":(.+?),"auth_hash":"(.+?)"}/gs);
			var res:Array = re.exec(data);
			
			mid = res[1];
			sid = res[2];
			secret = res[3];
			expire = res[4];
			
			initialized = true;
			
			end();
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