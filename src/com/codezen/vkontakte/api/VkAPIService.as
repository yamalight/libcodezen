package com.codezen.vkontakte.api
{
	import com.codezen.util.CUtils;
	import com.codezen.util.MD5;
	import com.codezen.vkontakte.api.data.AudioItem;
	import com.codezen.vkontakte.api.data.GroupData;
	import com.codezen.vkontakte.api.data.NewsItem;
	import com.codezen.vkontakte.api.data.PhotoItem;
	import com.codezen.vkontakte.api.data.UserData;
	import com.codezen.vkontakte.api.data.VideoItem;
	import com.codezen.vkontakte.api.service.Base;
	
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.utils.Timer;
	
	import mx.collections.ArrayCollection;
	import mx.utils.ObjectUtil;
	
	public class VkAPIService extends Base
	{
		// statuses result
		private var statuses:ArrayCollection;
		// videos data
		private var _videosData:ArrayCollection;
		// audio data
		private var _audioData:Object;
		// video data
		private var _videoData:Object;
		// user data
		private var _userData:Object;
		// string result
		private var _stringResult:String;
		
		public function VkAPIService(appID:String, appKey:String, silentInit:Boolean)
		{
			super(appID, appKey, silentInit);
		}
		
		public function get stringResult():String{
			return _stringResult;
		}
		
		public function get statusList():ArrayCollection{
			return statuses;
		}
		
		public function get audioData():Object{
			return _audioData;
		}
		
		public function get videoData():Object{
			return _videoData;
		}
		
		public function get userData():Object{
			return _userData;
		}
		
		public function getStatuses(time:Number = 0):void{
			if(!initialized) return;
			
			var activity:String = "newsfeed.get";
			var count:String = "100";
			
			var md5_string:String = mid+
				"api_id="+appID+
				"count="+count+
				"method="+activity;
			if(time != 0) md5_string += "start_time="+time;
			md5_string += "v=3.0"+secret; 
			
			// generate hash
			var md5hash:String =  MD5.encrypt(md5_string);
			
			var vars:URLVariables = new URLVariables();
			vars.api_id = appID;
			vars.count = count;
			vars.method = activity;
			vars.sig = md5hash;
			vars.v = "3.0";
			vars.sid = sid;//+'&'+format;
			if(time != 0) vars.start_time = time;
			
			// assign url
			urlRequest.url =  'http://api.vkontakte.ru/api.php';
			urlRequest.method = URLRequestMethod.POST;
			urlRequest.data = vars;
			
			myLoader.addEventListener(Event.COMPLETE, onStatusesRecieve);
			myLoader.load(urlRequest);
		}
		
		private function onStatusesRecieve(e:Event):void{
			// remove old listener
			myLoader.removeEventListener(Event.COMPLETE, onStatusesRecieve);
			
			// create new collections
			statuses = new ArrayCollection();
			_videosData = new ArrayCollection();
			
			// get data
			var xml:XML = new XML(myLoader.data);
			// get lists
			var stats:XMLList = new XMLList(xml.items.item);
			var profiles:XMLList = new XMLList(xml.profiles.user);
			var groups:XMLList = new XMLList(xml.groups.group);
			// create empty objects
			var item:Object;
			var subitem:Object;
			var photo:PhotoItem;
			var list:XMLList;
			// create news container
			var newsItem:NewsItem;
			
			for each(item in stats){
				// reset item
				newsItem = new NewsItem();
				
				// append common data
				newsItem.time = item.date.text();
				
				// user/group data
				if( int(item.source_id) > 0 ){					
					newsItem.user = new UserData();
					newsItem.user.id = item.source_id.text();
					newsItem.user.name = profiles.(uid == newsItem.user.id).first_name.text();
					newsItem.user.lastname = profiles.(uid == newsItem.user.id).last_name.text();
					newsItem.user.photo = profiles.(uid == newsItem.user.id).photo.text();
				}else{
					newsItem.group = new GroupData();
					newsItem.group.id = Math.abs( int(item.source_id) ).toString();
					newsItem.group.name = groups.(gid == newsItem.group.id).name.text();
					newsItem.group.photo = groups.(gid == newsItem.group.id).photo.text();
				}
				
				// add news depending on type
				switch( String(item.type) ){
					// if it's a post
					case "post":
						newsItem.text = item.text.text();
						if( item.attachment != null ){
							switch( String(item.attachment.type) ){
								case "photo":
									newsItem.photo = new PhotoItem();
									newsItem.photo.id = item.attachment.photo.pid.text();
									newsItem.photo.owner = item.attachment.photo.owner_id.text();
									newsItem.photo.album = item.attachment.photo.aid.text();
									newsItem.photo.src = item.attachment.photo.src.text();
									newsItem.photo.src_big = item.attachment.photo.src_big.text();
									break;
								case "posted_photo":
									newsItem.photo = new PhotoItem();
									newsItem.photo.id = item.attachment.posted_photo.pid.text();
									newsItem.photo.owner = item.attachment.posted_photo.owner_id.text();
									newsItem.photo.album = item.attachment.photo.aid.text();
									newsItem.photo.src = item.attachment.posted_photo.src.text();
									newsItem.photo.src_big = item.attachment.posted_photo.src_big.text();
									break;
								case "video":
									newsItem.video = new VideoItem();
									newsItem.video.id = item.attachment.video.vid.text();
									newsItem.video.owner = item.attachment.video.owner_id.text(); 
									newsItem.video.title = item.attachment.video.title.text();
									newsItem.video.dur = item.attachment.video.duration.text();
									
									_videosData.addItem({id: newsItem.video.id, owner: newsItem.video.owner});
									break;
								case "audio":
									newsItem.audio = new AudioItem();
									newsItem.audio.id = item.attachment.audio.aid.text();
									newsItem.audio.owner = item.attachment.audio.owner_id.text();
									newsItem.audio.artist = item.attachment.audio.performer.text();
									newsItem.audio.title = item.attachment.audio.title.text();
									newsItem.audio.dur = item.attachment.audio.duration.text();
									break;
							}
						}
						break;
					// if photo
					case "photo":
						list = new XMLList( item.photos.photo );
						newsItem.photos = new ArrayCollection();
						for each(subitem in list){
							photo = new PhotoItem();
							photo.id = subitem.pid.text();
							photo.owner = subitem.owner_id.text();
							photo.album = subitem.aid.text();
							photo.src = subitem.src.text();
							photo.src_big = subitem.src_big.text();
							newsItem.photos.addItem(photo);
						}
						break;
					default:
						//trace( ObjectUtil.toString(item.attachment) );
						//trace('----------------------------------------------------');
						break;
				}
				
				statuses.addItem(newsItem);
			}
			
			//trace( ObjectUtil.toString(statuses) );
			//end();
			
			// get videos 
			getVideosInfo();
		}
		
		private function getVideosInfo():void{
			var activity:String = "video.get";
			var vids:String = "";
			var i:int = 0;
			
			for(i = 0; i < _videosData.length; i++){
				vids += _videosData[i].owner + "_" + _videosData[i].id;
				if(i < (_videosData.length-1) ) vids += ",";
			}
			
			// generate hash
			var md5hash:String =  MD5.encrypt(
				mid+
				"api_id="+appID+
				"method="+activity+
				"v=3.0"+
				"videos="+vids+
				secret);
			
			var vars:URLVariables = new URLVariables();
			vars.api_id = appID;
			vars.videos = vids;
			vars.method = activity;
			vars.sig = md5hash;
			vars.v = "3.0";
			vars.sid = sid;//+'&'+format;
			
			// assign url
			urlRequest.url =  'http://api.vkontakte.ru/api.php';
			urlRequest.method = URLRequestMethod.POST;
			urlRequest.data = vars;
			
			myLoader.addEventListener(Event.COMPLETE, onVideosRecieve);
			myLoader.load(urlRequest);
		}
		
		private function onVideosRecieve(e:Event):void{
			myLoader.removeEventListener(Event.COMPLETE, onVideosRecieve);
			
			var vids:XMLList = new XMLList( XML(myLoader.data).video );
			var vid:Object;
			var stat:NewsItem;
			var i:int;
			
			for each(stat in statuses){
				if( stat.video != null ){
					for each(vid in vids){
						if( stat.video.id == vid.vid.text() && stat.video.owner == vid.owner_id.text() ){
							stat.video.desc = vid.description.text();
							stat.video.thumb = vid.image.text();
							stat.video.src = vid.link.text();
						}
					}
				}
			}
			
			end();
		}
		
		/**
		 * Gets video data by userid_vidid 
		 * @param id
		 * 
		 */
		public function getVideoData(vids:String):void{
			var activity:String = "video.get";
			
			// generate hash
			var md5hash:String =  MD5.encrypt(
				mid+
				"api_id="+appID+
				"method="+activity+
				"v=3.0"+
				"videos="+vids+
				secret);
			
			var vars:URLVariables = new URLVariables();
			vars.api_id = appID;
			vars.videos = vids;
			vars.method = activity;
			vars.sig = md5hash;
			vars.v = "3.0";
			vars.sid = sid;//+'&'+format;
			
			// assign url
			urlRequest.url =  'http://api.vkontakte.ru/api.php';
			urlRequest.method = URLRequestMethod.POST;
			urlRequest.data = vars;
			
			myLoader.addEventListener(Event.COMPLETE, onVideoDataRecieve);
			myLoader.load(urlRequest);
		}
		
		private function onVideoDataRecieve(e:Event):void{
			myLoader.removeEventListener(Event.COMPLETE, onVideoDataRecieve);
			
			var vids:XMLList = new XMLList( XML(myLoader.data).video );
			
			_videoData = new Object();
			_videoData.image = vids.image.text();
			_videoData.src = "http://vk.com/video"+vids.owner_id.text()+"_"+vids.vid.text();
			_videoData.title = vids.title.text();
			_videoData.dur = vids.duration.text();
			_videoData.date = vids.date.text();
			/*
			RESPONSE:
			<video>
			<vid>158411118</vid>
			<owner_id>117969393</owner_id>
			<title>Test</title>
			<description/>
			<duration>30</duration>
			<link>video158411118</link>
			<image>http://cs12622.vkontakte.ru/u117969393/video/m_b87e3c75.jpg</image>
			<date>1293207454</date>
			</video>
			*/
			
			end();
		}
		
		/**
		 * Gets song data 
		 * @param songid
		 * 
		 */
		public function getSongData(songid:String):void{
			var activity:String = "audio.getById";
			
			// generate hash
			var md5hash:String =  MD5.encrypt(
				mid+
				"api_id="+appID+
				"audios="+songid+
				"method="+activity+
				"v=3.0"+
				secret);
			
			var vars:URLVariables = new URLVariables();
			vars.api_id = appID;
			vars.audios = songid;
			vars.method = activity;
			vars.sig = md5hash;
			vars.v = "3.0";
			vars.sid = sid;
			
			// assign url
			urlRequest.url = "http://api.vkontakte.ru/api.php";
			urlRequest.method = URLRequestMethod.POST;
			urlRequest.data = vars;
			
			trace( ObjectUtil.toString(urlRequest) );
			
			// load
			myLoader.addEventListener(Event.COMPLETE, onAudioData);
			myLoader.load(urlRequest);
		}
		
		private function onAudioData(e:Event):void{
			// remove
			myLoader.removeEventListener(Event.COMPLETE, onAudioData);
			
			//trace(myLoader.data)
			
			// get result
			var xml:XML = new XML(myLoader.data);
			
			_audioData = {
				artist: xml.audio.artist.text(),
				title: xml.audio.title.text(),
				url: xml.audio.url.text()
			};
			
			end();
		}
		
		/**
		 * Get current user info 
		 * 
		 */
		public function getUserInfo():void{
			var activity:String = "getUserInfoEx";
			
			// generate hash
			var md5hash:String =  MD5.encrypt(
				mid+
				"api_id="+appID+
				"method="+activity+
				"v=3.0"+
				secret);
			
			var vars:URLVariables = new URLVariables();
			vars.api_id = appID;
			vars.method = activity;
			vars.sig = md5hash;
			vars.v = "3.0";
			vars.sid = sid;
			
			// assign url
			urlRequest.url = "http://api.vkontakte.ru/api.php";
			urlRequest.method = URLRequestMethod.POST;
			urlRequest.data = vars;
			
			// load
			myLoader.addEventListener(Event.COMPLETE, onUserInfo);
			myLoader.load(urlRequest);
		}
		
		private function onUserInfo(e:Event):void{
			myLoader.removeEventListener(Event.COMPLETE, onUserInfo);
			
			// get result
			var xml:XML = new XML(myLoader.data);
			
			//trace(xml);
			
			_userData = {
				id: xml.user_id.text(),
				name: xml.user_name.text(),
				photo: xml.user_photo.text()
			};
			
			end();
		}
		
		/**
		 * Make message post 
		 * 
		 */
		public function postMessage(msg:String):void{
			var activity:String = "wall.post";
			
			// generate hash
			var md5hash:String =  MD5.encrypt(
				mid+
				"api_id="+appID+
				"message="+msg+
				"method="+activity+
				"v=3.0"+
				secret);
			
			var vars:URLVariables = new URLVariables();
			vars.api_id = appID;
			vars.method = activity;
			vars.message = msg;
			vars.sig = md5hash;
			vars.v = "3.0";
			vars.sid = sid;
			
			// assign url
			urlRequest.url = "http://api.vkontakte.ru/api.php";
			urlRequest.method = URLRequestMethod.POST;
			urlRequest.data = vars;
			
			// load
			myLoader.addEventListener(Event.COMPLETE, onMessagePost);
			myLoader.load(urlRequest);
		}
		
		private function onMessagePost(e:Event):void{
			myLoader.removeEventListener(Event.COMPLETE, onMessagePost);
			
			// get result
			var xml:XML = new XML(myLoader.data);
			
			trace(xml);
			
			_stringResult = xml.post_id;
			
			end();
		}
	}
}















