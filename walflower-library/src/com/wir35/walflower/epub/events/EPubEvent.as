package com.wir35.walflower.epub.events
{
	import flash.events.Event;

	public class EPubEvent extends Event
	{
		
		public static const LOADING:String = "loading";
		public static const PROGRESS:String = "progressEvent";
		public static const PROGRESS_COMPLETE:String = "progressComplete";
		public static const ERROR:String = "error";
		
		public var message:String;
		public var percentComplete:Number;
		
		public function EPubEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			message = "";
			percentComplete = 0;
		}
		
	}
}