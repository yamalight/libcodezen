package com.codezen.myshows
{
	import com.codezen.helper.Worker;
	import com.codezen.util.CUtils;
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	
	import mx.collections.ArrayCollection;
	import mx.utils.ObjectUtil;

	public class MyShowsSearch extends Worker
	{
		// result of search
		private var series:ArrayCollection;
		private var seriesInfo:Object;
		private var episodes:ArrayCollection;
		private var seasonCount:int;
		
		// loader and request
		private var urlRequest:URLRequest;
		private var myLoader:URLLoader;
		
		public function MyShowsSearch()
		{
			// init request and loader
			urlRequest = new URLRequest();
			myLoader = new URLLoader();
			// set params and add error event listener
			urlRequest.requestHeaders['Referer'] = "http://myshows.ru/";
			myLoader.dataFormat = URLLoaderDataFormat.TEXT;
			myLoader.addEventListener(IOErrorEvent.IO_ERROR, onError);
		}
		
		/**
		 * 
		 * @return (Array) results of search 
		 * 
		 */
		public function get seriesCollection():ArrayCollection{
			return series;
		}
		
		/**
		 * 
		 * @return (Object) series info 
		 * 
		 */
		public function get seriesInformation():Object{
			return seriesInfo;
		}
		
		/**
		 * 
		 * @return (Array) results of search 
		 * 
		 */
		public function get seriesEpisodes():ArrayCollection{
			return episodes;
		}
		
		/**
		 * 
		 * @return (Array) results of search 
		 * 
		 */
		public function get seriesSeasons():int{
			return seasonCount;
		}
		
		/**
		 * Function that does log in to vkontakte.ru 
		 */
		public function findSeries(query:String):void{
			// create urlrequester and urlloader
			urlRequest.url = "http://myshows.ru/search/?q="+query;
			// add event listener and load url
			myLoader.addEventListener(Event.COMPLETE, onSeriesLoad);
			myLoader.load(urlRequest);
		}
		
		/**
		 * Result parser on reciev
		 **/
		private function onSeriesLoad(evt:Event):void{
			// add event listener and load url
			myLoader.removeEventListener(Event.COMPLETE, onSeriesLoad);
			
			// get result data
			var data:String = evt.target.data;
			
			/*data = data.replace(/\n/gs, "").replace(/\t/gs, "").replace(/\r/gs, "");
			data = data.replace(/\\n/gs, "").replace(/\\t/gs, "").replace(/\\r/gs, "");
			data = data.replace(/\s\s+/gs, "");
			data = data.replace(/\\"/gs, '"');
			data = data.replace(/\\\//gs, "/");
			*/

			//var re:RegExp = new RegExp(/<tr>.+?<th>.+?class="status.+?".+?href="(.+?)">(.+?)<\/a>.+?class="description">(.+?)<\/p>.+?<td>.+?<\/td>.+?<td.+?>.+?<\/td>.+?<td.+?>.+?<\/td>.+?<td.+?>(.+?)<\/td>.+?<td.+?>(.+?)<\/td>.+?<\/tr>/gs);
			var re:RegExp = new RegExp(/<th.+?class="status.+?"><a href="(.+?)">(.+?)<\/a>.+?class="description">(.+?)<\/p>.+?<td width="30%">(\d)<\/td>.+?<td width="10%">(\d+?)<\/td>.+?<\/tr>/gs);
			var res:Array = re.exec(data);
			
			var item:Object;
			series = new ArrayCollection();
			
			while(res != null){
				item = new Object();
				item.link = res[1];
				item.name = res[2];
				item.ename = res[3];
				item.seasons = res[4];
				item.year = res[5];
				
				series.addItem(item);
				
				res = re.exec(data);
			}
			
			// clean
			res = null;
			item = null;
			re = null;
			data = null;
			
			// finish
			endLoad();
		}
		
		/**
		 * Function that does log in to vkontakte.ru 
		 */
		public function loadEpisodes(url:String):void{
			// create urlrequester and urlloader
			urlRequest.url = url;
			// add event listener and load url
			myLoader.addEventListener(Event.COMPLETE, onEpisodesLoad);
			myLoader.load(urlRequest);
		}
		
		/**
		 * Result parser on reciev
		 **/
		private function onEpisodesLoad(evt:Event):void{
			// add event listener and load url
			myLoader.removeEventListener(Event.COMPLETE, onEpisodesLoad);
			
			// get result data
			var data:String = evt.target.data;
			
			data = data.replace(/\n/gs, "").replace(/\t/gs, "").replace(/\r/gs, "");
			data = data.replace(/\\n/gs, "").replace(/\\t/gs, "").replace(/\\r/gs, "");
			data = data.replace(/\s\s+/gs, "");
			data = data.replace(/\\"/gs, '"');
			data = data.replace(/\\\//gs, "/");
			
			var rei:RegExp = new RegExp(/<div class="show-info"><img src="(.+?)" title="(.+?)".+?<p><strong>Даты выхода:<\/strong>(.+?)<\/p><p><strong>Стран.+?<\/strong>(.+?)<\/p><p><strong>Жанры:<\/strong>(.+?)<\/p>.+?<p><strong>Общая длительность:<\/strong>(.+?)<\/p><p><strong>Рейтинг IMDB:<\/strong>(.+?)<\/p><p><strong>Рейтинг Кинопоиска:<\/strong>(.+?)<\/p>.+?<p class="join-or-die">.+?<\/p>(.+?)<\/p><ul class="reset">/gs);
			var resi:Array = rei.exec(data);
			
			// fill info
			seriesInfo = new Object();
			seriesInfo.image = resi[1];
			seriesInfo.title = resi[2];
			seriesInfo.dates = CUtils.convertHTMLEntities(resi[3]);
			seriesInfo.country = resi[4];
			seriesInfo.generes = CUtils.stripTags(resi[5]);
			seriesInfo.len = CUtils.convertHTMLEntities(resi[6]);
			seriesInfo.imdb = resi[7];
			seriesInfo.kino = resi[8];
			seriesInfo.desc = CUtils.stripTags(resi[9]);
			
			// get episodes list
			var re:RegExp = new RegExp(/<ul class="reset">(.+?)<\/ul><\/li><\/ul>/gs);
			var res:Array = re.exec(data);
			
			data = res[0];
			
			// break to seasons
			re = new RegExp(/<li.+?id="season.+?>.+?<\/ul.+?\/li>/gs);
			res = re.exec(data);
			
			var seasons:Array = new Array();
			
			while(res != null){
				seasons.push(res[0]);
				
				res = re.exec(data);
			}
			
			episodes = new ArrayCollection();
			
			var item:String;
			var season:int=0;
			//re = new RegExp(/useless">(.+?)<\/span.+?strong>(.+?)<\/strong+?href=.+?">(.+?)<\/a>/gs);
			re = new RegExp(/<li><label><span class="useless">(.+?)<\/span> <strong>(.+?)<\/strong><a class="pseudo-link fancylink" href="(.+?)">(.+?)<\/a><\/label><\/li>/gs);
			var snre:RegExp = new RegExp(/id="s(.)"/);
			var snres:Array;
			for each(item in seasons){
				snres = snre.exec(item);
				season = int(snres[1]);
				if(season > seasonCount){ 
					seasonCount = season;
				}
				
				res = re.exec(item);
				
				while(res != null){
					episodes.addItem({season:season, num:res[2], name:res[4], date:res[1], link:res[3]});
					
					res = re.exec(item);
				}
			}
			
			endLoad();
		}
		
		/**
		 * Error parser
		 **/
		private function onError(e:IOErrorEvent):void{
			dispatchError(e.text, "IO Error happened in MusicSearch class");
			//trace('io-error: '+e.text);
		}
	}
}