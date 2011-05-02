package com.codezen.music.search
{
	import flash.events.IEventDispatcher;

	public interface ISearchProvider extends IEventDispatcher
	{
		function get result():Array;
		function search(query:String):void;
	}
}