package com.wir35.walflower.epub
{
	
	import com.wir35.walflower.epub.NcxNavPoint;
	import com.wir35.walflower.epub.OpfPage;
	
	/*
	 * The NCX spine defines the default reading order for an EPub book.
	 */
	public class NcxSpine 
	{ 
		
		protected var _spine:Array; // of OpfPage
		protected var _lookup:Object; // dictionary for quick lookups by path
				
		public function NcxSpine() {
			_spine = new Array();
			_lookup = new Object();
		}

		public function push(p:OpfPage):void {
			_spine.push(p);
			_lookup[p.path] = p;
		}
		
		public function unshift(p:OpfPage):void {
			_spine.unshift(p);
			_lookup[p.path] = p;
		}

		public function getPageByNumber(pNum:Number):OpfPage {
			return _spine[pNum];
		}

		public function getPageByPath(p:String):OpfPage {
			return _lookup[p];
		}
		
		public function getPageNumberByPath(p:String):Number {
			return _spine.indexOf(getPageByPath(p));
		}
		
		public function getPageNumberByPage(p:OpfPage):Number {
			return _spine.indexOf(p);
		}
		
		public function get pages():Array {
			return _spine;
		}
		
		public function get length():Number {
			return _spine.length;
		}
	}
}