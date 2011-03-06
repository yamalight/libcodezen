package com.codezen.lastfm
{
	import com.codezen.helper.Worker;
	import com.codezen.util.CUtils;
	
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	
	import mx.core.FlexGlobals;
	
	public final class LastfmInfo extends Worker
	{		
		// result data
		private var imgUrl:String;
		private var wikiText:String;
		private var tags:Array;
		private var sims:Array;
		private var name:String;
		private var bio:XMLList;

		/**
		 * 
		 * Constructor 
		 */
		public function LastfmInfo()
		{
		}
		
		/**
		 * 
		 * @param mbid - musicbrainz artist id for search
		 * 
		 * Searches for track info and album cover
		 */
		public function findArtistInfo(mbid:String):void{			
			// Generate Last.FM url
			var sim_url:String = new String("http://ws.audioscrobbler.com/2.0/?method=artist.getinfo&mbid=" + mbid);
			sim_url += "&api_key=0b18095c48d2bb8bf4acbab629bcc30e&lang=en";
			
			// from urlrequest and urlloader
			var urlInfoRequest:URLRequest = new URLRequest(sim_url);
			var myInfoLoader:URLLoader = new URLLoader();
			// set prefs, add event listener and load request
			myInfoLoader.dataFormat = URLLoaderDataFormat.TEXT;
			myInfoLoader.addEventListener(Event.COMPLETE, onArtistInfoLoad);
			myInfoLoader.addEventListener(IOErrorEvent.IO_ERROR, onError);
			// load
			myInfoLoader.load(urlInfoRequest);
		}
		
		/**
		 * @param evt
		 * 
		 * On recieve info search data from last.fm
		 **/
		private function onArtistInfoLoad(evt:Event):void{
			evt.target.removeEventListener(Event.COMPLETE, onArtistInfoLoad);
			
			// create result XML
			var data:XML = new XML(evt.target.data);
			var i:int;

			// save name
			name = data.artist.name;
			
			// save image url
			imgUrl = data.artist.image[2];
			
			// get tags
			tags = [];
			for(i = 0; i < 5; i++){
				if(data.artist.tags.tag[i]){
					tags[i] = data.artist.tags.tag.name.children()[i];//tag[i].name.;
				}
			}
			
			// get similar
			sims = [];
			for(i = 0; i < 5; i++){
				if(data.artist.similar.artist[i]){
					sims[i] = data.artist.similar.artist.name.children()[i];//tag[i].name.;
				}
			}
			
			// get wiki text
			bio = new XMLList();
			bio = data.artist.bio.children();
			if (bio.length() < 1){
				bio = null;
			}
			
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
			// encode
			artist = CUtils.urlEncode(artist);
			track = CUtils.urlEncode(track);
			
			// Generate Last.FM url
			var sim_url:String = new String("http://ws.audioscrobbler.com/2.0/?method=track.getinfo&artist=" + artist);
			sim_url += "&track=" + track;
			sim_url += "&api_key=0b18095c48d2bb8bf4acbab629bcc30e";
			
			// from urlrequest and urlloader
			var urlInfoRequest:URLRequest = new URLRequest(sim_url);
			var myInfoLoader:URLLoader = new URLLoader();
			// set prefs, add event listener and load request
       		myInfoLoader.dataFormat = URLLoaderDataFormat.TEXT;
   			myInfoLoader.addEventListener(Event.COMPLETE, onInfoLoad);
			myInfoLoader.addEventListener(IOErrorEvent.IO_ERROR, onError);
			// load
			myInfoLoader.load(urlInfoRequest);
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
			imgUrl = data.track.album.image[2];
			
			// get tags
			tags = [];
			for(var i:int = 0; i < 5; i++){
				if(data.track.toptags.tag[i]){
					tags[i] = data.track.toptags.tag[i].name;
				}
			}
			
			// get wiki text
			wikiText = data.track.wiki.summary;
			if (wikiText.length < 2){
				wikiText = 'Nothing found :(';
			}
			
			// dispatch complete event
			endLoad();
		}
		
		/**
		 * 
		 * @param e
		 * 
		 * On search error
		 */
		private function onError(e:ErrorEvent):void{
			dispatchError(e.toString(), "Error getting album cover", false);
		}
		
		/**
		 * Get results
		 **/
		public function get imgURL():String{
			return imgUrl;
		}
		
		public function get tagsList():Array{
			return tags;
		}
		
		public function get simsList():Array{
			return sims;
		}
		
		public function get wikiInfo():String{
			return wikiText;
		}
		
		public function get artistName():String{
			return name;
		}
		
		public function get artistBio():XMLList{
			return bio;
		}
	}
}