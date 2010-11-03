package com.codezen.music.search
{
	import flash.events.IEventDispatcher;

	public interface ISearch extends IEventDispatcher
	{
		function findData(query:String, limit:int = 1, finddur:int = 0):void;
		function get resultString():String;
		function get classAlias():String;
		function get requireAuth():Boolean;
		function initAuth(login:String='', pass:String=''):void;
	}
}