/**
 * * File:	CameraDetectionEvent.as;
 * Author:	Ktu; 							[blog.cataclysmicrewind.com]
 * Updated:	12.17.10;
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
	import flash.media.Camera;
	import flash.media.Video;
	
	/**
	 *
	 * 	A CameraDetection object dispatches a CameraDetectionEvent
	 *
	 *
	 */
	public class CameraDetectionEvent extends Event {

		/**
		 * event value for when CameraDetection has completed its process
		 */
		public static const RESOLVE			:String = "cameraResolved";
		
		
		private var _camera:Camera;
		private var _video:Video;
		/**
		 * returns the camera associated with the event
		 */
		public function get camera():Camera { return _camera; }
		
        
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
		
		public function get video():Video { return _video; }
		/**
		 *  Constructor
		 *
		 * @param	type
		 * @param	camera
		 * @param	code
		 * @param	bubbles
		 * @param	cancelable
		 */
		public function CameraDetectionEvent (type:String, camera:Camera = null, code:String = null, video:Video = null, remembered:Boolean = false,  bubbles:Boolean = false, cancelable:Boolean = false ):void {
			_camera = camera;
			_code = code;
			_video = video;
			_remembered = remembered;
			super (type, bubbles, cancelable);
		}
	}
}