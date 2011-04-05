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
			case CameraDetectionResult.NO_PERMISSION :
				output("Camera access denied");
				break;
			case CameraDetectionResult.NO_CAMERAS :
				output("There are no suitable cameras connected to the computer");
				break;
		}
	}																														</listing>
	 *
	 * I chose to implement Grant Skinners IDisposable because I think its good practice
	 *
	 */
	public class CameraDetectionVerbose extends EventDispatcher implements IDisposable {
		
	//	private static const MAC_OS				:String 	= "Mac OS";
		private static const CAMERA_MUTED		:String 	= "Camera.Muted";
		private static const CAMERA_UNMUTED		:String 	= "Camera.Unmuted";
		
		
		private var _camera						:Camera;
		private var _currentCameraIndex			:uint		= 0;
		private var _numCameras					:uint;
		private var _defaultCameraName			:String;
		private var _video						:Video;
		
		private var _timer						:Timer;
		private var _defaultDelay				:uint		= 100;
		private var _defaultRepeatCount			:uint		= 25;
		private var _permissionsDelay			:uint		= 200;
		private var _permissionsDenyCount		:uint		= 2;
		private var _camFPSAverage				:Number;
		private var _camActivityInit			:Boolean;
		private var _camActivityAverage			:Number;
		private var numTimesGoodCamera			:int		= 0;
		private var minTimesGood				:int 		= 3;
	//	private var _isMac						:Boolean	= false;
		private var _stage						:Stage;
		
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
		 * The Fix:																											<br/>
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

	//		if (Capabilities.os.substr (0, 6) == MAC_OS)
	//			_isMac = true;
	//		output ("\t _isMac = " + _isMac);
			getDefaultCamera ();
			output ("\tCamera.muted = " + _camera.muted);
			if (_camera.muted == false) {
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
		 * */
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
		 * finds the default camera and then asks for permission to use the camera
		 *
		 * 		If we are on a Mac machine, grab the last camera in the list (because of their silly bug)
		 * 		If we already have permission to use the camera, check the camera,
		 * 		if not, get permission to use the camera
		 *
		 */
		private function getDefaultCamera ():void {
	//		if (_isMac) _camera = getMacDefaultCamera ();
	/*		else */		_camera = Camera.getCamera ();
			_defaultCameraName = _camera.name;
		}
		/** @private
		 *  gets the defualt camera for mac laptops
		 *
		 * 	This simply grabs the last camera in the list, as that is the normal location
		 * 	of mac laptop built in cameras
		 * @return
		 */
	//	private function getMacDefaultCamera():Camera{
	//		_isMac = false;
	//		var camera:Camera = Camera.getCamera (String (_numCameras - 1));
	//		_numCameras--;
	//		return camera;
	//	}
		/** @private
		 *
		 * begin checking a camera
		 *
		 * 	resets values, add eventlistener, attach camera to video, then start the timer
		 *
		 */
		private function checkCamera ():void {
			output ("CameraDetection::checkCamera()");
			output ("\t" + _camera.name);
			_camActivityInit = true;
			_camActivityAverage = -1;
			_camFPSAverage = -1;
			_camera.addEventListener (ActivityEvent.ACTIVITY, onCamActivity, false, 0, true);
			_video.attachCamera (_camera);
			_timer.reset ();
			_timer.start (); // callback function is tickCheckCamera()
			output ("activity:average\tfps:average");
		}
		
		/** @private
		 *
		 * 	prepares next Camera for checking.
		 *
		 * 		Dispose of previous camera
		 * 		if haven't checked all cameras, get the next camera and check it
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
					nextCamera ();
				} else {
					checkCamera ();
				}
			} else {
/* FAIL */		dispatch (CameraDetectionResult.NO_CAMERAS);
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
						numTimesGoodCamera ++;
						if (numTimesGoodCamera > minTimesGood)
/* SUCCESS */				dispatch (CameraDetectionResult.SUCCESS);
					}
				break;
				case TimerEvent.TIMER_COMPLETE:
					if (_camFPSAverage > 0 && _camActivityAverage >= 0) {
/* SUCCESS */				dispatch (CameraDetectionResult.SUCCESS);
							return
					}
					nextCamera ();	// we have bad camera, Try the next one
				break;
			}
		}
		/** @private
		 *
		 *  Ask user for permission to use camera
		 *
		 */
		private function askPermission ():void {
			_camera.addEventListener (StatusEvent.STATUS, onCamStatus, false, 0, true);
			/*
			 * _video.attachCamera(_camera);
			 * 		With introduction of drawStage, this succeeds every time I have tested
			 *
			 *  Yes - Quick    - Deny   =   Proper result of NO_PERMISSION
			 * 	Yes - Quick    - Allow  =   Proper result of SUCCESS
			 *  No  - Quick    - Deny	=	Proper result of NO_PERMISSION
			 *  No  - Quick    - Allow  =   Proper result of SUCCESS
			 *
			 *
			 * Security.showSettings
			 * 		Works every time with drawStage, but lots of SecurityErrors in the output
			 *
			 * 	No  - Settings - Deny	=   Proper result of NO_PERMISSION
			 * 	No  - Settings - Allow	=   Proper result of SUCCESS
			 * 	Yes - Settings - Deny   =   Proper result of NO_PERMISSION
			 * 	Yes - Settings - Allow  =   Proper result of SUCCESS
			 */
			output ("CameraDetection::askPermission()");
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
		private function havePermissions ():void {
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
					return;
				}
				havePermissions ();
				return;
			}
			if (isPermissionBoxClosed ()) {
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
		 * The user has checked remember and with deny in the settings.
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
			disposeTimer();
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
			_timer.addEventListener (TimerEvent.TIMER,          tickCheckCamera, false, 0, true);
			_timer.addEventListener (TimerEvent.TIMER_COMPLETE, tickCheckCamera, false, 0, true);
			
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