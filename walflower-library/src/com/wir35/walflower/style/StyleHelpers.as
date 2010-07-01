package com.wir35.walflower.style
{
	import com.wir35.walflower.style.Hyphenator;
	
	import flash.utils.getQualifiedClassName;
	
	import flashx.textLayout.elements.*;
	import flashx.textLayout.elements.FlowElement;
	import flashx.textLayout.elements.SpanElement;
	import flashx.textLayout.formats.TextAlign;

	
	public class StyleHelpers
	{
		protected static var _hyphenator:Hyphenator;
		
		public function StyleHelpers()
		{
			_hyphenator = new Hyphenator();
		}
		
		/**
		 * This function runs an English-only hypenation algorithm on the
		 * text inside a SpanElement. Hyphenation will only occur if the
		 * span is justified, and does not have line breaks. Both conditions
		 * would lead to awful typographical gremlins.
		 * @param span the SpanElement to hyphenate.
		 * @returns true or false, depending on whether hyphenation was run
		 */
		public static function hyphenateSpan(span:SpanElement):Boolean
		{	
			// Do not justify paragraphs that have any carraige returns.
			// It's a wack idea
			if (span.text.indexOf('\n') > -1) {
				span.textAlign = TextAlign.LEFT;
				return false;
			}	
			// If this is in a justified paragraph, run the hyphenator
			if (span.computedFormat.textAlign == TextAlign.JUSTIFY) {
				span.text = span.text.split(' ').map(hyphenateWord).join(' '); // wtf is this ruby?
				return true;
			} else {
				return false;
			}
		}
		
		protected static function hyphenateWord(e:String, index:int, arr:Array):String {
			return _hyphenator.hyphenateWord(e);
		}
		
		public static const SINGLE_QUOTE:String = '\'';
		public static const SINGLE_OPEN_QUOTE:String = '\u2018';
		public static const SINGLE_CLOSE_QUOTE:String = '\u2019';
		public static const DOUBLE_QUOTE:String = '"';
		public static const DOUBLE_OPEN_QUOTE:String = '\u201c';
		public static const DOUBLE_CLOSE_QUOTE:String = '\u201d';
		public static const SPACE:String = ' ';
		
		/**
		 * This function uses a very simple heuristic to try to turn dumb quotes
		 * into appropriate opening and closing quotes. It sometimes fails on weird formats
		 * but often it works pretty well.
		 * @param span The text to repair quotes in
		 */
		public static function fixQuotes(span:String):String {
			var l:int = span.length;
			for (var i:int=0; i<l; i++) {
				if (span.charAt(i) == SINGLE_QUOTE) {
					if (i==0 || span.charAt(i-1) == SPACE) {
						span = span.slice(0, i) + SINGLE_OPEN_QUOTE + span.slice(i+1);
					} else {
						span = span.slice(0, i) + SINGLE_CLOSE_QUOTE + span.slice(i+1);
					}
				}
				if (span.charAt(i) == DOUBLE_QUOTE) {
					if (i==0 || span.charAt(i-1) == SPACE) {
						span = span.slice(0, i) + DOUBLE_OPEN_QUOTE + span.slice(i+1);
					} else {
						span = span.slice(0, i) + DOUBLE_CLOSE_QUOTE + span.slice(i+1);
					}
				}
				// Make sure we didn't end a line with an open quote. That's stupid
				// Maybe improve this with a quote "balancing" scheme later
				if (span.charAt(l-1) == SINGLE_OPEN_QUOTE) {
					span = span.slice(0, l-1) + SINGLE_CLOSE_QUOTE;
				} else if (span.charAt(l-1) == DOUBLE_OPEN_QUOTE) {
					span = span.slice(0, l-1) + DOUBLE_CLOSE_QUOTE;
				}
			}
			return span;	
		}
		
		public static function isFlowGroup(flow:FlowElement):Boolean {
			if ( getQualifiedClassName(flow) == 'flashx.textLayout.elements::DivElement' || getQualifiedClassName(flow) == 'flashx.textLayout.elements::TextFlow') {
				return true; } else { return false; }
		}
		
		public static function isDiv(flow:FlowElement):Boolean {
			if ( getQualifiedClassName(flow) == 'flashx.textLayout.elements::DivElement') {
				return true; } else { return false; }
		}
		
		public static function isParagraph(flow:FlowElement):Boolean {
			if ( getQualifiedClassName(flow) == 'flashx.textLayout.elements::ParagraphElement') {
				return true; } else { return false; }
		}
		
		public static function isSpan(flow:FlowElement):Boolean {
			if ( getQualifiedClassName(flow) == 'flashx.textLayout.elements::SpanElement') {
				return true; } else { return false; }
		}
		
		public static function isLink(flow:FlowElement):Boolean {
			if ( getQualifiedClassName(flow) == 'flashx.textLayout.elements::LinkElement') {
				return true; } else { return false; }
		}
		
	}
}