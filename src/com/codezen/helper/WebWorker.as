package com.codezen.helper {
    import flash.events.ErrorEvent;
    import flash.events.IOErrorEvent;
    import flash.events.SecurityErrorEvent;
    import flash.net.URLLoader;
    import flash.net.URLLoaderDataFormat;
    import flash.net.URLRequest;

    public class WebWorker extends Worker {
        // loader and request
        protected var myLoader:URLLoader;

        public function WebWorker() {
            // init request and loader
            myLoader = new URLLoader();
            // set params and add error event listener
            //myLoader.dataFormat = URLLoaderDataFormat.TEXT;
            myLoader.addEventListener(IOErrorEvent.IO_ERROR, onError);
			myLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onError);
        }

        /**
         * Error parser
         **/
        protected function onError(e:ErrorEvent):void{
            dispatchError(e.text, "URL req Error happened in WebWorker class");
        }
    }
}
