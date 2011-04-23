package com.codezen.music.playr{
	
	 
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	
	
	public class PlaylistManager extends EventDispatcher{
		
		private var _xml:XML;
		private var _playlist:Array;
		private var _shufflelist:Array;
		private var _shuffle:Boolean = false;
		private var _currentNumber:Number = 0;
		private var _thisTrack:PlayrTrack;
		private var _playlistURL:String="";					//is this even ethical okay? I'm seriously suggesting the use of PHP here... Might not be a very political idea... Ohwell, politics are fucked, and PHP is open-source, so no sherrifs will be shot :)
																		//
		
		public function PlaylistManager(playlistURL:String = ""):void{
			_playlist = new Array();
			_shufflelist = new Array();
			if(playlistURL!=""){
				_playlistURL = playlistURL;
				loadPlaylist(_playlistURL);
			}
		}
		private function get playlist():Array{
			if(!_shuffle){
				return _playlist;
			}
			else{
				return _shufflelist;
			}
		}
		public function get length():int{
			return _playlist.length;
		}
		private function set playlist(list:Array):void{
			_playlist = new Array();
			var teller:Number=0;
			for (var i:uint = 0;i<list.length;i++){
				if(PlayrTrack(list[i]).file!=""){
					teller++;
					var song:PlayrTrack = new PlayrTrack();
					song.title = PlayrTrack(list[i]).title;
					song.titleName = PlayrTrack(list[i]).titleName;
					song.artist = PlayrTrack(list[i]).artist;
					song.album = PlayrTrack(list[i]).album;
					song.file = PlayrTrack(list[i]).file;
					song.totalSeconds = PlayrTrack(list[i]).totalSeconds;
					song.trackNumber = teller;
					//trace(song);
					_playlist.push(song);
				}
				else{
					dispatchEvent(new PlayrInternalEvent(PlayrInternalEvent.TRACK_NOT_ADDED_TO_PLAYLIST));
				}
			}
			//cleanUpTrackNumbers();
			createShuffleList();
			dispatchEvent(new PlayrInternalEvent(PlayrInternalEvent.PLAYLIST_LOADED));
			gotoFirstTrack();
		}
		public function moveTrackTo(trackNumber:Number,destination:Number):Boolean{
			var theTrack:PlayrTrack;
			if(trackNumber-1 <= _playlist.length && trackNumber != 0 && destination !=0){
				theTrack = PlayrTrack(_playlist[trackNumber-1]).copy();
				//trace('theTrack: ',theTrack);
				_playlist.splice(trackNumber-1,1);
				_playlist.splice(destination-1,0,theTrack);
				cleanUpTrackNumbers();
				return true;
			}
			else{
				return false;
			}
		}
		public function gotoNextTrack():void{
			_currentNumber++;
			if(_currentNumber == _playlist.length){
				_currentNumber = 0;
			}
			loadCurrentTrack();
		}
		public function removeTrack(trackNumber:Number):Boolean{
			if(getCurrentTrack().trackNumber == trackNumber){
				dispatchEvent(new PlayrInternalEvent(PlayrInternalEvent.CURRENT_TRACK_TO_BE_REMOVED));
			}
			for(var i:uint=0;i<_playlist.length;i++){
				if(PlayrTrack(_playlist[i]).trackNumber == trackNumber){
					_playlist.splice(i,1);
					cleanUpTrackNumbers();
					createShuffleList();
					return true;
				}
			}
			return false; 					//this should actually NEVER be the case... Should I fire a special event, so ppl know the should tell me about it? Some PlayrError.CONTACT_RONNY thing?
											// edit nov 6 2008: No. This can actually be the case, when somebody inserts a tracknummber which doesn't exist :)
		}
		public function get totalTracks():Number{
			return _playlist.length;
		}
		public function get currentTrackNumber():Number{
			return _currentNumber+1;
		}
		private function cleanUpTrackNumbers():void{
			for(var i:uint=0;i<_playlist.length;i++){
				PlayrTrack(_playlist[i]).trackNumber = i+1;
			}
		}
		public function gotoPreviousTrack():void{
			_currentNumber--;
			if(_currentNumber == -1){
				_currentNumber = _playlist.length-1;
			}
			loadCurrentTrack();
		}
		private function loadCurrentTrack():void{
			if(!_shuffle){
				_thisTrack = _playlist[_currentNumber];
			}
			else{
				_thisTrack = _shufflelist[_currentNumber];
			}
		}
		/**
		 * Adds a PlayrTrack object to the internal playlist. <br />
		 * @param track A PlayrTrack instance you want to add to the playlist.
		 */
		public function addTrack(track:PlayrTrack):Boolean{
			if(track.file!=''){
				if(_playlist==null){
					_playlist = new Array();
				}
				_playlist.push(track);
				cleanUpTrackNumbers();
				createShuffleList();
				dispatchEvent(new PlayrInternalEvent(PlayrInternalEvent.TRACK_ADDED_TO_PLAYLIST));
				return true;
			}
			else{
				return false;
			}
			
		}
		public function loadPlaylist(xmlPath:String):void{
			var urlloader:URLLoader = new URLLoader();
			urlloader.addEventListener(Event.COMPLETE, playlistLoaded);
			urlloader.addEventListener(IOErrorEvent.IO_ERROR,playListioErrorHandler);
			urlloader.load(new URLRequest(xmlPath+'?c='+Math.random()));
		}
		private function playListioErrorHandler(e:IOErrorEvent):void{
			dispatchEvent(new PlayrInternalEvent(PlayrInternalEvent.PLAYLIST_STREAM_ERROR));
		}
		public function gotoFirstTrack():void{
			if(!_shuffle){
				_thisTrack = _playlist[0];
			}
			else{
				_thisTrack = _shufflelist[0];
			}
		}
		public function getCurrentTrack():PlayrTrack{
			return _thisTrack;
		}
		public function get shuffle():Boolean{
			return _shuffle;
		}
		
		public function setShuffle(value:Boolean):Boolean{
			if(_shuffle != value){
				_shuffle = value;
				return true;
			}
			else{
				return false;
			}
		}
		private function playlistLoaded(e:Event):void{
			try{
				_xml = XML(e.target.data);
			}
			catch(e:TypeError){
				dispatchEvent(new PlayrInternalEvent(PlayrInternalEvent.PLAYLIST_INVALID_XML));
				return ;
			}
			_playlist = new Array();
			for (var i:uint = 0;i<_xml.track.length();i++){
				if(_xml.track[i].filename !=""){
					var song:PlayrTrack = new PlayrTrack();
					song.title = _xml.track[i].title;
					song.titleName = _xml.track[i].titleName;
					song.artist = _xml.track[i].artist;
					song.album = _xml.track[i].album;
					song.file = _xml.track[i].filename;
					song.totalSeconds = _xml.track[i].totalTime;
					song.trackNumber = i+1;
					_playlist.push(song);
				}
				else{
					dispatchEvent(new PlayrInternalEvent(PlayrInternalEvent.TRACK_NOT_ADDED_TO_PLAYLIST));
				}
			}
			//cleanUpTrackNumbers();
			createShuffleList();
			dispatchEvent(new PlayrInternalEvent(PlayrInternalEvent.PLAYLIST_LOADED));
		}
		private function createShuffleList():void{
			//trace('------------new shuffle--------------');
			_shufflelist = new Array();
			var temp:Array = new Array();
			for (var s:Number=0;s<_playlist.length;s++){
				temp.push(PlayrTrack(_playlist[s]).copy());
				//trace('ori: ',PlayrTrack(_playlist[s]));
			}
			//trace('--------------------------');
			var teller:Number =0;
			while(temp.length !=0){
				teller++;
				var next:Number = Math.floor(Math.random()*temp.length);
				var theTrack:PlayrTrack = PlayrTrack(temp[next]);
				theTrack.trackNumber = teller;
				//trace('shu: ',theTrack)
				_shufflelist.push(theTrack);
				temp.splice(next,1);
			}
			//trace('--------------------------');
		}
		public function gotoTrack(trackNumber:Number):void{
			if(!(trackNumber < 0) && !(trackNumber > _playlist.length)){
				_currentNumber = trackNumber-1;
				loadCurrentTrack();
				//trace('Jumped to: ',_thisTrack);
			}
			else{
				dispatchEvent(new PlayrInternalEvent(PlayrInternalEvent.PLAYLIST_TRACK_OUT_OF_BOUNDS));
			}
		}
		public function toArray():Array{
			return playlist;
		}
	}
}