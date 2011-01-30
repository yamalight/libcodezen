/*
 * Original version created by Hoblin
 * Original source code can be found at https://github.com/hoblin/AS3-ASS-parser
 * This is a changed verion with small optimizations and changed tweening library (http://www.greensock.com/tweenlite/) to minimize the size
 */


package com.codezen.subs{ 
	
	import com.greensock.TweenLite;
	
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
		
		private var srt:Boolean = false;
		
		private var text:String = '';
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
		private var animation:Object = new Object();
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
			var caption:Object = this;
			for (var p:String in p_caption){
				if(caption[p] != undefined){
					caption[p] = p_caption[p];
				}
			}
		}
		
		public function sub():void{
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
				shadow*1.5, 
				shadow*1.5,
				shadow*2);
			
			if(outline < 1) outline = 1;
			var outlineFilter:GlowFilter = new GlowFilter(
				outlineColor,
				1.0,
				outline*1.5,
				outline*1.5,
				outline*4);
			_field.filters = new Array(outlineFilter, shadowFilter);
			
			_field.width = _owner.width;
			_field.defaultTextFormat = captionTextFormat;
			_field.multiline = true;
			_field.wordWrap = true;
			/*_field.border = true;*/
			_field.selectable = false;
			_field.autoSize = TextFieldAutoSize.CENTER;
			_field.htmlText = text;
			if((y == 0)&&(x == 0)){
				// collizions
				var activeSubsArray:Array = _owner.getActiveSubs(valign);
				var collision_delta:Number = 0;
				if(activeSubsArray.length > 0){
					for each (var item:Caption in activeSubsArray)
					{
						if( item.end > this.begin )
							collision_delta += item.height + item.marginV;
					}
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
			if(animation.y < 0) animation.y = _owner.y;
			
			// ROTATION
			if(frx != 0) _field.rotationX = frx;
			if(fry != 0) _field.rotationY = fry;
			if(frz != 0) _field.rotationZ = -frz;
			
			_field.alpha = 0;
			TweenLite.to(_field, 1, animation);
			TweenLite.to(_field, fadeIn, {alpha:1});
			_owner.subtitles_mc.addChild(_field);
			active = true;
		}
		
		public function unsub():void{
			TweenLite.to(_field, fadeOut, {onComplete:drop, alpha:0});
		}
		
		private function drop():void{
			_owner.subtitles_mc.removeChild(_field);
			active = false;
			_field = null;
		}
		
		private function width(delta:*):Number{
			return _owner.width * Number(delta);
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