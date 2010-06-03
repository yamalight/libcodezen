package com.codezen.kinobaza
{
	import com.codezen.helper.Worker;
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	
	import mx.collections.ArrayCollection;
	import mx.utils.ObjectUtil;

	public class KinobazaTV extends Worker
	{
		// result of search
		private var series:ArrayCollection;
		private var seriesInfo:Object;
		private var episodes:ArrayCollection;
		private var seasonCount:int;
		
		// loader and request
		private var urlRequest:URLRequest;
		private var myLoader:URLLoader;
		
		public function KinobazaTV()
		{
			// init request and loader
			urlRequest = new URLRequest();
			myLoader = new URLLoader();
			// set params and add error event listener
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
		public function searchBase(query:String):void{
			// reset old vars
			resetVars();
			// create urlrequester and urlloader
			urlRequest.url = "http://qa.kinobaza.tv/search?query=" + query + "&search_type=films&" +
				"format=xml&per_page=15&wildcard=1";
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
			var data:XMLList = new XML(evt.target.data).children();
			
			// create new results arr
			series = new ArrayCollection();
			
			//<film id="382447" name="House, The" original_name="" year="2008" poster="/img/default_poster.jpg"/>
			// parse
			var item:XML;
			for each(item in data){
				series.addItem({
					id:item.@id,
					name:item.@name,
					original_name:item.@original_name,
					year:item.@year,
					poster:item.@poster,
					type:item.@type
				});
			}
			
			// clean
			item = null;
			data = null;
			
			// finish
			endLoad();
		}
		
		/**
		 * Function that does log in to vkontakte.ru 
		 */
		public function getInfo(id:String):void{
			// create urlrequester and urlloader
			urlRequest.url = "http://qa.kinobaza.tv/series/info?id="+id+"&format=xml";
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
			var data:XML = new XML(evt.target.data);

			seriesInfo = new Object();
			seriesInfo.id = data.@id;
			seriesInfo.name = data.@name;
			seriesInfo.original_name = data.@original_name;
			seriesInfo.year = data.@year;
			seriesInfo.poster = data.@poster;
			seriesInfo.tvrage_id = data.@tvrage_id;
			seriesInfo.kinopoisk_id = data.@kinopoisk_id;
			seriesInfo.kinopoisk_rating = data.@kinopoisk_rating;
			seriesInfo.kinopoisk_rating_voted = data.@kinopoisk_rating_voted;
			seriesInfo.imdb_id = data.@imdb_id;
			seriesInfo.imdb_rating = data.@imdb_rating;
			seriesInfo.imdb_rating_voted = data.@imdb_rating_voted;
			seriesInfo.tvcom_rating = data.@tvcom_rating;
			seriesInfo.tvcom_rating_voted = data.@tvcom_rating_voted;
			seriesInfo.description = data.@description;
			seriesInfo.countries = data.@countries;
			seriesInfo.genres = data.@genres;
			
			// parse seasons
			if(data.children().length() > 0){
				episodes = new ArrayCollection();
				var season:XML;
				var episode:XML;
				var snum:String;
				for each(season in data.children()){
					snum = season.@number;
					for each(episode in season.children()){
						episodes.addItem({
							id:episode.@id,
							number:episode.@number,
							season:snum,
							name:episode.@name,
							original_name:episode.@original_name,
							tvrage_id:episode.@tvrage_id,
							description:episode.@description
						});
					}
				}
			}
			
			endLoad();
		}
		
		private function resetVars():void{
			seasonCount = -1;
			series = null;
			episodes = null;
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