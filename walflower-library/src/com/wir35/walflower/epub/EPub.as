/*
 * EPub class holds the model for an ebook in EPub format
 * It depends on nochump zip library for reading the zip container
 */
package com.wir35.walflower.epub
{ 
	import com.wir35.walflower.epub.events.EPubEvent;
	import com.wir35.walflower.xhtml.XhtmlToTextFlow;
	
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.utils.ByteArray;
	import flash.utils.IDataInput;
	import flash.utils.getTimer;
	
	import flashx.textLayout.elements.FlowElement;
	import flashx.textLayout.elements.TextFlow;
	
	import mx.core.FlexGlobals;
	
	import nochump.util.zip.*;
	
	public final class EPub extends EventDispatcher {
		
		protected var _zipFile:ZipFile;
		protected var _loadedData:IDataInput;
		
		protected var _rootPath:String;
		protected var _opfFilePath:String; // the main ops with manifest
		protected var _opfDoc:XML;
		protected var _ncxFilePath:String;
		protected var _ncxDoc:XML;
		protected var _metadata:Object;
		protected var _spine:NcxSpine;
		protected var _toc:NcxContents;
		protected var _images:Object;
		
		
		protected var _processingItems:Array;
		protected var _processingImages:Array;
		protected var _processingCopy:Object;
		protected var _processingSections:Array;
		protected var _finishedItemCount:Number = 0;
		protected var _totalItemCount:Number = 0;
		protected var _startTime:Number;

		public var opf:Namespace;
		public var ncx:Namespace;
		
		public static const FUNNY_MESSAGES:Array = 	["Pouring another line of hot lead...", "Unclogging the interwebs...", 
			"Sprucing the place up...",	"Counting picas...", "Fixing another set of dumb quotes...", "Hyphenating word 99,1384...",
			"Taking a break...", "Almost done...", "Paper jam...", "PC Load Letter..?", "Converting metric to english...",
			"Calculating perfect ratios..." , "Making Flash run slow..." ];
		
		/**
		 * Construct an ePub object by passing the binary data input from the loader.
		 * Listen for EPubEvent and receive notifications on how the loading/translating is progressing.
		 * Relies on an enterFrame handler to batch the work across many frames.
		 * Unzipping especially can take a long time for large ePub docs.
		 * @param pData the binary data from the loader
		 */
		public function EPub(pData:IDataInput) {
			
			XML.ignoreComments = true;
			XML.ignoreWhitespace = true;
			XML.ignoreProcessingInstructions = true;
			
			_startTime = getTimer();
			
			_loadedData = pData;
			_zipFile = new ZipFile(_loadedData);
			build(); 
		}
		
		
		protected function build():void {
			
			// find the container.xml and get the root OPS and NCX files
			getRootFiles();
			// Start building the book
			makePagesFromOpf();
			
			// makeTocFromNcx();
			
		}
		
		protected function getRootFiles():void {
			
			var containerDoc:XML = getXMLFromZip('META-INF/container.xml');
			var xmlns:Namespace = containerDoc.namespace();			
			var rootFileNode:XML = containerDoc.xmlns::rootfiles[0].xmlns::rootfile[0];
			_opfFilePath = rootFileNode.attribute('full-path').toString();
			_opfDoc = getXMLFromZip(_opfFilePath);
			
			_rootPath = "";
			if (_opfFilePath.indexOf('/')) {
			 	_rootPath = _opfFilePath.slice(0, _opfFilePath.lastIndexOf('/')+1);
			}

			opf = _opfDoc.namespace(); // http://www.idpf.org/2007/opf
			var ncxItem:XMLList = _opfDoc.opf::manifest.opf::item.(@id == "ncx");	
			_ncxFilePath = ncxItem[0].@href.toString();
			_ncxDoc = getXMLFromZip(_rootPath+_ncxFilePath);
			ncx = _ncxDoc.namespace(); // http://www.daisy.org/z3986/2005/ncx/
		}
		
		/*
		 * This process is chunked by frame due to the massive processing overhead
		 */
		protected function makePagesFromOpf():void {
			
			_metadata = new Object();
			var dc:Namespace = new Namespace("http://purl.org/dc/elements/1.1/");
			_metadata.title = _opfDoc.opf::metadata.dc::title.toString();
			_metadata.creator = _opfDoc.opf::metadata.dc::creator.toString();
			
			_spine = new NcxSpine();
			_images = new Object();
			_processingSections = new Array();
			_processingItems = new Array();
			_processingImages = new Array();
			
			var extractedItems:Array = new Array();
			var itemNodes:XMLList = _opfDoc.opf::manifest.opf::item;			
			var i:int;
			var id:String;
			
			// Pull all html and image items out of the manifest into an assoc array by id
			var mimeType:String
			for (i=0; i<itemNodes.length(); i++) {
				mimeType= itemNodes[i].attribute("media-type").toString();
				id = itemNodes[i].@id.toString();
				if ( mimeType == 'application/xhtml+xml') {
					extractedItems[id] = new Object();
					extractedItems[id].path = itemNodes[i].@href.toString();
					extractedItems[id].zipPath = _rootPath + itemNodes[i].@href.toString();
				} else if ( mimeType == 'image/jpeg' || mimeType == 'image/gif' || mimeType == 'image/png') {
					// This takes too long to do at start-up, so later on, we might only do this when we need them
					var newImg:Object = new Object();
					newImg.path = itemNodes[i].@href.toString();
					newImg.zipPath = _rootPath + itemNodes[i].@href.toString();
					_processingImages.push(newImg);
				}
			}
			
			// Place all the extractedItems into processingItems in order dictated by spine
			var spineNodes:XMLList = _opfDoc.opf::spine.opf::itemref;
			for (i=0; i<spineNodes.length(); i++) {
				id = spineNodes[i].@idref.toString();
				_processingItems.push(extractedItems[id]);
			}
			
			// count
			_totalItemCount = _processingItems.length*3 + _processingImages.length;
			
			// dispatch progress event
			var pe:EPubEvent = new EPubEvent(EPubEvent.PROGRESS);
			pe.percentComplete = 5;
			pe.message = "Meta data loaded...";
			dispatchEvent(pe);
			
			// Begin to iterate over the items
			//   and unzip/parse/process a little bit each frame until the whole book is built
			FlexGlobals.topLevelApplication.addEventListener(Event.ENTER_FRAME, processSections);
		}
		
		/*
		 * Executes every frame until the book is loaded
		 */
		protected function processSections(e:Event):void {
			
			var pe:EPubEvent = new EPubEvent(EPubEvent.PROGRESS);
			_finishedItemCount++;
			pe.percentComplete = calculatePercentageComplete();
			pe.message = "Building sections...";
			
			if (_processingImages.length > 0) {					
				// We have images to process
				pe.message = "Unzipping " + _processingImages[0].path + "...";
				processImage(_processingImages.shift() );
				dispatchEvent(pe);
			} else if (_processingSections.length > 0) {
				// We have chopped up body content pulled out of the processing copy to make into sections
				pe.message = "Building " + _processingCopy.path + " section " + _processingSections.length + "...";
				processXMLSection( _processingSections.shift() );
				if (_processingSections.length == 0) {
					_processingCopy = null; // we're done with this chunk
				}
				dispatchEvent(pe);
			} else if (_processingCopy) {
				// We have a text blob pulled out of the zip to chop up
				pe.message = "Reading " + _processingCopy.path + "...";
				processStringCopy( _processingCopy );
				dispatchEvent(pe);
			} else if (_processingItems.length > 0) {
				// We need to unzip the next item
				pe.message = "Unzipping " + _processingItems[0].path +"...";
				processZipItem( _processingItems.shift() );
				dispatchEvent(pe);
			} else {
				// This is the last step
				FlexGlobals.topLevelApplication.removeEventListener(Event.ENTER_FRAME, processSections);
				// Do the final step. Make the table of contents
				processTocFromNcx();
				// dispatch the complete event
				var ce:EPubEvent = new EPubEvent(EPubEvent.PROGRESS_COMPLETE);
				ce.percentComplete = 100;
				ce.message = "Book finished building...";
				dispatchEvent(ce);
				
				var totalTime:Number = Math.round( (getTimer() - _startTime) / 1000);
				
				trace("It took " +  totalTime + " seconds to unzip and process this ePub.");
				trace("Book ready");
			}
		}
		
		protected function calculatePercentageComplete():Number {
			// Find the total number of objects 
			var pc:Number = Math.floor( (_finishedItemCount / _totalItemCount) * 100 );
			if (pc > 100) { pc = 100; }
			return pc;
		}
		
		// Called when a text flow needs to use an image
		public function unzipImage(imagePath:String):void {
			// unimplemented
		}
		
		// unzips and loads an image
		protected function processImage(img:Object):void {
			var entry:ZipEntry = _zipFile.getEntry(img.zipPath);
			var data:ByteArray = _zipFile.getInput(entry);
			var image:Object = new Object();
			image.loader = new Loader();
			image.loader.loadBytes(data);
			image.path = img.path;
			_images[img.path] = image;
		}
		
		// Takes the split sections and builds OpfPages for each
		//   and adds them to the spine in order
		protected function processXMLSection(xmlSection:XML):void {
			var nextSection:OpfPage = new OpfPage();
			nextSection.path = _processingCopy.path;
			nextSection.pageXML = xmlSection;
			nextSection.parseTextFlow();
			_spine.push(nextSection);
		}
		
		// Takes the unzipped string content, and turns it into a set of XML docs
		// Most cpu intensive part of this whole op
		protected function processStringCopy(stringCopy:Object):void {
			// no breaking spaces are giving us hell. must kill them before we make XML!
			var cleanString:String = stringCopy.pageString.replace(/&nbsp;/g, ' ');
			var pageXHTML:XML = new XML(cleanString); 
			var pageBody:XML = pageXHTML..*::body[0];
			var flatPage:XML = <body/>; 
			// This sucks. Blast through the XML file and flatten any extraneous divs
			// This enables us to treat the flow as heads and paragraphs and inlines,
			//   and easily split into seperate sections. This makes bunny cry
			XhtmlToTextFlow.flattenElements(pageBody, flatPage); 
			// Now split up this giant flat xml file into many sections (if needed)
			_processingSections = XhtmlToTextFlow.splitIntoSections(flatPage);
			_totalItemCount += _processingSections.length -1;
		}
		
		// Unzips the item into the processingCopy
		protected function processZipItem(zipItem:Object):void {
			_processingCopy = new Object();
			_processingCopy.path = zipItem.path;
			_processingCopy.pageString = getStringFromZip(zipItem.zipPath);
		}
		
		protected function processTocFromNcx():void {
			
			_toc = new NcxContents();
			// Get the array of navpoint nodes. Ignore nesting for now
			var items:XMLList = _ncxDoc.ncx::navMap..ncx::navPoint;
			
			var o:Object;
			var points:Array = new Array();
			for (var i:int=0; i<items.length(); i++) {
				var p:NcxNavPoint = new NcxNavPoint();
				p.id = items[i].@id.toString();
				var c:String = items[i].ncx::content[0].@src.toString();
				var path:String = c.split('#')[0];
				var anchor:String = c.split('#')[1];
				// p.page = _spine.getPageByPath(c);
				if (path) { p.path = path; }
				if (anchor) { p.elementId = anchor; }
				p.playOrder = parseInt(items[i].@playOrder);
				p.navLabel = items[i].ncx::navLabel[0].ncx::text[0].toString();
				p.level = 0; // all level 0 for now, no tree TOC
				points.push(p);
			}
			// sort points array by playOrder ascending, jst in case it's out of order in the xml
			points.sortOn('playOrder', Array.NUMERIC);
			
			// Fully qualify each nav point
			// Each one is a file link and maybe an internal anchor
			// We'll figure out the section and element reference for each link
			for (i=0; i<points.length; i++) {
				fullyQualifyNavPoint(points[i]);
				_toc.addNavPoint(points[i]);
			}
			
			
		}
		
		/*
		 * Public API
		 */
		 
		 public function get toc():NcxContents {
		 	return _toc;
		 }
		
		public function get spine():NcxSpine {
			return _spine;
		}
		
		public function get metadata():Object {
			return _metadata;
		}
		
		public function get images():Object {
			return _images;
		}
		
		// Given a navpoint, look up the exact section and element that this point describes
		//  and populate it with all the data it needs
		public function fullyQualifyNavPoint(np:NcxNavPoint):void {
			var i:int;
			if (np.element) {
				// If it's an element reference with aempty section info, find the section and path and populate
				if (np.element.id) { np.id = np.element.id; }
				if (!np.page) {
					for (i=0; i<_spine.length; i++) {
						if (np.element.getTextFlow() == _spine.pages[i].textFlow) {
							np.page = _spine.pages[i];
							np.path = _spine.pages[i].path;
						}
					} 
				}
			} else if (np.path) {
				// Iterate over sections to find the path
				for (i=0; i<_spine.length && !np.element; i++) {
					if (_spine.pages[i].path == np.path) {
						// this could be it
						np.page = _spine.pages[i];
						if (np.elementId) {
							// see if this element id exists in the section's text flow
							var e:FlowElement = TextFlow(_spine.pages[i].textFlow).getElementByID(np.elementId);
							if (e) {
								np.element = e;
								break; // found it, break out of loop
							}
						} else {
							// there is no anchor. So link to the first section, first element
							np.page = _spine.pages[i];
							np.element = TextFlow(_spine.pages[i].textFlow).getFirstLeaf();
							break;
						}
					}
				}
			}
				
		}
		
		
		/*
		 * Utilities
		 */
		
		
		
		protected function getStringFromZip(pEntryTitle:String):String {
			var entry:ZipEntry = _zipFile.getEntry(pEntryTitle);
			var data:ByteArray = _zipFile.getInput(entry); 
			return data.toString();
		}
		
		protected function getXMLFromZip(pEntryTitle:String):XML {
			var s:String = getStringFromZip(pEntryTitle);
			var x:XML = new XML( s );
			return x;
		}
		
	}
}