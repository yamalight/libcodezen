package com.codezen.vkontakte
{
	import com.codezen.helper.Worker;
	import com.codezen.util.CUtils;
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.system.System;
	
	import mx.collections.ArrayCollection;
	import mx.utils.ObjectUtil;

	/**
	 * 
	 * @author yamalight
	 * 
	 * Vkontakte music search class
	 * Returns one found song for request
	 * 
	 * USAGE:
	 * var s:MusicSearch = new MusicSearch('login','pass');
	 * s.addEventListener(Worker.COMPLETE, onLinkFound);
	 * s.init();
	 * s.findData('Muse Intro');
	 * 
	 */
	public class VideoSearch extends Worker
	{
		// login and passwork for auth
		protected var login_mail:String;
		protected var login_pass:String;
		
		// result of search
		protected var result:String;
		protected var results:ArrayCollection;
		
		// loader and request
		protected var urlRequest:URLRequest;
		protected var myLoader:URLLoader;
		
		// limit of search
		protected var limit:int;
		
		// limit of duration
		protected var finddur:int;
		
		public var data:String;
		
		/**
		 * 
		 * @param login - login for vkontakte.ru
		 * @param pass - password for vkontakte.ru
		 *
		 * Class constructor, sets login and password
		 */
		public function VideoSearch(login:String, pass:String)
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
		 * @return (String) result of search 
		 * 
		 */
		public function get resultString():String{
			return result;
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
			// close loader
			//myLoader.close();
			
			// get data
			var data:String = myLoader.data;
			
			// check if logged in
			if(data.match('id="myfriends"') == null){
				doLogin();
			}else{
				dispatchEvent(new Event(Worker.INITIALIZED));
			}
			
			data = null;
		}
		
		/**
		 * Function that does log in to vkontakte.ru 
		 */
		protected function doLogin():void{
			// create urlrequester and urlloader
			urlRequest.url = "http://vkontakte.ru/login.php?email="+login_mail+"&pass="+login_pass+"&expire=1";
			// add event listener and load url
			myLoader.addEventListener(Event.COMPLETE, onSiteLoad);
			myLoader.load(urlRequest);
		}
		
		/**
		 * Error parser
		 **/
		protected function onError(e:IOErrorEvent):void{
			dispatchError(e.text, "IO Error happened in MusicSearch class");
			//trace('io-error: '+e.text);
		}
		
		/**
		 * Result parser on reciev
		 **/
		protected function onSiteLoad(evt:Event):void{
			// add event listener and load url
			myLoader.removeEventListener(Event.COMPLETE, onSiteLoad);
			// close loader
			//myLoader.close();
			
			// get result data
			var data:String = evt.target.data;
			
			this.data = data;
			
			// dispatch error
			if(data.match("id='error'") != null){
				// call event
				dispatchError("Vkontakter login or password wrong!");	
			}else{
				dispatchEvent(new Event(Worker.INITIALIZED));
			}
			
			data = null;
		}
		
		/**
		 * 
		 * @param query - search query
		 * 
		 * Searches vkontakte.ru for mp3 for given query
		 */
		public function findData(query:String, limit:int = 1, finddur:int = 0):void{
			// http://vkontakte.ru/gsearch.php?q=%20Sonic%20Youth&section=audio&ajax=1&auto=1&c%5Bq%5D=Naoki%20Kenji&c%5Bsection%5D=audio
			// http://vkontakte.ru/gsearch.php?q="+query+"&section=audio
			urlRequest.url = "http://vkontakte.ru/gsearch.php?q="+CUtils.urlEncode(query)+"&section=video&ajax=1";
			// add event listener and load url
			myLoader.addEventListener(Event.COMPLETE, onSearchLoad);
			
			// set limit
			this.limit = limit;
			
			// set duration
			this.finddur = finddur;
			
			// enable cyrilic
			System.useCodePage = true;
			
			var vars:URLVariables = new URLVariables();
			vars['c[q]'] = query;
			vars['c[hd]'] = '1';
			vars['c[section]'] = "video";
			//vars.offset = 0;
			vars.auto = 1;
			vars.preload = 1;
			
			urlRequest.method = URLRequestMethod.POST;
			urlRequest.data = vars;
			urlRequest.requestHeaders['Referer'] = "http://vkontakte.ru/gsearch.php?q="+CUtils.urlEncode(query)+"&section=video";
			
			// remove default error cathcer
			myLoader.removeEventListener(IOErrorEvent.IO_ERROR, onError);
			// add speacial
			myLoader.addEventListener(IOErrorEvent.IO_ERROR, onTrackError);
			
			// load request
			myLoader.load(urlRequest);
		}
		
		/**
		 * 
		 * @param evt
		 * Result parser on recieve
		 */
		protected function onSearchLoad(evt:Event):void{
			// add event listener and load url
			myLoader.removeEventListener(Event.COMPLETE, onSearchLoad);
			// close 
			//myLoader.close();
			
			// get result data
			var data:String = String(evt.target.data);
			
			data = data.replace(/\n/gs, "").replace(/\t/gs, "").replace(/\r/gs, "");
			data = data.replace(/\\n/gs, "").replace(/\\t/gs, "").replace(/\\r/gs, "");
			data = data.replace(/\\"/gs, '"');
			data = data.replace(/\\\//gs, "/");
			
			// create regex
			var re:RegExp;
			// create res array
			var res:Array;
			
			// form regexp
			re = new RegExp(/{"host":"(.+?)","vtag":"(.+?)".+?"uid":"(.+?)".+?}/gs);
			// execute regexp on data
			res = re.exec(data);
			
			if(res != null){
				result = 'http://cs'+res[1]+'.vkontakte.ru/u'+res[3]+'/video/'+res[2]+'.360.mp4';
			}else{
				result = null;
			}
				
			
			// erase vars
			data = null;
			re = null;
			res = null;
			
			// init end
			end();
		}
		
		/**
		 * 
		 * @param e
		 * 
		 * Catches load error for track search 
		 */
		protected function onTrackError(e:IOErrorEvent):void{
			// set result
			result = null;
			
			// init end
			end();
		}
		
		protected function end():void{			
			// turn off cyrilic
			System.useCodePage = false;
			
			// call event
			dispatchEvent(new Event(Worker.COMPLETE));
		}
		
	}
}