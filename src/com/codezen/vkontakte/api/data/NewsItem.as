package com.codezen.vkontakte.api.data
{
	public final class NewsItem
	{
		/**
		 * Item ID 
		 */
		public var id:String;
		
		/**
		 * User ID 
		 */
		public var uid:String;
		// user name, nickname, lastname
		[Bindable]
		public var user_name:String;
		public var user_nname:String;
		[Bindable]
		public var user_lname:String;
		public var user_sex:String;
		[Bindable]
		public var user_photo:String;
		
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
		 * Media owned ID 
		 */
		public var owner:String;
		
		/**
		 * Media item ID 
		 */
		public var item:String;
		
		
		/**
		 * Item type: text, photo, audio, video(?) 
		 */
		public var type:String;
	}
}