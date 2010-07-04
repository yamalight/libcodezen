package com.codezen.vkontakte
{
	import com.adobe.serialization.json.JSON;
	import com.adobe.serialization.json.JSONDecoder;
	import com.adobe.utils.XMLUtil;
	import com.codezen.helper.Worker;
	import com.codezen.util.HtmlParser;
	import com.codezen.vkontakte.service.VkBase;
	
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
			
			// create class
			this.createClass(login, pass);
		}
		
		public function getFeed():void{
			// add event listener and load url
			myLoader.addEventListener(Event.COMPLETE, onFeedLoad);
			
			// get filter
			var filter:Number = feedFilters['base'];
			var key:Object;
			for (key in feedSelectors) {
				if(feedSelectors[key] == true){
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
			
			urlRequest.url = "http://vkontakte.ru/newsfeed.php";
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
			
			var res:Object = JSON.decode(data);
			var parser:HtmlParser = new HtmlParser();
			var xml:XMLList = new XMLList( parser.HTMLtoXML(res.rows) );
			
			var newsItem:Object;
			var newsArr:Array = new Array();
			
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
							newsItem.img = item..img[0].@src; 
						}
						// get feed time
						if(item..td.attribute("class")[2] == "feedTime"){
							newsItem.time = item..td[2].div.text();
						}
						if(item..a.attribute("class")[0] == "memLink"){
							newsItem.user_name = item..a[0].text();
							newsItem.user_id = item..a[0].@href;
						}
						
						//@TODO: Parse data somehow
						
						trace( ObjectUtil.toString(newsItem) );
					}
				}
				trace('--------------------------------------');
			}
			
			/*
			<table class="feedTable  first" cellpadding="0" cellspacing="0" border="0">
				<tr>
					<td class="feedIconWrap">
						<div>
							<img class="feedIcon" src="images/icons/people_s.gif?2"/>
						</div>
					</td>
					<td class="feedStory">
						<a class="memLink" href="/tonygreen">Тони Грин</a> Уехал...
					</td>
					<td class="feedTime">
						<div>19:25</div>
					</td>
				</tr>
			</table>
			*/
			
			
			end();
		}
	}
}








