package com.wir35.walflower.xhtml
{
	import flash.utils.getQualifiedClassName;
	
	import flashx.textLayout.conversion.ConversionType;
	import flashx.textLayout.conversion.TextConverter;
	import flashx.textLayout.elements.DivElement;
	import flashx.textLayout.elements.FlowElement;
	import flashx.textLayout.elements.FlowGroupElement;
	import flashx.textLayout.elements.FlowLeafElement;
	import flashx.textLayout.elements.InlineGraphicElement;
	import flashx.textLayout.elements.LinkElement;
	import flashx.textLayout.elements.ParagraphElement;
	import flashx.textLayout.elements.SpanElement;
	import flashx.textLayout.elements.TextFlow;
	import flashx.textLayout.events.FlowElementMouseEvent;
	
	import mx.core.FlexGlobals;
	
	public class XhtmlToTextFlow
	{
		
		public static var flow:Namespace = new Namespace("flow", "http://ns.adobe.com/textLayout/2008");
	
		
		// Character limits for section splitting
		public static const SECTION_MIN:Number = 400;
		public static const MAJOR_SECTION_MAX:Number = 20000;
		public static const MAXIMUM_SECTION:Number = 40000; 
		
		public function XhtmlToTextFlow()
		{
			XML.ignoreComments = true;
			XML.ignoreWhitespace = true;
		}
		
		/*
		 * Normalizes an xhtml file by flattening out all the divs that are just used for styles
		 * The result file will be a sequence of headings, paragraphs, and inline html elements
		 */
		public static function flattenElements(doc:XML, flatPage:XML, styleStack:String = ""):void {
			var nodes:XMLList = doc.children();
			var thisStack:String;
			for (var i:int=0; i < nodes.length(); i++) {
				if (nodes[i].localName() == 'div' ) {
					// Pull the div's styles and flatten
					var htmlClass:String = nodes[i].attribute('class').toString();
					var htmlId:String = nodes[i].attribute('id').toString();
					thisStack = styleStack;
					if (htmlClass != "") {
						thisStack = XhtmlToTextFlow.joinStyles(styleStack, 'div.' + htmlClass);
					}
					if (htmlId != "") {
						thisStack = XhtmlToTextFlow.joinStyles(styleStack, 'div#' + htmlId);
					}
					flattenElements(nodes[i], flatPage, thisStack);
				} else {
					// Assign the styles and add
					var styleName:String = nodes[i].@styleName.toString();
					if (styleStack != "") {
						nodes[i].@styleName = styleStack;
					} 
					flatPage.appendChild(nodes[i]);
				}
			}
		}
		
		/*
		 * Divides a long xhtml file into manageable chunks
		 * Each h1, h2, or h3 heading creates a new section document
		 * Returns an array of new XHTML files
		 */
		public static function splitIntoSections(doc:XML):Array {
			var sections:Array = new Array();
			var i:int; // counter
			var s:int=-1; // num of scurrent ection
			var children:XMLList = doc.children();
			for (i=0; i<children.length(); i++) {
				var tag:String = children[i].localName();
				var newSection:Boolean = false;
				if ( sections.length == 0) {
					// We need at least one section!
					newSection = true;
				} else {
					var thisSectionLength:Number = sections[s].toString().length; 
					if (tag == "h1" || tag == "h2" || tag == "h3") {
						// Make new sections on heads
						newSection = true;
						// Unless the current section is really tiny!
						if (thisSectionLength < SECTION_MIN ) {
							newSection = false;
						}
					} else if (thisSectionLength > MAJOR_SECTION_MAX) {
						// If this one has just gotten huge, break anyway at another head
						if ( tag == "h4" || tag == "h5" || tag == "h6") {
							newSection = true;
						}
					}
					if (thisSectionLength > MAXIMUM_SECTION) {
						// Too big. BREAK!
						newSection = true;
					}
				}
				
				
				if (newSection) {
					// put content into a new section
					s++;
					sections[s] = <body/>;
					sections[s].appendChild( children[i] );
				} else {
					// Append to the current section
					sections[s].appendChild( children[i] );
				}
			}
			return sections;
		}
		
		public static function convert(xhtml:XML):TextFlow
		{
			var textFlow:TextFlow = new TextFlow();
			XhtmlToTextFlow.parseElement(xhtml, textFlow);
			// XhtmlToTextFlow.testOutput(textFlow);
			return textFlow;
		}
		
		public static function testOutput(tf:TextFlow):void 
		{
			trace ( TextConverter.export(tf, TextConverter.TEXT_LAYOUT_FORMAT, ConversionType.XML_TYPE) );
		}
		
		public static function parseElement(xhtml:XML, flow:*, styleStack:String = "", pre:Boolean = false):void 
		{
			var tag:String = xhtml.localName();
			switch (tag) {
				case 'html':
					XhtmlToTextFlow.parseDivElement(xhtml, flow, "html", styleStack); break;
				case 'body':
					XhtmlToTextFlow.parseDivElement(xhtml, flow, "body", styleStack); break;
				case 'blockquote':
					XhtmlToTextFlow.parseDivElement(xhtml, flow, "blockquote", styleStack); break;
				case 'ul':
					XhtmlToTextFlow.parseDivElement(xhtml, flow, "ul", styleStack); break;
				case 'ol':
					XhtmlToTextFlow.parseDivElement(xhtml, flow, "ol", styleStack); break;
				case 'div': 
					XhtmlToTextFlow.parseDivElement(xhtml, flow, "div", styleStack); break;
				case 'p':
					XhtmlToTextFlow.parseParagraphElement(xhtml, flow, "p", styleStack); break;
				case 'h1':
					XhtmlToTextFlow.parseParagraphElement(xhtml, flow, "h1", styleStack); break;
				case 'h2':
					XhtmlToTextFlow.parseParagraphElement(xhtml, flow, "h2", styleStack); break;
				case 'h3':
					XhtmlToTextFlow.parseParagraphElement(xhtml, flow, "h3", styleStack); break;
				case 'h4':
					XhtmlToTextFlow.parseParagraphElement(xhtml, flow, "h4", styleStack); break;
				case 'h5':
					XhtmlToTextFlow.parseParagraphElement(xhtml, flow, "h5", styleStack); break;
				case 'h6':
					XhtmlToTextFlow.parseParagraphElement(xhtml, flow, "h6", styleStack); break;
				case 'li':
					XhtmlToTextFlow.parseParagraphElement(xhtml, flow, "li", styleStack); break;
				case 'span':
					XhtmlToTextFlow.parseSpanElement(xhtml, flow, "span", styleStack); break;
				case 'i':
					XhtmlToTextFlow.parseSpanElement(xhtml, flow, "i", styleStack); break;
				case 'b':
					XhtmlToTextFlow.parseSpanElement(xhtml, flow, "b", styleStack); break;
				case 'em':
					XhtmlToTextFlow.parseSpanElement(xhtml, flow, "em", styleStack); break;
				case 'strong':
					XhtmlToTextFlow.parseSpanElement(xhtml, flow, "strong", styleStack); break;
				case 'code':
					XhtmlToTextFlow.parseSpanElement(xhtml, flow, "code", styleStack); break;
				case 'cite':
					XhtmlToTextFlow.parseSpanElement(xhtml, flow, "cite", styleStack); break;
				case 'kbd':
					XhtmlToTextFlow.parseSpanElement(xhtml, flow, "kbd", styleStack); break;
				case 'a':
					XhtmlToTextFlow.parseLinkElement(xhtml, flow, styleStack); break;
				case 'pre':
					XhtmlToTextFlow.parsePreformatted(xhtml, flow, styleStack); break;
				case 'table':
					XhtmlToTextFlow.parseTable(xhtml, flow); break;
				case 'tr':
					XhtmlToTextFlow.parseParagraphElement(xhtml, flow, "tr", styleStack); break;
				case 'td':
					XhtmlToTextFlow.parseSpanElement(xhtml, flow, "td", styleStack); break;
				case 'img':
					XhtmlToTextFlow.parseImage(xhtml, flow); break;
				case 'hr':
					break; // ignore horizontal rules. they're stupid.
				case 'br':
					XhtmlToTextFlow.parseBrElement(xhtml, flow); break;
				case null:
					// Simple content 
					XhtmlToTextFlow.parseSimpleContent(xhtml, flow, styleStack, pre); break;
				default:
					XhtmlToTextFlow.parseUnknownElement(xhtml, flow); break;
			}
		}

		public static function parseChildren(xhtml:XML, flow:FlowElement, styleStack:String = "", pre:Boolean = false):void {
			if ( xhtml.hasSimpleContent() ) {
				XhtmlToTextFlow.parseSimpleContent(xhtml, flow, styleStack, pre); 
			} else {
				var children:XMLList = xhtml.children();
				for (var i:int=0; i<children.length(); i++) {
					XhtmlToTextFlow.parseElement(children[i], flow, styleStack, pre);
				}
			}
		}
		
		public static function joinStyles(styleStack:String, newStyle:String):String {
			var rslt:String = styleStack;
			if (newStyle.length > 0) {
				if (rslt.length > 0 ) {
					rslt += ',';
				}
				rslt += newStyle;
			}
			return rslt;
		}

		public static function parseDivElement(xhtml:XML, flow:*, tag:String, styleStack:String = ""):void {
			var htmlId:String = xhtml.attribute('id').toString();
			var htmlClass:String = xhtml.attribute('class').toString();
			if ( isFlowGroup(flow) ) {
				var divElement:DivElement = new DivElement();
				divElement.styleName = styleStack; 	// It's possible there is a styleStack but unlikely
				divElement.styleName = XhtmlToTextFlow.joinStyles(divElement.styleName, xhtml.@styleName.toString() ); // add from xhtml
				divElement.styleName = XhtmlToTextFlow.joinStyles(divElement.styleName, tag); // add tag
				styleStack = ""; // it's applied, so clear it
				if (htmlClass != "") { 
					divElement.styleName = XhtmlToTextFlow.joinStyles(divElement.styleName, tag + '.' + htmlClass); // add class
				}
				if (htmlId != "") { 
					divElement.styleName = XhtmlToTextFlow.joinStyles(divElement.styleName, tag + '#' + htmlId); // add id
					divElement.id = htmlId;
				}
				flow.addChild(divElement);
				XhtmlToTextFlow.parseChildren(xhtml, divElement, styleStack);
			} else {
				// This is a bad case, but we can potentially use the style stack to add div styling to
				//   things poorly nested, for example, a <div> inside a <p> Ug!
				trace("Badly formed xhtml. Ignoring for now.");
			}
		}
		
		public static function parseParagraphElement(xhtml:XML, flow:FlowGroupElement, tag:String, styleStack:String = ""):void 
		{	
			var htmlId:String = xhtml.attribute('id').toString();
			var htmlClass:String = xhtml.attribute('class').toString();
			if ( isFlowGroup(flow) && xhtml.children().length() > 0) { 
				var paraElement:ParagraphElement = new ParagraphElement();
				paraElement.styleName = styleStack;
				paraElement.styleName = XhtmlToTextFlow.joinStyles(paraElement.styleName, xhtml.@styleName.toString() );
				paraElement.styleName = XhtmlToTextFlow.joinStyles(paraElement.styleName, tag);
				styleStack = ""; 
				if (htmlClass != "") { 
					paraElement.styleName = XhtmlToTextFlow.joinStyles(paraElement.styleName, tag + '.' + htmlClass);
				}
				if (htmlId != "") { 
					paraElement.styleName = XhtmlToTextFlow.joinStyles(paraElement.styleName, tag + '#' + htmlId); 
					paraElement.id = htmlId; 
				}
				flow.addChild(paraElement);
				XhtmlToTextFlow.parseChildren(xhtml, paraElement, styleStack);
			} else {
				// badly formed html again
				trace("Ignoring badly formed xhtml");
			}
		}
		
		public static function parseSpanElement(xhtml:XML, flow:*, tag:String, styleStack:String = ""):void {
			var htmlId:String = xhtml.attribute('id').toString();
			var htmlClass:String = xhtml.attribute('class').toString();
			if ( isDiv(flow) ) {
				// This span will need a new paragraph
				// Create a new paragraph, apply the style stack if it exists
				// Create a new styleStack for this tag
				// Parse children
				var para:ParagraphElement = new ParagraphElement();
				para.styleName = styleStack;
				para.styleName = XhtmlToTextFlow.joinStyles(para.styleName, 'p');
				styleStack = tag;
				if (htmlClass != "") { 
					styleStack = XhtmlToTextFlow.joinStyles(styleStack, tag + '.' + htmlClass);
				}
				if (htmlId != "") { 
					styleStack = XhtmlToTextFlow.joinStyles(styleStack, tag + '#' + htmlId); 
				}
				DivElement(flow).addChild(para);
				XhtmlToTextFlow.parseChildren(xhtml, para, styleStack);
			} else if (isLink(flow) || isParagraph(flow) ) {
				// The children can be added here.
				// Apply to the styleStack and parse children
				styleStack = XhtmlToTextFlow.joinStyles(styleStack, tag);
				if (htmlClass != "") { 
					styleStack = XhtmlToTextFlow.joinStyles(styleStack, tag + '.' + htmlClass);
				}
				if (htmlId != "") { 
					styleStack = XhtmlToTextFlow.joinStyles(styleStack, tag + '#' + htmlId); 
				}
				XhtmlToTextFlow.parseChildren(xhtml, flow, styleStack);
			} else if ( isSpan(flow) ) {
				// Nested spans should no longer exist, as spans are only created around simple content
				trace("Metaphysical fail!");
			}
		}
		
		public static function parseSimpleContent(xhtml:XML, flow:FlowElement, styleStack:String = "", pre:Boolean = false):void {
			if (xhtml == null) { return; } // Sometimes bad things happen to good code
			var spanElement:SpanElement = new SpanElement();
			if ( isSpan(flow) ) {
				// This should no longer happen, since this is the only function making span elements
				trace("Metaphysical fail.");
			} else if (isLink(flow)) { 
				// Here's simple content link text, to be added to the link leaf group
				// Apply the styleStack and add the element
				spanElement.styleName = styleStack; 
				LinkElement(flow).addChild(spanElement);
			} else if ( isParagraph(flow) ) {
				// Most common scenario. Apply the style stack to the span and add content
				spanElement.styleName = styleStack;
				ParagraphElement(flow).addChild(spanElement);
			} else if ( isDiv(flow) ) {
				// Some html monstrosities may be missing paragraphs
				// Create the para, and add the styleStack to the p instead
				var para:ParagraphElement = new ParagraphElement();
				para.styleName = XhtmlToTextFlow.joinStyles(styleStack, 'p');
				spanElement.styleName = 'span';
				DivElement(flow).addChild(para);
				para.addChild(spanElement);
			} 
			if (spanElement.styleName.indexOf('span') == -1) {
				// Make sure it's a span, but try not to duplicate
				spanElement.styleName = XhtmlToTextFlow.joinStyles(spanElement.styleName, 'span');
			}
			if (pre) {
				// Add text to span with all whitespace and everything
				spanElement.text = xhtml.children()[0].toXMLString();
			} else {
				// Strip space and add the text to the span
				spanElement.text = XhtmlToTextFlow.stripSpace(xhtml.toString());
				XhtmlToTextFlow.addSpaceIfNeeded(spanElement);
			}
		}
		
		// This might not be working right
		public static function addSpaceIfNeeded(spanElement:SpanElement): void {
			// adds space in front of this span if it would be needed
			var prevLeaf:FlowLeafElement = spanElement.getPreviousLeaf(spanElement.getParagraph());
			if (prevLeaf) {
				var prevSpan:SpanElement = SpanElement(prevLeaf);
				var lastChar:String = prevSpan.text.charAt(prevSpan.text.length-1);
				if  (lastChar != " ") {
					spanElement.text = " " + spanElement.text;
				}
			}
		}
		
		public static function stripSpace(s:String):String {
			var whitespace:RegExp = /(\t|\n|\s{2,})/g;  
			var nbsp:RegExp = /\u00A0/g;
			s = s.replace(nbsp, ' ');
			s = s.replace(whitespace, ' ');
			return s;
		}
		
		
		
		public static function parseLinkElement(xhtml:XML, flow:*, styleStack:String = ""):void {
			var aName:String = xhtml.@name.toString();
			var htmlId:String = xhtml.attribute('id').toString();
			if (aName == "") {
				aName = htmlId; // I guess anchors can be @name or @id
			}
			var htmlClass:String = xhtml.attribute('class').toString();
			var href:String = xhtml.@href.toString();
			var para:ParagraphElement;
			// An <a> tag can be a hyperlink or a named anchor
			//  if it's a link, make a LinkElement tag, else make a named span
			if (href) {
				// Make a hyperlink, a LinkElement 
				var linkElement:LinkElement = new LinkElement();
				linkElement.target="_blank";
				linkElement.href = href; // can be an internal or external link
				if ( isSpan(flow) || isLink(flow) ) {
					// If a span is being added to a span or another link... we're hosed
					// Just add its body as simple content for now
					trace("Cannot add this link here.");
					XhtmlToTextFlow.parseChildren(xhtml, flow);
					return;
				} else if ( isDiv(flow) ) {
					// Wrap the link in a new paragraph, and assign the styleStack
					para = new ParagraphElement();
					para.styleName = styleStack;
					para.styleName = XhtmlToTextFlow.joinStyles(para.styleName, 'p');
					styleStack = "";
					linkElement.styleName = 'a';
					para.addChild(linkElement);
					DivElement(flow).addChild(para);					
				} else if ( isParagraph(flow) ) {
					ParagraphElement(flow).addChild(linkElement);
					linkElement.styleName = styleStack;
					linkElement.styleName = XhtmlToTextFlow.joinStyles(linkElement.styleName, 'a');
					styleStack = "";
				}
				// And continue for divs and paras 
				if (htmlClass != "") {
					linkElement.styleName = XhtmlToTextFlow.joinStyles(linkElement.styleName, 'a.' + htmlClass);
				}
				if (htmlId != "") {
					linkElement.styleName = XhtmlToTextFlow.joinStyles(linkElement.styleName, 'a#' + htmlId);
				}
				// And now add the event handler? Way interdependent ... ick
				linkElement.addEventListener(flashx.textLayout.events.FlowElementMouseEvent.CLICK,
					FlexGlobals.topLevelApplication._controller.textFlowLinkHandler);
				// And now parse link children, usually simple content
				XhtmlToTextFlow.parseChildren(xhtml, linkElement, styleStack);
			} else {
				// Make a named span as an internal anchor right here.
				var spanElement:SpanElement = new SpanElement();
				spanElement.id = aName;
				spanElement.styleName = "anchor";
				spanElement.text = " "; // add a space to hold the anchor
				if ( isDiv(flow) ) {
					// Wrap the span in a new paragraph
					para = new ParagraphElement();
					para.styleName = "p";
					para.addChild(spanElement);
					DivElement(flow).addChild(para);
					// Add children to the parent element, in case it's nested deep
					XhtmlToTextFlow.parseChildren(xhtml, flow, styleStack);
				} else if ( isParagraph(flow) ) {
					ParagraphElement(flow).addChild(spanElement);
					XhtmlToTextFlow.parseChildren(xhtml, flow);
				} else if ( isSpan(flow) ) {
					// If a span is being added to a span... we have a mess
					// Add the anchor name to the element so we can link to it and forget everything else   
					flow.id = aName;
				}
			} 

		}
		
		public static function parseBrElement(xhtml:XML, flow:FlowElement):void {
			var spanElement:SpanElement;
			if ( isSpan(flow) ) {
				// Line breaks can be added to a span
				SpanElement(flow).text += '\n';
			} else if ( isParagraph(flow) ) {
				// Breaks must be added to a span
				spanElement = new SpanElement();
				spanElement.styleName = "span";
				spanElement.text = " \n";
				ParagraphElement(flow).addChild(spanElement);
			} else if ( isDiv(flow) ) {
				// Simple content must be wrapped with a paragraph and a span to be added to a div
				spanElement = new SpanElement();
				spanElement.text = " \n";
				spanElement.styleName = "span";
				var paraElement:ParagraphElement = new ParagraphElement();
				paraElement.styleName = "p";
				paraElement.addChild(spanElement);
				DivElement(flow).addChild(paraElement);
			} else {
				trace("Don't know how to add a line break here");
			}
		}
		
		private static function parsePreformatted(xhtml:XML, flow:FlowElement, styleStack:String = ""):void {
			var divElement:DivElement = new DivElement();
			var spanElement:SpanElement;
			var paraElement:ParagraphElement = new ParagraphElement();
			var i:int;
			divElement.styleName = "pre";
			var children:XMLList = xhtml.children();
			//
			if ( isDiv(flow) ) {
				DivElement(flow).addChild(divElement);
				XhtmlToTextFlow.parseChildren(xhtml, divElement, styleStack, true);
			} 
			else if ( isParagraph(flow)) {
				// Add each child to the paragraph, maintaining its spaces and such
				XhtmlToTextFlow.parseChildren(xhtml, flow, styleStack, true);
			}
			if (isSpan(flow)) {
				// Why the hell did you put a <pre> block inside a span element?
				// ... are you trying to drive me crazy? Just adding it as simple content.
				for (i=0; i<children.length(); i++) {
					SpanElement(flow).text += children[i].toXMLString();
				}
			}
		}
		
		public static function parseTable(xhtml:XML, flow:FlowElement):void {
			// parameterize IGNORE_TABLES
			var IGNORE_TABLES:Boolean = true;
			if ( IGNORE_TABLES ) {
				var spanElement:SpanElement = new SpanElement();
				spanElement.text = "[HTML table omitted]";
				var paraElement:ParagraphElement = new ParagraphElement();
				paraElement.styleName = "table";
				paraElement.addChild(spanElement);
				FlowGroupElement(flow).addChild(paraElement);
			} else if ( isDiv(flow) ) {
				var divElement:DivElement = new DivElement();
				divElement.styleName = "table";
				DivElement(flow).addChild(divElement);
				XhtmlToTextFlow.parseChildren(xhtml, flow);
			}  
			
		}
		
		public static function parseImage(xhtml:XML, flow:FlowElement):void {
			var ige:InlineGraphicElement;
			if ( isSpan(flow) ) {
				// FOOL! Why you try to add an image to a span? 
				// You want to open a wormhole to another dimension of suck?
				SpanElement(flow).text += " [Image omitted] ";
				return;
			} else if ( isLink(flow)) {
				// Not sure about adding images to links right now
				trace("Not adding an image to a link");
			}if ( isParagraph(flow) ) {
				// Add the inline to the p
				ige = new InlineGraphicElement();
				ParagraphElement(flow).addChild(ige);
			} else if ( isDiv(flow) ) {
				// Add the inline to a new p and a new div
				// Maybe that'll help it flow?
				ige = new InlineGraphicElement();
				var p:ParagraphElement = new ParagraphElement();
				var d:DivElement = new DivElement();
				d.styleName="image";
				d.addChild(p);
				p.addChild(ige);
				DivElement(flow).addChild(p);
			}
			ige.styleName = "img";
			ige.setStyle("src", xhtml.@src.toString());
			// htmlWidth and height is the suggested values from the html, 
			// .. but the StyleFactory might chart it's own course later
			// The style factory also receives the asset manifest and matches up the DisplayObjects with their FLowELements
			ige.setStyle("htmlWidth", xhtml.@width.toString()); 
			ige.setStyle("htmlHeight", xhtml.@height.toString());
		}
		
		public static function parseUnknownElement(xhtml:XML, flow:FlowElement):void {
			var spanElement:SpanElement;
			if ( isSpan(flow)  ) {
				SpanElement(flow).text += " [Unrecognized content] ";
				SpanElement(flow).text += xhtml.toString();
				SpanElement(flow).text += " [end] ";
			} else if ( isLink(flow) ) {
				spanElement = new SpanElement();
				spanElement.styleName = "code";
				spanElement.text = " [Unrecognized content] " + xhtml.toString() + "  [end] ";
				LinkElement(flow).addChild(spanElement);
			} else if ( isParagraph(flow) ) {
				spanElement = new SpanElement();
				spanElement.styleName = "code";
				spanElement.text = " [Unrecognized content] " + xhtml.toString() + "  [end] ";
				ParagraphElement(flow).addChild(spanElement);
			} else if ( isDiv(flow) ) {
				// Simple content must be wrapped with a paragraph and a span to be added to a div
				spanElement = new SpanElement();
				spanElement.styleName = "code";
				spanElement.text = xhtml.toXMLString();
				var paraElement:ParagraphElement = new ParagraphElement();
				paraElement.styleName = "blockquote";
				paraElement.addChild(spanElement);
				FlowGroupElement(flow).addChild(paraElement);
			} else {
				trace("Don't know how to add this unknown element");
			}
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