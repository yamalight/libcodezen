package com.codezen.mse.services
{
	import com.adobe.crypto.MD5;
	import com.adobe.crypto.SHA1;
	import com.adobe.serialization.json.JSON;
	import com.adobe.serialization.json.JSONDecoder;
	import com.codezen.helper.WebWorker;
	import com.codezen.mse.models.Album;
	import com.codezen.mse.models.Artist;
	import com.codezen.mse.models.Mood;
	import com.codezen.mse.models.Song;
	
	import flash.events.Event;
	
	import mx.controls.Alert;
	import mx.utils.ObjectUtil;
	
	public final class Stereomood extends WebWorker
	{
		private var _moodsList:Array;
		private var _moodsFiltered:Array;
		private var _songs:Array;
		
		private const CYCLE_LIMIT:int = 5;
		private var cycleCounter:int;
		private var requestURL:String;
		
		public function Stereomood()
		{
			super();
		}
		
		
		public function get songs():Array
		{
			return _songs;
		}

		public function get moodsFiltered():Array
		{
			return _moodsFiltered;
		}

		public function get moodsList():Array
		{
			return _moodsList;
		}
		
		public function fetchMoods():void{
			// load moods lists
			urlRequest.url = "http://www.stereomood.com/";
			myLoader.addEventListener(Event.COMPLETE, onMoods);
			myLoader.load(urlRequest);
		}
		
		private function onMoods(e:Event):void{
			myLoader.removeEventListener(Event.COMPLETE, onMoods);
			
			_moodsList = [];
			
			// data
			var html:String = myLoader.data;
			parseMoods(html);
			
			// load more
			urlRequest.url = "http://www.stereomood.com/tools/ajax_more_tags.php";
			myLoader.addEventListener(Event.COMPLETE, onMoreMoods);
			myLoader.load(urlRequest);
		}
		
		private function onMoreMoods(e:Event):void{
			myLoader.removeEventListener(Event.COMPLETE, onMoreMoods);
			
			// data
			var html:String = myLoader.data;
			parseMoods(html);
			
			trace(ObjectUtil.toString(_moodsList));
			
			endLoad();
		}
		
		private function parseMoods(html:String):void{
			// remove all except moods
			var re:RegExp = new RegExp(/<ul class="TagCloud">(.+?)<\/ul>/g); 
			var res:Array = re.exec(html);
			html = res[1];
			
			re = new RegExp(/<li><a href="(.+?)".+?>(.+?)<\/a><\/li>/g);
			res = re.exec(html);
			
			var m:Mood;
			while(res != null){
				m = new Mood();
				m.name = res[2];
				m.url = res[1];
				
				_moodsList.push(m);
				
				res = re.exec(html);
			}
		}
		
		public function findMood(query:String):void{
			_moodsFiltered = [];
			
			var m:Mood;
			for each(m in _moodsList){
				if(m.name.toLowerCase().indexOf(query.toLowerCase()) != -1){
					_moodsFiltered.push(m);
				}
			}
			
			endLoad();
		}
		
		public function getMoodSongs(m:Mood):void{
			requestURL = "http://www.stereomood.com"+m.url+"/playlist.json?"; // ?index=1-2-3-etc
			cycleCounter = 0;
			
			_songs = [];
			
			nextRequest();
		}
		
		private function nextRequest():void{
			if(cycleCounter >= CYCLE_LIMIT){
				endLoad();
				return;
			}
			
			urlRequest.url = requestURL+"index="+cycleCounter;
			trace(urlRequest.url);
			
			myLoader.addEventListener(Event.COMPLETE, onSongs);
			myLoader.load(urlRequest);
		}
		
		private function onSongs(e:Event):void{
			myLoader.removeEventListener(Event.COMPLETE, onSongs);
			
			// data
			var res:Object = new JSONDecoder( myLoader.data, true ).getValue();
			
			var t:Object;
			var song:Song;
			for each(t in res.trackList){
				song = new Song();
				
				song.artist = new Artist();
				song.artist.name = t.creator;
				
				song.album = new Album();
				song.album.name = t.album;
				
				song.name = t.title;
				song.number = t.trackNum;
				
				_songs.push(song);
			}
			
			cycleCounter++;
			nextRequest();
		}

	}
}