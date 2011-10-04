package com.codezen.vkontakte.ajax
{
	import com.adobe.utils.XMLUtil;
	import com.codezen.helper.Worker;
	import com.codezen.vkontakte.ajax.service.VkBase;
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.filesystem.File;
	import flash.html.HTMLLoader;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.system.System;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.escapeMultiByte;
	
	import mx.collections.ArrayCollection;
	import mx.controls.HTML;
	import mx.utils.ObjectUtil;
	
	import spark.components.mediaClasses.VolumeBar;

	public class VkNews extends VkBase
	{
		// feed filters
		private var feedFilters:Dictionary;
		
		// feed selectors
		private var feedSelectors:Dictionary;
		
		public function VkNews(login:String, pass:String)
		{
			// init coefs
			feedFilters = new Dictionary();
			// friends
			feedFilters['base'] = 2147024896;
			feedFilters['photos'] = 2;
			feedFilters['videos'] = 16;
			feedFilters['notes'] = 4;
			feedFilters['topics'] = 8192;
			feedFilters['states'] = 32;
			feedFilters['friends'] = 64;
			feedFilters['groups'] = 128; 
			feedFilters['events'] = 512;
			feedFilters['audio'] = 32768;
			feedFilters['apps'] = 2048;
			feedFilters['marks'] = 8;
			feedFilters['pd'] = 131072;
			feedFilters['gift'] = 16384;
			// groups
			feedFilters['g_base'] = 2147377132;
			feedFilters['g_news'] = 65536; 
			
			// init selectors
			feedSelectors = new Dictionary();
			feedSelectors['photos'] = true;
			feedSelectors['videos'] = true;
			feedSelectors['notes'] = true;
			feedSelectors['topics'] = true;
			feedSelectors['states'] = true;
			feedSelectors['friends'] = true;
			feedSelectors['groups'] = true; 
			feedSelectors['events'] = true;
			feedSelectors['audio'] = true;
			feedSelectors['apps'] = true;
			feedSelectors['marks'] = true;
			feedSelectors['pd'] = true;
			feedSelectors['gift'] = true;
			feedSelectors['g_news'] = false;
			
			// create class
			this.createClass(login, pass);
		}
		
		public function getFeed(selectors:Dictionary = null, section:String = ''):void{
			// add event listener and load url
			myLoader.addEventListener(Event.COMPLETE, onFeedLoad);
			
			if(selectors == null) selectors = feedSelectors;
			
			// get filter
			var filter:Number = (section == 'groups')?feedFilters['g_base']:feedFilters['base'];
			var key:Object;
			for (key in selectors) {
				if(selectors[key] == true){
					filter += feedFilters[key];
				}
			}
			
			// get time
			var time:String = new Date().getTime().toString();
			time = time.substring(0, time.length-3);
			
			// assign vars
			var vars:URLVariables = new URLVariables();
			//vars.timestamp = parseInt(time);
			vars.filter = filter;
			vars.offset = 0; 
			
			urlRequest.url = "http://vkontakte.ru/newsfeed.php?section="+escapeMultiByte(section);
			urlRequest.method = URLRequestMethod.POST;
			urlRequest.requestHeaders.push(new URLRequestHeader('X-Requested-With','XMLHttpRequest'));
			urlRequest.data = vars;
			
			// load request
			myLoader.dataFormat = URLLoaderDataFormat.BINARY;
			myLoader.load(urlRequest);
		}
		
		private function onFeedLoad(evt:Event):void{
			// add event listener and load url
			myLoader.removeEventListener(Event.COMPLETE, onFeedLoad);
			
			// get result data
			var ba:ByteArray = evt.target.data as ByteArray;
			var data:String = new String(ba.readMultiByte(ba.length, 'windows-1251'));
			
			var res:Object = JSON.parse(data);
			//var parser:HtmlParser = new HtmlParser();
			// FIX HERE!!!!
			// !!!!!!!!!!!!
			// !!!!!!!!!!!
			// parser.HTMLtoXML(res.rows)
			return;
			var xml:XMLList = new XMLList(  );
			
			var newsItem:Object;
			results = new ArrayCollection();
			
			var list:XML;
			var items:XMLList;
			var item:XML;
			for each(list in xml){
				// if item is not feed day separator
				if( XML(list.children()[0]).attribute("class").toString() != "feedDay"){
					items = list.children();
					// for each child
					for each(item in items){
						// create new newsItem obj
						newsItem = new Object();
						// get feed icon
						if (item..img.attribute("class")[0] == "feedIcon"){
							if(String(item..img[0].@src).match("http://")){
								newsItem.img = item..img[0].@src;
							}else{
								newsItem.img = "http://vkontakte.ru/"+item..img[0].@src;
							}
						}
						// get feed time
						if(item..td.attribute("class")[2] == "feedTime"){
							newsItem.time = item..td[2].div.text();
						}
						if(item..a.attribute("class")[0] == "memLink"){
							newsItem.user_name = item..a[0].text();
							newsItem.user_id = item..a[0].@href;
						}
						if(item..td.attribute("class")[1] == "feedStory"){
							newsItem.content = String(item..td[1]).replace(/<td.+?>/, "").replace(/<\/td>/, '').replace(/\n/gs, "").replace(/\s\s+/gs, " ").replace(/href="/gs, "href=\"http://vkontakte.ru/"); 
						}
						
						//@TODO: Parse data somehow
						results.addItem(newsItem);
						//trace( ObjectUtil.toString(newsItem) );
					}
				}
			}
			
			
			end();
		}
	}
}








