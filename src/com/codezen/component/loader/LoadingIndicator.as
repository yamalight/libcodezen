/*

Based on LoadCanvas by Ryan Phelan
http://www.rphelan.com

*/

package com.codezen.component.loader
{
	
import flash.display.Graphics;

import mx.core.UIComponent;

import spark.components.BorderContainer;
import spark.components.Image;
import spark.filters.GlowFilter;

/**
 * 	Loader displays a loading indicator when isLoading is set to true
 */
public class LoadingIndicator extends BorderContainer
{
	[Embed(source="assets/loadAnimation.swf")]
	private var loadAnimation1:Class;
	
	[Embed(source="assets/loadAnimation2.swf")]
	private var loadAnimation2:Class;
	
	public function LoadingIndicator()
	{
		super();
	}
	
	/**
	 * 	Image that is displayed when loading
	 */
	private var img:Image;
	
	private var fade:UIComponent;
	
	private var _isLoading:Boolean;
	
	private var _colorOverlay:uint = 0x000000;
	
	public function set colorOverlay( c:uint ):void{
		_colorOverlay = c;
	}
	
	[Bindable]
	public function set isLoading( l:Boolean ):void
	{
		_isLoading = l;
		
		invalidateDisplayList();
	}		
	public function get isLoading():Boolean 
	{
		return _isLoading;
	}
	
	/**
	 * 	Source path/class for the loadImage
	 */
	private var _loadImage:int = 0;
	
	[Bindable]
	public function set loadImage( type:int ):void
	{
		_loadImage = type;
		
		invalidateDisplayList();
	}		
	public function get loadImage():int 
	{
		return _loadImage;
	}
	
	
	/**
	 * 	Create the loadImage and fade graphic
	 */
	protected override function createChildren():void
	{
		super.createChildren();
		
		if( !img ){
			img = new Image();
		}
		
		if( !fade ){
			fade = new UIComponent();
		}
	}
	
	/**
	 * 	Update the size and position of the fade graphic and loadImage
	 */
	protected override function updateDisplayList( unscaledWidth:Number, unscaledHeight:Number ):void
	{
		super.updateDisplayList( unscaledWidth, unscaledHeight );
		
		// center image
		if( img ){
			img.x = unscaledWidth/2 - img.width/2;
			img.y = unscaledHeight/2 - img.height/2;
		}
		
		if( _isLoading ){
			if(_loadImage == 1){
				img.source = loadAnimation2;
			}else{
				img.source = loadAnimation1;
			}
			
			var gf:GlowFilter = new GlowFilter(_colorOverlay, 1, 200, 200, 2, 1, true);
			img.filters = [gf];
			
			if( !this.contains( fade ) )
				addElement( fade );
			if( !this.contains( img ) )
				addElement( img );

			/*var g:Graphics = fade.graphics;				
			g.clear();
			g.beginFill( 0xFFFFFF, .6 );
			g.drawRect( 0, 0, unscaledWidth, unscaledHeight );
			g.endFill();*/			
		}else{
			img.source = null;
			
			if( this.contains( fade ) )
				removeElement( fade );
			if( this.contains( img ) )
				removeElement( img );				
		}
	}
	
}
}