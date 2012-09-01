package ktu.media {
    import flash.events.ActivityEvent;
    import flash.events.EventDispatcher;
    import flash.events.TimerEvent;
    import flash.media.Camera;
    import flash.media.Video;
    import flash.utils.Timer;
    import ktu.events.CameraDetectionEvent;
	
	
	/**
	 * ...
     * 
     * this class will accept a camera, and it will do the checking to see if it works.
     * 
     * 
     * 
	 * @author ktu
	 */
	public class CameraChecker extends EventDispatcher {
		
        protected var _timer				:Timer;                             // the main timer, user for both permissions and camera
		protected var _timerDelay			:uint		= 100;                  // the default delay for testing the camera
		protected var _timerRepeatCount		:uint		= 25;                   // the default repeatCount for testing the camera
		protected var _camFPSAverage		:Number;                            // the average of the fps of the camera we are checking
		protected var _camActivityInit		:Boolean;			                // whether we have passed the camera's activity init phase
		protected var _camActivityAverage	:Number; 			                // the average of the activity of the camera we are checking
		protected var _numTimesGoodCamera	:int		= 0;                    // number of times this camera has shown to work during a single check
		protected var _minTimesGood			:int 		= 5;                    // the min number of times a camera must respond as working
        protected var _video				:Video;                             // the video object to use with the camera to test
        protected var _camera               :Camera;
        
        public function get timerDelay():uint { return _timerDelay; }
        public function set timerDelay(value:uint):void { _timerDelay = value; }
        
        public function get timerRepeatCount():uint { return _timerRepeatCount; }
        public function set timerRepeatCount(value:uint):void { _timerRepeatCount = value; }
        
        public function get minTimesGood():int { return _minTimesGood; }
        public function set minTimesGood(value:int):void { _minTimesGood = value; }
        
        
		public function CameraChecker(){
		
		}
        
        public function check(camera:Camera):void {
            if (_camera) dispose();
            _camera = camera;
            _camActivityInit = true;
			_camActivityAverage = -1;
			_camFPSAverage = -1;
			_numTimesGoodCamera = 0;
			_camera.addEventListener (ActivityEvent.ACTIVITY, onCamActivity);
            _video = new Video();
			_video.attachCamera (_camera);
            constructTimer();
			_timer.start (); // callback function is tickCheckCamera()
        }
        /**
		 * disposes of all objects holding memory in this class																				<br>
		 * 																																	<br>
		 * This method will prepare all objects in this class for garbage collection. This method can be called at any time during
		 * the process of searching for a Camera. 																							<br>
		 * 																																	<br>
		 * *Implemented for IDisposable*
		 */
		public function dispose ():void {
			if (_video) {
				_video.attachCamera (null);
				_video = null;
			}
			if (_camera) disposeCamera();
			if (_timer) disposeTimer();
		}
        /** @private
		 *
		 * capture function for the timer that checks each Camera.
		 *
		 * TimerEvent.TIMER
		 * 		calculates an average of the fps coming from the camera.
		 * 		Checks if we are past the initial camera acitivity phase (when a Camera is first connected to the activity property reads 100 for a period of time)
		 * 		If we are past the camera activity init phase, calculate the average of the activity (this is less crutial)
		 *
		 * TimerEvent.COMPLETE
		 * 		If fps average and activity average are greater than 0, we found a good camera
		 * 		otherwise, it is not a good camera, check the next one
		 *
		 * @param	e
		 */
		protected function tickCheckCamera (e:TimerEvent):void {
			switch (e.type) {
				case TimerEvent.TIMER:
					_camFPSAverage = (_camFPSAverage < 0) ? _camera.currentFPS : ((_camFPSAverage * (_timer.currentCount-1)) + _camera.currentFPS) / _timer.currentCount;
					
					if (_camActivityInit && _camera.activityLevel < 100 ) _camActivityInit = false;
					else _camActivityAverage = (_camActivityAverage < 0) ? _camera.activityLevel : ((_camActivityAverage * (_timer.currentCount-1)) + _camera.activityLevel) / _timer.currentCount;
					if (_camFPSAverage > 0 && _camActivityAverage >= 0) {
						_numTimesGoodCamera ++;
						if (_numTimesGoodCamera > _minTimesGood)
/* SUCCESS */				dispatch (CameraDetectionResult.SUCCESS);
					}
					break;
				case TimerEvent.TIMER_COMPLETE:
/* FAIL*/			dispatch(CameraDetectionResult.NO_SUCCESS);
					break;
			}
		}
        
        
        
        /** @private
		 *
		 * 	prepare Timer object for checking Camera objects
		 */
		protected function constructTimer ():void {
			if (_timer) disposeTimer();
			_timer = new Timer (_timerDelay, _timerRepeatCount);
			_timer.addEventListener (TimerEvent.TIMER,          tickCheckCamera);
			_timer.addEventListener (TimerEvent.TIMER_COMPLETE, tickCheckCamera);
			
		}
		/** @private
		 *
		 * 	prepare Timer object for garbage collection
		 */
		protected function disposeTimer():void {
			if (_timer.running) _timer.stop();
			_timer.removeEventListener (TimerEvent.TIMER,          tickCheckCamera);
			_timer.removeEventListener (TimerEvent.TIMER_COMPLETE, tickCheckCamera);
			_timer = null;
		}
        /** @private
		 *
		 * 	prepare Camera object for garbage collection
		 */
		protected function disposeCamera ():void {
			_camera.removeEventListener (ActivityEvent.ACTIVITY, onCamActivity);
			_camera = null;
		}
        /** @private
		 *
		 * 	This function will dispatch the proper event, then dispose of itself
		 * @param	result
		 */
		protected function dispatch (result:String):void {
			if (result != CameraDetectionResult.SUCCESS) _camera = null;
            var e:CameraDetectionEvent = new CameraDetectionEvent(CameraDetectionEvent.RESOLVE, _camera, result);
			dispose ();
			dispatchEvent (e);
		}
        
        /** @private
		 * 	The Camera object will not update its activity property unless an event has been added to listen for activity changes
		 */
		protected function onCamActivity(e:ActivityEvent):void { }
	}

}