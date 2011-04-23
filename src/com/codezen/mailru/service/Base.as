package com.codezen.mailru.service
{
	import com.codezen.helper.WebWorker;
	
	import flash.events.Event;
	
	import mx.controls.HTML;
	import mx.core.Window;
	
	public class Base extends WebWorker
	{
		// app data
		protected var appID:String;
		protected var appKey:String;
		
		// initialized state
		protected var initialized:Boolean;
		
		// auth data
		protected var ref_token:String;
		protected var access_token:String;
		protected var type_token:String;
		protected var exp_in:String;
		protected var user_id:String;
		
		// auth wnd
		protected var html:HTML;
		protected var window:Window;
		
		public function Base(appID:String, appKey:String)
		{
			super();
			
			this.appID = appID;
			this.appKey = appKey;
			
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
			window.title = "Mail.ru Authorization";
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
			
			html.location = "https://connect.mail.ru/oauth/authorize?client_id="+appID+"&response_type=token&scope=widget&redirect_uri=http%3A%2F%2Fconnect.mail.ru%2Foauth%2Fsuccess.html";
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
			if (html.location.indexOf("mail.ru/oauth/success.html#") > 0 ){
				// remove event litener
				html.removeEventListener(Event.LOCATION_CHANGE, onLocationChange);
				
				/*
				refresh_token=0ee115be28be895641064da23522c815&
				expires_in=86400&
				access_token=c3b3b8f1c0742b996638ec392534de5b&
				token_type=bearer&
				x_mailru_vid=9314018550009422117
				*/
				var re:RegExp = new RegExp(/refresh_token=(.+?)&expires_in=(.+?)&access_token=(.+?)&token_type=(.+?)&x_mailru_vid=(.+)/gs);
				// 7.2.2011 - {"mid":47636,"secret":"0eafe29608","sid":"fe30000f3d1174ab3f72e8b92ed49e47c818787c6ab7a75623aa90c896a9fc","expire":0}
				var res:Array = re.exec( decodeURIComponent(html.location) );
				
				if( res != null ){
					ref_token = res[1];
					exp_in = res[2];
					access_token = res[3];
					type_token = res[4];
					user_id = res[5];
				}else{
					dispatchError("Cannot login correctly. Mail.ru server problems. Try later");
				}
				
				initialized = true;
				
				window.close();
				
				window = null;
				html = null;
				
				endLoad();
			}else if( html.location.indexOf("login_failure") > 0 ){
				// remove event litener
				html.removeEventListener(Event.LOCATION_CHANGE, onLocationChange);
				
				window.close();
				
				window = null;
				html = null;
				
				dispatchError("Login error!");
			}
		}
	}
}