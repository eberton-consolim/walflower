package 
{
	import flash.events.Event;

	public class UpdateEvent extends Event
	{
		public static const UPDATE:String = "update";
		public static const RESIZE:String = "resize";
		
		public function UpdateEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		
	}
}