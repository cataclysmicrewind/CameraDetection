package ktu.system {
	import flash.events.Event;
	
	/**
	 * ...
	 * @author ktu
	 */
	public class SecurityPanelEvent extends Event {
		
		public var isClosed:Boolean;
		
		public function SecurityPanelEvent(type:String, isClosed:Boolean, bubbles:Boolean = false, concelable:Boolean = false) {
			this.isClosed = isClosed;
			super(type, bubbles, cancelable);
		}
		
	}

}