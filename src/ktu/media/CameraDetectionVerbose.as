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
	
	import ktu.events.CameraDetectionEvent;
	import com.gskinner.utils.IDisposable;
	
	import flash.display.BitmapData;
	import flash.display.Stage;
	import flash.events.ActivityEvent;
	import flash.events.EventDispatcher;
	import flash.events.StatusEvent;
	import flash.events.TimerEvent;
	import flash.media.Camera;
	import flash.media.Video;
	import flash.system.Capabilities;
	import flash.system.Security;
	import flash.system.SecurityPanel;
	import flash.utils.Timer;
	
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
	[Event(name="cameraResolved", type="com.crp.events.CameraDetectionEvent")]

	
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
	 ***Once an event is dispatched from this class, the dispose method is called automatically***							<br>
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
     *	PERMISSIONS TESTING:
     *
     *  These are the results of my testing for permissions:
     *
     *  I conducted a thorough study of which methods produce which results when looking for permission from the user
     * After all of my tweaks and changes, I was able to get proper results for all scenarios using both methods.
     *
     * There are two methods. One, using video.attachCamera() to pop up the 'quick' permission dialog,
     * and the Security.showSettings() method which will ignore any choice of remember, and cause a two click process (on average)
     *
     * Below are the results from my testing. Here is the procedure of each test:
     *
     * Open
     * cameraDetection.begin()
     * permission box shows up
     * I make a choice
     *      depending on the criteria for the test, I choose remember or not
     * Wait for CameraDetectionResult
     * dispose of camera
     * cameraDetection.begin()
     * Wait for CameraDetectionResult
     *
     * The idea, is that if you use the quick settings, and you selected to remember my decision, the dialog will not show up at all
     * So, if you 'remember' allow, it should be ok. If you 'remember' deny, then CameraDetection should dispatch with NO_PERMISSION and so on...
     *
     *
     *  LEGEND:
     *      Yes = Remember my decision
     *      No = do not remember my decision
     *      Settings = the full settings dialog (which requires at least two clicks)
     *      Quick = the short permissions dialog
     *      Deny = I chose to deny permission
     *      Allow = I chose to allow permission
     *
     * _video.attachCamera(_camera);
     *
     *  Yes - Quick    - Deny   =   NO_PERMISSION
     * 	Yes - Quick    - Allow  =   SUCCESS
     *  No  - Quick    - Deny	=	NO_PERMISSION
     *  No  - Quick    - Allow  =   SUCCESS
     *
     *
     * Security.showSettings
     *
     * 	No  - Settings - Deny	=   NO_PERMISSION
     * 	No  - Settings - Allow	=   SUCCESS
     * 	Yes - Settings - Deny   =   NO_PERMISSION
     * 	Yes - Settings - Allow  =   SUCCESS
     *
     *
     *
     *
     *
     *
     *
	 * I chose to implement Grant Skinners IDisposable because I think its good practice
	 *
	 */
	public class CameraDetectionVerbose extends EventDispatcher implements IDisposable {
		
		private static const CAMERA_MUTED		:String 	= "Camera.Muted";
		private static const CAMERA_UNMUTED		:String 	= "Camera.Unmuted";
		
		
		private var _camera						:Camera;                            // the camera object we are testing
		private var _currentCameraIndex			:uint		= 0;                    // the current index of the camera we are testing
		private var _numCameras					:uint;                              // the number of cameras in the list
		private var _defaultCameraName			:String;                            // the name of the default camera
		private var _video						:Video;                             // the video object to use with the camera to test
		
		private var _timer						:Timer;                             // the main timer, user for both permissions and camera
		private var _defaultDelay				:uint		= 100;                  // the default delay for testing the camera
		private var _defaultRepeatCount			:uint		= 25;                   // the default repeatCount for testing the camera
		private var _permissionsDelay			:uint		= 200;                  // the default delay for checking permissions
		private var _permissionsDenyCount		:uint		= 2;                    // the default repeatCount for checking permissions
		private var _camFPSAverage				:Number;                            // the average of the fps of the camera we are checking
		private var _camActivityInit			:Boolean;                           // whether we have passed the camera's activity init phase
		private var _camActivityAverage			:Number;                            // the average of the activity of the camera we are checking
		private var _numTimesGoodCamera			:int		= 0;                    // number of times this camera has shown to work during a single check
		private var _minTimesGood				:int 		= 3;                    // the min number of times a camera must respond as working
        private var _rememberedPermissions      :Boolean    = false;                // true = the permissions dialog did not show once || false = permissions dialog did show

		private var _stage						:Stage;                             // ref to the stage for permissions checking
		
		/**
         * output is a function that accepts a string parameter.
         * It is designed to be able to see everything the class is doing.
         *
         * @default trace      It uses the trace function as a default.
         */
		public var output:Function;
		
		
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
		public function CameraDetectionVerbose (stage:Stage ):void {
			_stage = stage;
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
		 * begin searching for the first working Camera object. 														<br>
		 * 																												<br>
		 * This method first checks the defaultCamera. If using a Mac operating system, this class will check the last Camera
		 * object first because normally, the webcam Camera object on Mac laptops is at the bottom of the list.
		 */
		public function begin ():void {
			output ("CameraDetection::begin()");
			_video = new Video ();
			_numCameras = Camera.names.length;
			output ("\tfound " + _numCameras + " cameras");
			if (_numCameras == 0 || !Capabilities.hasVideoEncoder)
/* FAIL */		dispatch (CameraDetectionResult.NO_CAMERAS);

			getDefaultCamera ();
			
			if (!_camera)
/* FAIL */		dispatch (CameraDetectionResult.NO_CAMERAS);		// just in case?
			output ("\tCamera.muted = " + _camera.muted);
			if (!_camera.muted) {
                _rememberedPermissions = true;  // if default camera is not muted, then remember was checked with allow, no dialog will show
				havePermissions ();
			} else {
				askPermission ();
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
			output ("CameraDetection::dispose()");
			if (_video) {
				_video.attachCamera (null);
				_video = null;
			}
			if (_camera) disposeCamera();
			if (_timer) disposeTimer();
		}
		
		
		
		
		
		
		/** @private
		 *
		 * finds the default camera
		 *  _defaultCameraName is used for checking... We always check that one first, so in next camera,
         * we don't want to check it again, if it didn't work.
		 *
		 */
		private function getDefaultCamera ():void {
            _camera = Camera.getCamera ();
			_defaultCameraName = _camera.name;
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
			output ("CameraDetection::checkCamera()");
			output ("\t" + _camera.name);
			_camActivityInit = true;
			_camActivityAverage = -1;
			_camFPSAverage = -1;
			_camera.addEventListener (ActivityEvent.ACTIVITY, onCamActivity);
			_video.attachCamera (_camera);
			_timer.reset ();
			_timer.start (); // callback function is tick()
			output ("activity:average\tfps:average");
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
					
					output ("act: " + _camera.activityLevel + ":" + _camActivityAverage + "\tfps: " + _camera.fps + ":" + _camFPSAverage);
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
		 *  Ask user for permission to use camera
		 *
		 */
		private function askPermission():void {
			output ("CameraDetection::askPermission()");
			_camera.addEventListener (StatusEvent.STATUS, onCamStatus);
			//attaching to video will open quick dialog. If remember has been set, it won't open
				_video.attachCamera (_camera);
			// Show settings opens the two step that will bypass the remember setting
				//Security.showSettings(SecurityPanel.PRIVACY);
			_timer = new Timer(_permissionsDelay);
			_timer.addEventListener(TimerEvent.TIMER, tickPermissionsCheck);
			_timer.start();
		}
		/** @private
		 *
		 * We were given permissions, so start checking the first camera
		 *
		 */
		private function havePermissions():void {
			output ("CameraDetection::permissionGranted()");
			constructTimer();
			checkCamera ();
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
		private function tickPermissionsCheck (e:TimerEvent):void {
			if (!_camera.muted) { // permision was granted
				if (!_camActivityInit) {
					_camActivityInit = false;	// only to get one more tick out of the timer
				} else {
                    havePermissions ();
                }
			} else if (isPermissionBoxClosed ()) {
				if ( _timer.currentCount >= _permissionsDenyCount ) {
					output ("CameraDetection::permissionDenied()");
					dispatch (CameraDetectionResult.NO_PERMISSION);
					return;
				}
			}
		}
		/** @private
		 *
		 * 	Checks if the permissions box is closed
		 *
		 * 	This is only used to check if the dialog never displays at all. This will not display under only one circumstance:
		 * The user has checked remember in the settings.
		 *
		 * This method attempts to draw the stage. If the dialog is open, it throws a security error.
		 *
		 * Thanks to Philippe Piernot for the code
		 * https://bugs.adobe.com/jira/browse/FP-41
		 *
		 * aslo, a neighboring comment:
		 * Author:  Kaspar Lüthi:
		 * Comment: Philippe, your workaround is quite cool. Unfortunately it does not work when
		 * 			you have a video displayed, where you have no bitmap access to.
		 * @return
		 */
		private function isPermissionBoxClosed():Boolean{
			var closed:Boolean = true;
			var dummy:BitmapData;
			dummy = new BitmapData (1, 1);
			try {
				dummy.draw(_stage);
			} catch (error:SecurityError) {
                _rememberedPermissions = false;     // the dialog showed up at least for a bit, so no remembmer
				closed = false;
			}
			dummy.dispose ();
			return closed;
		}
		/** @private
		 *
		 * 	captures event dispatched from the Settings panel for permission to access the Camera
		 *
		 * @param	e
		 */
		private function onCamStatus (e:StatusEvent):void {
			disposeTimer ();
            _rememberedPermissions = false;     // only interaction with the panel could cause this event, thus, they did not remember
			switch (e.code) {
				case CAMERA_UNMUTED:
					havePermissions ();
				break;
				case CAMERA_MUTED:
					output ("CameraDetection::permissionDenied()");
/* FAIL */			dispatch (CameraDetectionResult.NO_PERMISSION);
				break;
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
			_timer.removeEventListener (TimerEvent.TIMER, tickPermissionsCheck);
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
			_camera.removeEventListener (StatusEvent.STATUS, onCamStatus);
			_camera = null;
		}
	}
}