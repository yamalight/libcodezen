package com.codezen.odnoklassniki.service
{
	import com.adobe.serialization.json.JSON;
	import com.codezen.helper.WebWorker;
	
	import flash.events.Event;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	
	import mx.controls.HTML;
	import mx.core.Window;
	import mx.utils.ObjectUtil;

	public class Base extends WebWorker
	{
		// app data
		protected var appID:String;
		protected var appKey:String;
		protected var appPubKey:String;
		
		// initialized state
		protected var initialized:Boolean;
		
		// auth data
		protected var code:String;
		protected var access_token:String;
		protected var refresh_token:String;
		protected var token_type:String;
		
		// auth wnd
		protected var html:HTML;
		protected var window:Window;
		
		public function Base(appID:String, appKey:String, appPubKey:String)
		{
			super();
			
			this.appID = appID;
			this.appKey = appKey;
			this.appPubKey = appPubKey;
			
			initialized = false;
			
			init();
		}
		
		/**
		 * Initializes class: checks if user already logged in 
		 * and if not - logs in.
		 * Must be executed before search 
		 */
		protected function init():void{
			//trace('VkBase init start');			
			// create window
			window = new Window();
			window.width = 600;
			window.height = 500;
			window.title = "Odnoklassniki.ru Authorization";
			window.alwaysInFront = true;
			window.resizable = false;
			window.showStatusBar = false;
			
			// init html
			html = new HTML();
			html.x = 0;
			html.y = 0;
			html.width = 600;
			html.height = 500;
			html.addEventListener(Event.LOCATION_CHANGE, onLocationChange);
			window.addElement( html );
			
			window.open(true);
			
			// http://www.odnoklassniki.ru/oauth/authorize?client_id={clientId}&scope={scope}&response_type={responseType}&redirect_uri={redirectUri}
			html.location = "http://www.odnoklassniki.ru/oauth/authorize?client_id="+appID+"&response_type=code&VALUABLE%20ACCESS&redirect_uri=about:blank";
		}
		
		/**
		 * 
		 * @param e
		 * 
		 * On recieve index page of vkontakte.ru
		 */
		private function onLocationChange(e:Event):void{
			trace(html.location);
			
			// check status 
			if (html.location.indexOf("?code=") > 0 ){
				// remove event litener
				html.removeEventListener(Event.LOCATION_CHANGE, onLocationChange);
				
				var re:RegExp = new RegExp(/code=(.+)/gs);
				// 7.2.2011 - {"mid":47636,"secret":"0eafe29608","sid":"fe30000f3d1174ab3f72e8b92ed49e47c818787c6ab7a75623aa90c896a9fc","expire":0}
				var res:Array = re.exec( decodeURIComponent(html.location) );
				
				if( res != null ){
					code = res[1];
				}else{
					dispatchError("Cannot login correctly. Odnoklassniki.ru server problems. Try later");
				}
				
				window.close();
				
				window = null;
				html = null;
				
				getToken();
				//endLoad();
			}else if( html.location.indexOf("&error=") > 0 ){
				// remove event litener
				html.removeEventListener(Event.LOCATION_CHANGE, onLocationChange);
				
				window.close();
				
				window = null;
				html = null;
				
				dispatchError("Login error!");
			}
		}
		
		private function getToken():void{			
			var vars:URLVariables = new URLVariables();
			vars.code = code;
			vars.redirect_uri = "about:blank";
			vars.grant_type = "authorization_code";
			vars.client_id = appID;
			vars.client_secret = appKey;
			
			urlRequest.url = "http://api.odnoklassniki.ru/oauth/token.do";
			urlRequest.method = URLRequestMethod.POST;
			urlRequest.data = vars;
			
			myLoader.addEventListener(Event.COMPLETE, onToken);
			myLoader.load(urlRequest);
		}
		
		private function onToken(e:Event):void{
			myLoader.removeEventListener(Event.COMPLETE, onToken);
			
			var data:Object = JSON.decode(myLoader.data);
			
			access_token = data.access_token;
			refresh_token = data.refresh_token;
			token_type = data.token_type; 
			
			initialized = true;
			endLoad();
		}
	}
}