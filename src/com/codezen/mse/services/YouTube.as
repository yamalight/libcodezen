package com.codezen.mse.services
{
	import com.adobe.serialization.json.JSONDecoder;
	import com.codezen.helper.WebWorker;
	import com.codezen.mse.models.VideoObject;
	
	import flash.events.Event;
	import flash.net.URLRequest;
	
	import mx.utils.ObjectUtil;
	
	public class YouTube extends WebWorker
	{		
		private var _videos:Array;
		
		public function YouTube()
		{
			super();
		}
		
		public function get videos():Array
		{
			return _videos;
		}
		
		public function getTopVideos():void{
			var url:String = "https://gdata.youtube.com/feeds/api/standardfeeds/top_rated_Music?alt=json&time=today&v=2";
			
			myLoader.addEventListener(Event.COMPLETE, onResults);
			myLoader.load(new URLRequest(url));
		}

		public function findVideo(q:String):void{
			var url:String = "https://gdata.youtube.com/feeds/api/videos?"
				url += "alt=json";
    			url += "&q="+encodeURIComponent(q);
    			url += "&orderby=published";
		    	url += "&max-results=50";
    			url += "&v=2";
			
			myLoader.addEventListener(Event.COMPLETE, onResults);
			myLoader.load(new URLRequest(url));
		}
		
		private function onResults(e:Event):void{
			myLoader.removeEventListener(Event.COMPLETE, onResults);
			
			var res:Object = new JSONDecoder( myLoader.data, true ).getValue();
			
			_videos = [];
			
			var vid:VideoObject;
			var entry:Object;
			for each(entry in res.feed.entry){
				vid = new VideoObject();
				vid.author = entry.author.name;
				vid.title = entry.title["$t"];
				vid.desctiption = entry["media$group"]["media$description"]["$t"];
				
				vid.contentURL = entry.content.src;
				vid.thumbURL = entry["media$group"]["media$thumbnail"][0]["url"];
				vid.thumbHDURL = entry["media$group"]["media$thumbnail"][1]["url"];
				_videos.push(vid);
			}
			
			trace(ObjectUtil.toString(_videos));
			
			endLoad();
		}
	}
}