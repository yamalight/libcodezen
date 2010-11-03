package com.codezen.music
{
	import com.codezen.helper.Worker;
	import com.codezen.music.search.ISearch;
	import com.codezen.music.search.VkApiMusic;
	import com.codezen.music.search.VkLoginMusic;
	
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.net.registerClassAlias;
	import flash.utils.Dictionary;
	import flash.utils.getDefinitionByName;
	
	import mx.collections.ArrayCollection;
	import mx.utils.ObjectUtil;
	
	public class MusicFinder extends Worker
	{
		// set of search interfaces
		private var searchInterfaces:Array;
		
		// login-pass pairs 
		private var credentials:Array;
		
		// counter
		private var counter:int;
		// search query
		private var query:String;
		// result url
		private var resultURL:String;
		
		// classes
		private var VkApi:VkApiMusic;
		private var VkLog:VkLoginMusic;
		
		/**
		 * Inits searchers list 
		 */
		public function MusicFinder()
		{
			// create search classes
			VkApi = new VkApiMusic();
			VkLog = new VkLoginMusic();
			
			// init search interfaces
			searchInterfaces = new Array();
			searchInterfaces.push( VkApi );
			searchInterfaces.push( VkLog );	
			
			// init creds array
			credentials = new Array();
		}
		
		/**
		 * Get founded url 
		 * @return url string
		 * 
		 */
		public function get result():String{
			return resultURL;
		}
		
		/**
		 * Initializes all search interfaces 
		 * 
		 */
		public function initSearchers():void{
			var searcher:ISearch;
			for each(searcher in searchInterfaces){
				if( searcher.requireAuth ){
					if( typeof credentials[searcher.classAlias] != 'undefined' ){
						searcher.initAuth(credentials[searcher.classAlias].login, credentials[searcher.classAlias].pass);
					}
				}
			}
		}
		
		/**
		 * Sets credentials for given search class 
		 * @param login
		 * @param pass
		 * @param className
		 * 
		 */
		public function addCredentials(login:String, pass:String, className:String):void{
			credentials[className] = {login: login, pass: pass};
		}
		
		/**
		 * Searches for song URL 
		 * @param query string
		 * 
		 */
		public function findSongURL(squery:String):void{
			counter = 0;
			query = squery;
			var searcher:ISearch = searchInterfaces[counter] as ISearch;
			searcher.addEventListener(Event.COMPLETE, onSearchComplete);
			searcher.addEventListener(ErrorEvent.ERROR, onSearchError);
			searcher.findData(query);
		}
		
		/**
		 * Executes search with next searcher 
		 */
		private function findNext():void{
			counter++;
			if( counter >= searchInterfaces.length ) return;
			var searcher:ISearch = searchInterfaces[counter] as ISearch;
			//searcher.registerResultEvent(onSearchComplete);
			searcher.addEventListener(Event.COMPLETE, onSearchComplete);
			searcher.findData(query);
		}
		
		/**
		 * On search results 
		 * @param e
		 * 
		 */
		private function onSearchComplete(e:Event):void{
			var searcher:ISearch = e.target as ISearch;
			searcher.removeEventListener(Event.COMPLETE, onSearchComplete);
			if(searcher.resultString == null){
				resultURL = null;
				findNext();
			}else{
				resultURL = searcher.resultString;
				endLoad();
			}
		}
		
		private function onSearchError(e:ErrorEvent):void{
			trace('error');
			resultURL = null;
			findNext();
		}
	}
}