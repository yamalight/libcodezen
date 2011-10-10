package com.codezen.mse.services{
	import com.codezen.helper.WebWorker;
	import com.codezen.mse.models.Album;
	import com.codezen.mse.models.Artist;
	import com.codezen.mse.models.Song;
	import com.codezen.util.CUtils;
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.utils.escapeMultiByte;
	
	import mx.utils.ObjectUtil;
	
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
	public final class MusicBrainz extends WebWorker
	{
		// result data
		private var artists:Array;
		private var tracks:Array;
		private var albums:Array;
		private var songs:Array;
		private var _albumCover:String;
		
		// internal data
		private var _artist:Artist;
		private var _album:Album;
		
		private var _offset:int;
		
		// Misc data
		private static var searchLimit:int;
		private static var artistSearchURL:String = 'http://musicbrainz.org/ws/2/artist?query=%query%&limit='+searchLimit;
		private static var albumsSearchURL:String = 'http://musicbrainz.org/ws/2/release?query=%query%&limit='+searchLimit;
		private static var trackSearchURL:String = 'http://musicbrainz.org/ws/2/recording?query=%query%&limit='+searchLimit;
		private static var albumsURL:String = 'http://musicbrainz.org/ws/2/release?artist=%artistid%&type=album|ep|single&limit=100';//status=official&limit=500';
		private static var tracksURL:String = 'http://musicbrainz.org/ws/2/release/%albumid%?inc=recordings';
		private static var lastCoverURL:String = 'http://ws.audioscrobbler.com/1.0/album/%artistalbum%/info.xml';
		private static var findAlbumByNameURL:String = 'http://musicbrainz.org/ws/2/release?query=release:%album%+artist:%artist%&limit=100'; //type:album
		private static var findAlbumByNameIdURL:String = 'http://musicbrainz.org/ws/2/release?query=release:%album%+arid:%id%&limit=100'; //type:album
		
		// Namespace
		private var xmlNs:Namespace = new Namespace("http://musicbrainz.org/ns/mmd-2.0#");
		
		public function MusicBrainz(limit:int = 5)
		{
			super();
			
			searchLimit = limit;
		}
		
		public function get albumCover():String
		{
			return _albumCover;
		}
		
		/**
		 *
		 * @returns found artists list
		 *
		 */
		public function get artistsList():Array{
			return artists;
		}
		
		/**
		 *
		 * @returns found tracks list
		 *
		 */
		public function get tracksList():Array{
			return tracks;
		}
		
		/**
		 *
		 * @returns found albums collection
		 *
		 */
		public function get albumsList():Array{
			return albums;
		}
		
		/**
		 *
		 * @returns found songs collection
		 *
		 */
		public function get songsList():Array{
			return songs;
		}
		
		/**
		 * Finds most relative  artist on request
		 *
		 * @param artist
		 *
		 */
		public function findArtist(artist:String):void{
			// Generate url
			var search_url:String = artistSearchURL.replace("%query%",CUtils.urlEncode(artist));
			// Report status
			setStatus('Begining artist search..');
			
			// from urlrequest and urlloader
			urlRequest.url = search_url;
			// add event listener and load request
			myLoader.addEventListener(Event.COMPLETE, onArtistLoad);
			myLoader.load(urlRequest);
		}
		
		/**
		 * Parses search result for artist search
		 * @param evt
		 *
		 */
		private function onArtistLoad(evt:Event):void{
			// remove event listener
			myLoader.removeEventListener(Event.COMPLETE, onArtistLoad);
			
			// clean old stuff
			artists = [];
			
			// set namespace
			default xml namespace = xmlNs;
			
			// create result XML
			var data:XML = new XML(evt.target.data);
			
			// get artists list
			var artistsList:XMLList = data.descendants("artist-list").children();
			
			//set found
			var ar:Artist;
			
			// Getting artist with same name
			for each(var item:XML in artistsList){
				ar = new Artist();
				ar.mbID = item.@id;
				ar.name = item.name.text();
				ar.disambiguation = item.disambiguation.text();
				ar.active_start = item.child("life-span").@begin;
				ar.active_end = item.child("life-span").@end;
				artists.push(ar);
			}
			
			// Report status
			if (artists.length < 1){
				setStatus('No artists not found :(');
			}else{
				setStatus('Found '+artists.length+' artists!');
			}
			
			// erase
			data = null;
			
			// dispatch event
			endLoad();
		}
		
		/**
		 * Loads a list of albums of found artist
		 */
		public function findAlbums(album:String):void{
			albums = null;
			
			// Generate url
			var search_url:String = albumsSearchURL.replace("%query%",album);
			
			// from urlrequest and urlloader
			urlRequest.url = search_url;
			// add event listener and load request
			myLoader.addEventListener(Event.COMPLETE, onAlbumsSearchLoad);
			myLoader.load(urlRequest);
		}
		
		/**
		 * Parses search result for albums search
		 * @param evt
		 *
		 */
		private function onAlbumsSearchLoad(evt:Event):void{
			// remove event listener
			myLoader.removeEventListener(Event.COMPLETE, onAlbumsSearchLoad);
			
			// create result XML
			var data:XML = new XML(evt.target.data);
			
			// get albums list
			var albumsList:XMLList = data.descendants("release-list").children();//.(@type == "Album Official" || @type == "EP Official");
			
			// create albums storage
			albums = [];
			
			// counter
			var num:int = 0;
			
			// album title
			var title:String = '';
			var date:String = '';
			var alb:Album;
			
			// albums already saved
			var saved_albums:Array = [];
			
			// parse list to storage
			for each(var item:XML in albumsList){
				// get date
				date = item.date.text();
				// get title
				title = item.title.text();
				title = item.title.text();
				// check if title already saved
				if(saved_albums.indexOf(title) < 0 && item.status.text() == "Official"){
					saved_albums.push(title);
					
					// save album
					alb = new Album();
					alb.mbID = item.@id;
					alb.number = num;
					alb.name = title;
					alb.date = date;
					alb.image = '';
					alb.artist = new Artist();
					alb.artist.mbID = item.descendants("artist-credit").descendants("name-credit").artist.@id;
					alb.artist.name = item.descendants("artist-credit").descendants("name-credit").artist.name.text();
					
					albums.push(alb);
					num++;
				}
			}
			
			// reset vars
			data = null;
			albumsList = null;
			title = null;
			date = null;
			
			if(albums.length < 1){
				// Report error
				dispatchError("No albums found!", "Albums result error!", false, 1);
				return;
			}
			
			// Report status
			setStatus('Found '+albums.length+' albums!');
			
			// end
			endLoad();
		}
		
		/**
		 * Loads a list of albums of found artist
		 */
		public function findAlbumByName(album:String, artist:String, artistId:String = ''):void{
			albums = null;
			
			// Generate url
			var search_url:String;
			if(artistId != null && artistId.length > 0){
				search_url = encodeURI(
					findAlbumByNameIdURL.replace(
						"%album%", "'"+album.replace(/\s/g, "_").replace(/'/g, "")+"'"
					).replace(
						"%id%", artistId
					)
				);
			}else{
				search_url = encodeURI( 
					findAlbumByNameURL.replace(
						"%album%", "'"+album.replace(/\s/g, "_").replace(/'/g, "")+"'"
					).replace(
						"%artist%","'"+artist.replace(/\s/g, "_").replace(/'/g, "")+"'"
					)
				);
			}
			
			trace(search_url);
			
			// from urlrequest and urlloader
			urlRequest.url = search_url;
			// add event listener and load request
			myLoader.addEventListener(Event.COMPLETE, onAlbumsByNameSearchLoad);
			myLoader.load(urlRequest);
		}
		
		/**
		 * Parses search result for albums search
		 * @param evt
		 *
		 */
		private function onAlbumsByNameSearchLoad(evt:Event):void{
			// remove event listener
			myLoader.removeEventListener(Event.COMPLETE, onAlbumsByNameSearchLoad);
			
			// create result XML
			var data:XML = new XML(evt.target.data);
			
			// get albums list
			var albumsList:XMLList = data.descendants("release-list").children();//.(@type == "Album Official" || @type == "EP Official");
			
			// create albums storage
			albums = [];
			
			// counter
			var num:int = 0;
			
			// album title
			var title:String = '';
			var date:String = '';
			var alb:Album;
			
			// albums already saved
			var saved_albums:Array = [];
			
			// parse list to storage
			for each(var item:XML in albumsList){
				// get date
				date = item.date.text();
				// get title
				title = item.title.text();
				// check if title already saved
				if(saved_albums.indexOf(title) < 0){// && item.status.text() == "Official"){
					saved_albums.push(title);
					
					// save album
					alb = new Album();
					alb.mbID = item.@id;
					alb.number = num;
					alb.name = title;
					alb.date = date;
					alb.image = '';
					alb.artist = new Artist();
					alb.artist.mbID = item.descendants("artist-credit").descendants("name-credit").artist.@id;
					alb.artist.name = item.descendants("artist-credit").descendants("name-credit").artist.name.text();
					
					albums.push(alb);
					num++;
				}
			}
			
			// reset vars
			data = null;
			albumsList = null;
			title = null;
			date = null;
			
			if(albums.length < 1){
				// Report error
				dispatchError("No albums found!", "Albums result error!", false, 1);
				return;
			}
			
			// Report status
			setStatus('Found '+albums.length+' albums!');
			
			// end
			endLoad();
		}
		
		/**
		 * Finds most relative tracks on request
		 *
		 * @param query
		 *
		 */
		public function findSongs(query:String):void{
			// clean old stuff
			tracks = [];
			
			// Generate url
			var search_url:String = trackSearchURL.replace("%query%",CUtils.urlEncode(query));
			// Report status
			setStatus('Begining tracks search..');
			
			// from urlrequest and urlloader
			urlRequest.url = search_url;
			// add event listener and load request
			myLoader.addEventListener(Event.COMPLETE, onSongsLoad);
			myLoader.load(urlRequest);
		}
		
		/**
		 * Parses search result for artist search
		 * @param evt
		 *
		 */
		private function onSongsLoad(evt:Event):void{
			// remove event listener
			myLoader.removeEventListener(Event.COMPLETE, onSongsLoad);
			
			// set namespace
			default xml namespace = xmlNs;
			
			// create result XML
			var data:XML = new XML(evt.target.data);
			
			// get artists list
			var songList:XMLList = data.descendants("recording-list").children();
			
			// counter
			var num:int = 0;
			var dur:int = 0;
			var duration:String = '';
			var sng:Song;
			var item:XML;
			
			// parse list
			for each(item in songList){
				if(item.length != null){
					dur = item.length.text();
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
				
				sng = new Song();
				sng.mbID = item.@id;
				sng.name = item.title.text();
				sng.number = num;
				sng.duration = dur;
				sng.durationText = duration;
				sng.artist = new Artist();
				sng.artist.name = item.descendants("artist-credit").descendants("name-credit").artist.name.text();
				sng.artist.mbID = item.descendants("artist-credit").descendants("name-credit").artist.@id;
				
				tracks.push(sng);
				num++;
			}
			
			// Report status
			if (tracks.length < 1){
				setStatus('No songs found :(');
			}else{
				setStatus('Found '+tracks.length+' songs!');
			}
			
			// erase
			data = null;
			
			// dispatch event
			endLoad();
		}
		
		/**
		 * Loads a list of albums of found artist
		 */
		public function getAlbums(artist:Artist, offset:int = 0):void{
			if(offset == 0){
				albums = null;
			}
			
			_artist = artist;
			_offset = offset;
			
			// Generate url
			var search_url:String = albumsURL.replace("%artistid%",artist.mbID);
			if(offset > 0){
				search_url += "&offset="+offset;
				trace('requesting one more time');
			}
			
			// from urlrequest and urlloader
			urlRequest.url = search_url;
			// add event listener and load request
			myLoader.addEventListener(Event.COMPLETE, onAlbumsLoad);
			myLoader.load(urlRequest);
		}
		
		/**
		 * Parses search result for albums search
		 * @param evt
		 *
		 */
		private function onAlbumsLoad(evt:Event):void{
			// remove event listener
			myLoader.removeEventListener(Event.COMPLETE, onAlbumsLoad);
			
			// create result XML
			var data:XML = new XML(evt.target.data);
			
			// get albums list
			var albumsList:XMLList = data.descendants("release-list").children();//.(@type == "Album Official" || @type == "EP Official" || @type == "Single Official");
			
			// total results count
			var total:int = data.descendants("release-list").@count;
			
			// create albums storage
			if(_offset == 0) albums = [];
			
			// counter
			var num:int = 0;
			
			// artist info
			var artistId:String = data.artist.@id;
			var artistName:String = data.artist.name.text();
			
			// albums already saved
			var saved_albums:Array = [];
			
			// album title
			var title:String = '';
			var date:String = '';
			var alb:Album;
			
			// refill saved
			if(_offset > 0){
				for each(alb in albums){
					saved_albums.push(alb.name);
				}
			}
			
			// parse list to storage
			for each(var item:XML in albumsList){
				// get date
				date = item.date.text();
				// get title
				title = item.title.text();
				// check if title already saved
				if(saved_albums.indexOf(title) < 0 && item.status.text() == "Official"){
					saved_albums.push(title);
					
					alb = new Album();
					alb.mbID = item.@id;
					alb.number = num;
					alb.name = title;
					alb.date = date;
					alb.image = '';
					alb.artist = _artist;
					
					albums.push(alb);
					num++;
				}
			}
			
			// reset vars
			data = null;
			albumsList = null;
			title = null;
			date = null;
			saved_albums = null;
			
			if(_offset < total){
				_offset += 100;
				getAlbums(_artist, _offset);
			}else{
				if(albums.length < 1){
					// Report error
					dispatchError("No albums found!", "Albums result error!", false, 1);
					return;
				}
				
				albums.sortOn("date", Array.DESCENDING);
				
				// Report status
				setStatus('Found '+albums.length+' albums!');
				
				// end
				endLoad();
			}
		}
		
		/**
		 * Searches for tracklist for given album
		 * @param albumid
		 *
		 */
		public function getTracks(album:Album):void{
			_album = album;
			
			songs = null;
			
			if(album == null || album.mbID == null || album.mbID.length < 1){
				// Dispatch error event
				dispatchError("No album ID specified!", "Tracks find error!");
				return;
			}
			// Generate url
			var search_url:String = tracksURL.replace("%albumid%",album.mbID);
			
			// Report status
			setStatus('Begining tracks search..');
			
			// from urlrequest and urlloader
			urlRequest.url = search_url;
			// add event listener and load request
			myLoader.addEventListener(Event.COMPLETE, onTracksLoad);
			myLoader.load(urlRequest);
		}
		
		/**
		 * Parses search result for tracks search
		 * @param evt
		 *
		 */
		private function onTracksLoad(evt:Event):void{
			// remove event listener
			myLoader.removeEventListener(Event.COMPLETE, onTracksLoad);
			
			// set namespace
			default xml namespace = xmlNs;
			
			// create result XML
			var data:XML = new XML(evt.target.data);
			
			// get song list
			var songsList:XMLList = data.release.descendants("track-list").children();
			
			// init array
			songs = [];
			
			// Report status
			setStatus('Parsing search results..');
			
			// counter
			var dur:int = 0;
			var duration:String = '';
			var sng:Song;
			
			// parse list
			for each(var item:XML in songsList){
				trace(item);
				if(item.length != null){
					dur = item.length.text();
					
					if( dur > 0 ){
						var secs:int = dur/1000;
						var mins:int = Math.floor(secs/60);
						secs = secs - mins*60;
						if( secs < 10 ){
							duration = mins+":0"+secs;
						}else{
							duration = mins+":"+secs;
						}
					}else{
						duration = "?:??";
					}
				}else{
					dur = 0;
					duration = "?:??";
				}
				
				sng = new Song();
				sng.mbID = item.recording.@id;
				sng.name = item.recording.title.text();
				sng.number = item.position.text();
				sng.duration = dur;
				sng.durationText = duration;
				sng.artist = new Artist();
				sng.artist.name = _album.artist.name;
				sng.artist.mbID = _album.artist.mbID;
				
				songs.push(sng);
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
			_albumCover = null;
			
			// generate search string
			var search_string:String = encodeURIComponent( artist ).replace(/%26/g, "%2526")+"/";
			search_string += encodeURIComponent( albumName ).replace(/%26/g, "%2526");
			// Generate url
			var search_url:String = lastCoverURL.replace("%artistalbum%", search_string);
			
			// from urlrequest and urlloader
			urlRequest.url = search_url;
			// add event listener and load request
			myLoader.addEventListener(Event.COMPLETE, onCoverLoad);
			// remove generic event catcher
			myLoader.removeEventListener(IOErrorEvent.IO_ERROR, onError);
			// add special event catcher
			myLoader.addEventListener(IOErrorEvent.IO_ERROR, onAlbumsIOError);
			myLoader.load(urlRequest);
		}
		
		/**
		 * Parses search result for album cover search
		 * @param evt
		 *
		 */
		private function onCoverLoad(evt:Event):void{
			// remove event listener
			myLoader.removeEventListener(Event.COMPLETE, onCoverLoad);
			
			// create result XML
			var data:XML = new XML(evt.target.data);
			var cover:String = data.coverart.large.text();
			var date:String = data.releasedate.text();
			
			//if(cover.length < 0){ trace('error'); return; }
			
			// Report status
			setStatus('Found cover.. Continuing');
			//setStatus('Найдено '+(albums.length-counter+1)+' из '+albums.length+' картинок. Продолжаем..');
			
			// save album cover url
			_albumCover = cover;
			
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
		private function onAlbumsIOError(e:IOErrorEvent):void{
			// remove event listener
			myLoader.removeEventListener(IOErrorEvent.IO_ERROR, onAlbumsIOError);
			
			// Report status
			setStatus('No cover found! Setting default image.');
			
			// set default cover
			_albumCover = "http://cdn.last.fm/flatness/catalogue/noimage/2/default_album_medium.png";
			
			// end
			endLoad();
		}
		
		
		/**
		 * Dispatches end of load event and does cleanup
		 */
		override protected function endLoad():void{
			// do cleanup
			// remove special event catcher
			myLoader.removeEventListener(IOErrorEvent.IO_ERROR, onAlbumsIOError);
			// add generic event catcher
			myLoader.addEventListener(IOErrorEvent.IO_ERROR, onError);
			// Report status
			setStatus('Search complete!');
			// Dispatch complete event
			dispatchEvent(new Event(Event.COMPLETE));
		}
	}
}