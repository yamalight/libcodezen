package com.codezen.mse.models {
    public class Artist {
        public var mbID:String;
		[Bindable]
        public var name:String;
        public var disambiguation:String;
        //public var origin:String;
        //public var label:String;
        public var active_start:String;
        public var active_end:String;
        //public var home_page:String;
        //public var acquire_webpage:String;
		
        /*public var album:Array;
        public var genre:Array;
        public var contribution:Array;
        public var track:Array;
        public var track_contributions:Array;
        public var concert_tours:Array;
        public var supporting_artists:Array;*/
		
		public var image:String;
		public var description_short:String;
		public var description:String;
		public var tags:Array;
		public var similar:Array;
    }
}
