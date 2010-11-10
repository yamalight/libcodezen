package com.codezen.vkontakte.api.data
{
	public final class NewsItem
	{
		/**
		 * Item ID 
		 */
		public var id:String;
		
		/**
		 * User 
		 */
		[Bindable]
		public var user:User;
		
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
		 * Photo var 
		 */
		[Bindable]
		public var photo:Photo;
		
		/**
		 * Media item ID 
		 */
		public var item:String;
		/**
		 * Media owned ID 
		 */
		public var owner:String;
		
		/**
		 * Item type: text, photo, audio, video(?) 
		 */
		public var type:String;
	}
}