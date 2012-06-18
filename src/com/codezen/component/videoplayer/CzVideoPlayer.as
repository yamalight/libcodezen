import com.codezen.component.loader.LoadingIndicator;
import com.codezen.mse.playr.PlaylistManager;
import com.codezen.mse.playr.Playr;
import com.codezen.mse.playr.PlayrEvent;
import com.codezen.mse.playr.PlayrTrack;
import com.codezen.subs.Caption;
import com.codezen.subs.Subtitle;

import flash.display.StageDisplayState;
import flash.events.ErrorEvent;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.events.NetStatusEvent;
import flash.events.StageVideoAvailabilityEvent;
import flash.events.StageVideoEvent;
import flash.events.TimerEvent;
import flash.geom.Rectangle;
import flash.media.SoundTransform;
import flash.media.StageVideo;
import flash.media.StageVideoAvailability;
import flash.media.Video;
import flash.net.NetConnection;
import flash.net.NetStream;
import flash.system.Capabilities;
import flash.ui.Keyboard;
import flash.ui.Mouse;
import flash.utils.Timer;

import mx.collections.ArrayCollection;
import mx.controls.Alert;
import mx.core.FlexGlobals;
import mx.events.FlexEvent;
import mx.utils.ObjectUtil;

import spark.events.DropDownEvent;

private var sv:StageVideo;
private var svAvailable:Boolean;
// netsteam
private var ns:NetStream;
private var nc:NetConnection;
private var vid:Video;
private var customClient:Object;
// pos save timer
private var saveTime:Number;
// seek offset
private var seekOffset:Number;
// url
private var videoURL:String;
// gui timer
private var hideTimer:Timer;
// file durations - text
private var maxDur:String;
// num
private var totalDuration:Number;
// video sizes
private var origWidth:Number;
private var origHeight:Number;
// player state
private var playState:Boolean;
// subs
[Bindable]
private var isSub:Boolean;
[Bindable]
private var isSubSwitch:Boolean;
private var subs:Array;
[Bindable]
private var subNames:ArrayCollection;
private var subArray:Array;
private var subCurrent:Array;
private var subIndex:Number;
private var forcedSubtitles:Object; // {'lang': 'url'}
private var _autoloadSub:Boolean = false;
// sounds
private var maxVolumeOverride:Number = 1.0;
[Bindable]
private var isSnd:Boolean;
[Bindable]
private var isSndSwitch:Boolean;
private var snds:ArrayCollection;
[Bindable]
private var sndNames:ArrayCollection;
private var sndArray:Array;
private var soundPlayer:Playr;
private var soundPercent:Number;
private var isSoundPlaying:Boolean;
private var firstSndPlay:Boolean;

// watched control
private var watchedReport:Boolean;
// old volume 
private var volumeLevel:Number;
// seek width on init
private var progressOffset:Number;
// start position
private var startPos:Number;
// autoplay flag
private var _autoplay:Boolean = true;

// EMBED ASSETS STUFF
[Embed(source="assets/player/play.png")]
[Bindable]
public var playBtn:Class;
[Embed(source="assets/player/pause.png")]
[Bindable]
public var pauseBtn:Class;
[Embed(source="assets/player/soundOn.png")]
[Bindable]
public var muteBtn:Class;
[Embed(source="assets/player/soundOff.png")]
[Bindable]
public var unmuteBtn:Class;
[Embed(source="assets/player/ontop_lock.png")]
[Bindable]
public var onTopLock:Class;
[Embed(source="assets/player/ontop_norm.png")]
[Bindable]
public var onTopNormal:Class;
[Embed(source="assets/player/play_loop_selected.png")]
[Bindable]
public var loopSel:Class;
[Embed(source="assets/player/play_loop.png")]
[Bindable]
public var loopOff:Class;

// Event constants // 
private const EPISODE_WATCHED:String = "episodeWatched";
private const RETURN_VIEW:String = "returnView";
private const PLAY_PREV:String = "playPrev";
private const PLAY_NEXT:String = "playNext";
private const UPDATE_TIME:String = "updateTime";
private const ON_PLAY:String = "onPlay";
private const ON_PAUSE:String = "onPause";
private const ON_END:String = "onEnd";
private const ON_ENTER_FULLSCREEN:String = "onEnterFullscreen";
private const ON_EXIT_FULLSCREEN:String = "onExitFullscreen";

// visibility of btns
[Bindable]
private var _showLoop:Boolean = true;
[Bindable]
private var loop_width:int = 22;

[Bindable]
private var _showScale:Boolean = true;

[Bindable]
private var _showClose:Boolean = true;
[Bindable]
private var close_width:int = 22;

[Bindable]
private var _showTop:Boolean = true;
[Bindable]
private var top_width:int = 22;


// mobile
[Bindable]
private var _isMobile:Boolean; 

// setters
public function set autoloadSub(s:Boolean):void{
	_autoloadSub = s;
}

public function set overrideVolume(v:Number):void{
	maxVolumeOverride = v;
	
	if(ns){
		ns.soundTransform = new SoundTransform(maxVolumeOverride * (volumeLevel/100) );
		trace(maxVolumeOverride * (volumeLevel/100) );
	}
}

public function set showLoop(show:Boolean):void{
	_showLoop = show;
	if(!_showLoop){
		loop_width = 1;
	}else{
		loop_width = 22;
	}
}
public function set showScale(show:Boolean):void{
	_showScale = show;
}
public function set showClose(show:Boolean):void{
	_showClose = show;
	if(!_showClose){
		close_width = 1;
	}else{
		close_width = 22;
	}
}
public function set showTop(show:Boolean):void{
	_showTop = show;
	if(!_showTop){
		top_width = 1;
	}else{
		top_width = 22;
	}
}
public function set autoplay(ap:Boolean):void{
	_autoplay = ap;
}
public function set isMobile(m:Boolean):void{
	_isMobile = m;
}

private function onCreationComplete():void{
	// rescale for mobile
	if(_isMobile){
		player_controls.removeElement(fullscreen_btn);//.width = 0;
		player_controls.removeElement(player_volume);//.width = 0;
		player_controls.removeElement(mute_btn);//.width = 0;
		//loading_wnd.removeElement(loading_spin);
		
		// resize sub and sound
		player_sndselect.width = player_subselect.width = 150;
		sndBar.maxWidth = subBar.maxWidth = 140;
		
		//player_data.removeElement(player_subselect);
		//player_data.removeElement(player_sndselect);
	}else{
		var ind:LoadingIndicator = new LoadingIndicator();
		ind.setStyle("backgroundAlpha", 0);
		ind.setStyle("borderAlpha", 0);
		ind.colorOverlay = 0xFFFFFF;
		ind.isLoading = true;
		ind.width = ind.height = 24;
		loading_wnd.addElementAt(ind, 0);
		//<loader:LoadingIndicator isLoading="true" id="loading_spin" colorOverlay="#FFFFFF" />
	}
	
	this.addEventListener(Event.ADDED_TO_STAGE, initStagePlayer);
}

// init functions
private function initStagePlayer(e:Event = null):void{
	this.removeEventListener(Event.ADDED_TO_STAGE, initStagePlayer);
	
	// stagevideo check
	this.stage.addEventListener(StageVideoAvailabilityEvent.STAGE_VIDEO_AVAILABILITY, onStageVideoState);
	
	//loadVideoAndPlay("http://serials.tulavideo.net/MER/MER-01-01.mp4");
	//this.invalidateDisplayList();	
}

private function onStageVideoState(event:StageVideoAvailabilityEvent):void       {
	this.stage.removeEventListener(StageVideoAvailabilityEvent.STAGE_VIDEO_AVAILABILITY, onStageVideoState);
	
	svAvailable = (event.availability == StageVideoAvailability.AVAILABLE);       
}

private function stageVideoStateChange(event:StageVideoEvent):void{          
	var status:String = event.status;
	trace(status);
	resizeStageVideo();
}

private function resizeStageVideo():void{
	trace('resize sv');
	if(sv == null) return;
	// rescale saving proportions
	var _width:Number;
	var _height:Number
	var _x:Number;
	var _y:Number;
	if(video_player.height > (origHeight*(video_player.width/origWidth)) ){
		_width = video_player.width;
		_height = origHeight*(video_player.width/origWidth);
		_y = (video_player.height - _height)/2;
		_x = 0;
	}else{
		_height = video_player.height;
		_width = origWidth*(video_player.height/origHeight);
		_x = (video_player.width - _width)/2;
		_y = 0;
	}
	
	//trace(_x, _y, _width, _height);
	
	//if(_x < 1 || _y < 1 || _width < 1 || _height < 1) return;
	
	sv.viewPort = new Rectangle(_x, _y, _width, _height);
	
	// rescale sub
	var s:Caption;
	for each(s in subCurrent){
		if(s.active){
			s.unsub(); 
			s.sub();
		}
	}
}

public function getActiveSubs(valign:String):Array{
	var activeSubs:Array = [];
	var item:Caption;
	for each (item in subCurrent){
		if( (item.active) && (item.v_align == valign) ){ //  
			activeSubs.push(item);
		}
	}
	return activeSubs;
}

// load video to play
public function loadVideoAndPlay(link:String, subtitles:Array = null, sounds:Array = null, startPos:int = 0, forcedSubs:Object = null):void{
	// save link for seeking
	videoURL = link;
	
	this.startPos = startPos;
	this.forcedSubtitles = forcedSubs;
	
	// parse subs
	if(subtitles != null && subtitles.length > 0){
		isSub = true;
		isSubSwitch = true;
		parseSubtitiles(subtitles);
	}else{
		isSub = false;
		isSubSwitch = false;
	}
	
	// parse subs
	if(sounds != null && sounds.length > 0){
		isSnd = true;
		isSndSwitch = true;
		isSoundPlaying = false;
		soundPlayer = new Playr();
		soundPlayer.buffer = 10000;
		parseSounds(sounds);
	}else{
		isSnd = false;
		isSndSwitch = false;
		isSoundPlaying = false;
	}
	
	// reset durations and offset
	maxDur = "0:00:00";
	totalDuration = 0;
	seekOffset = 0;
	progressOffset = 0;
	saveTime = -1;
	
	// set play state
	watchedReport = false;
	
	// assign button
	playpause.select = false;
	playState = true;
	
	// create new client
	customClient = {};
	customClient.onMetaData = metaDataHandler;
	
	// establish new connection
	nc = new NetConnection();
	nc.connect(null);
	
	// attach stream to connection
	ns = new NetStream(nc);
	// assign client
	ns.client = customClient;
	if(_isMobile){
		ns.maxPauseBufferTime = 120;
		ns.backBufferTime = 3;
		ns.bufferTimeMax = 120;
	}
	//ns.addEventListener(NetStatusEvent.NET_STATUS, function(e:NetStatusEvent):void{
	//	trace("NetStatus: "+ObjectUtil.toString(e));
	//});
	
	// if StageVideo is available, attach the NetStream to StageVideo       
	if (svAvailable)       
	{       
		trace('stage');
		sv = this.stage.stageVideos[0];
		sv.attachNetStream(ns);
	}else{
		trace('normal');
		vid = new Video(video_player.width, video_player.height);
		if(!_isMobile){
			// max quality
			vid.smoothing = true;
			vid.deblocking = 0;
		}else{
			// disable all filters for speed
			vid.smoothing = false;
			vid.deblocking = 1;
		}
		
		// add video to stage
		video_player.addChild(vid);
		
		// attach stream to video 
		vid.attachNetStream(ns);
	}
	
	ns.play(videoURL);
	
	// set volume
	if(volumeLevel >= 0){
		player_volume.value = volumeLevel;
		setVolume();
	}
	
	// init gui timer
	hideTimer = new Timer(4000, 1);
	hideTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onHideTimer);
	//hideTimer.start();
	
	// set focus
	//video_player.setFocus();
}

private function onSoundStream(e:PlayrEvent):void{
	soundPercent = e.progress;
	sound_loading_status.text = "Загрузка звуковой дорожки.. " + int( soundPercent/((seekOffset+ns.time)/totalDuration + 0.1) * 100 ) + "%";
	if( firstSndPlay && soundPercent >= ( (seekOffset+ns.time)/totalDuration + 0.1)  ){
		firstSndPlay = false;
		loading_status_wnd.visible = false;
		togglePlayPause();
	}
	if(soundPercent == 1){
		soundPlayer.removeEventListener(PlayrEvent.STREAM_PROGRESS, onSoundStream);
		firstSndPlay = false;
		loading_status_wnd.visible = false;
	}
}

public var defaultSoundName:String = "jp";

private function parseSounds(sounds:Array):void{
	//trace(ObjectUtil.toString(subtitiles));
	sndBar.selectedIndex = 0;
	
	sndArray = sounds;
	sndNames = new ArrayCollection();
	sndNames.addItem({label: defaultSoundName});
	var i:int = 0;
	for(i = 0; i < sounds.length; i++){
		if(String(sounds[i]).indexOf("_1.mp3") > 0 || String(sounds[i]).indexOf("_ru.mp3") > 0){
			sndNames.addItem({label: "ru"});
		}
		if(String(sounds[i]).indexOf("_2.mp3") > 0 || String(sounds[i]).indexOf("_en.mp3") > 0){
			sndNames.addItem({label: "en"});
		}
	}
	
	if(sndNames.length > 1) isSndSwitch = true;
}

private function loadSound(sndURL:String):void{
	if( sndURL == "unload" ){
		soundPlayer.stop();
		soundPlayer.playlist = new PlaylistManager();
		isSoundPlaying = false;
		ns.soundTransform = new SoundTransform(maxVolumeOverride * (volumeLevel/100));
		
		if(forcedSubtitles != null && forcedSubtitles.hasOwnProperty(defaultSoundName) && subBar.selectedIndex == 0){
			loadSubtitles(forcedSubtitles[defaultSoundName]);
		}
	}else{
		if(playState) togglePlayPause();
		soundPlayer.stop();
		soundPlayer.playlist = new PlaylistManager();
		isSoundPlaying = false;
		ns.soundTransform = new SoundTransform(0);
		firstSndPlay = true;
		soundPlayer.autoPlay = false;
		soundPlayer.volume = maxVolumeOverride * (volumeLevel/100);
		
		// add loading event
		soundPlayer.addEventListener(PlayrEvent.STREAM_PROGRESS, onSoundStream);
		
		// add track
		var playlist:PlaylistManager = new PlaylistManager();
		var track:PlayrTrack = new PlayrTrack();
		track.file = sndURL;
		playlist.addTrack(track);
		soundPlayer.playlist = playlist;
		
		// load and scrobble
		soundPlayer.play();
		soundPlayer.scrobbleTo( (seekOffset+ns.time)*1000 );
		soundPlayer.pause();
		
		// show loader
		loading_status_wnd.visible = true;
		
		// unload forced subs
		if(forcedSubtitles != null && forcedSubtitles.hasOwnProperty(defaultSoundName) && subBar.selectedIndex == 0){
			loadSubtitles("unload", true);
		}
	}
}

/**
 * Subtitles stuff
 */
private function parseSubtitiles(subtitiles:Array):void{
	//trace(ObjectUtil.toString(subtitiles));
	subArray = subtitiles;
	subNames = new ArrayCollection();
	subNames.addItem({label: "off"});
	var i:int = 0;
	for(i = 0; i < subtitiles.length; i++){
		if(String(subtitiles[i]).indexOf("_1.") > 0 || String(subtitiles[i]).indexOf("_ru.") > 0){
			subNames.addItem({label: "ru"});
			//subNames.push("ru");
		}
		if(String(subtitiles[i]).indexOf("_2.") > 0 || String(subtitiles[i]).indexOf("_en.") > 0){
			subNames.addItem({label: "en"});
			//subNames.push("en");
		}
	}
	
	if(subNames.length > 1) isSubSwitch = true;
	
	if(_autoloadSub){
		trace(ObjectUtil.toString(forcedSubtitles))
		if(forcedSubtitles != null && forcedSubtitles.hasOwnProperty(defaultSoundName)){
			subBar.selectedIndex = 0;
			loadSubtitles(forcedSubtitles[defaultSoundName]);
		}else{
			subBar.selectedIndex = 1;
			loadSubtitles(subtitiles[0]);
		}
	}
}

private function loadSubtitles(subURL:String, forceUnload:Boolean = false):void{	
	// clean up stuff
	if(isSub && subCurrent != null && subCurrent.length > 0){
		// clear old from screen
		var c:Caption;
		for each(c in subCurrent){
			if(c.active) c.unsub();
		}
	}
	isSub = false;
	subs = [];
	subCurrent = [];
	var forced:Boolean = false;
	if(subURL == "unload"){
		if(!forceUnload && forcedSubtitles != null && forcedSubtitles.hasOwnProperty(defaultSoundName)){
			forced = true;
			subURL = forcedSubtitles[defaultSoundName];
		}else{
			isSubSwitch = true;
			return;
		}
	}
	// load subs
	trace('load sub: '+subURL);
	var subLoad:Subtitle = new Subtitle(this, subURL);
	subLoad.addEventListener("SubParsed", function():void{
		subs = subLoad.captions;
		subs.sortOn("begin", Array.NUMERIC);
		
		//trace( ObjectUtil.toString(subs) )
		
		subIndex = 0;
		isSub = true;
		
		subLoad = null;
	}, false, 0, false);
	subLoad.addEventListener(ErrorEvent.ERROR, function():void{
		if(!forced) Alert.show("Субтитры не найдены! Сообщите пожалуйста администрации!", "Ошибка");
	}, false, 0, false);
	subLoad.parse();
	
}

private function setSubtitles(time:Number):void{
	if( isNaN(subIndex) || subs == null || subs.length < 1 ) return;
	// add subs to current
	var sub:Caption;
	//var del:Boolean = false;
	var i:int = 0;
	while( subs[subIndex].begin <= time ) {
		if( subs[subIndex].end >= time && subCurrent.indexOf(subs[subIndex]) < 0 ){
			sub = subs[subIndex];
			subCurrent.push(sub);
			sub.sub();
		}
		if(subIndex < subs.length-1){
			subIndex++;
		}else{
			break;
		}
	}
	
	// delete old subs
	var del:Boolean = false;
	for each(sub in subCurrent) {
		if( sub.end <= time ){//|| (sub.begin > (time + 3) ) ){ //
			del = true;
			sub.unsub();
			i = subCurrent.indexOf(sub);
		}
	}
	
	if(del && subCurrent.length > 1){
		// resub
		for each(sub in subCurrent) {
			if( sub.active ){
				sub.unsub(false);
				sub.sub(false);
			}
		}
	}
	
	// clean
	sub = null;
}

/**
 * Setup listeners 
 * 
 */
private function setupListeners():void{
	// assign event listeners
	trace('assing events');
	
	// start gui timer
	hideTimer.start();
	
	// sv
	if(svAvailable){
		sv.addEventListener(StageVideoEvent.RENDER_STATE, stageVideoStateChange);
	}
	
	// refresh
	this.addEventListener(Event.ENTER_FRAME, onPlayerEnterFrame);
	// mouse stuff
	this.addEventListener(MouseEvent.MOUSE_DOWN, onMouseClick);
	// add mouse events if it's not mobile
	if( !_isMobile ){
		this.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
		this.doubleClickEnabled = true;
		this.addEventListener(MouseEvent.DOUBLE_CLICK, onDoubleClick);
		this.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
	}
	
	// keyboard stuff
	if(FlexGlobals.topLevelApplication.hasOwnProperty("nativeApplication")){
		FlexGlobals.topLevelApplication.nativeApplication.addEventListener(KeyboardEvent.KEY_UP, onPlayerKey);
	}else{
		this.stage.addEventListener(KeyboardEvent.KEY_UP, onPlayerKey);
	}
	
	// statuses
	ns.addEventListener(NetStatusEvent.NET_STATUS, onVideoState);
	
	// video progress
	video_progress.slider.addEventListener(FlexEvent.CHANGE_END, onSeek);
	video_progress.slider.dataTipFormatFunction = timeDataTip;
}

private function onMouseWheel(e:MouseEvent):void{
	if(e.delta > 0){
		volumeUp();
	}else{
		volumeDown();
	}
}

private function volumeUp():void{
	if(player_volume.value < 100){
		player_volume.value += 5;
	}
	volumeLevel = player_volume.value;
	
	if(isSoundPlaying){
		soundPlayer.volume = maxVolumeOverride * (player_volume.value/100);
	}else{	
		ns.soundTransform = new SoundTransform( maxVolumeOverride * (player_volume.value/100) );
	}
}

private function volumeDown():void{
	if(player_volume.value > 5){
		player_volume.value -= 5;
	}
	volumeLevel = player_volume.value;
	
	if(isSoundPlaying){
		soundPlayer.volume = maxVolumeOverride * (player_volume.value/100);
	}else{	
		ns.soundTransform = new SoundTransform( maxVolumeOverride * (player_volume.value/100) );
	}
}

/**
 * Double click handler 
 * @param e
 * 
 */
private function onDoubleClick(e:Event):void{
	if( player_controls.mouseY < 0 ){
		toggleFullScreen();
	}
	//video_player.setFocus();
}

/**
 * On video view end 
 * @param e
 * 
 */
private function onVideoState(e:NetStatusEvent):void{
	if(e.info["code"] == "NetStream.Play.Stop" && int(seekOffset+ns.time) == int(totalDuration)){
		if(play_nonstop.selected){
			nextEpisode();
		}else{
			this.dispatchEvent(new Event(ON_END));
			// toggle next episode wnd
			/*if(player_next_ep_txt.text != "null")
				player_episodes_wnd_1.visible = true;
			// toggle prev episode wnd
			if(player_prev_ep_txt.text != "null")
				player_episodes_wnd.visible = true;*/
			// toggle video controls
			hideTimer.stop();
			player_controls.visible = true;
			player_data.visible = true;
			Mouse.show();
		}
	}
}

/**
 * GUI hide timer event 
 * @param e
 * 
 */
private function onHideTimer(e:Event):void{
	if(video_progress.getFocus() != video_progress){
		//player_controls.visible = false;
		//player_data.visible = false;
		//player_volume.visible = false;
		Mouse.hide();
	}
	
	//if( player_data_bg.mouseY > player_data_bg.height ){
	player_data_bg.visible = false;
	//}
	
	if( this.mouseY < (this.parent.height - 40) || this.mouseY > this.parent.height  ){
		player_controls.visible = false;
	}
	
	/*if( player_subselect.mouseX < 0 || player_subselect.mouseY < 0 ||
	player_subselect.mouseX > player_subselect.width ||
	player_subselect.mouseY > player_subselect.height){*/
	player_subselect.visible = false;
	//}
	
	/*if( player_sndselect.mouseX < 0 || player_sndselect.mouseY < 0 ||
	player_sndselect.mouseX > player_sndselect.width ||
	player_sndselect.mouseY > player_sndselect.height){*/
	player_sndselect.visible = false;
	//}
}

/**
 * GUI show on mouse move
 * @param e
 * 
 */
private function onMouseMove(e:Event):void{
	//player_controls.visible = true;
	//player_data.visible = true;
	Mouse.show();
	
	// if mouse is over controls
	//if( mouseY > (parent.height - 36) ){ // do not hide
	player_controls.visible = true;
	//hideTimer.stop();
	//}else if( mouseY < 40 ){
	//player_data_bg.visible = true;
	//}else if( mouseY < 40 ){
	player_data_bg.visible = true;
	/*}else if( player_subselect.mouseX >= 0 && player_subselect.mouseY >= 0 && 
	player_subselect.mouseX <= player_subselect.width &&
	player_subselect.mouseY <= player_subselect.height &&*/
	if(isSubSwitch)
		player_subselect.visible = true;
	/*}else if( player_sndselect.mouseX >= 0 && player_sndselect.mouseY >= 0 && 
	player_sndselect.mouseX <= player_sndselect.width &&
	player_sndselect.mouseY <= player_sndselect.height &&*/
	if(isSndSwitch)
		player_sndselect.visible = true;
	//}else{ // otherwise hide
	if( int(seekOffset+ns.time) != int(totalDuration) ){
		hideTimer.start();
	}
	//}
}

/**
 * On click
 * @param e
 * 
 */
private function onMouseClick(e:Event):void{
	if(_isMobile && !player_controls.visible){
		onMouseMove(e);
		return;
	}
	
	if( !(this.mouseY > (this.parent.height - 36) || 
		(player_subselect.contentMouseX >= 0 && player_subselect.contentMouseY >= 0 && 
			player_subselect.contentMouseX <= player_subselect.width &&
			player_subselect.contentMouseY <= player_subselect.height &&
			isSubSwitch) || 
		(player_sndselect.contentMouseX >= 0 && player_sndselect.contentMouseY >= 0 && 
			player_sndselect.contentMouseX <= player_sndselect.width &&
			player_sndselect.contentMouseY <= player_sndselect.height &&
			isSndSwitch) || 
		(fullscreen_btn.contentMouseX >= 0 && fullscreen_btn.contentMouseX <= fullscreen_btn.width &&
			fullscreen_btn.contentMouseY >= 0 && fullscreen_btn.mouseY <= fullscreen_btn.height)
		|| (this.mouseY < 40)
	) ){
		togglePlayPause();
	}
	
	
}

private function sendUpdateTime():void{
	updateTime = saveTime;
	// dispatch update time event
	this.dispatchEvent(new Event(UPDATE_TIME));
}

/**
 * Report play progress on enter frame 
 * @param e
 * 
 */
private function onPlayerEnterFrame(e:Event):void{
	// remember time
	if( saveTime == -1 ){
		saveTime = seekOffset+ns.time;
	}else{
		if( Math.abs( (seekOffset+ns.time) - saveTime ) > 20 ){
			saveTime = seekOffset+ns.time;
			sendUpdateTime();
		}
	}
	//time = seekOffset+ns.time;
	// set labels
	setTime(ns.time);
	// set progress
	setProgress(ns.bytesLoaded/ns.bytesTotal * 100);
	// set thumb
	if(video_progress.getFocus() != video_progress){
		video_progress.position = seekOffset + ns.time;
	}
	// set subs
	if(isSub){
		//removeSubtitles(seekOffset+ns.time);
		setSubtitles(seekOffset+ns.time);
	}
	// sync sound
	if( soundPlayer && isSoundPlaying ){
		var delta:Number = (seekOffset+ns.time) - soundPlayer.currentMiliseconds/1000;
		if( delta > 0.3 || delta < -0.3 ){
			//trace('delta: '+delta, ' vid: '+(seekOffset+ns.time), ' sound: '+soundPlayer.currentSeconds);
			soundPlayer.scrobbleTo( (seekOffset+ns.time)*1000 );
		}
		if(!firstSndPlay && soundPercent != 1 && soundPercent < ( (seekOffset+ns.time)/totalDuration + 0.05 )  ){
			togglePlayPause(true);
			firstSndPlay = true;
			loading_status_wnd.visible = true;
		}
	}
	// set episode watched
	/*if( int(seekOffset+ns.time) >= int(totalDuration*0.8) && !watchedReport ){
	// set ep watched
	//setEpisodeWatched(currentEpisode);
	watchedReport = true;
	dispatchEvent(new Event(EPISODE_WATCHED));
	}*/
}

/**
 * Handle metadata from file 
 * @param infoObject
 * 
 */
private function metaDataHandler(infoObject:Object):void {
	if(totalDuration == 0){
		setupListeners();
		
		setMaximumDur(infoObject["duration"]);
		// save sizes
		origWidth = infoObject["width"];
		origHeight = infoObject["height"];
		// set size
		if(svAvailable){
			resizeStageVideo();
		}else{
			vid.width = origWidth;
			vid.height = origHeight;
			onVideoResize();
		}
		
		loading_wnd.visible = /*loading_spin.isLoading =*/ preview_img.visible = false;
		//loading_text.visible = false;
		
		// seek if already watched
		if( startPos > -1 ){
			if( Math.abs(totalDuration-startPos) < 60 ) startPos -= 60;
			video_progress.slider.value = startPos;
			onSeek(null);
		}
		
		if(!_autoplay){
			playpause.select = playState;
			playState = !playState;
			ns.pause();
		}
		
	}else{
		seekOffset = totalDuration - Number(infoObject["duration"]);
		rescaleProgress();
		if(isSub){
			// clear view
			while(subtitles_mc.numChildren > 0) subtitles_mc.removeChildAt(0);
			// remove all current
			subCurrent = [];
			// set index
			subIndex = 0;
			// resub
			setSubtitles(seekOffset - 10);
		}
		if(soundPlayer){
			soundPlayer.play();
			soundPlayer.scrobbleTo(seekOffset*1000);
			//soundChannel = soundTrack.play(seekOffset*1000);
			if(soundPercent != 1 && soundPercent < ( (seekOffset+ns.time)/totalDuration + 0.05)  ){
				togglePlayPause(true);
				firstSndPlay = true;
				loading_status_wnd.visible = true;
			}
		}
	}
	/*for (var prop:String in infoObject){
	trace(prop+" : "+infoObject[prop]);
	}*/
}

/**
 * Seeking 
 * @param e
 * 
 */
private function onSeek(e:Event):void{
	var bufferedTime:Number = (ns.bytesLoaded/ns.bytesTotal) * totalDuration;
	var seekTime:Number = video_progress.slider.value;
	if(seekTime < (bufferedTime + seekOffset) && seekTime >= seekOffset ){
		ns.seek(seekTime - seekOffset);
	}else{
		seekOffset = seekTime;
		if(soundPlayer) soundPlayer.pause();
		ns.play(videoURL+"?start="+seekTime);
	}
	if(!playState){
		playpause.select = playState;
		playState = !playState;
		//video_player.setFocus();
		if(playState){
			this.dispatchEvent(new Event(ON_PLAY));
		}else{
			this.dispatchEvent(new Event(ON_PAUSE));
		}
	}
	// clean subs and sounds
	if(seekOffset != seekTime){
		if(soundPlayer){
			soundPlayer.scrobbleTo(seekTime*1000);
		}
		if(isSub){
			// clear view
			while(subtitles_mc.numChildren > 0) subtitles_mc.removeChildAt(0);
			// remove all current
			subCurrent = [];
			// set index
			subIndex = 0;
			// resub
			setSubtitles(seekTime - 10);
		}
	}
	//
	hideTimer.start();
	//video_player.setFocus();
}

/**
 * Toggle play/pause 
 * 
 */
private function togglePlayPause(ignoreBuffer:Boolean = false):void{
	if( !ignoreBuffer && soundPlayer != null && soundPercent != 1 && soundPercent < ( (seekOffset+ns.time)/totalDuration + 0.05)  ) return; 
	playpause.select = playState;
	playState = !playState;
	if( soundPlayer != null && soundPlayer.playlist.length > 0 ) {
		if( isSoundPlaying ){
			//soundPausePoint = soundChannel.position;
			soundPlayer.pause();
			isSoundPlaying = false;
		}else{
			//soundChannel = soundTrack.play(soundPausePoint);
			soundPlayer.play();
			isSoundPlaying = true;
		}
	}
	if(ns)
		ns.togglePause();
	//video_player.setFocus();
	if(playState){
		this.dispatchEvent(new Event(ON_PLAY));
	}else{
		this.dispatchEvent(new Event(ON_PAUSE));
	}
}

/**
 * Toggle fullscreen 
 * 
 */
private function toggleFullScreen():void{
	switch (this.stage.displayState) {
		case StageDisplayState.FULL_SCREEN:
		case StageDisplayState.FULL_SCREEN_INTERACTIVE:
			/* If already in full screen mode, switch to normal mode. */
			this.stage.displayState = StageDisplayState.NORMAL;
			
			if(svAvailable){
				resizeStageVideo();
			}else{
				onVideoResize();
			}
			
			// dispatch notifying event
			this.dispatchEvent(new Event(ON_EXIT_FULLSCREEN));
			
			//player_controls.bottom = "50";
			break;
		default:
			/* If not in full screen mode, switch to full screen mode. */
			//stage.fullScreenSourceRect = new Rectangle(0,0,stage.width,stage.height);
			switch (Capabilities.playerType) {
				case 'Desktop':
					//air runtime
					this.stage.displayState = StageDisplayState.FULL_SCREEN_INTERACTIVE;
					break;
				case 'PlugIn':
				case 'ActiveX':
					//browser
					this.stage.displayState = StageDisplayState.FULL_SCREEN;
					break;
			}
			
			if(svAvailable){
				resizeStageVideo();
			}else{
				onVideoResize();
			}
			
			// dispatch notifying event
			this.dispatchEvent(new Event(ON_ENTER_FULLSCREEN));
			
			//player_controls.bottom = "135";
			break;
	}
	//subText = '';
	//video_player.setFocus();
	
	if(svAvailable) resizeStageVideo();
}

/**
 * Resize video 
 * 
 */
private function onVideoResize():void{	
	if(vid == null) return;
	// rescale saving proportions
	switch(ratio_list.selectedItem.data){
		default:
		case "orig":
			if(this.height > (origHeight*(video_player.width/origWidth)) ){
				vid.width = video_player.width;
				vid.height = origHeight*(video_player.width/origWidth);
				vid.y = (video_player.height - vid.height)/2;
				vid.x = 0;
			}else{
				vid.height = video_player.height;
				vid.width = origWidth*(video_player.height/origHeight);
				vid.x = (video_player.width - vid.width)/2;
				vid.y = 0;
			}
			break;
		case "horizontal":
			vid.width = video_player.width;
			vid.height = origHeight*(video_player.width/origWidth);
			vid.y = (video_player.height - vid.height)/2;
			vid.x = 0;
			break;
		case "vertical":
			vid.height = video_player.height;
			vid.width = origWidth*(video_player.height/origHeight);
			vid.x = (video_player.width - vid.width)/2;
			vid.y = 0;
			break;
	}	
	// rescale sub
	for each(var s:Caption in subCurrent){
		if(s.active){
			s.unsub(); 
			s.sub();
		}
	}
}

/**
 * Set play time for GUI
 * @param duration
 * 
 */
private function setTime(duration:Number):void{
	duration += seekOffset;
	
	var min:int = duration/60;
	var secs:String = String( int(duration - min*60) );
	var hour:int = int(duration/(60*60));
	
	if(hour > 0){
		min -= hour*60;		
	}
	
	var mins:String = String( min );
	var hours:String = String( hour );
	
	if(mins.length == 1) mins = "0"+mins;
	if(secs.length == 1) secs = "0"+secs;
	
	var dur:String = hours + ":" + mins + ":" + secs;
	
	//video_time_end.text = maxDur;
	video_time.text = dur;
}

/**
 * Set video length string 
 * @param duration
 * 
 */
private function setMaximumDur(duration:Number):void{
	video_progress.slider.minimum = 0;
	video_progress.slider.maximum = duration;
	totalDuration = duration;
	
	var min:int = duration/60;
	var secs:String = String( int(duration - min*60) );
	var hour:int = int(duration/(60*60));
	
	if(hour > 0){
		min -= hour*60;		
	}
	
	var mins:String = String( min );
	var hours:String = String( hour );
	
	if(mins.length == 1) mins = "0"+mins;
	if(secs.length == 1) secs = "0"+secs;
	
	maxDur = hours + ":" + mins + ":" + secs;
	video_time_end.text = maxDur;
}

/**
 * Rescale progressbar on seek 
 * 
 */
private function rescaleProgress():void{				
	//progLeft = 40+video_seek.thumb.x;
	//video_progress.setProgress( (seekOffset+ns.time)/totalDuration, totalDuration );
	//asd
	video_progress.offset = (seekOffset+ns.time)/totalDuration;
}

/**
 * Set progress 
 * @param progress
 * 
 */
private function setProgress(progress:Number):void{
	video_progress.progress = progress/100;
}

/**
 * Set volume 
 * 
 */
private function setVolume():void{
	if(isSoundPlaying){
		if(soundPlayer)
			soundPlayer.volume = maxVolumeOverride * (player_volume.value/100);
	}else{
		if(ns)
			ns.soundTransform = new SoundTransform( maxVolumeOverride * (player_volume.value/100) );
	}
	volumeLevel = player_volume.value;
	trace( maxVolumeOverride * (volumeLevel/100) );
	//video_player.setFocus();
}

/**
 * Data tip for time slider 
 * @param val
 * @return 
 * 
 */
private function timeDataTip(val:String):String{
	var duration:Number = Number(val);
	
	//var mins:String = String( int(duration/60) );
	var min:int = duration/60;
	var secs:String = String( int(duration - min*60) );
	//var hours:String = String( int(duration/(60*60)) );
	var hour:int = int(duration/(60*60));
	
	if(hour > 0){
		min -= hour*60;		
	}
	
	var mins:String = String( min );
	var hours:String = String( hour );
	
	if(mins.length == 1) mins = "0"+mins;
	if(secs.length == 1) secs = "0"+secs;
	
	return hours + ":" + mins + ":" + secs;
}

/**
 * Player cleanup 
 * 
 */
public function resetPlayer(nofullscreen:Boolean = true):void{
	// reset controls
	video_progress.reset();
	video_time_end.text = "0:00:00";
	video_time.text = "0:00:00";
	subCurrent = null;
	
	// reset buttons
	if(nofullscreen){
		if(playState){
			playpause.select = playState;
			playState = false;
		}
		//playpause.resetState();
	}
	
	// reset above all
	above_all.resetState();
	
	// reset watch
	watchedReport = false;
	
	// show loader
	loading_wnd.visible = /*loading_spin.isLoading =*/ preview_img.visible = true;
	//loading_text.visible = true;
	
	// reset next and prev windows
	/*player_episodes_wnd.visible = false;
	player_episodes_wnd_1.visible = false;
	player_next_ep_txt.text = "null";
	player_prev_ep_txt.text = "null";*/
	
	
	// reset fullscreen
	if (nofullscreen && this.stage.displayState == StageDisplayState.FULL_SCREEN_INTERACTIVE){
		/* If already in full screen mode, switch to normal mode. */
		this.stage.displayState = StageDisplayState.NORMAL;
		
		//player_controls.bottom = "75";
	}
	
	// reset on top
	if(nofullscreen && FlexGlobals.topLevelApplication.hasOwnProperty("nativeWindow") && FlexGlobals.topLevelApplication.nativeWindow.alwaysInFront){
		FlexGlobals.topLevelApplication.nativeWindow.alwaysInFront = !FlexGlobals.topLevelApplication.nativeWindow.alwaysInFront;
		above_all.selected = false;
		//above_all.text = "'";
	}
	
	// clean listeners
	if(ns)
		ns.removeEventListener(NetStatusEvent.NET_STATUS, onVideoState);
	video_player.removeEventListener(KeyboardEvent.KEY_UP, onPlayerKey);
	this.removeEventListener(MouseEvent.CLICK, onMouseClick);
	this.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
	this.removeEventListener(Event.ENTER_FRAME, onPlayerEnterFrame);
	
	// remove timer
	if(hideTimer)
		hideTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, onHideTimer);
	hideTimer = null;
	
	// clear sub
	while(subtitles_mc.numChildren > 0) subtitles_mc.removeChildAt(0);
	
	// clear sound
	if( soundPlayer ){
		soundPlayer.stop();
		soundPlayer.destroy();
		soundPlayer = null;
	}
	
	// clear video
	if(vid)
		vid.clear();
	if(ns)
		ns.close();
	while(video_player.numChildren > 0) video_player.removeChildAt(0);
	
	// clean vars
	ns = null;
	vid = null;
	
	// force GC
	startGCCycle();
}

/**
 * On key press callback 
 * @param event
 * 
 */
private function onPlayerKey(event:KeyboardEvent):void{
	switch(event.keyCode){
		case Keyboard.SPACE:
			togglePlayPause();
			break;
		case Keyboard.F:
			toggleFullScreen();
			break;
		case Keyboard.UP:
			volumeUp();
			break;
		case Keyboard.DOWN:
			volumeDown();
			break;
		case Keyboard.LEFT:
			if(ns.time < 10) break;
			// clean
			// clean subs
			if(isSub){
				subCurrent = [];
				while(subtitles_mc.numChildren > 0) subtitles_mc.removeChildAt(0);
				subIndex = 0;
			}
			setSubtitles(ns.time-8);
			// set time
			ns.seek(ns.time - 10);
			break;
		case Keyboard.RIGHT:
			if(ns.time > totalDuration) break;
			// clean
			// clean subs
			if(isSub){
				subCurrent = [];
				while(subtitles_mc.numChildren > 0) subtitles_mc.removeChildAt(0);
				subIndex = 0;
			}
			setSubtitles(ns.time+8);
			// set time
			ns.seek(ns.time + 10);
			break;
		case Keyboard.M:
			toggleMute();
			break;
		case Keyboard.Q:
			returnView();
			break;
	}
}

private function toggleMute():void{
	if(player_volume.value != 0){
		volumeLevel = player_volume.value;
		player_volume.value = 0;
	}else{
		player_volume.value = volumeLevel;
	}
	setVolume();
}

private function returnView():void{
	// reset ontop
	if(FlexGlobals.topLevelApplication.hasOwnProperty("nativeWindow"))
		FlexGlobals.topLevelApplication.nativeWindow.alwaysInFront = false;
	// reset player
	resetPlayer();
	//
	Mouse.show();
	// event
	this.dispatchEvent(new Event(RETURN_VIEW)); 
}

private function prevEpisode():void{
	// reset player
	resetPlayer(false);
	
	// play prev
	//series_video_list.selectedIndex += 1;
	//series_video_list.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
	this.dispatchEvent(new Event(PLAY_PREV)); 
} 

private function nextEpisode():void{
	// reset player
	resetPlayer(false);
	
	// play prev
	//series_video_list.selectedIndex -= 1;
	//series_video_list.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
	this.dispatchEvent(new Event(PLAY_NEXT)); 
}

private function aboveAll():void{
	FlexGlobals.topLevelApplication.nativeWindow.alwaysInFront = !FlexGlobals.topLevelApplication.nativeWindow.alwaysInFront;
	//if(nativeWindow.alwaysInFront){
	//above_all.text = ';';
	//}else{
	//above_all.text = "'";
	//}
}

protected function ratio_list_openHandler(event:DropDownEvent):void{
	// TODO Auto-generated method stub
	hideTimer.stop();
}


protected function ratio_list_closeHandler(event:DropDownEvent):void{
	// TODO Auto-generated method stub
	hideTimer.start();
	//video_player.setFocus();
}

// advanced garbage collection
// ---------------------------
/**
 * GC counter 
 */
private var gcCount:int;

/**
 * Starts GC
 */
private function startGCCycle():void{
	gcCount = 0;
	this.addEventListener(Event.ENTER_FRAME, doGC);
}

/**
 * GC Timer proc, does the collection
 * @param evt
 * 
 */
private function doGC(evt:Event):void{
	flash.system.System.gc();
	if(++gcCount > 1){
		this.removeEventListener(Event.ENTER_FRAME, doGC);
		setTimeout(lastGC, 40);
	}
}

/**
 * Last GC, to be sure 
 */
private function lastGC():void{
	flash.system.System.gc();
}


protected function subBar_itemClickHandler(event:Event):void{
	if( subBar.selectedIndex == -1 ) return;
	var i:int = subBar.selectedIndex - 1;
	if( i >= 0 && i < subArray.length ){
		loadSubtitles(subArray[i]);
	}else{
		loadSubtitles("unload");
	}
}

protected function sndBar_itemClickHandler(event:Event):void{
	if( sndBar.selectedIndex == -1 ) return;
	var i:int = sndBar.selectedIndex - 1;
	if( i >= 0 && i < sndArray.length ){
		loadSound(sndArray[i]);
	}else{
		loadSound("unload");
	}
}
