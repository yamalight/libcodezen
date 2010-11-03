package com.codezen.music.search
{
	import com.codezen.util.CUtils;
	import com.codezen.vkontakte.service.VkBase;
	
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
	 * Requires login and pass
	 * 
	 * USAGE:
	 * var s:MusicSearch = new MusicSearch('login','pass');
	 * s.addEventListener(Worker.COMPLETE, onLinkFound);
	 * s.init();
	 * s.findData('Muse Intro');
	 * 
	 */
	public class VkLoginMusic extends VkBase implements ISearch
	{		
		// result of search
		private var result:String;
		
		// limit of search
		private var limit:int;
		
		// limit of duration
		private var finddur:int;
		
		/**
		 * 
		 * @param login - login for vkontakte.ru
		 * @param pass - password for vkontakte.ru
		 *
		 * Class constructor, sets login and password
		 */
		public function VkLoginMusic(login:String = '', pass:String = '')
		{
			if( login.length < 1 || pass.length < 1) return;
			this.createClass(login, pass);
		}
		
		
		/**
		 * Initializes class with auth data 
		 * @param login
		 * @param pass
		 * 
		 */
		public function initAuth(login:String='', pass:String=''):void{
			trace('lp: '+login+' - '+pass);
			if(!initialized){
				trace('not init');
				this.createClass(login, pass);
			}
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
		 * Returns search class name 
		 * @return class name (VkLogin)
		 * 
		 */
		public function get classAlias():String{
			return "VkLoginMusic";
		}
		
		/**
		 * If class requires authentification 
		 * @return bool
		 * 
		 */
		public function get requireAuth():Boolean{
			return true;
		}
		
		/**
		 * 
		 * @param query - search query
		 * 
		 * Searches vkontakte.ru for mp3 for given query
		 */
		public function findData(query:String, limit:int = 1, finddur:int = 0):void{
			if( !initialized ){
				dispatchError('not initialized');
			}
			// http://vkontakte.ru/gsearch.php?q=%20Sonic%20Youth&section=audio&ajax=1&auto=1&c%5Bq%5D=Naoki%20Kenji&c%5Bsection%5D=audio
			// http://vkontakte.ru/gsearch.php?q="+query+"&section=audio
			urlRequest.url = "http://vkontakte.ru/gsearch.php?q="+CUtils.urlEncode(query)+"&section=audio&ajax=1";
			// add event listener and load url
			myLoader.addEventListener(Event.COMPLETE, onSearchLoad);
			
			// set limit
			this.limit = limit;
			
			// set duration
			this.finddur = finddur;
			
			var vars:URLVariables = new URLVariables();
			vars['c[q]'] = query;
			vars['c[section]'] = "audio";
			//vars.offset = 0;
			vars.auto = 1;
			vars.preload = 1;
			
			urlRequest.method = URLRequestMethod.POST;
			urlRequest.data = vars;
			urlRequest.requestHeaders['Referer'] = "http://vkontakte.ru/gsearch.php?q="+CUtils.urlEncode(query)+"&section=audio";
			
			// remove default error cathcer
			myLoader.removeEventListener(IOErrorEvent.IO_ERROR, onError);
			// add speacial
			myLoader.addEventListener(IOErrorEvent.IO_ERROR, onError);
			
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
			//re = new RegExp(/<div class="audioRow".+?operate\(.+?,(.+?),(.+?),'(.+?)',.+?\).+?id="performer.+?">/gs);
			re = new RegExp(/<div class="audioRow".+?operate\(.+?,(.+?),(.+?),'(.+?)',.+?\).+?id="performer.+?">(.+?)<.b>.+?id="title.+?">(.+?)<.span>.+?class="duration">(.+?)<.div>/gs);
			// execute regexp on data
			res = re.exec(data);		
			
			// if res null result = null
			if(res == null){
				result = null;
			}
			// if finddur is set
			if(finddur != 0){
				// find right duration
				while(res != null){
					// parse text duration
					var durS:Array = String(res[6]).split(":");
					var dur:int = int(durS[0])*60 + int(durS[1]); 
					// if duaration matches
					if(dur == finddur){
						result = 'http://cs'+res[1]+'.vkontakte.ru/u'+res[2]+'/audio/'+res[3]+'.mp3';
						break;
					}else{
						res = re.exec(data);
					}
				}
			// if duration not set and there is a result
			}else if(res != null){
				result = 'http://cs'+res[1]+'.vkontakte.ru/u'+res[2]+'/audio/'+res[3]+'.mp3';
			}
				
			
			// erase vars
			data = null;
			re = null;
			res = null;
			
			// init end
			end();
		}		
	}
}