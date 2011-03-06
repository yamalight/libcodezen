package com.codezen.lastfm
{
	import com.codezen.helper.Worker;
	import com.codezen.util.CUtils;
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.system.System;
	
	import mx.collections.ArrayCollection;
	
	public class LastfmSearch extends Worker
	{
		// result of search
		protected var result:String;
		protected var results:ArrayCollection;
		
		// loader and request
		protected var urlRequest:URLRequest;
		protected var myLoader:URLLoader;
		protected var mode:int=0;
		protected var query:String="";
		
		public function LastfmSearch()
		{
			// init request and loader
			urlRequest = new URLRequest();
			myLoader = new URLLoader();
			// set params and add error event listener
			myLoader.dataFormat = URLLoaderDataFormat.TEXT;
			myLoader.addEventListener(IOErrorEvent.IO_ERROR, onError);
		}
		
		public function init():void{
			// init request and loader
			urlRequest = new URLRequest();
			myLoader = new URLLoader();
			// set params and add error event listener
			myLoader.dataFormat = URLLoaderDataFormat.TEXT;
			//myLoader.addEventListener(IOErrorEvent.IO_ERROR, onError);
			// remove default error cathcer
			myLoader.removeEventListener(IOErrorEvent.IO_ERROR, onError);
			// add speacial
			myLoader.addEventListener(IOErrorEvent.IO_ERROR, onTrackError);
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
		 * Error parser
		 **/
		protected function onError(e:IOErrorEvent):void{
			dispatchError(e.text, "IO Error happened in LastfmSearch class");
			//trace('io-error: '+e.text);
		}
		
		
		/**
		 * 
		 * @param query - search query
		 * 
		 * Searches vkontakte.ru for mp3 for given query
		 */
		public function findData(query:String,curr_mode:int=0):void{
			this.query = query;
			query = CUtils.urlEncode(query);
			this.mode = curr_mode;
			
			//get toptracks by tag
			if (mode == 0){
				urlRequest.url = "http://ws.audioscrobbler.com/1.0/tag/"+query+"/toptracks.xml";
			}
			
			//get top tags by artist
			if (mode == 1){
				urlRequest.url = "http://ws.audioscrobbler.com/1.0/artist/"+query+"/toptags.xml";
			}
			
			//get similar artists
			if (mode == 2){
				urlRequest.url = "http://ws.audioscrobbler.com/1.0/artist/"+query+"/similar.xml";
			}
			
			//get toptracks of artist
			if (mode == 3){
				urlRequest.url = "http://ws.audioscrobbler.com/1.0/artist/"+query+"/toptracks.xml";
			}
			
			//get toptracks of lastfm username
			if (mode == 4){
				urlRequest.url = "http://ws.audioscrobbler.com/1.0/user/"+query+"/toptracks.xml";
			}
			
			//get topartists by tag
			if (mode == 5){
				urlRequest.url = "http://ws.audioscrobbler.com/1.0/tag/"+query+"/topartists.xml";
			}

			// add event listener and load url
			myLoader.addEventListener(Event.COMPLETE, onSearchLoad);
			
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
			
			// set namespace
			//default xml namespace = xmlNs;
			
			// create result XML
			var data:XML = new XML(evt.target.data);
			var songsList:XMLList;
			
			// counter
			var num:int = 0;
			var artist:String = '';
			var track:String = '';
			
			// get toptracks by tag 
			if (mode == 0){
				// get song list
				songsList = data.track;
				
				// init array
				results = new ArrayCollection();
				
				// Report status
				setStatus('Parsing search results..');
				//setStatus('Парсим результаты поиска..');
				
				// counter
				num = 0;
				var mbid:String = '';
				
				// parse list
				//todo mbid
				for each(var item:XML in songsList){
					track = item.@name;
					if(item.children()[0] != null){
						artist = item.children()[0].@name;
					}else{
						artist = '';
					}
					if(item.children()[0].mbid != null){
						mbid = item.children()[0].mbid;
					}else{
						mbid = '';
					}
					if (artist != '' && track != ''){
						results.addItem({id:num,
							num:num,
							mbid:mbid,
							artist:artist,
							album:'',
							title:track,
							name:artist+" - "+track,
							dur:0,
							dur_link:0,
							url:'findme'});
					}
					artist = '';
					track = '';
					mbid = '';
					num++;
				}
			}

			//get top tags by artist
			if (mode == 1){
				// get song list
				songsList = data.tag;
				
				// init array
				results = new ArrayCollection();
				
				// Report status
				setStatus('Parsing tags list..');
				//setStatus('Парсим список тегов..');
				
				var tag:String = '';
				num = 0;
				
				// parse list
				for each(var itemtags:XML in songsList){
					tag = itemtags.name;
					if (tag != ''){
						results.addItem(tag);					
					}
					tag = '';
					num++;
					if (num == 5) break;
				}
			}

			//get similar artists
			if (mode == 2){
				// get song list
				songsList = data.artist;
				
				// init array
				results = new ArrayCollection();
				
				var str:String = '';
				num = 0;
				
				// parse list
				for each(var itemartists:XML in songsList){
					str = itemartists.name;
					if (str != ''){
						results.addItem({name:str});					
					}
					tag = '';
					num++;
					if (num == 12) break;
				}
			}
			
			// get toptracks by artist 
			if (mode == 3){
				// get song list
				songsList = data.track;
				
				// init array
				results = new ArrayCollection();
				
				// counter
				num = 0;
				var track_artist:String = '';
				
				// parse list
				for each(var item_track:XML in songsList){
					track_artist = item_track.name;
					if (query != '' && track_artist != ''){
						results.addItem({id:num,
							artist:query,
							num:num,
							name:query+" - "+track_artist,
							title:track_artist,
							dur:0,
							url:'findme'});					
					}
					track_artist = '';
					num++;
				}
			}
			
			// get toptracks by username 
			if (mode == 4){
				// get song list
				songsList = data.track;
				
				// init array
				results = new ArrayCollection();
				
				// counter
				num = 0;
				
				// parse list
				for each(var item_tracks:XML in songsList){
					track = item_tracks.name;
					artist = item_tracks.artist;
					if (artist != '' && track != ''){
						results.addItem({id:num,
							artist:artist,
							num:num,
							name:artist+" - "+track,
							title:track,
							dur:0,
							url:'findme'});					
					}
					num++;
				}
			}
			
			// get topartists by tag 
			if (mode == 5){
				// get song list
				songsList = data.artist;
				
				// init array
				results = new ArrayCollection();
				
				for each(var itemArtist:XML in songsList){
					artist = itemArtist.@name;

					if (artist != ''){
						results.addItem({
							artist:artist
						});
					}
					artist = '';
				}
			}
			
			// erase vars
			data = null;
			songsList = null;
			
			// Finished
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
			// call event
			dispatchEvent(new Event(Event.COMPLETE));
		}
	}
}