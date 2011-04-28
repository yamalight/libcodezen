package com.codezen.skins.layouts
{
	import flash.geom.Matrix3D;
	import flash.geom.PerspectiveProjection;
	import flash.geom.Point;
	import flash.geom.Vector3D;
	
	import mx.controls.Alert;
	import mx.controls.Image;
	import mx.core.IVisualElement;
	import mx.core.UIComponent;
	
	import spark.filters.GlowFilter;
	import spark.layouts.supportClasses.LayoutBase;
	
	/**
	 * Flex 4 3D Wall layout
	 * based on Tony Georgiev TopSitesLayout (http://tgeorgiev.blogspot.com)
	 */
	public class Wall3DLayout extends LayoutBase
	{
		private var _columnWidth:Number;
		private var _rowHeight:Number;
		private var _columns:int;
		private var _rows:int;
		
		private var isColumnWidthSet:Boolean;
		private var isRowHeightSet:Boolean;
		private var isColumnsSet:Boolean;
		private var isRowsSet:Boolean;
		
		private var _horizontalGap:Number;
		private var _verticalGap:Number;
		
		private var rotatingAngle:Number;
		private var radius:Number;
		private var cameraPosition:Number;
		private var chordLength:Number;
		private var arcLength:Number;
				
		public static var VIEW_ANGLE:Number = 120;
		
		public function Wall3DLayout()
		{
			super();
			_columnWidth = 0;
			_rowHeight = 0;
			_rows = 0;
			_horizontalGap = 0;
			_verticalGap = 0;
		}
		
		/**
		 * Specifies the width in pixels of each column. If not specified
		 * the width will be auto calculated depending on the width of the target
		 * and the number of columns
		 */
		public function get columnWidth():Number
		{
			return _columnWidth;
		}

		public function set columnWidth(value:Number):void
		{
			_columnWidth = value;
			isColumnWidthSet = true;
		}
		
		/**
		 * Specifies the height in pixels of each row. If not specified
		 * the height will be auto calculated depending on the height of the target
		 * and the number of rows
		 */
		public function get rowHeight():Number
		{
			return _rowHeight;
		}
		
		public function set rowHeight(value:Number):void
		{
			_rowHeight = value;
			isRowHeightSet = true;
		}
		
		/**
		 * The number of columns to display. If not specified
		 * the number will be self determined
		 */
		public function get columns():int
		{
			return _columns;
		}
		
		public function set columns(value:int):void
		{
			_columns = value;
			isColumnsSet = true;
		}
		
		/**
		 * The number of rows to display. If not specified
		 * the number will be self determined
		 */
		public function get rows():int
		{
			return _rows;
		}
		
		public function set rows(value:int):void
		{
			_rows = value;
			isRowsSet = true;
		}
		
		/**
		 * The space in pixels between two rows
		 */
		public function get horizontalGap():Number
		{
			return _horizontalGap;
		}
		
		public function set horizontalGap(value:Number):void
		{
			_horizontalGap = value;
		}
		
		/**
		 * The space in pixels between two columns
		 */
		public function get verticalGap():Number
		{
			return _verticalGap;
		}
		
		public function set verticalGap(value:Number):void
		{
			_verticalGap = value;
		}
		
		override public function updateDisplayList(width:Number, height:Number):void
		{
			calculateRowsCols();
			chordLength = width;
			calculateRadiusAndArc(width, height);
			
			
			
			var degreesMove:Number = rotatingAngle / (_columns-1);
			if(isNaN(degreesMove))
				degreesMove = 0;
			var startDegree:Number = -rotatingAngle/2;
			
			for(var i:int = 0; i < _rows; i++)
			{
				for(var j:int = 0; j < _columns; j++)
				{
					var index:int = i*_columns + j;
					if(index >= target.numElements)
					{
						return;
					}
					var element:IVisualElement = target.getVirtualElementAt(index);
					element.setLayoutBoundsSize(_columnWidth, _rowHeight, true);
					
					var pp:PerspectiveProjection = new PerspectiveProjection();
					pp.fieldOfView = 15;
					pp.projectionCenter = new Point(width/2, height/2);
					
					element["transform"].perspectiveProjection = pp;
					
					var matrix:Matrix3D = new Matrix3D();
					matrix.appendTranslation(-_columnWidth/2, 0, radius);
					matrix.appendRotation(startDegree + degreesMove*j, Vector3D.Y_AXIS);
					matrix.appendTranslation(width/2, (_rowHeight + _horizontalGap) * i ,-cameraPosition);
					element.setLayoutMatrix3D(matrix, false);
				}
			}
		
		}
		
		protected function calculateRadiusAndArc(width:Number, height:Number):void
		{
			
			var viewAngleRadians:Number = VIEW_ANGLE * Math.PI / 180;
			
			//chordLength = 2r * sin (angle/2);
			var sinus:Number = Math.sin( viewAngleRadians );
			radius = chordLength / (2 * Math.sin( viewAngleRadians / 2 ));
			
			//chordLength = 2*Math.sqrt(r*r - h*h)
			cameraPosition = Math.sqrt(4 * radius * radius - chordLength * chordLength) / 2;
			
			//arcLength 
			arcLength = viewAngleRadians * radius;
			
			measureRowsColsWidth(arcLength, height);
			
			//the old length of the arc minus width for element
			//half for the left, half for the right
			var newArcLength:Number = arcLength - (_columnWidth + _verticalGap);
			
			//the angle of the new arc, a.k.a the allowed degrees move
			var rotatingAngleRadians:Number =  newArcLength/radius
			rotatingAngle = rotatingAngleRadians * 180/Math.PI;
		}
		
		private function measureRowsColsWidth(width:Number, height:Number):void
		{
			if(isRowHeightSet == false)
			{
				_rowHeight = (height - _rows*_horizontalGap) / _rows;
			}
			
			if(isColumnWidthSet == false)
			{
				_columnWidth = (width - _columns*_verticalGap) / _columns;
			}
		}
		
		private function calculateRowsCols():void
		{
			if(isColumnsSet == false && isRowsSet == false)
			{
				if( target.getVirtualElementAt(0) == null ){
					trace('no elems');
					return;
				}
				trace(target.getVirtualElementAt(0).getMinBoundsWidth() )
				_columns = Math.ceil( target.width / target.getVirtualElementAt(0).getMinBoundsWidth() ); //Math.ceil(Math.sqrt(target.numElements));
				_rows = Math.ceil(target.numElements / _columns);
			}
			else
			if(isColumnsSet == false)
			{
				_columns = Math.ceil(target.numElements / _rows);
			}
			else
			if(isRowsSet == false)
			{
				_rows = Math.ceil(target.numElements / _columns);
			}
		}
	}
}