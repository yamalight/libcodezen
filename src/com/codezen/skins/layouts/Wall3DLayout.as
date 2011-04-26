package com.codezen.skins.layouts
{
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	
	import mx.core.ILayoutElement;

	public class Wall3DLayout extends LayoutBase3D
	{
		// ========================================
		// private properties
		// ========================================
		private var _gap:Number = 2;
		private var _baseY:Number = 100;
		
		// ========================================
		// public properties
		// ========================================
		
		/**
		 * Gap between each item
		 */
		public function get gap():Number
		{
			return _gap;
		}
		public function set gap( value:Number ):void
		{
			if ( _gap != value )
			{
				_gap = value;
				invalidateTarget();
			}
		}
		
		// ========================================
		// constructor
		// ========================================
		
		/**
		 * Constructor
		 */
		public function Wall3DLayout()
		{
			super();
		}
		
		// ========================================
		// public methods
		// ========================================
		
		override public function updateDisplayList( width:Number, height:Number ) : void
		{
			var numElements:int = target.numElements;
			if(numElements < 1) return;
			
			var selectedIndex:int = index == -1 ? int( target.numElements / 2 ) : index;
			var selectedChild:ILayoutElement = target.getElementAt( selectedIndex );
			
			var element:ILayoutElement;
			var elementWidth:Number;
			var elementHeight:Number;
			var matrix:Matrix3D;
			
			var rowElementsNum:int = -1;
			var startAngle:int = -15;
			var maxAngle:int = 15;
			var stepAngle:Number;
			var x:Number = 0, y:Number = 0;
			var xi:int = 0, yi:int = 0;
			var angle:Number = startAngle;
			var oldWidth:Number = 10;
			
			for(var i:int = 0; i < numElements; i++){
				element = target.getElementAt( i );
				element.setLayoutBoundsSize( NaN, NaN, false ); // reset size
				
				elementWidth = element.getLayoutBoundsWidth( false );
				elementHeight = element.getLayoutBoundsHeight( false );
				
				if(rowElementsNum == -1){
					rowElementsNum = width/(elementWidth+_gap);
					stepAngle = ( maxAngle - startAngle ) / (rowElementsNum-1);
				}
				
				matrix = new Matrix3D();
				
				angle = startAngle + stepAngle*xi;
//				trace(angle);
				
//				var dy:Number = 0;//Math.pow( (elementsNum-1)/2 - xi, 2) / Math.pow( (elementsNum-1)/4, 2 );
//				trace(dy);
//				var dx:Number = elementWidth * Math.cos(angle*Math.PI/180);//( (elementsNum - 1)/2 - xi )*Math.abs(Math.abs(angle) - maxAngle);
//				trace(dx);
				
				
//				if(xi == 0){
//					x += oldWidth + _gap;
//				}else{
//					x += oldWidth*2 - elementWidth + _gap;
//				}
				y = elementHeight*yi;// + _gap*yi;
				xi++;
				
				
				if(xi >= rowElementsNum){
					x = 10;
					yi++;
					xi = 0;
					
					angle = startAngle;
					oldWidth = 10;
					y = elementHeight*yi;// + _gap*yi;
				}
				
				matrix.appendTranslation(x,y,1);
				
				matrix.appendTranslation( -elementWidth/2, -elementHeight / 2, -1 ); // negative so selected index is in front
				matrix.appendRotation(angle, Vector3D.Y_AXIS); // rotate on y axis
				matrix.appendTranslation( elementWidth/2, elementHeight / 2, 1 ); // center element in container
				
				
				element.setLayoutMatrix3D( matrix, false );
				
//				trace(x, oldWidth);
				
				x += _gap + elementWidth * Math.cos(angle*Math.PI/180);
//				trace(oldWidth);
//				trace('------------------------------');
			}
		}
	}
}