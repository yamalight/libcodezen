package com.codezen.util
{
	import com.codezen.helper.Worker;
	
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.net.URLRequest;
	import flash.net.URLStream;
	import flash.utils.ByteArray;
	
	import mx.collections.ArrayCollection;
	
	import utils.serials.Episode;

	/**
	 * Helper to read a file from a server and save it on user's local
	 * machine.
	 *  
	 * @author yamalight
	 * 
	 */
	public class DownloadHelper extends Worker
	{
		import flash.filesystem.File;
		import flash.filesystem.FileMode;
		import flash.filesystem.FileStream;
	    
	    private var request:URLRequest; 
		private var stream:URLStream;
		private var fileStream:FileStream;
		private var file:File;
				
		private var downloadPath:String;
		private var downloadFile:String;
		
		public function DownloadHelper(fileLocalLocation:String = null)
		{
			if(fileLocalLocation != null && fileLocalLocation.length > 1){
				downloadPath = fileLocalLocation+"/";
			}else{
				downloadPath = File.applicationStorageDirectory.resolvePath("download").nativePath+"/";
			}
			
			fileStream = new FileStream();
			stream = new URLStream();
			
			stream.addEventListener(ProgressEvent.PROGRESS, onDownloadProgress);
			stream.addEventListener(Event.COMPLETE, onDownloadComplete);
			stream.addEventListener(IOErrorEvent.IO_ERROR, onDownloadError);
			
			super();
		}
		
		/**
		 * Method to download a file from a server. 
		 * 
		 * @param fileURL the server URL
		 * @param fileLocalLocation the location to be saved
		 * 
		 */		
		public function downloadFileFromServer(fileName:String, fileURL:String):void
		{
			downloadFile = fileName;
			
			file = File.desktopDirectory.resolvePath(downloadPath+downloadFile);	
			request = new URLRequest(fileURL);
	        fileStream.openAsync(file, FileMode.WRITE);
			
	        stream.load(request);
		}
		
		public function cancelDownload():void{
			try{
				fileStream.close();
				stream.close();
				file.deleteFile();
			}catch(e:Error){
				trace(e.toString());
			}
		}
		
		public function set localPath(path:String):void{
			downloadPath = path+"/";
		}
		
		public function get localPath():String{
			return downloadPath;
		}
		
		public function get filename():String{
			return downloadFile;
		}
		
		protected function onDownloadError(e:ErrorEvent):void{
			//Alert.show(e.toString(), "Ошибка при загрузке!");
			dispatchError("File not found", '', false);
		}
		
        /**
         * Event handler to handle the async progress events.
         * 
         * @param event
         * 
         */		
        protected function onDownloadProgress(event:ProgressEvent):void 
        {
            var byteArray:ByteArray = new ByteArray();
            var value:Number = event.bytesLoaded;
            var total:Number = event.bytesTotal;
            var precent:Number = Math.round(value*100/total);
                            
            stream.readBytes(byteArray, 0, stream.bytesAvailable);
            fileStream.writeBytes(byteArray, 0, byteArray.length);
			
			var progressEvent:ProgressEvent = new ProgressEvent(ProgressEvent.PROGRESS);
			progressEvent.bytesLoaded = value;
			progressEvent.bytesTotal = total;
			
			this.dispatchEvent(progressEvent);
    	}
    	
    	/**
    	 * Event handler to handle the event complete.
    	 * 
    	 * @param event
    	 * 
    	 */    	
		protected function onDownloadComplete(event:Event):void
    	{
            fileStream.close();
            stream.close(); 
            
            /*stream.removeEventListener(ProgressEvent.PROGRESS, onDownloadProgress);
            stream.removeEventListener(Event.COMPLETE, onDownloadComplete);*/
            
			var completeEvent:Event = new Event(Event.COMPLETE);
			this.dispatchEvent(completeEvent);            
    	}		
	}
}