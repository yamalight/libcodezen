package com.codezen.vkontakte.api.data
{
	import mx.collections.ArrayCollection;

	public final class NewsItem
	{
		/**
		 * User and group  
		 */
		[Bindable]
		public var user:UserData;
		[Bindable]
		public var group:GroupData;
		
		/**
		 * Timestamp 
		 */
		public var time:String;
		
		/**
		 * Status text 
		 */
		[Bindable]
		public var text:String;
		
		/**
		 * media vars 
		 */
		[Bindable]
		public var photo:PhotoItem;
		[Bindable]
		public var video:VideoItem;
		[Bindable]
		public var audio:AudioItem;
		
		/**
		 * media arrays
		 */
		public var photos:ArrayCollection;
		
		/**
		 * Item type: text, photo, audio, video(?) 
		 */
		public var type:String;
		
		// source 
		public var source:String = "vk";
	}
}