package com.codezen.skins.layouts
{
	import flash.geom.Matrix;
	
	import mx.core.ILayoutElement;
	import mx.core.IVisualElement;
	
	import spark.components.supportClasses.GroupBase;
	import spark.layouts.supportClasses.LayoutBase;
	
	/**
	 * Layout Base 3D
	 */
	public class LayoutBase3D extends LayoutBase
	{
		// ========================================
		// private properties
		// ========================================
		
		private var _index:int = 0;
		
		// ========================================
		// public properties
		// ========================================
		
		/**
		 * Index of centered item
		 */
		public function get index():int
		{
			return _index;
		}
		
		public function set index( value:int ):void
		{
			if ( _index != value )
			{
				_index = value;
				invalidateTarget();
			}
		}
		
		override public function set target(value:GroupBase) : void
		{    
			if ( target != value )
			{
				if ( target )
				{
					target.maintainProjectionCenter = false;
					
					for ( var i:int = 0; i < target.numElements; i++ )
					{
						var e:ILayoutElement = target.getElementAt( i );
						
						// remove any 3D positioning
						e.setLayoutMatrix( new Matrix(), false );
						
						// reset layer to default
						if ( e is IVisualElement )
						{
							IVisualElement( e ).depth = 0;
						}
					}
				}
				
				super.target = value;
				
				if ( target )
				{
					target.maintainProjectionCenter = true;
				}
			}
		}
		
		// ========================================
		// constructor
		// ========================================
		
		/**
		 * Constructor
		 */
		public function LayoutBase3D()
		{
			super();
		}
		
		// ========================================
		// protected methods
		// ========================================
		
		protected function invalidateTarget():void
		{
			if ( target )
			{
				target.invalidateSize();
				target.invalidateDisplayList();
			}
		}
		
	} // end class
}