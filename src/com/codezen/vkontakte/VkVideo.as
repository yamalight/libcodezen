package com.codezen.vkontakte
{
	import com.adobe.serialization.json.JSON;
	import com.codezen.helper.Worker;
	import com.codezen.util.CUtils;
	import com.codezen.vkontakte.service.VkBase;
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileStream;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.system.System;
	import flash.utils.Dictionary;
	import flash.utils.escapeMultiByte;
	import flash.utils.unescapeMultiByte;
	
	import flashx.textLayout.utils.CharacterUtil;
	
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
	public class VkVideo extends VkBase
	{
		// hd def array
		private var hdDef:Dictionary;
		
		// limit of duration
		private var finddur:int;
		
		//private var data:String;
		
		/**
		 * 
		 * @param login - login for vkontakte.ru
		 * @param pass - password for vkontakte.ru
		 *
		 * Class constructor, sets login and password
		 */
		public function VkVideo(login:String, pass:String)
		{
			hdDef = new Dictionary();
			hdDef["1"] = "360";
			hdDef["2"] = "480";
			hdDef["3"] = "720";
			
			this.createClass(login, pass);
		}
		
		/**
		 * 
		 * @param query - search query
		 * 
		 * Searches vkontakte.ru for mp3 for given query
		 */
		public function findData(query:String, hd:int = 0, finddur:int = 0):void{
			urlRequest.url = "http://vkontakte.ru/gsearch.php?ajax=1"; // q="+escapeMultiByte(query)+"&section=video&
			// add event listener and load url
			myLoader.addEventListener(Event.COMPLETE, onSearchLoad);
			
			// set duration
			this.finddur = finddur;
			
			var vars:URLVariables = new URLVariables();
			vars['c[q]'] = query;
			if(hd > 0){
				vars['c[hd]'] = "1";
				//vars['c[quality]'] = hd.toString();
			}
			vars['c[section]'] = "video";
			//vars.offset = 0;
			vars.auto = 1;
			vars.preload = 1;

			urlRequest.method = URLRequestMethod.POST;
			urlRequest.data = vars;
			urlRequest.requestHeaders['Referer'] = "http://vkontakte.ru/gsearch.php?q="+escapeMultiByte(query)+"&section=video";
			
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
		private function onSearchLoad(evt:Event):void{
			// add event listener and load url
			myLoader.removeEventListener(Event.COMPLETE, onSearchLoad);
			// close 
			//myLoader.close();
			
			// get result data
			var data:String = new String(evt.target.data);
			
			data = data.replace(/\n/gs, "").replace(/\t/gs, "").replace(/\r/gs, "");
			data = data.replace(/\\n/gs, "").replace(/\\t/gs, "").replace(/\\r/gs, "");
			data = data.replace(/\\"/gs, '"');
			data = data.replace(/\\\//gs, "/");
			data = data.replace(/\\\\\//gs, "/");
			data = CUtils.prepareVkVideoTitle(data);
			
			trace(data);
			
			// create regex
			var re:RegExp;
			// create res array
			var res:Array;
			
			// form regexp
			re = new RegExp(/"uid":"(.+?)".+?"host":"(.+?)".+?"vtag":"(.+?)".+?"ltag":"(.+?)".+?"md_title":"(.+?)".+?"hd":(.+?),.+?"thumb":"(.+?)".+?(class="ainfo".+?style=.color:#000.>(.+?)<\/b>|<\/td.?+\/tr><\/table>)/gs);
			// execute regexp on data
			res = re.exec(data);
			
			// http://395.gt2.vkadre.ru/assets/videos/4ab02b6b02fd-70281235.vk.flv
			
			//trace(data);
			//trace(ObjectUtil.toString(res));
			
			var info:Object;
			results = new ArrayCollection();
			
			while(res != null){				
				// if really old flv from old srv - skip
				if(String(res[1]).length < 3){
					res = re.exec(data);
					continue;
				}
				// create new object
				
				res['input'] = '';
				res[0] = '';
				//trace(ObjectUtil.toString(res));
				
				if(res[9] != null && int( String(res[9]).split(":")[0] ) > finddur){
					info = new Object();
					info.uid = res[1];
					info.host = res[2];
					info.vtag = res[3];
					info.ltag = res[4];
					info.title = res[5];
					info.hd = res[6];
					info.thumb = res[7];
					info.len = (res[9]==null)?"?:??":res[9];
					if(info.hd == 0){
						info.url = info.host+'u'+info.uid+'/video/'+
							info.vtag+'.flv';
						info.hd_text = "260p";
					}else{
						info.url = info.host+'u'+info.uid+'/video/'+
							info.vtag+'.'+hdDef[info.hd]+'.mp4';
						info.hd_text = hdDef[info.hd]+"p";
					}
	
					// add res
					results.addItem(info);
				}

				res = re.exec(data);
			}

			// erase vars
			//dupes = null;
			info = null;
			data = null;
			re = null;
			res = null;
			
			//trace(ObjectUtil.toString(results));
			
			// init end
			end();
		}
		
		/**
		 * 
		 * @param e
		 * 
		 * Catches load error for track search 
		 */
		private function onTrackError(e:IOErrorEvent):void{
			// set result
			results = null;
			
			// init end
			end();
		}		
	}
}