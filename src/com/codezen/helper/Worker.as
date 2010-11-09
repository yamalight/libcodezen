package com.codezen.helper
{	
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.ProgressEvent;
	
	import mx.controls.Alert;

	/**
	 *  
	 * @author yamalight
	 * 
	 * Base class for classes utilizing event dispatcher and status reports
	 */
	public class Worker extends EventDispatcher
	{		
		// Status var
		protected var status:String = 'Init me';
		protected var errorCode:int;
		
		public function Worker()
		{
		}
		
		/**
		 * Sets current status and dispatches status reporting event 
		 * @param status
		 * 
		 */
		protected function setStatus(status:String):void{
			this.status = status;
			// Dispatch progress event
			dispatchEvent(new Event(ProgressEvent.PROGRESS));
		}
		
		/**
		 * Sets and dispatches error reporting event 
		 * @param status
		 * 
		 */
		protected function dispatchError(status:String, title:String = "Error occured!", showAlert:Boolean = true, errorCode:int = 0):void{
			// show error
			//if(showAlert)
			//	Alert.show(status,title);
			// set error code
			this.errorCode = errorCode;
			// set status
			this.status = status;
			// Dispatch error event
			this.dispatchEvent(new ErrorEvent(ErrorEvent.ERROR, true, false, status));
		}
		
		/**
		 * 
		 * @returns search status 
		 * 
		 */
		public function get state():String{
			return status;
		}		
		
		/**
		 * 
		 * @returns error code
		 * 
		 */
		public function get errorcode():int{
			return errorCode;
		}		
		
		/**
		 * Dispatches end of load event and does cleanup 
		 */
		protected function endLoad():void{
			// Dispatch complete event
			dispatchEvent(new Event(Event.COMPLETE));
		}
	}
}