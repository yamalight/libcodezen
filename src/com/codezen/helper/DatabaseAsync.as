package com.codezen.helper
{
	import flash.data.SQLConnection;
	import flash.data.SQLResult;
	import flash.data.SQLStatement;
	import flash.events.Event;
	import flash.events.SQLErrorEvent;
	import flash.events.SQLEvent;
	import flash.filesystem.File;
	
	import mx.utils.ObjectUtil;
	
	/**
	 * 
	 * @author yamalight
	 * 
	 * Database basic class.
	 * Used as base for classes, working with local SQLite databases
	 * Should be extended
	 * 
	 */
	public class DatabaseAsync extends Worker
	{
		// database file name
		protected var file:String = 'default.db';
		// connection var
		private var conn:SQLConnection;
		
		// result var
		private var sqlResult:SQLResult;
		
		// statement for initial table creation
		protected var createStatement:String; 
		
		// closed event
		public static var CLOSED:String = "Closed";
		
		/**
		 * Constructor 
		 */
		public function DatabaseAsync()
		{
			doInit();
		}
		
		private function doInit():void{
			// create connection
			conn = new SQLConnection();
			
			// assign listeners
			conn.addEventListener(SQLEvent.OPEN, onDatabaseOpen);
			conn.addEventListener(SQLErrorEvent.ERROR, errorHandler);
			
			// get currently dir   
			var dbFile:File = File.applicationStorageDirectory.resolvePath(file);
			
			// open database,If the file doesn't exist yet, it will be created
			conn.openAsync(dbFile);
			
			dbFile = null;
		}
		
		/**
		 * 
		 * @return result of query as SQLResult 
		 * 
		 */
		public function get result():SQLResult{
			return sqlResult;
		}
		
		/**
		 * Closes connection with db 
		 */
		public function closeConnection():void{
			conn.addEventListener(SQLEvent.CLOSE, onConnectionClose); 
			conn.close();
		}
		
		/**
		 * On close 
		 * @param e
		 * 
		 */
		private function onConnectionClose(e:SQLEvent):void{
			conn.removeEventListener(SQLEvent.CLOSE, onConnectionClose);
			dispatchEvent(new Event(DatabaseAsync.CLOSED));
		}
		
		/**
		 * Opens connection to database to work with 
		 */
		private function onDatabaseOpen(e:SQLEvent):void{			
			// init db
			initDatabase();
		}
		
		/**
		 * Error event 
		 * @param e
		 * 
		 */
		private function errorHandler(e:SQLErrorEvent):void{
			trace(e.toString());
		}
		
		/**
		 * Database initialization - creation of table 
		 */
		private function initDatabase():void{
			// db statement
			var dbStatement:SQLStatement = new SQLStatement();
			dbStatement.addEventListener(SQLErrorEvent.ERROR, errorHandler);
			// assign connection to statement
			dbStatement.sqlConnection = conn;
			// set statement text
			dbStatement.text = createStatement;
			
			// add event listener
			dbStatement.addEventListener(SQLEvent.RESULT, onInitResult);
			
			// try executing
			dbStatement.execute();
		}
		
		/**
		 * On init result
		 * @param e
		 * 
		 */
		private function onInitResult(e:SQLEvent):void{
			e.target.removeEventListener(SQLEvent.RESULT, onInitResult);
			dispatchEvent(new Event(Event.INIT));
		}
		
		/**
		 * 
		 * @param query
		 * 
		 * Sends query to database
		 */
		protected function queryDatabase(query:String, params:Array = null):void{
			// db statement
			var dbStatement:SQLStatement = new SQLStatement();
			dbStatement.addEventListener(SQLErrorEvent.ERROR, errorHandler);
			// assign connection to statement
			dbStatement.sqlConnection = conn;
			// reset result
			sqlResult = new SQLResult();
			// assign query
			dbStatement.text = query;
			// params
			if(params != null && params.length > 0){
				var param:String;
				var data:String;
				var i:int;
				for(i = 0; i < params.length; i++){
					param = params[i][0];
					data = params[i][1];
					dbStatement.parameters[param] = data;
				}
			}
			// add event listener
			dbStatement.addEventListener(SQLEvent.RESULT, onQueryResult);
			
			// try executing
			dbStatement.execute();
		}
		
		/**
		 * 
		 * @param e
		 * 
		 * Catches result recieve
		 */
		private function onQueryResult(e:SQLEvent):void{
			// remove event listener
			e.target.removeEventListener(SQLEvent.RESULT, onQueryResult);
			// set result
			sqlResult = e.target.getResult();			
			// alert end load
			endLoad();
		}
	}
}