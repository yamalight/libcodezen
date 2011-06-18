package com.codezen.mse.playr{
	import flash.events.Event;
	/**
	 * Dedicated error event class. The class won't be breaking your application which is a good thing. However you won't be notified by the ActionScript debugger when runtime errors occur (such as 'url not found') as they are caught and translated into harmless events.
	 */
	public class PlayrErrorEvent extends Event{
		
		
				
		public static const TRACK_OUT_OF_BOUNDS:String = "track_out_of_bounds";
		public static const PLAYLIST_STREAM_ERROR:String="playlist_stream_error";
		public static const SOUND_STREAM_ERROR:String="sound_stream_error";
		public static const PLAYLIST_INVALID_XML:String="playlist_invalid_xml";
		public static const TRACK_NOT_ADDED_TO_PLAYLIST:String="track_not_added_to_playlist";
		public static const NO_PLAYLIST_SELECTED:String="no_playlist_selected";
		public static const IO_ERROR:String = "io_error";
		
		
		public function PlayrErrorEvent(type:String){
			super(type,true);
		}
	}
}