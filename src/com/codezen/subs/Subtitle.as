/*
 * Original version created by Hoblin
 * Original source code can be found at https://github.com/hoblin/AS3-ASS-parser
 * This is a changed version that parses srt AND ass with small optimizations
 */

package com.codezen.subs{  
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.net.*;
	
	import mx.controls.Alert;
	
	public class Subtitle extends EventDispatcher
	{
		private var _owner:*;
		private var _captions:Array = [];
		
		private var ext:String = "ass";
		
		// ASS parser vars
		private var _mode:String;
		private var _file:String;
		private var _format:Array;
		private var _styles:Object = {};
		private var _styles_arr:Array = [];
		private var x_resolution:Number;
		private var y_resolution:Number;
		
		public function Subtitle(owner:*,subfile:String){
			_owner = owner;
			_file = subfile;
		}
		
		public function get captions():Array{
			return _captions;
		}
		
		public function get parsed():Boolean{
			return (_captions.length > 0);
		}
		
		public function parse():void{
			// loading file
			var subLoader:URLLoader = new URLLoader();
			subLoader.addEventListener(Event.COMPLETE, parseSubFile);
			if( ext == "ass"){
				subLoader.addEventListener(IOErrorEvent.IO_ERROR, onASSError);
			}else{
				subLoader.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
			}
			subLoader.load(new URLRequest(_file+ext));
		}
		
		private function onASSError(e:Event):void{
			ext = "srt";
			parse();
		}
		
		private function onIOError(e:Event):void{
			Alert.show("Субтитры не найдены! Сообщите пожалуйста администрации!", "Ошибка");
		}
		
		private function parseSubFile(evt:Event):void{
			if( ext == "ass" ){
				parseASS(evt.target.data);
			}else if( ext == "srt" ){
				parseSRT(evt.target.data);
			}
		}
		
		private function parseASS(dat:String):void{
			var stringsArr:Array = dat.split(/\r?\n/);
			var str:String;
			for each (str in stringsArr){
				if( str.length > 0 ) parseASSString(str)
			}
			dispatchEvent(new Event("SubParsed"));
		};
		
		private function parseASSString(dat:String):void{
			var blockReg:RegExp = /^\[([^\]]+)\]$/;
			var blockRes:Array = blockReg.exec(dat);
			
			var infoReg:RegExp = /^(?P<ident>\w+)\:\s?(?P<val>.+)(?:\s+)?$/g;
			var infoRes:Array = infoReg.exec(dat);
			
			var formatReg:RegExp = /^Format\:\s?((?:(?:\w+)\,?\s?)+)/g;
			var formatRes:Array = formatReg.exec(dat);
			
			var styleReg:RegExp = /^Style\:\s?((?:(?:[^,]*)\,?\s?)+)/g;
			var styleRes:Array = styleReg.exec(dat);
			
			var dialogReg:RegExp = /^Dialogue\:\s?((?:(?:[^,]*)\,?)+)/g;
			var dialogRes:Array = dialogReg.exec(dat);
			
			if(blockRes){
				// change current mode
				switch (blockRes[1])
				{
					case 'Script Info' :
						_mode = 'info';
						break;
					case 'V4+ Styles' :
						_mode = 'styles';
						break;
					case 'Events' :
						_mode = 'dialogs';
						break;
				}
			}else if(formatRes){
				_format = formatRes[1].split(/,\s?/);
			}else if(styleRes){
				var styleArray:Array = styleRes[1].split(",");
				var styleObj:Object = new Object();
				var p:String;
				for (p in _format){
					styleObj[_format[p]] = styleArray[p];
				}
				_styles[styleObj.Name] = styleObj;
				_styles_arr.push(styleObj);
			}else if(dialogRes){
				var dialogObject:Object = new Object();
				var dialogParseRegString:String = '';
				var f:String;
				for (f in _format){
					if(_format[f] != "Text"){
						dialogParseRegString += '(?P<'+_format[f]+'>[^,]*),';
					}else{
						dialogParseRegString += '(?P<'+_format[f]+'>.+)?\r?$';
					}
				}
				var dialogParseReg:RegExp = new RegExp(dialogParseRegString);
				var dialogParseRes:Array = dialogParseReg.exec(dialogRes[1]);
				var s:String;
				for (s in _format)
				{
					var fieldName:String = _format[s];
					if(fieldName == 'Style'){
						var dialog_style:* = _styles[dialogParseRes[fieldName]];
						if(dialog_style == undefined){
							dialog_style = _styles_arr[0];
						}
						dialogObject[fieldName] = dialog_style;
					}else{
						dialogObject[fieldName] = dialogParseRes[fieldName];
					}
				}
				parseASSDialog(dialogObject);
			}else if((_mode == 'info')&&infoRes){
				switch (infoRes.ident){
					case 'PlayResX' :
						x_resolution = Number(infoRes.val);
						break;
					case 'PlayResY' :
						y_resolution = Number(infoRes.val);
						break;
				}
			}
		};
		
		private function parseASSDialog(dialog:Object):void{
			var captionAnmationObject:Object = {};
			var captionObject:Object = {};
			
			captionObject['begin'] = Number(seconds( dialog.Start ));
			captionObject['end'] = Number(seconds( dialog.End ));
			
			captionObject['active'] = false;
			captionObject['outline'] = dialog.Style.Outline;
			captionObject['outlineColor'] = parseColor(dialog.Style.OutlineColour);
			
			captionObject['shadow'] = dialog.Style.Shadow;
			captionObject['shadowColor'] = parseColor(dialog.Style.BackColour);
			
			captionObject['marginL'] = dialog.Style.MarginL / x_resolution;
			captionObject['marginR'] = dialog.Style.MarginR / x_resolution;
			captionObject['marginV'] = dialog.Style.MarginV / y_resolution;
			
			captionObject['font'] = dialog.Style.Fontname;
			captionObject['size'] = dialog.Style.Fontsize / y_resolution;
			captionObject['color'] = parseColor(dialog.Style.PrimaryColour);
			
			captionObject['bold'] = (dialog.Style.Bold != 0);
			captionObject['italic'] = (dialog.Style.Italic != 0);
			captionObject['underline'] = (dialog.Style.Underline != 0);
			
			var numberAlign:Number = Number(dialog.Style.Alignment);
			if(numberAlign > 6){
				captionObject['valign'] = 'top';
				numberAlign -= 6;
			}else if(numberAlign > 3){
				captionObject['valign'] = 'mid';
				numberAlign -= 3;
			}
			if(numberAlign == 1){
				captionObject['align'] = 'left';
			}else if(numberAlign == 3){
				captionObject['align'] = 'right';
			}
			
			// removing karaoke effects
			var karaokeReplaceReg:RegExp = /\{\\k\w?\d+\}/g;
			var cleanedText:String = dialog.Text.replace(karaokeReplaceReg, '');
			
			var paramsStringReg:RegExp = /(?:\{(?P<params>[^\}]+)\})(?P<text>.+)/;
			var paramsStringRes:Array = paramsStringReg.exec(cleanedText);
			if(paramsStringRes){
				cleanedText = paramsStringRes.text;
			}
			
			// INLINE TAG PARSING
			// adding spaces
			var hReplaceReg:RegExp = /\\h/g;
			cleanedText = cleanedText.replace(hReplaceReg, ' ');
			
			// adding line breaks
			var NReplaceReg:RegExp = /\\(N|n)/g;
			cleanedText = cleanedText.replace(NReplaceReg, '<br>');
			// font string
			
			var fontReg:RegExp = /(?P<before>.*)\{(?P<c>\\c\&H?(?P<blue>\w{2})(?P<green>\w{2})(?P<red>\w{2})[\&H]?)?(?P<3c>\\3c\&H(?P<3blue>\w{2})(?P<3green>\w{2})(?P<3red>\w{2})[\&H]?)?(\\fs\d+)?(?P<bord>\\bord(?P<border>\d))?\}(?P<after>.*)/;
			var fontRes:Array = fontReg.exec(cleanedText);
			var fontColor:String = '';
			var fontSize:String = '';
			while (fontRes){
				if(fontRes.c){
					fontColor = ' color="#' + fontRes.red + fontRes.green + fontRes.blue + '"';
				}else{
					fontColor = '';
				}
				cleanedText = fontRes.before + '<font >' + fontRes.after + '</font>';
				fontRes = fontReg.exec(cleanedText);
			}
			
			// removing inline tags
			var inlineTagReg:RegExp = /[\{\\p1\}]?m.+\{\\p0\}/g;
			cleanedText = cleanedText.replace(inlineTagReg, '');
			
			// removing inline params
			var inlineModReg:RegExp = /\{\\[^\}]+\}/g;
			cleanedText = cleanedText.replace(inlineModReg, '');
			
			// removing comments
			var commentsReg:RegExp = /\{[^\}]+\}/g;
			cleanedText = cleanedText.replace(commentsReg, '');
			
			// removing draw strings
			var drawReg:RegExp = /m [\d\sl]+/g;
			cleanedText = cleanedText.replace(drawReg, '');
			
			if(cleanedText != ''){
				captionObject['text'] = cleanedText;
				
				if(paramsStringRes){
					var paramsReg:RegExp = /\\(?P<ident>\d?[a-z]+)(?P<params>(?:[\&HA-F\d]+)*(?:\([^\)]+\))?)/ig;
					var paramsRes:Array = paramsReg.exec(paramsStringRes.params);
					while (paramsRes){
						switch (paramsRes.ident){
							case 'pos' :
								var mod_x:Number = paramsRes.params.match(/\((?P<val>-?[\d.]+),\s?-?[\d.]+\)/)?paramsRes.params.match(/\((?P<val>-?[\d.]+),\s?-?[\d.]+\)/).val:0;
								var mod_y:Number = paramsRes.params.match(/\(-?[\d.]+,\s?(?P<val>-?[\d.]+)\)/)?paramsRes.params.match(/\(-?[\d.]+,\s?(?P<val>-?[\d.]+)\)/).val:0;
								captionObject['x'] = mod_x / x_resolution;
								captionObject['y'] = mod_y / y_resolution;
								captionObject['valign'] = 'pos';
								break;
							case 'move' :
								var mod_x_start:Number = paramsRes.params.match(/\((?P<val>-?[\d.]+),\s?(?:-?[\d.]+,?\s?){3,5}\)/)?paramsRes.params.match(/\((?P<val>-?[\d.]+),\s?(?:-?[\d.]+,?\s?){3,5}\)/).val:0;
								var mod_y_start:Number = paramsRes.params.match(/\((?:-?[\d.]+,\s?)(?P<val>-?[\d.]+),\s?(?:-?[\d.]+,?\s?){2,4}\)/)?paramsRes.params.match(/\((?:-?[\d.]+,\s?)(?P<val>-?[\d.]+),\s?(?:-?[\d.]+,?\s?){2,4}\)/).val:0;
								var mod_x_end:Number = paramsRes.params.match(/\((?:-?[\d.]+,\s?){2}(?P<val>-?[\d.]+),\s?(?:-?[\d.]+,?\s?){1,3}\)/)?paramsRes.params.match(/\((?:-?[\d.]+,\s?){2}(?P<val>-?[\d.]+),\s?(?:-?[\d.]+,?\s?){1,3}\)/).val:0;
								var mod_y_end:Number = paramsRes.params.match(/\((?:-?[\d.]+,\s?){3}(?P<val>-?[\d.]+),?\s?(?:-?[\d.]+,?\s?)*\)/)?paramsRes.params.match(/\((?:-?[\d.]+,\s?){3}(?P<val>-?[\d.]+),?\s?(?:-?[\d.]+,?\s?)*\)/).val:0;
								var mod_time_start_res:Object = paramsRes.params.match(/\((?:-?[\d.]+,\s?){4}(?P<val>-?[\d.]+),\s?(?:-?[\d.]+,?\s?)\)/);
								var mod_time_end_res:Object = paramsRes.params.match(/\((?:-?[\d.]+,\s?){5}(?P<val>-?[\d.]+)\s?\)/);
								var mod_time_start:Number = 0;
								var mod_time_end:Number = captionObject['end'] - captionObject['begin'];
								if(mod_time_start_res){
									mod_time_start = Number(mod_time_start_res.val) / 100;
								}
								if(mod_time_end_res){
									mod_time_end = Number(mod_time_end_res.val) / 100;
								}
								captionObject['x'] = mod_x_start / x_resolution;
								captionObject['y'] = mod_y_start / y_resolution;
								captionAnmationObject['x'] = mod_x_end / x_resolution;
								captionAnmationObject['y'] = mod_y_end / y_resolution;
								captionAnmationObject['delay'] = mod_time_start;
								captionAnmationObject['time'] = mod_time_end;
								captionObject['valign'] = 'move';
								/*debug('\t\tparsed');*/
								break;
							case 'c' :
								var mod_color:* = parseColor(paramsRes.params);
								captionObject['color'] = mod_color;
								break;
							case '3c' :
								var mod_outline_color:* = parseColor(paramsRes.params);
								captionObject['outlineColor'] = mod_outline_color;
								break;
							case 'fad' :
								captionObject['fadeIn'] = paramsRes.params.match(/\((?P<val>[\d.]+)[,;]\s?[\d.]+\)/) ? Number(paramsRes.params.match(/\((?P<val>[\d.]+)[,;]\s?[\d.]+\)/).val) / 1000 : 0;
								captionObject['fadeOut'] = paramsRes.params.match(/\([\d.]+[,;]\s?(?P<val>[\d.]+)\)/) ? Number(paramsRes.params.match(/\([\d.]+[,;]\s?(?P<val>[\d.]+)\)/).val) / 1000 : 0;
								break;
							case 'fs' :
								captionObject['size'] = Number(paramsRes.params) / y_resolution;
								break;
							case 'frx' :
								captionObject['frx'] = Number(paramsRes.params);
								break;
							case 'fry' :
								captionObject['fry'] = Number(paramsRes.params);
								break;
							case 'frz' :
								captionObject['frz'] = Number(paramsRes.params);
								break;
							case 'a' :
								var numberAlignMod:* = Number(paramsRes.params);
								if(numberAlignMod > 6){
									captionObject['valign'] = 'top';
									numberAlignMod -= 6;
								}else if(numberAlignMod > 3){
									captionObject['valign'] = 'mid';
									numberAlignMod -= 3;
								}
								if(numberAlignMod == 1){
									captionObject['align'] = 'left';
								}else if(numberAlignMod == 3){
									captionObject['align'] = 'right';
								}
								break;
						}
						paramsRes = paramsReg.exec(paramsStringRes.params);
					}
				}
				captionObject['animation'] = captionAnmationObject;
				
				// check for same captions
				var cap:Caption;
				var isThere:Boolean = false;
				for each(cap in _captions){
					//  || cap.text == captionObject['text']
					if( cap.text == captionObject['text'] && cap.begin == captionObject['begin'] && cap.end == captionObject['end'] ){
						isThere = true;
						break;
					}
				}
				if(!isThere) _captions.push(new Caption(_owner, captionObject));
			}
		}
		
		private function parseColor(str:String):Number{
			var colorReg:RegExp = /^\&[Hh]?(?P<alpha>\w{2})?(?P<blue>\w{2})(?P<green>\w{2})(?P<red>\w{2})[\&Hh]?$/;
			var colorRes:Array = colorReg.exec(str);
			return Number('0x'+colorRes.red+colorRes.green+colorRes.blue)
		}
		
		private function parseSRT(dat:String):void{
			var arr:Array = [];
			var lst:Array = dat.split("\r\n\r\n");
			if(lst.length == 1) { lst = dat.split("\n\n"); }
			for(var i:Number=0; i<lst.length; i++) {
				var obj:Object = parseSRTCaption(lst[i]);
				if(obj['end']) { _captions.push(new Caption(_owner, obj)) };
			}
			dispatchEvent(new Event("SubParsed"));
			//return arr;
		};
		
		/** Parse a single captions entry. **/
		private function parseSRTCaption(dat:String):Object {
			var obj:Object = {};
			var arr:Array = dat.split("\r\n");
			if(arr.length == 1) { arr = dat.split("\n"); }
			try { 
				var idx:Number = arr[1].indexOf(' --> ');
				obj['begin'] = Number(seconds(arr[1].substr(0,idx)));
				obj['end'] = Number(seconds(arr[1].substr(idx+5)));
				obj['text'] = arr[2] == null ? "" : arr[2];
				obj['srt'] = true;
				if(arr[3]) { obj['text'] += '<br />'+arr[3]; }
			} catch (err:Error) {}
			return obj;
		};
		
		private function seconds(str:String):Number {
			str = str.replace(',','.');
			var arr:Array = str.split(':');
			var sec:Number = 0;
			if (str.substr(-1) == 's') {
				sec = Number(str.substr(0,str.length-1));
			} else if (str.substr(-1) == 'm') {
				sec = Number(str.substr(0,str.length-1)) * 60;
			} else if(str.substr(-1) == 'h') {
				sec = Number(str.substr(0,str.length-1)) *3600;
			} else if(arr.length > 1) {
				sec = Number(arr[arr.length-1]);
				sec += Number(arr[arr.length-2]) * 60;
				if(arr.length == 3) {
					sec += Number(arr[arr.length-3]) *3600;
				}
			} else {
				sec = Number(str);
			}
			return sec;
		};
	}
}