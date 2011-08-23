package com.codezen.mse.services
{
	import com.codezen.helper.WebWorker;
	import com.codezen.mse.models.Album;
	import com.codezen.mse.models.Artist;
	
	import flash.events.Event;
	
	public final class BBCRadio extends WebWorker
	{
		private var chartsURL:String = "http://www.bbc.co.uk/radio1/chart/albums.xml";//"http://www.bbc.co.uk/programmes/music/artists/charts.xml";
		
		private var _albumsChart:Array;
		
		public function BBCRadio()
		{
			super();
		}
		
		public function get albumsChart():Array
		{
			return _albumsChart;
		}

		public function getCharts():void{
			urlRequest.url = chartsURL;
			myLoader.addEventListener(Event.COMPLETE, onChartData);
			myLoader.load(urlRequest);
		}
		
		private function onChartData(e:Event):void{
			var data:XML = new XML(myLoader.data);
			var albums:XMLList = data.children();
			
			_albumsChart = [];
			
			var item:Object;
			var album:Album;
			for each(item in albums){
				//<track position="1" lastweek="new" weeksinchart="1" artist="Arctic Monkeys" gid="ada7a83c-e3e1-40f1-93f9-3e73dbc9298a" title="Suck It And See" label="Domino Recordings" isrc="(none)" catno="WIGCD258"/>
				album = new Album();
				album.name = item.@title;
				album.artist = new Artist();
				album.artist.name = item.@artist;
				album.artist.mbID = item.@gid;
				_albumsChart.push(album);
			}
			
			endLoad();
		}
	}
}