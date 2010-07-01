package com.wir35.walflower.style
{
	import com.wir35.walflower.style.Unit;
	
	/**
	 * ModScale defines a modular scale for specific typographic control over document display.
	 * Each unit in the scale is a multiple scaling factor.
 	 */
	public class ModScale
	{
		
		protected var _scale:Array;
		
		public function ModScale()
		{
		}
		
		/**
		 * Define the scale
		 * @param s is an array of Number, starting with 0 and representing sizes
		 * ie. [0, 0.1, 0.3, 0.5, 0.7, 1, 1.5, etc...]
		 * 1 is typically in the middle and corresponds to an em 
		 */
		public function set scale(s:Array):void {
			_scale = s;
		}

		
		/**
		 * Return the actual pixel value of a unit in the scale according to
		 * a specific zoom factor.
		 * @param unitVal = the 0-beginning index of the unit in the scale
		 * @param zoomVal = the number of pixels in a unit
		 * @returns A Number that is the number of pixels scaled for that unit in the scale.
		 */
		public function u (unitVal:int, zoomVal: Number):Number {
			return _scale[unitVal] * zoomVal;
		}

	}
}