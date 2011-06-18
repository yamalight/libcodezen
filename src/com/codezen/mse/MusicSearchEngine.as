package com.codezen.mse {
    import com.codezen.helper.Worker;
    import com.codezen.mse.models.Album;
    import com.codezen.mse.models.Artist;
    import com.codezen.mse.models.Song;
    import com.codezen.mse.plugins.PluginManager;
    import com.codezen.mse.services.LastFM;
    import com.codezen.mse.services.MusicBrainz;
    import com.codezen.mse.services.Stereomood;
    import com.codezen.mse.playr.PlayrTrack;
    
    import flash.events.Event;
    import flash.filesystem.File;
    
    import mx.collections.ArrayCollection;
    import mx.utils.ObjectUtil;

    public class MusicSearchEngine extends Worker {
		// plugin manager
		private var pluginManager:PluginManager;
		
		// stereomood
		private var moodSearch:Stereomood;
		
        // lastfm
        private var lastfmSearch:LastFM;

        // musicbrainz searchers
        private var artistSearch:MusicBrainz;
        private var albumSearch:MusicBrainz;
        private var songSearch:MusicBrainz;
		
		// results
		private var _artists:Array;
		private var _albums:Array;
		private var _songs:Array;
		private var _tags:Array;
		private var _moods:Array;
		private var _mp3s:Array;
		
		// album info
		private var _album:Album;
		
		// artist info
		private var _artistInfo:Artist;
		
		// counter 
		private var _searchCounter:int;
		
		// limit
		private var _limit:int = 10;

        public function MusicSearchEngine() {
			artistSearch = new MusicBrainz(_limit);
			albumSearch = new MusicBrainz(_limit);
			lastfmSearch = new LastFM(_limit);
			songSearch = new MusicBrainz(_limit);
			//moodSearch = new Stereomood();
			
			initPluginManager();
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

		/**
		 * LastFM Tags results 
		 * @param e
		 * 
		 */
        private function onLFMTag(e:Event):void{
			lastfmSearch.removeEventListener(Event.COMPLETE, onLFMTag);
			
			_tags = lastfmSearch.resultArray;
			
			_searchCounter--;
			if(_searchCounter == 0) endLoad();
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
			if(_searchCounter == 0) endLoad();
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
			if(_searchCounter == 0) endLoad();
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
			if(_searchCounter == 0) endLoad();
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
			if(_searchCounter == 0) endLoad();
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
		
		// ------------------------------------------------------------------
		public function getAlbumTracks(album:Album):void{
			_album = album;
			
			albumSearch.addEventListener(Event.COMPLETE, onTracklist);
			albumSearch.getTracks(album);
		}
		
		private function onTracklist(e:Event):void{
			albumSearch.removeEventListener(Event.COMPLETE, onTracklist);
			
			_album.songs = albumSearch.songsList;
			endLoad();
		}
		
		// ---------------------- PLUGINS STUFF --------------------------------
		private function initPluginManager():void{
			pluginManager = new PluginManager( File.applicationDirectory.resolvePath("plugins/").nativePath );
		}
		
		public function findMP3(song:Song):void{
			pluginManager.addEventListener(Event.COMPLETE, onSong);
			pluginManager.findURLs(song.artist.name + ' ' + song.name, song.duration);
		}
		
		private function onSong(e:Event):void{
			pluginManager.removeEventListener(Event.COMPLETE, onSong);
			
			trace( ObjectUtil.toString(pluginManager.results) )
			
			_mp3s = [];
			var track:PlayrTrack;
			for each( track in pluginManager.results ){
				_mp3s.push(track);
			}
			
			endLoad();
		}
    }
}
