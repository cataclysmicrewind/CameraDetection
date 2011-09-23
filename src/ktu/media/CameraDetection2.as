/**
 * * File:	CameraDetection.as;
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
package ktu.media {
	
	import flash.display.Stage;
	import flash.events.ActivityEvent;
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.media.Camera;
	import flash.media.Video;
	import flash.utils.Timer;
	import ktu.events.CameraDetectionEvent;
	import ktu.events.MediaPermissionsEvent;
	import ktu.media.MediaPermissions;
	
	
	
	
	/**
	 *  dispatched when the class has finished checking the cameras.
	 *
	 * All codes come through this one event. In your event listener function, switch the CameraDetectionEvent.code property			<br>
	 * 																														<br>
	 * ex:																													<br><listing version="3">
	 * 	function onCameraResolve (e:CameraDetectionEvent):void {
	 * 		switch (e.code) {
	 * 			case CameraDetectionResult.SUCCESS:
     *          case CameraDetectionResult.NO_SUCCESS:
	 * 			case CameraDetectionResult.NO_CAMERAS:
	 * 			case CameraDetectionResult.NO_PERMISSION:
	 * 		}
	 *  }																													</listing>
	 */
	[Event(name="cameraResolved", type="ktu.media.CameraDetectionEvent")]

	
	/**
	 *
	 *  CameraDetection searches all available Camera objects to find the first working Camera.								<br>
	 * 																														<br>
	 * 																														<br>
	 * 		This class does one thing; Find the first available working Camera object. 										<br>
	 * 																														<br>
	 *
	 * 	To begin checking for the right camera to use, call begin();														<br>
	 *  To stop the process before it is finished, call dispose();															<br>
	 *  Use CameraDetection.detectionDelay and CameraDetection.detectionRepeatCount to set the 								<br>
	 *     delay and repeatCount of the timer used while checking a camera													<br>
	 * 																														<br>
	 *																														<br>
	 *  Once an event is dispatched from this class, the dispose method is called automatically								<br>
	 *																														<br>
	 *																														<br>
	 * 																														<br>
	 * 	@example																											<listing version="3">
	import ktu.events.CameraDetectionEvent;
	import ktu.media.CameraDetection;
	import ktu.media.CameraDetectionResult;

	var video:Video = new Video();
	addChild(video);

	var cd:CameraDetection = new CameraDetection ();
	cd.addEventListener(CameraDetectionEvent.RESOLVE, onResolve);
	cd.begin();

	function onResolve(e:CameraDetectionEvent):void {
		switch (e.code) {
			case CameraDetectionResult.SUCCESS :
				video.attachCamera(e.camera);
				break;
            case CameraDetectionResult.NO_SUCCESS:
                trace("No Cameras in the list responded properly");
				break;
			case CameraDetectionResult.NO_PERMISSION :
				trace("Camera access denied");
				break;
			case CameraDetectionResult.NO_CAMERAS :
				trace("There are no Cameras installed");
				break;
		}
	}																														</listing>
	 *
     *
     *
	 */
	public class CameraDetection2 extends EventDispatcher {
		
		private var _camera						:Camera;                            // the camera object we are testing
		private var _currentCameraIndex			:uint		= 0;                    // the current index of the camera we are testing
		private var _numCameras					:uint;                              // the number of cameras in the list
		private var _defaultCameraName			:String;                            // the name of the default camera
		private var _video						:Video;                             // the video object to use with the camera to test
		
		private var _timer						:Timer;                             // the main timer, user for both permissions and camera
		private var _defaultDelay				:uint		= 100;                  // the default delay for testing the camera
		private var _defaultRepeatCount			:uint		= 25;                   // the default repeatCount for testing the camera
		private var _camFPSAverage				:Number;                            // the average of the fps of the camera we are checking
		private var _camActivityInit			:Boolean;			                // whether we have passed the camera's activity init phase
		private var _camActivityAverage			:Number; 			                // the average of the activity of the camera we are checking
		private var _numTimesGoodCamera			:int		= 0;                    // number of times this camera has shown to work during a single check
		private var _minTimesGood				:int 		= 3;                    // the min number of times a camera must respond as working
        private var _rememberedPermissions      :Boolean    = false;                // true = the permissions dialog did not show once || false = permissions dialog did show
		
		private var _stage						:Stage;                             // ref to the stage for permissions checking
		private var _mediaPermissions			:MediaPermissions;
		
		
		
		/**
		 *
		 * 	Very sad to say, that a reference to the stage is required with the new fix.									<br/>
		 *																													<br/>
		 *  The Problem:																									<br/>
		 * 		A user has previously selected to remember the decision of Deny for privacy settings in your domain.		<br/>
		 * 		Developer uses attachCamera function to trigger the dialog asking for permission,							<br/>
		 * 		The dialog simply never shows up.																			<br/>
		 *																													<br/>
		 *  The Fix:																										<br/>
		 * 		* Thanks to Philippe Piernot for the code from https://bugs.adobe.com/jira/browse/FP-41						<br/>
		 *																													<br/>
		 * 		Attempt to draw the stage into a BitmapData using bitmap.draw();											<br/>
		 * 		If the dialog is open, a SecurityError will be thrown.														<br/>
		 * 			There by we can tell if the dialog never shows up														<br/>
		 * 			Thus informing us that the user had selected remember with deny.										<br/>
		 *
		 */
		public function CameraDetection2 (stage:Stage):void {
			_stage = stage;
			_mediaPermissions = new MediaPermissions(_stage);
		}
		
		/**
		 * repeatCount property of the timer used while checking a Camera object										<br>
		 *
		 * This value along with the detectionDelay property will determine how long this object will spend
		 * checking each Camera object.
		 */
		public function get detectionRepeatCount():uint { return _defaultRepeatCount; }
		public function set detectionRepeatCount(value:uint):void {
			_defaultRepeatCount = value;
			if (_timer) _timer.repeatCount = value;
		}
		/**
		 * delay property of the timer used while checking a Camera object												<br>
		 *
		 * This value along with the detectionRepeatCount property will determine how long this object will spend
		 * checking each Camera object.
		 */
		public function get detectionDelay():uint { return _defaultDelay; }
		public function set detectionDelay (value:uint):void {
			_defaultDelay = value;
			if (_timer) _timer.delay = value;
		}
        /**
         * property telling wether the user had previously chosen 'remember my decision' in the settings dialog.
         *
         * This value is used for statistics only. It is interesting to find if users are actually using 'remember' and thus
         *  we can determine how our users use the application.
		 *
		 * This property is only useful the FIRST time you run the code. If the user selects allow, then you dispose the camera
		 * and detect the camera again, the class will think they selected remember. Where the real issue is that they have already given
		 * this session permission.
		 *
		 * NOTE: since cameraDetection automatically calls dispose() when it's done, be wary of garbage collection... If accessed
		 * 		 in the event that is dispatched you will be fine, but after it may not be around if you have no other references to the object.
         */
        public function get rememberedPermissions ():Boolean {
            return _rememberedPermissions;
        }
		/**
		 * setting for which way CameraDetection will ask for permission
		 *
		 * QUICK = Video.attachCamera(); this will trigger a quick "Camera and Microphone Access" dialog.
		 * 			It only contains an "Allow" and "Deny" radio button.
		 * 			If the user had selected "Remember" in the Privacy dialog to "deny" then this dialog will not show up.
		 * 			If this happens, then no events get triggered, thus requiring the Bitmap.draw(stage) hack to find out if it ever does show up.
		 *
		 * PRIVACY = Security.showSettings(SecurityPanel.PRIVACY); this will trigger the full Settings dialog for the flash player, showing the
		 * 			 "Privacy" tab. In here there is an "Allow" and "Deny" radio buttons and also a "Remember" checkbox.
		 * 			 Using this, there is no worry that a dialog won't show and it won't trigger events.
		 */
		public function get permissionsMode ():String { return _mediaPermissions.mode;	}
		public function set permissionsMode (value:String):void {
			if (value == MediaPermissions.QUICK_ACCESS || value == MediaPermissions.PRIVACY_DIALOG) _mediaPermissions.mode = value;
		}
		
		public function get mediaPermissions():MediaPermissions {
			return _mediaPermissions;
		}
		/**
		 * begin searching for the first working Camera object. 														<br>
		 * 																												<br>
		 * This method first checks the defaultCamera. If using a Mac operating system, this class will check the last Camera
		 * object first because normally, the webcam Camera object on Mac laptops is at the bottom of the list.
		 */
		public function begin ():void {
			_video = new Video ();
			_numCameras = Camera.names.length;
			
			
			if (mediaPermissions.checkCameraAvailability())
/* FAIL */		dispatch (CameraDetectionResult.NO_CAMERAS);

			_camera = Camera.getCamera ();
			_defaultCameraName = _camera.name;
			
			if (mediaPermissions.havePermission()) {
                _rememberedPermissions = true;  // if default camera is not muted, then remember was checked with allow, no dialog will show NOTE, this is only true the FIRST time this code is run in an swf.
				havePermissions ();
			} else {
				_mediaPermissions.addEventListener(MediaPermissionsEvent.RESOLVE, onMediaPermissionsResolve);
				_mediaPermissions.getPermission(Camera);
			}
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
		 * We were given permissions, so start checking the first camera
		 *
		 */
		private function havePermissions():void{
			constructTimer();
			checkCamera ();
		}
		
		
		/** @private
		 *
		 * begin checking a camera
		 *
		 * 	resets values, add eventlistener, attach camera to video, then start the timer
         *
         * we are checking a new camera, so the values must be reset. The Activity event must be listened for
         * otherwise that value does not get updated.
		 *
		 */
		private function checkCamera ():void {
			_camActivityInit = true;
			_camActivityAverage = -1;
			_camFPSAverage = -1;
			_numTimesGoodCamera = 0;
			_camera.addEventListener (ActivityEvent.ACTIVITY, onCamActivity);
			_video.attachCamera (_camera);
			_timer.reset ();
			_timer.start (); // callback function is tick()
		}
		/** @private
		 *
		 * 	prepares next Camera for checking.
		 *
		 * 		Dispose of previous camera
		 * 		if haven't checked all cameras, get the next camera and check it
         *      if the camera we are checking is the default, skip it, cause it has already been checked
		 * 		if all cameras have been checked, FAIL, no cameras work
		 *
		 */
		private function nextCamera ():void {
			_video.attachCamera (null);
			disposeCamera();
			if (_currentCameraIndex < _numCameras) {
				_camera = Camera.getCamera ( String (_currentCameraIndex) );
				_currentCameraIndex ++;
				if (_camera.name == _defaultCameraName) {
					nextCamera ();  // skip it because it always gets checked first, and shouldn't be checked twice
				} else {
					checkCamera ();
				}
			} else {
/* FAIL */		dispatch (CameraDetectionResult.NO_SUCCESS);
			}
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
		private function tickCheckCamera (e:TimerEvent):void {
			switch (e.type) {
				case TimerEvent.TIMER:
					_camFPSAverage = (_camFPSAverage < 0) ? _camera.currentFPS : ((_camFPSAverage * _timer.currentCount) + _camera.currentFPS) / _timer.currentCount;
					
					if (_camActivityInit && _camera.activityLevel < 100 ) _camActivityInit = false;
					else _camActivityAverage = (_camActivityAverage < 0) ? _camera.activityLevel : (_camActivityAverage + _camera.activityLevel) / 2;
					
					if (_camFPSAverage > 0 && _camActivityAverage >= 0) {
						_numTimesGoodCamera ++;
						if (_numTimesGoodCamera > _minTimesGood)
/* SUCCESS */				dispatch (CameraDetectionResult.SUCCESS);
					}
					break;
				case TimerEvent.TIMER_COMPLETE:
					nextCamera ();	// we have bad camera, Try the next one
					break;
			}
		}
		
		
		/** @private
		 *
		 * when requesting permission to use the camera, sometimes the settings dialog does not dispatch its events.
		 * This has some part to do with that dialog being written in AS2. This function is called by a timer and
		 * checks to see if the muted property of Camera changes. Then, if there is no change in access, it attempts to
		 * figure out if the dialog is still open. If the dialog is no longer open and the access did not change, then
		 * the diolog had never opened. Thus, the user has at one time selected to remember the setting of Deny for your domain
		 *
		 * 	* The _camActivityInit reference is simply to allow the timer one more iteration before actually continuing *
		 *
		 * @param	e
		 */
		private function onMediaPermissionsResolve(e:MediaPermissionsEvent):void {
			_rememberedPermissions = e.remembered;
			if (e.code == MediaPermissionsResult.GRANTED) {
				havePermissions();
			} else {
				dispatch (CameraDetectionResult.NO_PERMISSION);
			}
		}
		
		/** @private
		 *
		 * 	The Camera object will not update its activity property unless an event has been added to listen for activity changes
		 *
		 * @param	e
		 */
		private function onCamActivity(e:ActivityEvent):void {
			//
		}
		/** @private
		 *
		 * 	This function will dispatch the proper event, then dispose of itself
		 * @param	result
		 */
		private function dispatch (result:String):void {
			if (result != CameraDetectionResult.SUCCESS) _camera = null;
			dispatchEvent (new CameraDetectionEvent (CameraDetectionEvent.RESOLVE, _camera, result));
			dispose ();
		}
		/** @private
		 *
		 * 	prepare Timer object for checking Camera objects
		 */
		private function constructTimer ():void {
			if (_timer) disposeTimer();
			_timer = new Timer (_defaultDelay, _defaultRepeatCount);
			_timer.addEventListener (TimerEvent.TIMER,          tickCheckCamera);
			_timer.addEventListener (TimerEvent.TIMER_COMPLETE, tickCheckCamera);
			
		}
		/** @private
		 *
		 * 	prepare Timer object for garbage collection
		 */
		private function disposeTimer():void {
			if (_timer.running) _timer.stop();
			_timer.removeEventListener (TimerEvent.TIMER,          tickCheckCamera);
			_timer.removeEventListener (TimerEvent.TIMER_COMPLETE, tickCheckCamera);
			_timer = null;
		}
		/** @private
		 *
		 * 	prepare Camera object for garbage collection
		 */
		private function disposeCamera ():void {
			_camera.removeEventListener (ActivityEvent.ACTIVITY, onCamActivity);
			_camera = null;
		}
	}
}