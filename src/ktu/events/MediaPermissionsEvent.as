/**
 * * File:	MediaPermissionsEvent.as;
 * Author:	Ktu; 							[blog.cataclysmicrewind.com]
 * Updated:	2011.9.21
 * Thanks: Pavel fljot
 *
 * This class is free to use and modify, however I request that the header (except example code),
 * and original package remain intact.
 * If you choose to modify it, please contact me before releasing the product.
 * 		[ktu_flash@cataclysmicrewind.com]
 *
 */
package ktu.events {
	
	import flash.events.Event;
	
	/**
	 *
	 * 	A CameraDetection object dispatches a CameraDetectionEvent
	 *
	 *
	 */
	public class MediaPermissionsEvent extends Event {

		/**
		 * event value for when CameraDetection has completed its process
		 */
		public static const RESOLVE			:String = "mediaPermissionsResolved";
		
        
		private var _code:String;
		/**
		 * String code associated with the event
		 */
		public function get code():String { return _code; }
		
		
		
		
		private var _remembered:Boolean;
		/**
		 * Specifies whether the user had remembered their permission settings from a previous session
		 */
		public function get remembered():Boolean { return _remembered; }
		/**
		 *  Constructor
		 *
		 * @param	type
		 * @param	camera
		 * @param	code
		 * @param	bubbles
		 * @param	cancelable
		 */
		public function MediaPermissionsEvent (type:String, code:String = null, remembered:Boolean = false,  bubbles:Boolean = false, cancelable:Boolean = false ):void {
			_code = code;
			_remembered = remembered;
			super (type, bubbles, cancelable);
		}
	}
}