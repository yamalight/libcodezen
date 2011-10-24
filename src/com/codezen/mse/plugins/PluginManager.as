package com.codezen.mse.plugins
{
	import com.codezen.helper.Worker;
	import com.codezen.mse.models.Song;
	import com.codezen.mse.playr.PlayrTrack;
	import com.codezen.mse.search.ISearchProvider;
	import com.codezen.util.CUtils;
	
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.FileListEvent;
	import flash.events.IOErrorEvent;
	import flash.filesystem.File;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	
	import mx.controls.Alert;
	import mx.utils.ObjectUtil;
	import mx.utils.object_proxy;
	
	public final class PluginManager extends Worker
	{
		// plugins array
		private var _plugins:Array;
		
		// loaders
		private var urlReq:URLRequest;			
		private var urlLoad:URLLoader;
		private var loader:Loader;
		
		// load queue
		private var _loadQueue:Array;
		
		// plugins dir
		private var _dirs:Array;
		// file class
		private var _file:File;
		
		// context
		private var context:LoaderContext;
		
		// counter
		private var dircounter:int;
		private var counter:int;
		// searched nums array
		private var usedPlugins:Array;
		// search query
		private var query:String;
		// search song
		private var song:Song;
		// result url
		private var _results:Vector.<PlayrTrack>;
		
		public function PluginManager(dirs:Array)
		{
			// init results
			_results = new Vector.<PlayrTrack>();
			
			// save dir
			_dirs = dirs.concat();
			
			// init plugins array
			_plugins = [];			
			
			// load plugins
			dircounter = _dirs.length;
			loadPlugins();
		}
		
		// load all plugins from set dir

		public function get results():Vector.<PlayrTrack>
		{
			return _results;
		}

		private function loadPlugins():void{
			dircounter--;
			if(dircounter < 0){
				dispatchEvent(new Event(Event.INIT));
				return;
			}
			_file = new File(_dirs[dircounter]);
			if(!_file.exists){
				loadPlugins();
				return;
			}
			_file.addEventListener(FileListEvent.DIRECTORY_LISTING, onListing);
			//_file.addEventListener(IOErrorEvent.IO_ERROR, onFolderError);
			_file.getDirectoryListingAsync();
		}
		
		// parse listing of files
		private function onListing(e:FileListEvent):void{
			var contents:Array = e.files;
			
			_loadQueue = [];
			
			var cFile:File;
			for (var i:int = 0; i < contents.length; i++) {
				cFile = contents[i] as File;
				// check extension
				if(cFile.extension == "swf") _loadQueue.push(cFile.url);
				//loadPluginFromPath(cFile.url);
			}
			
			counter = _loadQueue.length;
			loadPluginsFromPath();
		}
		
		// load plugin from path
		private function loadPluginsFromPath():void{
			var path:String = _loadQueue[ _loadQueue.length - counter ];
			urlReq = new URLRequest(path);			
			urlLoad = new URLLoader();
			urlLoad.dataFormat = URLLoaderDataFormat.BINARY;
			urlLoad.addEventListener(Event.COMPLETE, onPluginData);
			urlLoad.load(urlReq);
		}
		
		private function onPluginData(e:Event):void{
			urlLoad.removeEventListener(Event.COMPLETE, onPluginData);
			
			// create context
			context = new LoaderContext(false, ApplicationDomain.currentDomain );
			context.allowCodeImport = true;
			context.applicationDomain = new ApplicationDomain(ApplicationDomain.currentDomain);
			// create loader
			loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onPluginLoaded);
			loader.loadBytes(urlLoad.data, context);
		}
		
		private function onPluginLoaded(e:Event):void{
			loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onPluginLoaded);
			
			var className:Class = loader.contentLoaderInfo.applicationDomain.getDefinition("Searcher") as Class;
			var classInstance:ISearchProvider = new className();
			_plugins.push(classInstance);
			
			checkInit();
		}
		
		private function checkInit():void{
			counter--;
			if(counter <= 0){
				if(dircounter <= 0){
					trace( 'done: '+ObjectUtil.toString(_plugins) );
				
					dispatchEvent(new Event(Event.INIT));
				}else{
					loadPlugins();
				}
			}else{
				loadPluginsFromPath();
			}
		}
		
		/*private function onFolderError(e:Event):void{
			if(dircounter <= 0){
				trace( 'done: '+ObjectUtil.toString(_plugins) );
				
				dispatchEvent(new Event(Event.INIT));
			}else{
				loadPlugins();
			}
		}*/
		
		// ---------------- SIMPLE TEXT SEARCH ---------------------------
		public function findURLsByText(query:String):void{			
			counter = 0;
			this.query = CUtils.cleanMusicQuery(query);
			trace('starting search for: '+this.query);
			_results = new Vector.<PlayrTrack>();
			var searcher:ISearchProvider = _plugins[counter] as ISearchProvider;
			searcher.addEventListener(Event.COMPLETE, onSearchComplete);
			searcher.addEventListener(ErrorEvent.ERROR, onSearchError);
			searcher.search(this.query);
		}
		
		/**
		 * Executes search with next searcher 
		 */
		private function findNext():void{
			counter++;
			if( counter >= _plugins.length ){ 
				trace('done');
				endLoad();
				return;
			}
			var searcher:ISearchProvider = _plugins[counter] as ISearchProvider;
			searcher.addEventListener(Event.COMPLETE, onSearchComplete);
			searcher.addEventListener(ErrorEvent.ERROR, onSearchError);
			searcher.search(query);
		}
		
		/**
		 * On search results 
		 * @param e
		 * 
		 */
		private function onSearchComplete(e:Event):void{
			trace('found data!');
			
			var searcher:ISearchProvider = e.target as ISearchProvider;
			searcher.removeEventListener(Event.COMPLETE, onSearchComplete);
			searcher.removeEventListener(ErrorEvent.ERROR, onSongSearchError);
			
			if(searcher.result == null || searcher.result.length < 1){
				findNext();
			}else{
				_results = searcher.result.concat(_results);
				findNext();
			}
		}
		
		private function onSearchError(e:ErrorEvent):void{
			var searcher:ISearchProvider = e.target as ISearchProvider;
			searcher.removeEventListener(Event.COMPLETE, onSearchComplete);
			searcher.removeEventListener(ErrorEvent.ERROR, onSongSearchError);
			
			trace('error');
			findNext();
		}
		
		// ---------------- SONG SEACH ---------------------------
		public function findURLs(song:Song):void{
			this.song = song;
			trace('starting search for song: '+this.song.name+" "+this.song.artist.name);
			
			usedPlugins = [];
			_results = new Vector.<PlayrTrack>();
			
			var num:int = Math.floor(_plugins.length * Math.random());
			usedPlugins.push(num);
			
			query = CUtils.cleanMusicQuery(song.artist.name+" "+song.name);
			trace('query: '+query);
			
			var searcher:ISearchProvider = _plugins[num] as ISearchProvider;
			searcher.addEventListener(Event.COMPLETE, onSongSearchComplete);
			searcher.addEventListener(ErrorEvent.ERROR, onSongSearchError);
			searcher.search(query, song.duration);
		}
		
		/**
		 * Executes search with next searcher 
		 */
		private function findNextSong():void{
			if( usedPlugins.length >= _plugins.length ){ 
				trace('done');
				endLoad();
				return;
			}
			
			// get new random plugin
			var num:int; 
			do{
				num = Math.floor(_plugins.length * Math.random());
			}while(usedPlugins.indexOf(num) != -1);
			usedPlugins.push(num);
			
			var searcher:ISearchProvider = _plugins[num] as ISearchProvider;
			searcher.addEventListener(Event.COMPLETE, onSongSearchComplete);
			searcher.addEventListener(ErrorEvent.ERROR, onSongSearchError);
			searcher.search(query, song.duration);
		}
		
		/**
		 * On search results 
		 * @param e
		 * 
		 */
		private function onSongSearchComplete(e:Event):void{
			trace('found song data!');
			
			// clear listeners
			var searcher:ISearchProvider = e.target as ISearchProvider;
			searcher.removeEventListener(Event.COMPLETE, onSongSearchComplete);
			searcher.removeEventListener(ErrorEvent.ERROR, onSongSearchError);
			
			// if there's no result, just go next
			if(searcher.result == null || searcher.result.length < 1){
				findNextSong();
			}else{ // if something was found, try to filter
				var track:PlayrTrack;
				for each( track in searcher.result ){
					if( track.artist != null && track.title != null ){
						trace(track.artist, 
							track.title, 
							track.totalSeconds, 
							(song.duration/1000), 
							Math.abs(track.totalSeconds - (song.duration/1000)),
							CUtils.compareStrings(
								CUtils.convertHTMLEntities(track.title.toLowerCase()), 
								song.name.toLowerCase()
							),
							CUtils.compareStrings(
								CUtils.convertHTMLEntities(track.artist.toLowerCase()), 
								song.artist.name.toLowerCase()
							)
						);
					}
					if( track.artist != null && track.title != null &&
						CUtils.compareStrings(
							CUtils.convertHTMLEntities(track.title.toLowerCase()), 
							song.name.toLowerCase()
						) > 80 &&
						CUtils.compareStrings(
							CUtils.convertHTMLEntities(track.artist.toLowerCase()), 
							song.artist.name.toLowerCase()
						) > 80 && 
						( song.duration < 10 || Math.abs(track.totalSeconds - (song.duration/1000)) <= 10 ) ){
						_results.push(track);
					}
				}
				
				if(_results.length > 0){
					endLoad();
				}else{
					findNextSong();
				}
			}
		}
		
		private function onSongSearchError(e:ErrorEvent):void{
			var searcher:ISearchProvider = e.target as ISearchProvider;
			searcher.removeEventListener(Event.COMPLETE, onSongSearchComplete);
			searcher.removeEventListener(ErrorEvent.ERROR, onSongSearchError);
			
			trace('error');
			findNextSong();
		}
		
		// ---------------------------------------------
		public function listPlugins():Array{
			var searcher:ISearchProvider;
			var i:int;
			var res:Array = [];
			for(i = 0; i < _plugins.length; i++){
				searcher = _plugins[i] as ISearchProvider;
				res.push({index: i+1, name: searcher.PLUGIN_NAME, author: searcher.AUTHOR_NAME});
			}
			
			return res;
		}
	}
}
