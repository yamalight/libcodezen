package com.codezen.helper {
    import flash.events.IOErrorEvent;
    import flash.net.URLLoader;
    import flash.net.URLLoaderDataFormat;
    import flash.net.URLRequest;

    public class WebWorker extends Worker {
        // loader and request
        protected var urlRequest:URLRequest;
        protected var myLoader:URLLoader;

        public function WebWorker() {
            // init request and loader
            urlRequest = new URLRequest();
            myLoader = new URLLoader();
            // set params and add error event listener
            //myLoader.dataFormat = URLLoaderDataFormat.TEXT;
            myLoader.addEventListener(IOErrorEvent.IO_ERROR, onError);
        }

        /**
         * Error parser
         **/
        protected function onError(e:IOErrorEvent):void{
            dispatchError(e.text, "IO Error happened in WebWorker class");
        }
    }
}
