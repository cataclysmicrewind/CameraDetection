/**
 * author:	ktu; 							[blog.cataclysmicrewind.com]
 * updated:	2012.10.06;
 * 
 * This class is free to use and modify, however I request that the header (except example code),
 * and original package remain intact.
 * If you choose to modify it, please contact me before releasing the product.
 * 		[ktu_flash@cataclysmicrewind.com]
 * 
 */
package ktu.media {
	
    import flash.events.ActivityEvent;
    import flash.events.EventDispatcher;
    import flash.events.TimerEvent;
    import flash.media.Camera;
    import flash.media.Video;
    import flash.utils.Timer;
    import ktu.events.CameraDetectionEvent;
	
	
	/**
     * this class will accept a camera, and it will do the checking to see if it works.
     * 
     * this class does some important stuff!
     * 
     * Flash is terrible with Camera Objects... (not sure about Microphone objects honestly)
     * 
     * here are some scenarios:
     * 
     *      first, how about the ideal situation: the user has a camera, and no other applications are using it.
     *          if you ask Camera.getCamera() you will get a valid instance, and the Camera will work!
     *      next, let us say that the user has a camera and has Skype running
     *          if you ask Camera.getCamera() it will return a valid instance, however the Camera a will NOT work!
     * 
     * if for some reason the camera you get is already in use, it has an expected behaviour (determined from my testing)
     *      this behaviour is to report -1 or 100 for activity (i believe depending on flash player version)
     *      and to report 0 for fps.
     * 
     * this class will check for a period of time (configurable) to make sure that the camera is working.
     * this class determines that a camera is working when it finally reports an fps and some activity (outside the extremes)
     *      
     * 
	 */
	public class CameraChecker extends EventDispatcher {
		
        protected var _timer				:Timer;                             // the main timer, user for both permissions and camera
		protected var _timerDelay			:uint		= 100;                  // the default delay for testing the camera
		protected var _timerRepeatCount		:uint		= 30;                   // the default repeatCount for testing the camera
		protected var _camFPSAverage		:Number;                            // the average of the fps of the camera we are checking
		protected var _camActivityInit		:Boolean;			                // whether we have passed the camera's activity init phase
		protected var _camActivityAverage	:Number; 			                // the average of the activity of the camera we are checking
		protected var _numTimesGoodCamera	:int		= 0;                    // number of times this camera has shown to work during a single check
		protected var _minTimesGood			:int 		= 5;                    // the min number of times a camera must respond as working (this is mostly for eliminating delays)
        protected var _video				:Video;                             // the video object to use with the camera to test
        protected var _camera               :Camera;
		protected var _customVideo			:Boolean	= false;
        
        public function get timerDelay():uint { return _timerDelay; }
        public function set timerDelay(value:uint):void { _timerDelay = value; }
        
        public function get timerRepeatCount():uint { return _timerRepeatCount; }
        public function set timerRepeatCount(value:uint):void { _timerRepeatCount = value; }
        
        public function get minTimesGood():int { return _minTimesGood; }
        public function set minTimesGood(value:int):void { _minTimesGood = value; }
        
        
        public function check(camera:Camera, video:Video = null):void {
            if (_camera) dispose();
			_customVideo = Boolean(video);
            _camera = camera;
            _camActivityInit = true;
			_camActivityAverage = -1;
			_camFPSAverage = -1;
			_numTimesGoodCamera = 0;
			_camera.addEventListener (ActivityEvent.ACTIVITY, onCamActivity);
			_video = _customVideo ? video : new Video();
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
		 */
		public function dispose ():void {
			if (_video) {
				if (!_customVideo) _video.attachCamera (null);
				_video = null;
			}
			if (_camera) {
                _camera.removeEventListener (ActivityEvent.ACTIVITY, onCamActivity);
                _camera = null;
            }
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
		 * 		this only gets fired if the camera doesn't work.
		 *
		 * @param	e
		 */
		protected function tickCheckCamera (e:TimerEvent):void {
			switch (e.type) {
				case TimerEvent.TIMER:
					_camFPSAverage = (_camFPSAverage < 0) ? _camera.currentFPS : ((_camFPSAverage * (_timer.currentCount-1)) + _camera.currentFPS) / _timer.currentCount;
					if (_camActivityInit && (_camera.activityLevel != -1 && _camera.activityLevel < 100)) _camActivityInit = false;
					else _camActivityAverage = (_camActivityAverage < 0) ? _camera.activityLevel : ((_camActivityAverage * (_timer.currentCount - 1)) + _camera.activityLevel) / _timer.currentCount;
					if (_camFPSAverage > 0 && _camActivityAverage >= 0) {
						_numTimesGoodCamera ++;
/*SUCCESS*/			    if (_numTimesGoodCamera > _minTimesGood) dispatch (CameraDetectionResult.SUCCESS);
					}
					break;
				case TimerEvent.TIMER_COMPLETE:
/*FAIL*/			dispatch(CameraDetectionResult.NO_SUCCESS);
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
			_timer.stop();
			_timer.removeEventListener (TimerEvent.TIMER,          tickCheckCamera);
			_timer.removeEventListener (TimerEvent.TIMER_COMPLETE, tickCheckCamera);
			_timer = null;
		}
        /** @private
		 *
		 * 	This function will dispatch the proper event, then dispose of itself
		 * @param	result
		 */
		protected function dispatch (result:String):void {
			if (result != CameraDetectionResult.SUCCESS) _camera = null;
			var video:Video = _customVideo ? _video : null;
            var e:CameraDetectionEvent = new CameraDetectionEvent(CameraDetectionEvent.RESOLVE, _camera, result, video);
			dispose ();
			dispatchEvent (e);
		}
        
        /** @private
		 * 	The Camera object will not update its activity property unless an event has been added to listen for activity changes
		 */
		protected function onCamActivity(e:ActivityEvent):void { }
	}

}