package com.codezen.vkontakte.service
{
	import com.codezen.helper.Worker;
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.escapeMultiByte;
	
	import mx.collections.ArrayCollection;
	
	public class VkBase extends Worker
	{
		// login and passwork for auth
		protected var login_mail:String;
		protected var login_pass:String;
		
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
			
			// init request and loader
			urlRequest = new URLRequest();
			myLoader = new URLLoader();
			// set params and add error event listener
			urlRequest.requestHeaders['Referer'] = "http://vkontakte.ru/";
			myLoader.dataFormat = URLLoaderDataFormat.TEXT;
			myLoader.addEventListener(IOErrorEvent.IO_ERROR, onError);
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
			
			// get data
			var data:String = myLoader.data;
			
			// check if logged in
			if(data.match('id="myfriends"') == null){
				doLogin();
			}else{
				dispatchEvent(new Event(Event.INIT));
			}
			
			data = null;
		}
		
		/**
		 * Function that does log in to vkontakte.ru 
		 */
		protected function doLogin():void{
			// create urlrequester and urlloader
			urlRequest.url = "http://vkontakte.ru/login.php?email="+
				escapeMultiByte(login_mail)+"&pass="+
				escapeMultiByte(login_pass)+"&expire=1";
			
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
			var data:String = evt.target.data;
			
			// dispatch error
			if(data.match('forgotPass') != null){
				// call event
				dispatchError("Неверный логин или пароль вконтакте!");	
			}else{
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