package com.codezen.mse.models {
    public class Song {
        public var mbID:String;
		[Bindable]
        public var name:String;
        public var number:int;
        public var duration:int;
        public var durationText:String;
        public var description:String;
		
		public var artist:Artist;
		public var album:Album;
		
		public var tags:Array;
    }
}
