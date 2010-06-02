package com.codezen.helper
{
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.xml.XMLNode;
	
	import mx.collections.ArrayCollection;
	import mx.utils.ObjectUtil;

	public class Settings
	{
		private var file:String;
		
		public function Settings(filename:String)
		{
			file = filename;
		}
		
		public function loadPrefs():Array{
			// load prefs file from app dir
			var prefsFile:File = File.applicationStorageDirectory.resolvePath(file);
			// create new reading stream
			var stream:FileStream = new FileStream();
			// create new array collection of settings
			var settings:Array = new Array();
			// if file exists
			if (prefsFile.exists) {
				// read file
				stream.open(prefsFile, FileMode.READ);
				// create xml from file
				var prefsXML:XML = XML(stream.readUTFBytes(stream.bytesAvailable));
				// close stream
				stream.close();
				// fill vars
				var item:XML;
				for each(item in prefsXML.children()){
					settings[item.localName()] = item.text();
				}
			}
			
			item = null;
			prefsFile = null;
			stream = null;
			
			return settings;
		}
		
		public function save(settings:Array):void{
			var prefsXML:XML = <settings/>;
			
			// vkontakte
			var obj:Object; 
			var node:XML;
			for(obj in settings){
				prefsXML.appendChild(<{obj}>{settings[obj]}</{obj}>);
			}
			// create xml strign 
			var outputString:String = '<?xml version="1.0" encoding="utf-8"?>\n';
			// append data
			outputString += prefsXML.toXMLString();
			// remove string breaks
			outputString = outputString.replace(/\n/gs, File.lineEnding);
			// load prefs file from app dir
			var prefsFile:File = File.applicationStorageDirectory.resolvePath(file);
			// create new reading stream
			var stream:FileStream = new FileStream();
			// create new file if not exist and open
			stream.open(prefsFile, FileMode.WRITE);
			// write settings
			stream.writeUTFBytes(outputString);
			// close file
			stream.close();
			// reset vars
			prefsFile = null;
			stream = null;
			prefsXML = null;
		}

	}
}