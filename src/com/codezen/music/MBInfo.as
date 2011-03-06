package com.codezen.music
{
	import com.codezen.helper.Worker;
	import com.codezen.util.CUtils;
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	
	import mx.collections.ArrayCollection;

	/**
	 * 
	 * @author yamalight
	 * Musicbrains search class
	 * Allows searching for artist by text, 
	 * albums of artist by artist id
	 * and tracks of album by album id
	 * 
	 * USAGE:
	 * var search:MBInfo = new MBInfo();
	 * search.addEventListener(MBInfo.COMPLETE, function():void{
	 *   trace(search.getAlbumsCollection());
	 * });
	 * search.getArtist('Muse');
	 * 
	 */
	public class MBInfo extends Worker
	{
		// Event dispatcher states
		public static var ARTIST_FOUND:String = "Artist found";
		
		// Saved data
		private var artistid:String;
		private var artistname:String;
		private var moreArtists:String;
		private var albumCover:String;
		private var albums:ArrayCollection;
		private var songs:ArrayCollection;
		
		// Misc data
		private static var artistURL:String = 'http://musicbrainz.org/ws/1/artist/?name=%query%&type=xml&limit=5';
		private static var albumsURL:String = 'http://musicbrainz.org/ws/1/artist/%artistid%?type=xml&inc=sa-Official+release-events';
		private static var tracksURL:String = 'http://musicbrainz.org/ws/1/release/%albumid%?type=xml&inc=tracks';
		private static var lastCoverURL:String = 'http://ws.audioscrobbler.com/1.0/album/%artistalbum%/info.xml';
		
		// Namespace
		private var xmlNs:Namespace = new Namespace("http://musicbrainz.org/ns/mmd-1.0#");
		
		// Counter
		private var counter:int;
		
		// requesters
		protected var urlInfoRequest:URLRequest;
		protected var myInfoLoader:URLLoader;
		
		public function MBInfo()
		{
			// create urlrequest and urlloader
			urlInfoRequest = new URLRequest();
			myInfoLoader = new URLLoader();
			// set prefs, add error event listener 
			myInfoLoader.dataFormat = URLLoaderDataFormat.TEXT;
			myInfoLoader.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
		}
		
		/**
		 * 
		 * @returns found artist name 
		 * 
		 */
		public function get artistName():String{
			return artistname;
		}
		
		/**
		 * 
		 * @returns found album cover url  
		 * 
		 */
		public function get albumCoverURL():String{
			return albumCover;
		}
		
		/**
		 * 
		 * @returns found artist id 
		 * 
		 */
		public function get artistId():String{
			return artistid;
		}
		
		 
		/**
		 * 
		 * @return relevant artists 
		 * 
		 */
		public function get relevantArtists():String{
			return moreArtists;
		}

		
		/**
		 * 
		 * @returns found albums collection 
		 * 
		 */
		public function get albumsList():ArrayCollection{
			return albums;
		}
		
		/**
		 * 
		 * @returns found songs collection 
		 * 
		 */
		public function get songsList():ArrayCollection{
			return songs;
		}
		
		/**
		 * Finds most popular artist on request and 
		 * get albums list
		 * 
		 * @param artist
		 * 
		 */		
		public function findArtist(artist:String):void{
			artistid = null;
			artistname = null;
			moreArtists = null;
			
			// Generate url
			var search_url:String = artistURL.replace("%query%",CUtils.urlEncode(artist));
			// Report status
			setStatus('Begining artist search..');
			//setStatus('Начинаем поиск исполнителя..');
			
			// from urlrequest and urlloader
			urlInfoRequest.url = search_url;
			// add event listener and load request
			myInfoLoader.addEventListener(Event.COMPLETE, onArtistLoad);
			myInfoLoader.load(urlInfoRequest);
		}
		
		/**
		 * Parses search result for artist search
		 * @param evt
		 * 
		 */		
		protected function onArtistLoad(evt:Event):void{
			// remove event listener
			myInfoLoader.removeEventListener(Event.COMPLETE, onArtistLoad);
			// close loader
			//myInfoLoader.close();
			
			// set namespace
			default xml namespace = xmlNs;
			
			// create result XML
			var data:XML = new XML(evt.target.data);
			
			// get artists list
			var artistsList:XMLList = data.descendants("artist-list").children();
			
			//set found 
			//var found:int = 0;
			//var step:int = 0;
			//var disambiguation:String = "";
			
			// Getting artist with same name
			for each(var item:XML in artistsList){
				//if (found == 0 && ((artist2find.toLowerCase() == item.name.text().toLowerCase()) || (('the '+artist2find.toLowerCase()) == item.name.text().toLowerCase()))){
					artistid = item.@id;
					artistname = item.name.text();
					/*found = 1;
					step++;
					if (step == 4) break;
				}
				else{
					if (item.descendants("disambiguation").children()[0] == null) {
						disambiguation = "";
					}
					else disambiguation = item.disambiguation.text().toLowerCase();
					moreArtists += item.@id + "|" + item.name.text() + "|" + item.name.text() + disambiguation + "@";
				}*/
				break;
			}

			// Report status
			if (artistname == null){
				setStatus('Album list not found :(');
				//setStatus('Списка альбомов не найдено(');
			}else{
				setStatus('Artist found: '+artistname+'!');
				//setStatus('Исполнитель найден: '+artistname+'!');				
			}
						
			// erase
			data = null;
			
			// dispatch event
			dispatchEvent(new Event(MBInfo.ARTIST_FOUND));
		}
		
		/**
		 * Loads a list of albums of found artist 
		 */		
		public function findAlbums(artistId:String,artistName:String):void{
			albums = null;
			
			artistid = artistId;
			artistname = artistName;
			// Generate url
			var search_url:String = albumsURL.replace("%artistid%",artistid);
			
			// from urlrequest and urlloader
			urlInfoRequest.url = search_url;
			// add event listener and load request
			myInfoLoader.addEventListener(Event.COMPLETE, onAlbumsLoad);
			myInfoLoader.load(urlInfoRequest);
		}
		
		/**
		 * Parses search result for albums search
		 * @param evt
		 * 
		 */		
		protected function onAlbumsLoad(evt:Event):void{
			// remove event listener
			myInfoLoader.removeEventListener(Event.COMPLETE, onAlbumsLoad);
			// close loader
			//myInfoLoader.close();
			
			// create result XML
			var data:XML = new XML(evt.target.data);
			
			// get albums list
			var albumsList:XMLList = data.artist.descendants("release-list").children().(@type == "Album Official" || @type == "EP Official");
			
			// create albums storage
			albums = new ArrayCollection();

			// counter
			var num:int = 0;
			
			// albums already saved
			var saved_albums:Array = new Array();
			
			// album title
			var title:String = '';
			var date:String = '';
			
			// parse list to storage
			for each(var item:XML in albumsList){
				// get date
				if(item.descendants("release-event-list").children()[0] != null){
					date = item.descendants("release-event-list").children()[0].@date;
				}else{
					date = '';
				}
				// get title
				title = String(item.children()[0].text());
				// check if title already saved
				if(saved_albums.indexOf(title) < 0){
					saved_albums.push(title);
					albums.addItem({id:item.@id,
									num:num,
									name:title,
									artistid:artistid,
									artist:artistname,
									date:date,
									image:'',
									image_local:''});
					num++;
				}
			}
			
			// reset vars
			data = null;
			albumsList = null;
			title = null;
			date = null;
			saved_albums = null;
			
			if(albums.length < 1){
				// Report error
				dispatchError("No albums found!", "Albums result error!", false, 1);
				//dispatchError("Ни одного альбома не найдено! :(", "Ошибка в результатах поиска альбомов!", false, 1);
				return;
			}
			
			// Report status
			setStatus('Found '+albums.length+' albums! Begining cover images search.');
			//setStatus('Найдено '+albums.length+' альбомов! Начинаем поиск картинок..');
			
			// get albums covers
			//loadAlbumCovers();
			endLoad();
		}
		
		/**
		 * Searches for tracklist for given album 
		 * @param albumid
		 * 
		 */
		public function findTracks(albumid:String):void{
			songs = null;
			
			if(albumid == '' || albumid.length < 1){
				// Dispatch error event
				dispatchError("No album ID specified!", "Tracks find error!");
				//dispatchError("Не задан ID альбома!", "Ошибка поиска песен!");
				return;
			}
			// Generate url
			var search_url:String = tracksURL.replace("%albumid%",albumid);
			
			// Report status
			setStatus('Begining tracks search..');
			//setStatus('Начинаем искать песни..');
			
			// from urlrequest and urlloader
			urlInfoRequest.url = search_url;
			// add event listener and load request
			myInfoLoader.addEventListener(Event.COMPLETE, onTracksLoad);
			myInfoLoader.load(urlInfoRequest);
		}
		
		/**
		 * Parses search result for tracks search
		 * @param evt
		 * 
		 */		
		protected function onTracksLoad(evt:Event):void{
			// remove event listener
			myInfoLoader.removeEventListener(Event.COMPLETE, onTracksLoad);
			// close loader
			//myInfoLoader.close();
			
			// set namespace
			default xml namespace = xmlNs;
			
			// create result XML
			var data:XML = new XML(evt.target.data);
			
			// get song list
			var songsList:XMLList = data.release.descendants("track-list").children();
			
			// init array
			songs = new ArrayCollection();
			
			// Report status
			setStatus('Parsing search results..');
			//setStatus('Парсим результаты поиска..');
			
			// counter
			var num:int = 0;
			var dur:int = 0;
			var duration:String = '';
			
			// parse list
			for each(var item:XML in songsList){
				if(item.children()[1] != null){
					dur = item.children()[1].text();
				}else{
					dur = 0;
				}
				
				var secs:int = dur/1000;
				var mins:int = Math.floor(secs/60);
				secs = secs - mins*60;
				if( secs < 10 ){ 
					duration = mins+":0"+secs;
				}else{
					duration = mins+":"+secs;
				}
				
				songs.addItem({id:item.@id,
					num:num,
					name:item.children()[0].text(),
					dur:dur,
					duration:duration
				});
				//trace('find track:'+ item.children()[0].text());
				num++;
			}
			
			// erase vars
			data = null;
			songsList = null;
			
			// Finished
			endLoad();
		}
		
		/**
		 * Loads a covers of found albums 
		 */		
		public function findAlbumCover(albumName:String, artist:String = null):void{	
			albumCover = null;
			
			// generate search string
			var search_string:String = (artist == null)?artistname:artist+"/";
			search_string += CUtils.urlEncode( String(albumName).replace(/\(.*?\)/gs, "") );
			// Generate url
			var search_url:String = lastCoverURL.replace("%artistalbum%",search_string);
			
			// from urlrequest and urlloader
			urlInfoRequest.url = search_url;
			// add event listener and load request
			myInfoLoader.addEventListener(Event.COMPLETE, onCoverLoad);
			// remove generic event catcher
			myInfoLoader.removeEventListener(IOErrorEvent.IO_ERROR, onIOError);
			// add special event catcher
			myInfoLoader.addEventListener(IOErrorEvent.IO_ERROR, onAlbumsIOError);
			myInfoLoader.load(urlInfoRequest);
		}
		
		/**
		 * Parses search result for album cover search
		 * @param evt
		 * 
		 */		
		protected function onCoverLoad(evt:Event):void{
			// remove event listener
			myInfoLoader.removeEventListener(Event.COMPLETE, onCoverLoad);
			// close loader
			//myInfoLoader.close();
			
			// create result XML
			var data:XML = new XML(evt.target.data);
			var cover:String = data.coverart.large.text();
			var date:String = data.releasedate.text();

			//if(cover.length < 0){ trace('error'); return; }
			
			// Report status
			setStatus('Found cover.. Continuing');
			//setStatus('Найдено '+(albums.length-counter+1)+' из '+albums.length+' картинок. Продолжаем..');
			
			// save album cover url
			albumCover = cover;
			
			// erase var
			data = null;
			cover = null;
			date = null;
			
			// end
			endLoad();
		}
		
		/**
		 * 
		 * @param e
		 * 
		 * Generic IO Error event handler
		 */
		protected function onAlbumsIOError(e:IOErrorEvent):void{
			// remove event listener
			myInfoLoader.removeEventListener(IOErrorEvent.IO_ERROR, onAlbumsIOError);
			// close loader
			//myInfoLoader.close();
			
			// Report status
			setStatus('Not found cover.. Continuing');
			//setStatus('Найдено '+(albums.length-counter+1)+' из '+albums.length+' картинок. Продолжаем..');
			
			// set default cover
			albumCover = "http://cdn.last.fm/flatness/catalogue/noimage/2/default_album_medium.png";
			
			// end
			endLoad();
		}

		
		/**
		 * Dispatches end of load event and does cleanup 
		 */
		override protected function endLoad():void{
			// do cleanup
			// remove special event catcher
			myInfoLoader.removeEventListener(IOErrorEvent.IO_ERROR, onAlbumsIOError);
			// add generic event catcher
			myInfoLoader.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
			// Report status
			setStatus('Search complete!');
			//setStatus('Поиск завершен!');
			// Dispatch complete event
			dispatchEvent(new Event(Event.COMPLETE));
		}
		
		/**
		 * 
		 * @param e
		 * 
		 * Generic IO Error event handler
		 */
		protected function onIOError(e:IOErrorEvent):void{
			//dispatchError(e.text, "IO Error happened in MBInfo class");
			trace("Generic IO Error! "+e.text);
		}
	}
}