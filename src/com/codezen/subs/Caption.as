/*
 * Original version created by Hoblin
 * Original source code can be found at https://github.com/hoblin/AS3-ASS-parser
 * This is a changed verion with small optimizations and changed tweening library (http://www.greensock.com/tweenlite/) to minimize the size
 */


package com.codezen.subs{ 
	
	import com.greensock.TweenLite;
	
	import flash.display.MovieClip;
	import flash.filters.DropShadowFilter;
	import flash.filters.GlowFilter;
	import flash.text.*;
	
	public class Caption extends Object
	{
		
		private var _owner:*;
		private var _field:TextField;
		
		public var active:Boolean = false;
		public var begin:Number;
		public var end:Number;
		public var shift:int = 0;
		
		private var srt:Boolean = false;
		
		public var text:String = '';
		private var font:String = 'Arial';
		private var size:Number = 0.0556;
		private var color:Number = 0xFFFFFF;
		private var bold:Boolean = false;
		private var italic:Boolean = false;
		private var underline:Boolean = false;
		private var align:String = 'center';
		private var valign:String = 'sub';
		private var x:Number = 0;
		private var y:Number = 0;
		private var marginL:Number = 0.0;
		private var marginR:Number = 0.0;
		private var marginV:Number = 0.0;
		private var animation:Object = {};
		private var fadeIn:Number = 0.0;
		private var fadeOut:Number = 0.0;
		private var outline:Number = 2;
		private var outlineColor:Number = 0x000000;
		private var shadow:Number = 2;
		private var shadowColor:Number = 0x000000;
		private var frx:Number = 0;
		private var fry:Number = 0;
		private var frz:Number = 0;
		
		public function Caption(p_owner:*, p_caption:Object){
			_owner = p_owner;
			//var caption:Object = this;
			var p:String;
			for (p in p_caption){
				if(this[p] != undefined){
					this[p] = p_caption[p];
				}
			}
		}
		
		public function sub(animate:Boolean = true):void{
			if(_field != null) return;
			
			_field = new TextField();
			var captionTextFormat:TextFormat = new TextFormat();
			
			captionTextFormat.rightMargin = width(marginR);
			captionTextFormat.leftMargin = width(marginL);
			captionTextFormat.font = font;
			captionTextFormat.size = countHeight(size);
			captionTextFormat.color = color;
			captionTextFormat.bold = bold;
			captionTextFormat.italic = italic;
			captionTextFormat.underline = underline;
			captionTextFormat.align = align;
			
			if(shadow < 1) shadow = 1;
			var shadowFilter:DropShadowFilter = new DropShadowFilter(
				shadow*1.5, 
				45, 
				shadowColor, 
				shadow/4, 
				shadow*2.5, 
				shadow*2.5,
				shadow*4);
			
			if(outline < 1) outline = 1;
			var outlineFilter:GlowFilter = new GlowFilter(
				outlineColor,
				1.0,
				outline*2.5,
				outline*2.5,
				outline*6);
			_field.filters = new Array(outlineFilter, shadowFilter);
			
			_field.width = _owner.width;
			_field.defaultTextFormat = captionTextFormat;
			_field.multiline = true;
			_field.wordWrap = true;
			_field.antiAliasType = AntiAliasType.ADVANCED;
			/*_field.border = true;*/
			_field.selectable = false;
			_field.autoSize = TextFieldAutoSize.CENTER;
			_field.htmlText = text;
			if((y == 0)&&(x == 0)){
				// collizions
				var activeSubsArray:Array = _owner.getActiveSubs(valign);
				var collision_delta:Number = 0;
				if(activeSubsArray.length > 0){
					var item:Caption;
					var maxShift:int = activeSubsArray[0].shift;
					var minShift:int = activeSubsArray[0].shift;
					var shifts:Array = [];
					shift = 0;
					trace('--------------------------------------------');
					trace('shift for sub: '+text);
					trace('init shift: '+shift+' maxShift: '+maxShift);
					for each (item in activeSubsArray){
						shifts.push(item.shift);
						if( item.shift > maxShift ) maxShift = item.shift;
						if( item.shift < minShift ) minShift = item.shift;
					}
					trace('maxShift detected: '+maxShift);
					trace('minShift detected: '+minShift);
					
					
					for each (item in activeSubsArray){						
						if( shift < minShift) break;
						if( item != this && ( (item.end > this.begin && item.begin < this.begin) || (item.begin == this.begin && item.end == this.end) )
							&& item.shift > -1){
							collision_delta += item.height + item.marginV;
							shift++;
							if( shifts.indexOf(shift) < 0 || shift > maxShift ) break;
						}
					}

					trace('set shift: '+shift);
				}
				if(valign == 'top'){
					_field.y = countHeight(0.0) + collision_delta;
				}else if(valign == 'mid'){
					_field.y = countHeight(0.5) + _field.height - collision_delta;
				}else{
					var coef:Number;
					if( srt ){ coef = 0.95; }else{ coef = 0.97; };
					_field.y = countHeight(coef) - _field.height - countHeight(marginV) - collision_delta;
				}
				_field.x = 0;
			}else{
				_field.y = countHeight(y) - _field.height + _owner.y;
				_field.x = width(x) - (_field.width / 2);
			}
			
			if(animation.x != undefined) animation.x = width(animation.x) - (_field.width / 2);
			if(animation.y != undefined) animation.y = countHeight(animation.y) - _field.height + _owner.y;
			
			if(_field.y < 0) _field.y = _owner.y;
			if(_field.x < 0) _field.x = _owner.x;
			if(animation.y < 0) animation.y = _owner.y;
			if(animation.x < 0) animation.x = _owner.x;
			
			// ROTATION
			if(frx != 0) _field.rotationX = frx;
			if(fry != 0) _field.rotationY = fry;
			if(frz != 0) _field.rotationZ = -frz;
			
			if(animate){
				_field.alpha = 0;
				TweenLite.to(_field, 1, animation);
				TweenLite.to(_field, fadeIn, {alpha:1});
			}
			_owner.subtitles_mc.addChild(_field);
			active = true;
		}
		
		public function unsub(animate:Boolean = true):void{
			if( _field == null ) return;
			if(animate){
				TweenLite.to(_field, fadeOut, {onComplete:drop, alpha:0});
			}else{
				drop();
			}
		}
		
		private function drop():void{
			try{
				_owner.subtitles_mc.removeChild(_field);
			}catch(e:Error){}
			shift = -1;
			active = false;
			_field = null;
		}
		
		private function width(delta:*):Number{
			return _owner.width * ( Number(delta) / 2 );
		}
		
		private function countHeight(delta:*):Number{
			return _owner.height * Number(delta);
		}
		
		public function get height():Number{
			return _field.height;
		}
		
		public function get v_align():String{
			return valign;
		}
	}
}