package com.codezen.mse {
    import com.codezen.helper.Worker;
    import com.codezen.mse.models.Album;
    import com.codezen.mse.models.Artist;
    import com.codezen.mse.models.Song;
    import com.codezen.mse.playr.PlayrTrack;
    import com.codezen.mse.plugins.PluginManager;
    import com.codezen.mse.services.BBCRadio;
    import com.codezen.mse.services.LastFM;
    import com.codezen.mse.services.MusicBrainz;
    import com.codezen.mse.services.Stereomood;
    import com.codezen.mse.services.YouTube;
    import com.codezen.util.CUtils;
    
    import flash.events.ErrorEvent;
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.filesystem.File;
    
    import flashx.textLayout.utils.CharacterUtil;
    
    import mx.collections.ArrayCollection;
    import mx.utils.ObjectUtil;

    public class MusicSearchEngine extends Worker {
		// plugin manager
		private var pluginManager:PluginManager;
		
		// stereomood
		private var moodSearch:Stereomood;
		
		// bbc
		private var bbcSearch:BBCRadio;
		
        // lastfm
        private var lastfmSearch:LastFM;

        // musicbrainz searchers
        private var artistSearch:MusicBrainz;
        private var albumSearch:MusicBrainz;
        private var songSearch:MusicBrainz;
		
		// youtube
		private var youtubeSearch:YouTube;
		
		// results
		private var _artists:Array;
		private var _albums:Array;
		private var _songs:Array;
		private var _tags:Array;
		private var _moods:Array;
		private var _mp3s:Array;
		private var _videos:Array;
		
		// album info
		private var _album:Album;
		
		// artist info
		private var _artistInfo:Artist;
		
		// song info
		private var _songInfo:Song;
		
		// counter 
		private var _searchCounter:int;
		private var _globalSearch:Boolean;
		
		// limit
		private var _limit:int = 10;
		
		private var _song2find:Song;

        public function MusicSearchEngine() {
			_globalSearch = false;
			
			artistSearch = new MusicBrainz(_limit);
			albumSearch = new MusicBrainz(_limit);
			lastfmSearch = new LastFM(_limit);
			songSearch = new MusicBrainz(_limit);
			//moodSearch = new Stereomood();
			bbcSearch = new BBCRadio();
			youtubeSearch = new YouTube();
			
			artistSearch.addEventListener(ErrorEvent.ERROR, onError);
			albumSearch.addEventListener(ErrorEvent.ERROR, onError);
			lastfmSearch.addEventListener(ErrorEvent.ERROR, onError);
			songSearch.addEventListener(ErrorEvent.ERROR, onError);
			bbcSearch.addEventListener(ErrorEvent.ERROR, onError);
			youtubeSearch.addEventListener(ErrorEvent.ERROR, onError);
			
			initPluginManager();
        }

		public function get videos():Array
		{
			return _videos;
		}

		public function get songInfo():Song
		{
			return _songInfo;
		}

		public function get mp3s():Array
		{
			return _mp3s;
		}

		public function get artistInfo():Artist
		{
			return _artistInfo;
		}

		public function get moods():Array
		{
			return _moods;
		}

		public function get album():Album
		{
			return _album;
		}

		public function get tags():Array
		{
			return _tags;
		}

		public function get songs():Array
		{
			return _songs;
		}

		public function get albums():Array
		{
			return _albums;
		}

		public function get artists():Array
		{
			return _artists;
		}

		
		/**
		 * Searches for data on query 
		 * @param query (String) - query to search for
		 * 
		 */
        public function query(query:String):void{
			trace('searching for '+query);
            // test if it's complex query
            // --
			
			_globalSearch = true;
			
			// cleanup old stuff
			_artists = [];
			_albums = [];
			_songs = [];
			_tags = [];
			_moods = [];
			
			// init counter 
			_searchCounter = 4;

            // find matching artists
            artistSearch.addEventListener(Event.COMPLETE, onMBArtist);
            artistSearch.findArtist(query);

            // find matching albums
            albumSearch.addEventListener(Event.COMPLETE, onMBAlbums);
            albumSearch.findAlbums(query);

            // find matching songs
            songSearch.addEventListener(Event.COMPLETE, onMBSong);
            songSearch.findSongs(query);

            // find matching tags
            lastfmSearch.addEventListener(Event.COMPLETE, onLFMTag);
            lastfmSearch.findTags(query);
			
			// find moods
			//moodSearch.addEventListener(Event.COMPLETE, onMood);
			//moodSearch.findMood(query);
        }
		
		// --------------------------------- GENERIC ERRORS -------------------------------
		
		private function onError(e:ErrorEvent):void{
			if(_globalSearch){
				_searchCounter--;
				if(_searchCounter == 0){
					_globalSearch = false;
					endLoad();
				}
			}else{
				dispatchError(e.text);
			}
		}
		
		/**
		 * LastFM Tags results 
		 * @param e
		 * 
		 */
        private function onLFMTag(e:Event):void{
			lastfmSearch.removeEventListener(Event.COMPLETE, onLFMTag);
			
			_tags = lastfmSearch.resultArray;
			
			var tag:Object;
			for each(tag in _tags){
				tag.count = 0.4;
			}
			
			_tags.sortOn("name");
			
			_searchCounter--;
			if(_searchCounter == 0){
				_globalSearch = false;
				endLoad();
			}
        }

		/**
		 * Musicbrainz artists results 
		 * @param e
		 * 
		 */
        private function onMBArtist(e:Event):void{
			artistSearch.removeEventListener(Event.COMPLETE, onMBArtist);
			
			_artists = artistSearch.artistsList;
			
			_searchCounter--;
			if(_searchCounter == 0){
				_globalSearch = false;
				endLoad();
			}
        }

		/**
		 * Musicbrainz song results 
		 * @param e
		 * 
		 */
        private function onMBSong(e:Event):void{
			songSearch.removeEventListener(Event.COMPLETE, onMBSong);
			
			_songs = songSearch.tracksList;
			
			_searchCounter--;
			if(_searchCounter == 0){
				_globalSearch = false;
				endLoad();
			}
        }

		/**
		 * Musicbrainz album results 
		 * @param e
		 * 
		 */
        private function onMBAlbums(e:Event):void{
			albumSearch.removeEventListener(Event.COMPLETE, onMBAlbums);
			
			_albums = albumSearch.albumsList;
			
			_searchCounter--;
			if(_searchCounter == 0){
				_globalSearch = false;
				endLoad();
			}
        }
		
		/**
		 * Stereomood result 
		 * @param e
		 * 
		 */
		private function onMood(e:Event):void{
			moodSearch.removeEventListener(Event.COMPLETE, onMood);
			
			_moods = moodSearch.moodsList;
			
			_searchCounter--;
			if(_searchCounter == 0){
				_globalSearch = false;
				endLoad();
			}
		}
		
		// --------------------------------- ARTIST INFO -------------------------------
		public function getArtistInfo(artist:Artist):void{
			lastfmSearch.addEventListener(Event.COMPLETE, onArtistInfo);
			lastfmSearch.getArtistInfo(artist);
		}
		
		private function onArtistInfo(e:Event):void{
			lastfmSearch.removeEventListener(Event.COMPLETE, onArtistInfo);
			
			_artistInfo = lastfmSearch.artist;
			
			endLoad();
		}
		
		// --------------------------TOP TAGS ----------------------------------
		public function getTopTags():void{
			lastfmSearch.addEventListener(Event.COMPLETE, onTopTags);
			lastfmSearch.getTopTags();
		}
		private function onTopTags(e:Event):void{
			lastfmSearch.removeEventListener(Event.COMPLETE, onTopTags);
			
			_tags = lastfmSearch.resultArray;
			
			var tag:Object;
			var maxVal:int = 0;
			for each(tag in _tags){
				if( tag.count > maxVal ) maxVal = tag.count;
			}
			for each(tag in _tags){
				tag.count = tag.count / maxVal;
				if( tag.count < 0.25 ) tag.count = 0.25;
			}
			
			_tags.sortOn("name");
			
			trace(ObjectUtil.toString(_tags));
			
			endLoad();
		}
		
		// --------------------------FIND TAGS ----------------------------------
		public function findTags(q:String):void{
			lastfmSearch.addEventListener(Event.COMPLETE, onTagsSearch);
			lastfmSearch.findTags(q);
		}
		private function onTagsSearch(e:Event):void{
			lastfmSearch.removeEventListener(Event.COMPLETE, onTagsSearch);
			
			_tags = lastfmSearch.resultArray;
			
			var tag:Object;
			for each(tag in _tags){
				tag.count = 0.5;
			}
			_tags.sortOn("name");
			
			endLoad();
		}
		
		// --------------------------FIND SONGS BY TAG ----------------------------------
		public function findSongsByTag(t:String):void{
			lastfmSearch.addEventListener(Event.COMPLETE, onSongTagSearch);
			lastfmSearch.getTopTracksByTag(t);
		}
		private function onSongTagSearch(e:Event):void{
			lastfmSearch.removeEventListener(Event.COMPLETE, onSongTagSearch);
			
			_songs = lastfmSearch.resultArray;
			
			endLoad();
		}
		
		// --------------------------ARTIST ALBUMS ----------------------------------
		public function getArtistAlbums(a:Artist):void{
			albumSearch.addEventListener(Event.COMPLETE, onAlbumsFound);
			albumSearch.getAlbums(a);
		}
		private function onAlbumsFound(e:Event):void{
			albumSearch.removeEventListener(Event.COMPLETE, onAlbumsFound);
			
			_albums = albumSearch.albumsList;
			
			endLoad();
		}
		// ------------------------ FIND ARTIST ----------------------------------
		public function findArtist(query:String):void{
			artistSearch.addEventListener(Event.COMPLETE, onArtistSearch);
			artistSearch.findArtist(query);
		}
		
		private function onArtistSearch(e:Event):void{
			artistSearch.removeEventListener(Event.COMPLETE, onArtistSearch);
			
			_artists = artistSearch.artistsList;
			
			endLoad();
		}
		
		// ------------------------ FIND ARTIST ----------------------------------
		public function getArtistByTag(tag:String):void{
			lastfmSearch.addEventListener(Event.COMPLETE, onTagArtist);
			lastfmSearch.getTopArtistsByTag(tag);
		}
		
		private function onTagArtist(e:Event):void{
			lastfmSearch.removeEventListener(Event.COMPLETE, onTagArtist);
			
			_artists = lastfmSearch.resultArray;
			
			endLoad();
		}
		
		// ------------------------ FIND ALBUMS ----------------------------------
		public function findAlbum(query:String):void{
			albumSearch.addEventListener(Event.COMPLETE, onAlbumSearch);
			albumSearch.findAlbums(query);
		}
		
		private function onAlbumSearch(e:Event):void{
			albumSearch.removeEventListener(Event.COMPLETE, onAlbumSearch);
			
			_albums = albumSearch.albumsList;
			
			endLoad();
		}
		
		// ------------------------------------------------------------------
		public function getAlbumTracks(album:Album):void{
			_album = album;
			
			if(album.mbID == null || album.mbID.length < 2){
				albumSearch.addEventListener(Event.COMPLETE, onAlbumID);
				albumSearch.findAlbumByName(album.name, album.artist.name, album.artist.mbID);
			}else{
				getCurrentAlbumTracks();
			}
		}
		
		private function onAlbumID(e:Event):void{
			albumSearch.removeEventListener(Event.COMPLETE, onAlbumID);
						
			var a:Album;
			var anm:String, arnm:String;
			var replace:RegExp = new RegExp(/['’"&!?.: ]/g);
			var origanm:String = _album.name.toLowerCase().replace(replace, "");
			var origarnm:String = _album.artist.name.toLowerCase().replace(replace, "");
			for each(a in albumSearch.albumsList){
				//trace(ObjectUtil.toString(a));
				anm = a.name.toLowerCase().replace(replace, ""); 
				arnm = a.artist.name.toLowerCase().replace(replace, "");
				//if(anm == origanm && arnm == origarnm){
				if( CUtils.compareStrings(anm, origanm) > 90 && CUtils.compareStrings(arnm, origarnm) > 90 ){
					_album.mbID = a.mbID;
					_album.date = a.date;
					break;
				}
			}
			
			if(_album.mbID == null){
				dispatchError("Album not found!");
			}else{
				getCurrentAlbumTracks();
			}
		}
		
		private function getCurrentAlbumTracks():void{
			albumSearch.addEventListener(Event.COMPLETE, onTracklist);
			albumSearch.getTracks(_album);
		}
		
		private function onTracklist(e:Event):void{
			albumSearch.removeEventListener(Event.COMPLETE, onTracklist);
			
			_album.songs = albumSearch.songsList;
			
			endLoad();
		}
		
		// ---------------------------- GET TOP TRACKS -----------------------------------
		public function getTopTracks():void{
			lastfmSearch.addEventListener(Event.COMPLETE, onTopSongs);
			lastfmSearch.getTopTracks();
		}
		
		private function onTopSongs(e:Event):void{
			lastfmSearch.removeEventListener(Event.COMPLETE, onTopSongs);
			
			_songs = lastfmSearch.resultArray;
			
			endLoad();
		}
		
		// ---------------------------- GET TRACK INFO -----------------------------------
		public function getTrackInfo(artist:String, track:String):void{
			lastfmSearch.addEventListener(Event.COMPLETE, onTrackInfo);
			lastfmSearch.addEventListener(ErrorEvent.ERROR, onTrackInfoError);
			lastfmSearch.findSongInfo(artist, track);
		}
		
		private function onTrackInfo(e:Event):void{
			lastfmSearch.removeEventListener(Event.COMPLETE, onTrackInfo);
			
			_songInfo = lastfmSearch.song;
			
			endLoad();
		}
		
		private function onTrackInfoError(e:Event):void{
			trace('track info error');
			_songInfo = null;
			dispatchError("Song info search error");
		}
		
		// -------------------------- GET TOP ARTISTS ------------------------------------
		public function getTopArtists():void{
			lastfmSearch.addEventListener(Event.COMPLETE, onTopArtists);
			lastfmSearch.getTopArtists();
		}
		
		private function onTopArtists(e:Event):void{
			lastfmSearch.removeEventListener(Event.COMPLETE, onTopArtists);
			
			_artists = lastfmSearch.resultArray;
			
			endLoad();
		}
		
		// -------------------------- GET TOP ALBUMS ---------------------------------------
		public function getTopAlbums():void{
			bbcSearch.addEventListener(Event.COMPLETE, onChart);
			bbcSearch.getCharts();
		}
		
		private function onChart(e:Event):void{
			bbcSearch.removeEventListener(Event.COMPLETE, onChart);
			
			_albums = bbcSearch.albumsChart;
			
			endLoad();
		}
		
		// -------------------------- GET TOP VIDEOS ---------------------------------------
		public function getTopVideos():void{
			youtubeSearch.addEventListener(Event.COMPLETE, onVideos);
			youtubeSearch.getTopVideos();
		}
		
		// find video
		public function findVideo(q:String):void{
			youtubeSearch.addEventListener(Event.COMPLETE, onVideos);
			youtubeSearch.findVideo(q);
		}
		
		private function onVideos(e:Event):void{
			youtubeSearch.removeEventListener(Event.COMPLETE, onVideos);
			
			_videos = youtubeSearch.videos;
			
			endLoad();
		}
		
		// ---------------------- PLUGINS STUFF --------------------------------
		private function initPluginManager():void{
			pluginManager = new PluginManager( [File.applicationDirectory.resolvePath("plugins/").nativePath, File.applicationStorageDirectory.resolvePath("plugins/").nativePath] );
			pluginManager.addEventListener(Event.INIT, onPmInit);
		}
		
		private function onPmInit(e:Event):void{
			this.dispatchEvent(new Event(Event.INIT));
		}
		
		public function getActivePlugins():Array{
			return pluginManager.listPlugins();
		}
		
		public function findMP3(song:Song):void{
			_song2find = song;
			
			pluginManager.addEventListener(Event.COMPLETE, onSong);
			pluginManager.findURLs(song);
		}
		
		public function findMP3byText(query:String):void{
			_song2find = null;
			
			pluginManager.addEventListener(Event.COMPLETE, onSong);
			pluginManager.findURLsByText(query);
		}
		
		private function onSong(e:Event):void{
			pluginManager.removeEventListener(Event.COMPLETE, onSong);
			
			_mp3s = [];
			var track:PlayrTrack;
			for each( track in pluginManager.results ){
				_mp3s.push(track);
			}
			
			trace( ObjectUtil.toString(_mp3s) );
			
			endLoad();
		}
    }
}
