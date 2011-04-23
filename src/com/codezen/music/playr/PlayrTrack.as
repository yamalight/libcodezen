package com.codezen.music.playr{
	import flash.net.URLRequest;

	/**
	 * The PlayrTrack instance is a summary of basic information which reflect ID3 information. However Playr 2.0 doesn't use the ID3 at all. The primary way of getting that data is due the use of the XML playlist. <br/>
	 * The PlayrTrack class is primary used for playlist manipulation.
	 */
	public class PlayrTrack{
		public var titleName:String = "";
		public var title:String = "";
		public var artist:String = "";
		public var album:String = "";
		public var totalTime:String = "0:00";
		public var file:String="";
		public var request:URLRequest = null;
		public var trackNumber:Number=0;
		private var _totalSeconds:Number = 0;
		
		/**
		 * Constuctor: Builds a PlayrTrack instance.
		 */		 
		public function PlayrTrack(titleName:String=null,title:String=null,artist:String=null,album:String = null,file:String = null,trackNumber:Number = 0,totalSeconds:Number = 0):void{
			this.titleName = titleName;
			this.title = title;
			this.artist = artist;
			this.album = album;
			this.totalSeconds = totalSeconds;
			this.file = file;
			this.trackNumber = trackNumber;
			this.totalTime = ":"+totalSeconds;
		}
		
		/**
		 * Gets or sets the total seconds of the PlayrTrack.
		 */
		public function set totalSeconds(seconds:Number):void{
			_totalSeconds=seconds;
			var min:Number = (_totalSeconds - (_totalSeconds%60))/60;
			var sec:Number = _totalSeconds%60;
			this.totalTime = min + ':';
			if(sec<10){
				this.totalTime += "0";
			}
			this.totalTime += sec;
		}
		public function get totalSeconds():Number{
			return _totalSeconds;	
		}
		/**
		 * Returns a string version of the track: {trackNumber}. {title} - {artist}
		 */
		public function toString():String{
			return this.trackNumber + ". " + this.title + " - " + this.artist;
		}
		/**
		 * Returns an indipendent copy of the given PlayrTrack instance (Primarly used for creating the shuffled playlist).
		 */
		public function copy():PlayrTrack{
			var copy:PlayrTrack = new PlayrTrack();
			copy.album = this.album;
			copy.artist = this.artist;
			copy.totalTime = this.totalTime;
			copy.totalSeconds = this.totalSeconds;
			copy.file = this.file;
			copy.title = this.title;
			copy.titleName = this.titleName;
			copy.trackNumber = this.trackNumber;
			copy.request = this.request;
			return copy;
		}
	}
}