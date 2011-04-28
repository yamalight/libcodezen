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
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	
	import mx.collections.ArrayCollection;
	import mx.utils.ObjectUtil;
	
	public class VkAPIService extends Base
	{
		// users
		private var _users:ArrayCollection;
		// statuses result
		private var statuses:ArrayCollection;
		// wall data
		private var _wallData:Object;
		// videos data
		private var _videosData:ArrayCollection;
		// audio data
		private var _audioData:Object;
		// video data
		private var _videoData:Object;
		private var _videoURL:String;
		// photo data
		private var _photoData:Object;
		private var _photos:Array;
		// albums data
		private var _albumsData:Array;
		// user data
		private var _userData:Object;
		private var _usersData:Array;
		// string result
		private var _stringResult:String;
		
		// users help vars
		private var user_counter:int;
		private var users_all:Array;
		private var users_to_get:Array;
		
		public function VkAPIService(appID:String, appKey:String, silentInit:Boolean)
		{
			super(appID, appKey, silentInit);
			_users = new ArrayCollection();
		}
		
		public function get wallData():Object
		{
			return _wallData;
		}

		public function get albumsData():Array
		{
			return _albumsData;
		}

		public function get photos():Array
		{
			return _photos;
		}

		public function get usersData():Array
		{
			return _usersData;
		}

		public function get photoData():Object
		{
			return _photoData;
		}

		public function get videoURL():String{
			return _videoURL;
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
		
		public function getStatuses(time:Number = 0, older:Boolean = false):void{
			if(!initialized) return;
			
			var activity:String = "newsfeed.get";
			var count:String = "100";
			
			var md5_string:String = mid+
				"api_id="+appID+
				"count="+count;
			
			if(older){
				if(time != 0) md5_string += "end_time="+time;
			}
			
			md5_string += "method="+activity;
			
			if(!older){
				if(time != 0) md5_string += "start_time="+time;
			}
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
			if(older){
				if(time != 0) vars.end_time = time;
			}else{
				if(time != 0) vars.start_time = time;
			}
			
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
			//trace(xml);
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
//				trace(item);
				newsItem = new NewsItem();
				
				// append common data
				newsItem.time = item.date.text();
				newsItem.commentsCount = item.comments.count.text();
				newsItem.likesCount = item.likes.count.text();
				
				// user/group data
				if( int(item.source_id) > 0 ){					
					newsItem.user = new UserData();
					newsItem.user.id = item.source_id.text();
					newsItem.user.name = profiles.(uid == newsItem.user.id).first_name.text();
					newsItem.user.lastname = profiles.(uid == newsItem.user.id).last_name.text();
					newsItem.user.photo = profiles.(uid == newsItem.user.id).photo.text();
					
					_users.addItem(newsItem.user);
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
						// item id
						newsItem.post_id = item.post_id.text();
						// text
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
		 * Gets photos from album by albumid
		 * @param albumid
		 * @param owner
		 * 
		 */
		public function getPhotosFromAlbum(albumid:String, owner:String):void{
			var activity:String = "photos.get";
			
			// generate hash
			var md5hash:String =  MD5.encrypt(
				mid+
				"aid="+albumid+
				"api_id="+appID+
				"method="+activity+
				"uid="+owner+
				"v=3.0"+
				secret);
			
			var vars:URLVariables = new URLVariables();
			vars.api_id = appID;
			vars.aid = albumid;
			vars.uid = owner;
			vars.method = activity;
			vars.sig = md5hash;
			vars.v = "3.0";
			vars.sid = sid;//+'&'+format;
			
			// assign url
			urlRequest.url =  'http://api.vkontakte.ru/api.php';
			urlRequest.method = URLRequestMethod.POST;
			urlRequest.data = vars;
			
			myLoader.addEventListener(Event.COMPLETE, onPhotosFromAlbumRecieve);
			myLoader.load(urlRequest);
		}
		
		private function onPhotosFromAlbumRecieve(e:Event):void{
			myLoader.removeEventListener(Event.COMPLETE, onPhotosFromAlbumRecieve);
			
			var photos:XMLList = new XMLList( XML(myLoader.data).photo );
			
			_photos = [];
			
			var obj:Object;
			var photo:PhotoItem;
			for each(obj in photos){
				photo = new PhotoItem();
				photo.id = obj.pid.text();
				photo.album = obj.aid.text();
				photo.src = obj.src.text();
				photo.src_big = obj.src_big.text();
				photo.owner = obj.owner_id.text();
				_photos.push(photo);
			}
			
			end();
		}
		
		/**
		 * Gets album info by id
		 * @param albumid
		 * @param owner
		 * 
		 */
		public function getAlbumInfo(albumid:String, owner:String):void{
			var activity:String = "photos.getAlbums";
			
			// generate hash
			var md5hash:String =  MD5.encrypt(
				mid+
				"aid="+albumid+
				"api_id="+appID+
				"method="+activity+
				"uid="+owner+
				"v=3.0"+
				secret);
			
			var vars:URLVariables = new URLVariables();
			vars.api_id = appID;
			vars.aid = albumid;
			vars.uid = owner;
			vars.method = activity;
			vars.sig = md5hash;
			vars.v = "3.0";
			vars.sid = sid;//+'&'+format;
			
			// assign url
			urlRequest.url =  'http://api.vkontakte.ru/api.php';
			urlRequest.method = URLRequestMethod.POST;
			urlRequest.data = vars;
			
			myLoader.addEventListener(Event.COMPLETE, onAlbumInfoRecieve);
			myLoader.load(urlRequest);
		}
		
		private function onAlbumInfoRecieve(e:Event):void{
			myLoader.removeEventListener(Event.COMPLETE, onAlbumInfoRecieve);
			
			var albums:XMLList = new XMLList( XML(myLoader.data).album );
			
			_albumsData = [];
			
			var obj:Object;
			for each(obj in albums){
				_albumsData.push({
					id: obj.aid.text(),
					title: obj.title.text(),
					created: obj.created.text(),
					updated: obj.updated.text(),
					size: obj.size.text()
				});
			}
			
			end();
		}
		
		/**
		 * Gets photo comments 
		 * @param id
		 * 
		 */
		public function getPhotoComments(pid:String, owner:String):void{
			var activity:String = "photos.getComments";
			
			// generate hash
			var md5hash:String =  MD5.encrypt(
				mid+
				"api_id="+appID+
				"method="+activity+
				"owner_id="+owner+
				"pid="+pid+
				"v=3.0"+
				secret);
			
			var vars:URLVariables = new URLVariables();
			vars.api_id = appID;
			vars.pid = pid;
			vars.owner_id = owner;
			vars.method = activity;
			vars.sig = md5hash;
			vars.v = "3.0";
			vars.sid = sid;//+'&'+format;
			
			// assign url
			urlRequest.url =  'http://api.vkontakte.ru/api.php';
			urlRequest.method = URLRequestMethod.POST;
			urlRequest.data = vars;
			
			myLoader.addEventListener(Event.COMPLETE, onPhotoCommentsRecieve);
			myLoader.load(urlRequest);
		}
		
		private function onPhotoCommentsRecieve(e:Event):void{
			myLoader.removeEventListener(Event.COMPLETE, onPhotoCommentsRecieve);
			
			var comments:XMLList = new XMLList( XML(myLoader.data).comment );
			
			_photoData = new Object();
			_photoData.comments = [];
			
			var obj:Object;
			for each(obj in comments){
				_photoData.comments.push({
					cid: obj.cid.text(),
					from_id: obj.from_id.text(),
					from_name: '',
					from_img: '',
					date: obj.date.text(),
					message: obj.message.text()
				});
			}
			
			end();
		}
		
		/**
		 * Gets photo comments 
		 * @param id
		 * 
		 */
		public function getWallComments(pid:String, owner:String):void{
			var activity:String = "wall.getComments";
			
			// generate hash
			var md5hash:String =  MD5.encrypt(
				mid+
				"api_id="+appID+
				"method="+activity+
				"owner_id="+owner+
				"post_id="+pid+
				"v=3.0"+
				secret);
			
			var vars:URLVariables = new URLVariables();
			vars.api_id = appID;
			vars.post_id = pid;
			vars.owner_id = owner;
			vars.method = activity;
			vars.sig = md5hash;
			vars.v = "3.0";
			vars.sid = sid;//+'&'+format;
			
			// assign url
			urlRequest.url =  'http://api.vkontakte.ru/api.php';
			urlRequest.method = URLRequestMethod.POST;
			urlRequest.data = vars;
			
			myLoader.addEventListener(Event.COMPLETE, onWallCommentsRecieve);
			myLoader.load(urlRequest);
		}
		
		private function onWallCommentsRecieve(e:Event):void{
			myLoader.removeEventListener(Event.COMPLETE, onWallCommentsRecieve);
			
			var comments:XMLList = new XMLList( XML(myLoader.data).comment );
			
			_wallData = new Object();
			_wallData.comments = [];
			
//			trace(comments);
			
			var obj:Object;
			for each(obj in comments){
				_wallData.comments.push({
					cid: obj.cid.text(),
					from_id: obj.uid.text(),
					from_name: '',
					from_img: '',
					date: obj.date.text(),
					message: obj.text.text()
				});
			}
			
			end();
		}
		
		/**
		 * Gets photo comments 
		 * @param id
		 * 
		 */
		public function getVideoComments(vid:String, owner:String):void{
			var activity:String = "video.getComments";
			
			// generate hash
			var md5hash:String =  MD5.encrypt(
				mid+
				"api_id="+appID+
				"method="+activity+
				"owner_id="+owner+
				"v=3.0"+
				"vid="+vid+
				secret);
			
			var vars:URLVariables = new URLVariables();
			vars.api_id = appID;
			vars.vid = vid;
			vars.owner_id = owner;
			vars.method = activity;
			vars.sig = md5hash;
			vars.v = "3.0";
			vars.sid = sid;//+'&'+format;
			
			// assign url
			urlRequest.url =  'http://api.vkontakte.ru/api.php';
			urlRequest.method = URLRequestMethod.POST;
			urlRequest.data = vars;
			
			myLoader.addEventListener(Event.COMPLETE, onVideoCommentsRecieve);
			myLoader.load(urlRequest);
		}
		
		private function onVideoCommentsRecieve(e:Event):void{
			myLoader.removeEventListener(Event.COMPLETE, onVideoCommentsRecieve);
			
			trace(myLoader.data);
			
			var comments:XMLList = new XMLList( XML(myLoader.data).comment );
			
			_videoData = new Object();
			_videoData.comments = [];
			
			var obj:Object;
			for each(obj in comments){
				_videoData.comments.push({
					cid: obj.cid.text(),
					from_id: obj.from_id.text(),
					from_name: '',
					from_img: '',
					date: obj.date.text(),
					message: obj.message.text()
				});
			}
			
			end();
		}
		
		/**
		 * Gets direct video uri from source page 
		 * @param source
		 * 
		 */
		public function parseVideoDirectURI(source:String):void{
			// assign url
			urlRequest.url =  source;
			
			myLoader.addEventListener(Event.COMPLETE, onVideoSourceRecieve);
			myLoader.load(urlRequest);
		}
		
		private function onVideoSourceRecieve(e:Event):void{
			myLoader.removeEventListener(Event.COMPLETE, onVideoSourceRecieve);
			
			var data:String = e.target.data;
			
//			trace(data);
			
			// create regex
			var re:RegExp = new RegExp(/\\"uid\\":\\"(.+?)\\".+?\\"host\\":\\"(.+?)\\".+?\\"vtag\\":\\"(.+?)\\".+?\\"hd\\":(.+?),/gs);
			// create res array
			var res:Array = re.exec(data);
			
			if( res == null ){
				_videoURL = null;
				end();
				return;
			}
			
			var hdDef:Dictionary = new Dictionary();
			hdDef["0"] = "240";
			hdDef["1"] = "360";
			hdDef["2"] = "480";
			hdDef["3"] = "720";
			
			var url:String = res[2]+'u'+res[1]+'/video/'+res[3]+'.'+hdDef[res[4]]+'.mp4';
			url = url.replace(/\\\//g, "\/");
			url = url.replace(/\\\//g, "\/");
			url = url.replace(/\\\//g, "\/");
			
			_videoURL = url;
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
			
			//trace( ObjectUtil.toString(urlRequest) );
			
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
				sex: int(xml.user_sex.text() ),
				bdate: xml.user_bdate.text(),
				city: xml.user_city.text(),
				photo: xml.user_photo.text()
			};
			
			var user:UserData = new UserData();
			user.id = _userData.id;
			user.name = _userData.name;
			user.photo = _userData.photo;
			_users.addItem(user);
			
			user = null;
			
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
			
			//trace(xml);
			
			_stringResult = xml.post_id;
			
			end();
		}
		
		/**
		 * Gets user details by id
		 * @param uid
		 * 
		 */
		public function getOtherUserInfo(users:Array):void{
			user_counter = users.length;
			users_all = users;
			users_to_get = [];
			_usersData = [];
			
			getNextUserData();
		}
		
		private function getNextUserData():void{
			if(user_counter < 0){
				// get left from vk
				if(users_to_get.length > 0){
					loadUserData();
				}else{
					end();
				}
				return;
			}
			
			var uid:String = users_all[user_counter];
			if( uid != null ){
				var index:int = CUtils.getItemIndexByProperty(_users, "id", uid);
				if(index < 0){
					// need get from vk
					//trace(uid+' added for request');
					users_to_get.push(uid);
				}else{
					// have info, done with this
					//trace(uid+' already known');
					_usersData.push(_users[index]);
				}
			}
			// continue
			user_counter--;
			getNextUserData();
		}
		
		private function loadUserData():void{
			var activity:String = "getProfiles";
			
			// generate hash
			var md5hash:String =  MD5.encrypt(
				mid+
				"api_id="+appID+
				"fields=uid,first_name,last_name,photo"+
				"method="+activity+
				"uids="+users_to_get.join(",")+
				"v=3.0"+
				secret);
			
			var vars:URLVariables = new URLVariables();
			vars.api_id = appID;
			vars.fields = "uid,first_name,last_name,photo";
			vars.method = activity;
			vars.uids = users_to_get.join(",");
			vars.sig = md5hash;
			vars.v = "3.0";
			vars.sid = sid;
			
			// assign url
			urlRequest.url = "http://api.vkontakte.ru/api.php";
			urlRequest.method = URLRequestMethod.POST;
			urlRequest.data = vars;
			
			// load
			myLoader.addEventListener(Event.COMPLETE, onUsersData);
			myLoader.load(urlRequest);
		}
		
		private function onUsersData(e:Event):void{
			myLoader.removeEventListener(Event.COMPLETE, onUsersData);
			
			// get result
			var xml:XMLList = new XMLList( XML(myLoader.data).user );
			
			var user:XML;
			var ud:UserData;
			for each(user in xml){
				//trace(user);
				ud = new UserData();
				ud.id = user.uid.text();
				ud.name = user.first_name.text();
				ud.lastname = user.last_name.text();
				ud.photo = user.photo.text();
				
				_usersData.push(ud);
			}
			
			end();
		}
	}
}















