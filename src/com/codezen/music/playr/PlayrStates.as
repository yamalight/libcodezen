package com.codezen.music.playr{
	/**
	 * Defines that states in which the Playr instance can be residing.
	 */
	public class PlayrStates{		
		/**
		 * The music is playing.
		 */
		public static const PLAYING:String="playing";
		/**
		 * The music is paused.
		 */
		public static const PAUSED:String="pause";
		/**
		 * The music has stopped playing.
		 */
		public static const STOPPED:String="stopped";
		/**
		 * The music is buffering.
		 */
		public static const BUFFERING:String="buffering";
		/**
		 * The Playr instance is initializing.
		 */
		public static const INIT:String="init";
		/**
		 * The Playr instance is loading a playlist file.
		 */
		public static const LOADING_PLAYLIST:String="loading_playlist";
		/**
		 * The Playr instance is initialized and is ready to take over the heavy lifting.
		 */
		public static const READY:String="ready";
		/**
		 * The Playr instance is waiting for internal process to complete.
		 */
		public static const WAITING:String="waiting";
	}
}