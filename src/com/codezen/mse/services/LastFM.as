package com.codezen.mse.services{
	import com.codezen.helper.WebWorker;
	import com.codezen.mse.models.Album;
	import com.codezen.mse.models.Artist;
	import com.codezen.mse.models.Song;
	import com.codezen.util.CUtils;
	
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	
	import mx.utils.ObjectUtil;
	
	public final class LastFM extends WebWorker
	{
		/**
		 * TODO: REWRITE ALL THESE CRAP
		 */
		// result of search
		private var _result:String;
		private var _results:Array;
		
		// artist info
		private var _artist:Artist;
		// song info
		private var _song:Song;
		
		// api key - this one from Mielophone
		private var api_key:String = "0b18095c48d2bb8bf4acbab629bcc30e";
		
		// limit
		private var _limit:int;
		
		public function LastFM(limit:int = 5)
		{
			super();
			
			_limit = limit;
		}
		
		public function get song():Song
		{
			return _song;
		}

		public function get artist():Artist
		{
			return _artist;
		}
		
		/**
		 *
		 * @return (String) result of search
		 *
		 */
		public function get resultString():String{
			return _result;
		}
		
		/**
		 *
		 * @return (Array) results of search
		 *
		 */
		public function get resultArray():Array{
			return _results;
		}
		
		public function getTopArtists():void{
			// reset old stuff
			_results = [];
			
			//get topartists by tag
			var urlRequest:URLRequest = new URLRequest("http://ws.audioscrobbler.com/2.0/?method=chart.gettopartists&api_key="+api_key);
			
			// add event listener and load url
			myLoader.addEventListener(Event.COMPLETE, onTopArtistLoad);
			myLoader.load(urlRequest);
		}
		
		private function onTopArtistLoad(evt:Event):void{
			// add event listener and load url
			myLoader.removeEventListener(Event.COMPLETE, onTopArtistLoad);
			
			// create result XML
			var data:XML = new XML(evt.target.data);
			var artistList:XMLList = data.artists.children();
			
			// counter
			var artist:Artist;
			var itemArtist:XML;
			
			for each(itemArtist in artistList){
				artist = new Artist();
				artist.name = itemArtist.name.text();
				if( itemArtist.image.(@size == "large") != null ){
					artist.image = itemArtist.image.(@size == "large").text();
				}
				artist.mbID = itemArtist.mbid.text();
				
				_results.push(artist);
			}
			
			// erase vars
			data = null;
			artistList = null;
			
			// Finished
			endLoad();
		}
		
		public function getTopTracks():void{
			// reset old stuff
			_results = [];
			
			//get toptracks by tag
			var urlRequest:URLRequest = new URLRequest("http://ws.audioscrobbler.com/2.0/?method=chart.gettoptracks&api_key="+api_key);
			
			// add event listener and load url
			myLoader.addEventListener(Event.COMPLETE, onTopTracksLoad);
			myLoader.load(urlRequest);
		}
		
		private function onTopTracksLoad(evt:Event):void{
			// add event listener and load url
			myLoader.removeEventListener(Event.COMPLETE, onTopTracksLoad);
			
			// create result XML
			var data:XML = new XML(evt.target.data);
			var songsList:XMLList = data.tracks.children();
			
			// parse list
			var item:XML;
			var song:Song;
			var num:int = 1;
			var dur:int = 0;
			var duration:String = '';
			
			for each(item in songsList){
				if(item.duration != null){
					dur = item.duration.text();
				}else{
					dur = 0;
				}
				
				var secs:int = dur;
				var mins:int = Math.floor(secs/60);
				secs = secs - mins*60;
				if( secs < 10 ){
					duration = mins+":0"+secs;
				}else{
					duration = mins+":"+secs;
				}
				
				song = new Song();
				song.number = num++;
				song.name = item.name.text();
				song.duration = dur * 1000;
				song.durationText = duration;
				song.artist = new Artist();
				song.artist.mbID = item.artist.mbid.text();
				song.artist.name = item.artist.name.text();
				
				_results.push(song);
			}
			
			// erase vars
			data = null;
			songsList = null;
			
			// Finished
			endLoad();
		}
		
		// -------------------------------------------------
		
		public function getTopTracksByTag(tag:String):void{
			// reset old stuff
			_results = [];
			
			//get toptracks by tag
			var urlRequest:URLRequest = new URLRequest("http://ws.audioscrobbler.com/2.0/?method=tag.gettoptracks&limit=100&tag="+encodeURIComponent(tag)+"&api_key="+api_key);
			
			// add event listener and load url
			myLoader.addEventListener(Event.COMPLETE, onTracksSearchLoad);
			myLoader.load(urlRequest);
		}
		
		private function onTracksSearchLoad(evt:Event):void{
			// add event listener and load url
			myLoader.removeEventListener(Event.COMPLETE, onTracksSearchLoad);
			
			// create result XML
			var data:XML = new XML(myLoader.data);
			var songsList:XMLList = data.toptracks.track;
			
			// init array
			_results = [];
			
			// Report status
			setStatus('Parsing search results..');
			
			// counter
			var s:Song;
			
			// parse list
			for each(var item:XML in songsList){
				s = new Song();
				s.name = item.name;
				s.artist = new Artist();
				s.artist.name = item.artist.name;
				s.artist.mbID = item.artist.mbid;
				
				_results.push(s);
			}
			
			// erase vars
			data = null;
			songsList = null;
			
			// Finished
			endLoad();
		}
		
		
		public function getTopTags():void{
			// reset old stuff
			_results = [];
			
			//get top tags by artist
			var urlRequest:URLRequest = new URLRequest("http://ws.audioscrobbler.com/2.0/?method=tag.getTopTags&api_key="+api_key);
			
			// add event listener and load url
			myLoader.addEventListener(Event.COMPLETE, onTopTags);
			myLoader.load(urlRequest);
		}
		
		private function onTopTags(evt:Event):void{
			// add event listener and load url
			myLoader.removeEventListener(Event.COMPLETE, onTopTags);
			
			// create result XML
			var data:XML = new XML(myLoader.data);
			var tagList:XMLList = data.toptags.children();
			
			// init array
			_results = [];
			
			// Report status
			setStatus('Parsing tags list..');
			
			// parse list
			var num:int = 0;
			var tag:XML;
			for each(tag in tagList){
				_results.push({name: tag.name.text(), count: int(tag.count.text())});
				num++;
				if (num == 50) break;
			}
			
			// erase vars
			data = null;
			tagList = null;
			
			// Finished
			endLoad();
		}
		
		public function getSimilar(query:String):void{
			// reset old stuff
			_results = [];
			
			// encode query
			query = CUtils.urlEncode(query);
			
			//get similar artists
			var urlRequest:URLRequest = new URLRequest("http://ws.audioscrobbler.com/1.0/artist/"+query+"/similar.xml");
			
			// add event listener and load url
			myLoader.addEventListener(Event.COMPLETE, onSimilarLoad);
			myLoader.load(urlRequest);
		}
		
		private function onSimilarLoad(evt:Event):void{
			// add event listener and load url
			myLoader.removeEventListener(Event.COMPLETE, onSimilarLoad);
			
			// create result XML
			var data:XML = new XML(evt.target.data);
			var songsList:XMLList = data.artist;
			
			// counter
			var num:int = 0;
			var artist:String = '';
			var track:String = '';
			
			// init array
			_results = [];
			
			var str:String = '';
			num = 0;
			
			// parse list
			for each(var itemartists:XML in songsList){
				str = itemartists.name;
				if (str != ''){
					_results.push({name:str});
				}
				//tag = '';
				num++;
				if (num == _limit) break;
			}
			
			// erase vars
			data = null;
			songsList = null;
			
			// Finished
			endLoad();
		}
		
		public function getTopArtistTracks(query:String):void{
			// reset old stuff
			_results = [];
			
			// encode query
			query = CUtils.urlEncode(query);
			
			//get toptracks of artist
			var urlRequest:URLRequest = new URLRequest("http://ws.audioscrobbler.com/1.0/artist/"+query+"/toptracks.xml");
			
			// add event listener and load url
			myLoader.addEventListener(Event.COMPLETE, onTopArtistTracksLoad);
			myLoader.load(urlRequest);
		}
		
		private function onTopArtistTracksLoad(evt:Event):void{
			// add event listener and load url
			myLoader.removeEventListener(Event.COMPLETE, onTopArtistTracksLoad);
			
			// create result XML
			var data:XML = new XML(evt.target.data);
			var songsList:XMLList = data.track;
			
			// counter
			var num:int = 0;
			var artist:String = '';
			var track:String = '';
			
			// init array
			_results = [];
			
			// counter
			num = 0;
			var track_artist:String = '';
			
			// parse list
			var query:String = ''; // TODO: WTF IS THIS?
			for each(var item_track:XML in songsList){
				track_artist = item_track.name;
				if (query != '' && track_artist != ''){
					_results.addItem({id:num,
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
			
			// erase vars
			data = null;
			songsList = null;
			
			// Finished
			endLoad();
		}
		
		public function getTopUserTracks(query:String):void{
			// reset old stuff
			_results = [];
			
			// encode query
			query = CUtils.urlEncode(query);
			
			//get toptracks of lastfm username
			var urlRequest:URLRequest = new URLRequest("http://ws.audioscrobbler.com/1.0/user/"+query+"/toptracks.xml");
			
			// add event listener and load url
			myLoader.addEventListener(Event.COMPLETE, onTopUserTracksLoad);
			myLoader.load(urlRequest);
		}
		
		private function onTopUserTracksLoad(evt:Event):void{
			// add event listener and load url
			myLoader.removeEventListener(Event.COMPLETE, onTopUserTracksLoad);
			
			// create result XML
			var data:XML = new XML(evt.target.data);
			var songsList:XMLList = data.track;
			
			// counter
			var num:int = 0;
			var artist:String = '';
			var track:String = '';
			
			// init array
			_results = [];
			
			// counter
			num = 0;
			
			// parse list
			for each(var item_tracks:XML in songsList){
				track = item_tracks.name;
				artist = item_tracks.artist;
				if (artist != '' && track != ''){
					_results.push({id:num,
						artist:artist,
						num:num,
						name:artist+" - "+track,
						title:track,
						dur:0,
						url:'findme'});
				}
				num++;
			}
			
			// erase vars
			data = null;
			songsList = null;
			
			// Finished
			endLoad();
		}
		
		
		public function getTopArtistsByTag(tag:String):void{
			// reset old stuff
			_results = [];
			
			//get topartists by tag
			var urlRequest:URLRequest = new URLRequest("http://ws.audioscrobbler.com/2.0/?method=tag.gettopartists&tag="+encodeURIComponent(tag)+"&api_key="+api_key);
			
			// add event listener and load url
			myLoader.addEventListener(Event.COMPLETE, onTopArtistByTagLoad);
			myLoader.load(urlRequest);
		}
		
		private function onTopArtistByTagLoad(evt:Event):void{
			// add event listener and load url
			myLoader.removeEventListener(Event.COMPLETE, onTopArtistByTagLoad);
			
			// create result XML
			var data:XML = new XML(evt.target.data);
			var artistList:XMLList = data.topartists.children();
			
			// counter
			var artist:Artist;
			
			// init array
			_results = [];
			
			var item:XML;
			for each(item in artistList){
				artist = new Artist();
				artist.name = item.name.text();
				artist.mbID = item.mbid.text();
				artist.image = item.image[2].text();
				_results.push(artist);
			}
			
			// erase vars
			data = null;
			artistList = null;
			
			// Finished
			endLoad();
		}
		
		/**
		 *
		 * @param mbid - musicbrainz artist id for search
		 *
		 * Searches for track info and album cover
		 */
		public function getArtistInfo(artist:Artist):void{
			_artist = artist;
			
			// Generate Last.FM url
			var sim_url:String = "http://ws.audioscrobbler.com/2.0/?method=artist.getinfo";
			if(_artist.mbID == null || _artist.mbID.length < 1){
				sim_url += "&artist="+encodeURIComponent(_artist.name);
			}else{
				sim_url += "&mbid=" + encodeURIComponent(_artist.mbID);
			}
			sim_url += "&api_key="+api_key+"&lang=en";
			
			// set prefs, add event listener and load request
			myLoader.addEventListener(Event.COMPLETE, onArtistInfoLoad);
			// load
			myLoader.load(new URLRequest(sim_url));
		}
		
		/**
		 * @param evt
		 *
		 * On recieve info search data from last.fm
		 **/
		private function onArtistInfoLoad(evt:Event):void{
			myLoader.removeEventListener(Event.COMPLETE, onArtistInfoLoad);
			
			// create result XML
			var data:XML = new XML(evt.target.data);
			var i:int;
			
			// save name
			_artist.name = data.artist.name;
			
			// save mbid
			if(_artist.mbID == null || _artist.mbID.length < 1)
				_artist.mbID = data.artist.mbid.text();
			trace(_artist.mbID);
			
			// save image url
			_artist.image = data.artist.image[2];
			
			// get tags
			_artist.tags = [];
			for(i = 0; i < _limit; i++){
				if(data.artist.tags.tag[i]){
					_artist.tags.push({name: data.artist.tags.tag.name.children()[i], count: 0.4});
				}
			}
			
			// get similar
			_artist.similar = [];
			var sart:Artist;
			for(i = 0; i < _limit; i++){
				if(data.artist.similar.artist[i]){
					sart = new Artist();
					sart.name = data.artist.similar.artist.name.children()[i];
					_artist.similar.push(sart);//tag[i].name.;
				}
			}
			
			// get wiki text
			var bio:XMLList = data.artist.bio.children();
			_artist.description_short = bio[1].text();
			_artist.description = bio[2].text();
			
			// cleanup
			data = null;
			bio = null;
			
			// dispatch complete event
			endLoad();
		}
		
		/**
		 *
		 * @param art - artist for search
		 * @param trc - track for search
		 *
		 * Searches for track info and album cover
		 */
		public function findSongInfo(artist:String, track:String):void{
			_song = new Song();
			_song.artist = new Artist();
			_song.artist.name = artist;
			_song.album = new Album();
			_song.name = track;
			// encode
			artist = CUtils.urlEncode(artist);
			track = CUtils.urlEncode(track);
			
			// Generate Last.FM url
			var sim_url:String = new String("http://ws.audioscrobbler.com/2.0/?method=track.getinfo&artist=" + artist);
			sim_url += "&track=" + track;
			sim_url += "&api_key="+api_key;
			
			// set prefs, add event listener and load request
			myLoader.addEventListener(Event.COMPLETE, onInfoLoad);
			// load
			myLoader.load(new URLRequest(sim_url));
		}
		
		/**
		 * @param evt
		 *
		 * On recieve info search data from last.fm
		 **/
		private function onInfoLoad(evt:Event):void{
			evt.target.removeEventListener(Event.COMPLETE, onInfoLoad);
			
			// create result XML
			var data:XML = new XML(evt.target.data);
			
			// save image url
			_song.album.image = data.track.album.image[2];
			
			// get tags
			_song.tags = [];
			for(var i:int = 0; i < _limit; i++){
				if(data.track.toptags.tag[i]){
					_song.tags[i] = data.track.toptags.tag[i].name;
				}
			}
			
			// get wiki text
			_song.description = data.track.wiki.summary;
			if (_song.description.length < 2){
				_song.description = 'Nothing found :(';
			}
			
			// dispatch complete event
			endLoad();
		}
		
		/**
		 *
		 * @param query
		 *
		 * Searches for matching tags
		 */
		public function findTags(query:String):void{
			// Generate Last.FM url
			var sim_url:String = new String("http://ws.audioscrobbler.com/2.0/?method=tag.search&tag=" + query);
			sim_url += "&api_key="+api_key+"&lang=en";
			
			// set prefs, add event listener and load request
			myLoader.addEventListener(Event.COMPLETE, onTagLoad);
			// load
			myLoader.load(new URLRequest(sim_url));
		}
		
		/**
		 * @param evt
		 *
		 * On recieve info search data from last.fm
		 **/
		private function onTagLoad(evt:Event):void{
			evt.target.removeEventListener(Event.COMPLETE, onTagLoad);
			
			// create result XML
			var data:XML = new XML(evt.target.data);
			var tagList:XMLList = data.results.tagmatches.tag;
			
			_results = [];
			
			// get tags
			var tag:XML;
			for each(tag in tagList){
				_results.push({name: tag.name.text(), count: int(tag.tagcount.text())});
			}
			
			// dispatch complete event
			endLoad();
		}
	}
}