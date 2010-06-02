package com.codezen.component.videoplayer.subs
{
	public class SubTitleData {
		public var text : String;
		public var start : Number;
		public var duration : Number;
		public var end : Number;
		
		public function SubTitleData(inText : String = "",inStart : Number = 0,inDuration : Number = 0,inEnd : Number = 0) {
			text = inText;
			start = inStart;
			duration = inDuration;
			end = inEnd;
		}
	}
}