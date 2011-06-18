package com.codezen.mse.models {
    public class Album {
        public var mbID:String;
        public var number:int;
		[Bindable]
        public var name:String;
        public var date:String;
        public var image:String;
        public var songs:Array;
        public var artist:Artist;
    }
}
