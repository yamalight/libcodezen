package com.codezen.vkontakte.service
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
	import flash.utils.escapeMultiByte;
	
	import mx.collections.ArrayCollection;
	import mx.utils.ObjectUtil;
	
	public class VkBase extends Worker
	{
		// login and passwork for auth
		protected var login_mail:String;
		protected var login_pass:String;
		
		// initialized state
		protected var initialized:Boolean;
		
		// result of search
		protected var results:ArrayCollection;
		
		// loader and request
		protected var urlRequest:URLRequest;
		protected var myLoader:URLLoader;
		
		public function VkBase(){}
		
		protected function createClass(login:String, pass:String):void
		{
			// save login and password
			login_mail = login;
			login_pass = pass;
			
			// init state
			initialized = false;
			
			// init request and loader
			urlRequest = new URLRequest();
			myLoader = new URLLoader();
			// set params and add error event listener
			urlRequest.requestHeaders['Referer'] = "http://vkontakte.ru/";
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
		 * 
		 * @return (Array) results of search 
		 * 
		 */
		public function get resultArray():ArrayCollection{
			return results;
		}
		
		/**
		 * Initializes class: checks if user already logged in 
		 * and if not - logs in.
		 * Must be executed before search 
		 */
		public function init():void{
			//trace('VkBase init start');
			// init request
			urlRequest.url = "http://vkontakte.ru/";
			// add event listener and load url
			myLoader.addEventListener(Event.COMPLETE, onCheckLogin);
			myLoader.load(urlRequest);
		}
		
		/**
		 * 
		 * @param e
		 * 
		 * On recieve index page of vkontakte.ru
		 */
		protected function onCheckLogin(e:Event):void{
			// remove event litener
			myLoader.removeEventListener(Event.COMPLETE, onCheckLogin);
			
			//trace('VkBase onCheckLogin done');
			
			// get data
			var ba:ByteArray = myLoader.data as ByteArray;
			var data:String = new String(ba.readMultiByte(ba.length, 'windows-1251'));
			
			//trace('data: '+data);
			
			// check if logged in
			if(data.match('id="myfriends"') == null){
				doLogin();
			}else{
				initialized = true;
				dispatchEvent(new Event(Event.INIT));
			}
			
			data = null;
		}
		
		/**
		 * Function that does log in to vkontakte.ru 
		 */
		protected function doLogin():void{
			//trace('VkBase doLogin');
			
			// create vars
			var vars:URLVariables = new URLVariables();
			vars.op = "a_login_attempt";
			
			// create urlrequester and urlloader
			//urlRequest.url = "http://vkontakte.ru/login.php?email="+
			//	escapeMultiByte(login_mail)+"&pass="+
			//	escapeMultiByte(login_pass)+"&expire=1";
			urlRequest.url = "http://vkontakte.ru/login.php";
			urlRequest.method = URLRequestMethod.POST;
			urlRequest.requestHeaders.push(new URLRequestHeader('X-Requested-With','XMLHttpRequest'));
			urlRequest.data = vars;
			
			// add event listener and load url
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
			var data:String = new String(ba.readMultiByte(ba.length, 'windows-1251'));
			
			//trace('first load data: ' +data); 
			
			// create vars
			var vars:URLVariables = new URLVariables();
			vars.email = login_mail;
			vars.pass = login_pass;
			vars.expire = '1';
			vars.al_test = '1';
			vars.vk = '';
			
			// create urlrequester and urlloader
			urlRequest.url = "http://login.vk.com/?act=login";
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
			var data:String = new String(ba.readMultiByte(ba.length, 'windows-1251'));
			
			//trace('second load data: ' +data); 
			
			var vars:URLVariables = new URLVariables();
			
			var re:RegExp = new RegExp(/<input type=['|"]hidden['|"] name=['|"](.+?)['|"] value=['|"](.*?)['|"] \/>/gs);
			var res:Array = re.exec(data);
			while(res != null){
				vars[res[1]] = res[2];
				res = re.exec(data);
			}
			
			// create urlrequester and urlloader
			urlRequest.url = "http://vkontakte.ru/login.php";
			urlRequest.method = URLRequestMethod.POST;
			urlRequest.requestHeaders.push(new URLRequestHeader('X-Requested-With','XMLHttpRequest'));
			urlRequest.data = vars;
			
			// add event listener and load url
			myLoader.addEventListener(Event.COMPLETE, onSiteLoad);
			myLoader.load(urlRequest);
		}
		
		/**
		 * Result parser on reciev
		 **/
		protected function onSiteLoad(evt:Event):void{
			// add event listener and load url
			myLoader.removeEventListener(Event.COMPLETE, onSiteLoad);
			
			// get result data
			var ba:ByteArray = myLoader.data as ByteArray;
			var data:String = new String(ba.readMultiByte(ba.length, 'windows-1251'));
			
			//trace("FINAL: "+data);
			
			// dispatch error
			if(data.match('forgotPass') != null){
				// call event
				dispatchError("Неверный логин или пароль вконтакте!");	
			}else{
				trace('vklogin initialized');
				initialized = true;
				dispatchEvent(new Event(Event.INIT));
			}
			data = null;
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