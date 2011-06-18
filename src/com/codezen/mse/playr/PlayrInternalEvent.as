package com.codezen.mse.playr{
	import flash.events.Event;
	/**
	 * Used for interal error and event handling.
	 */
	public class PlayrInternalEvent extends Event{
		
		
		public static const DEBUG:String = "playr_debug";		
		public static const PLAYLIST_LOADED:String = "playlist_loaded";
		public static const PLAYLIST_TRACK_OUT_OF_BOUNDS:String="playlist_track_out_of_bounds";
		public static const PLAYLIST_STREAM_ERROR:String="playlist_stream_error";
		public static const PLAYLIST_INVALID_XML:String="playlist_invalid_xml";
		public static const TRACK_NOT_ADDED_TO_PLAYLIST:String="track_not_added_to_playlist";
		public static const TRACK_ADDED_TO_PLAYLIST:String="track_added_to_playlist";
		public static const TRACK_LOADING:String = "track_loading";
		public static const CURRENT_TRACK_TO_BE_REMOVED:String="current_track_to_be_removed";
		public function PlayrInternalEvent(type:String){
			super(type);
		}
		public var message:String = "";
	}
}