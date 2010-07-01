package 
{
	import com.wir35.walflower.epub.EPub;
	import com.wir35.walflower.epub.OpfPage;
	import com.wir35.walflower.epub.events.EPubEvent;
	import UpdateEvent;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.IDataInput;
	
	import flashx.textLayout.elements.FlowElement;
	import flashx.textLayout.elements.TextFlow;
	
	/*
	 * Determines the behavior of a Reader application
	 */
	[Bindable]
	public class Model extends EventDispatcher
	{
		protected var _book:EPub;
		protected var _bookReady:Boolean;
		protected var _statusMessage:String;
		protected var _percentLoaded:Number;
		
		
				
		public static const FUNNY_MESSAGES:Array = 	["Pouring another line of hot lead...", "Unclogging the interwebs...", 
			"Sprucing the place up...",	"Counting picas...", "Fixing another set of dumb quotes...", "Hyphenating word 99,1384...",
			"Taking a break...", "Almost done...", "Paper jam...", "PC Load Letter..?", "Converting metric to english...",
			"Calculating perfect ratios..." , "Making Flash run slow..." ];
				
		public function Model() {
			_bookReady = false;
			_statusMessage = "Initializing...";
			_percentLoaded = 1;
		}
		
		public function set book(b:EPub):void {
			_book = b;
			update();
		}
		
		public function get book():EPub {
			return _book;
		}
		
		public function get statusMessage():String {
			return _statusMessage;
		}
		
		public function get percentLoaded():Number { 
			return _percentLoaded;
		}
		
		public function get bookReady():Boolean {
			return _bookReady;
		}
		
		
		public function update():void {
			trace("Model update:" + _statusMessage);
			dispatchEvent( new UpdateEvent(UpdateEvent.UPDATE) ); 
		}
		
		
		
		/*
		 * Book loading
		 */
		
		public function loadBook(bookUrl:String):void {
			var loader:URLLoader = new URLLoader();
			loader.dataFormat = URLLoaderDataFormat.BINARY;
			loader.addEventListener(Event.COMPLETE, onLoaded);
			loader.addEventListener(ProgressEvent.PROGRESS, onProgress);
			loader.addEventListener(IOErrorEvent.IO_ERROR, onLoadError);
			loader.load( new URLRequest(bookUrl) );
			trace("Loading book...");
			_statusMessage = "Loading book...";
			_percentLoaded = 2;
			update();
		}
		
		private function onProgress(e:ProgressEvent):void {
			_percentLoaded = Math.floor( 100 * e.bytesLoaded / e.bytesTotal);
			_statusMessage = "Loading EPUB file..." + _percentLoaded + "%";
			update();
		}
		
		private function onLoaded(e:Event):void {
			trace("Book epub file loaded");
			var loadedData:IDataInput = IDataInput( e.target.data );
			_book = new EPub(loadedData);
			// now add event listeners
			_book.addEventListener(EPubEvent.PROGRESS_COMPLETE, bookReadyHandler);
			_book.addEventListener(EPubEvent.PROGRESS, bookProgressHandler);
		}
		
		// Book is done loading + parsing and is ready to read
		private function bookReadyHandler(e:EPubEvent):void {
		    _bookReady = true;
			update();
		}
		
		private function bookProgressHandler(e:EPubEvent):void {
			// Sometimes it'll say something funny
			if (Math.random() > 0.1) {
				_statusMessage = e.message;
			} else {
				_statusMessage = FUNNY_MESSAGES[ Math.floor(Math.random()*FUNNY_MESSAGES.length) ];
			}
			
			_percentLoaded = e.percentComplete;
			update();
			
		}
		
		private function onLoadError(e:IOErrorEvent):void {
			trace("Book load error");
		}
		
	}
}