package com.wir35.walflower.epub
{
	
	import flashx.textLayout.elements.FlowElement;
	/*
	 * A NCX navPoint defines a place in the book.
	 * It can be a section, or a specific element in a flow
	 *
	 * A nav point can be specified in one of the following ways:
	 * 
	 * 1. A reference to the section (OpfPage)
	 * 2. A file path to the original html file plus an internal anchor (ie an html href )
	 * 3. A unique element id in any text flow
	 * 4. An element reference
	 * 
	 */
	public class NcxNavPoint
	{
		public var id:String; // string id of the opf page
		public var page:OpfPage; // reference to the opf page
		public var path:String; // file path to the link
		public var navLabel:String; // Title of navpoint
		public var elementId:String; // The element id in the textflow. 
		public var element:FlowElement; // The element to link to
		public var playOrder:int;
		public var level:int;
		
		public function NcxNavPoint()
		{
		}
		
	}
}