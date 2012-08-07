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
	public class CameraDetection3 extends EventDispatcher {
		
		private var _currentCameraIndex			:uint		= 0;                    // the current index of the camera we are testing
		private var _numCameras					:uint;                              // the number of cameras in the list
		private var _defaultCameraName			:String;                            // the name of the default camera
		
        private var _rememberedPermissions      :Boolean    = false;                // true = the permissions dialog did not show once || false = permissions dialog did show
		
		private var _stage						:Stage;                             // ref to the stage for permissions checking
		private var _mediaPermissions			:MediaPermissions;
        private var _cCheck                     :CameraChecker;
		
        
		/**
		 * repeatCount property of the timer used while checking a Camera object										<br>
		 *
		 * This value along with the detectionDelay property will determine how long this object will spend
		 * checking each Camera object.
		 */
		public function get detectionRepeatCount():uint { return _cCheck.timerRepeatCount; }
		public function set detectionRepeatCount(value:uint):void { _cCheck.timerRepeatCount = value; }
		/**
		 * delay property of the timer used while checking a Camera object												<br>
		 *
		 * This value along with the detectionRepeatCount property will determine how long this object will spend
		 * checking each Camera object.
		 */
		public function get detectionDelay():uint { return _cCheck.timerDelay; }
		public function set detectionDelay (value:uint):void { _cCheck.timerDelay = value; }
        /**
         * delay for the timer while checking permissions. this is likley to not need changing, but it ist still
         * an option.
         */
        public function get permissionsDelay():uint { return _mediaPermissions.timerDelay; }
        public function set permissionsDelay(value):uint { _mediaPermissions.timerDelay = value; }
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
        public function get rememberedPermissions ():Boolean { return _rememberedPermissions; }
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
		 * 		* Thanks to Martin Arvisais for the code from https://bugs.adobe.com/jira/browse/FP-41						<br/>
		 *																													<br/>
		 * 		checks the number of children on the stage. if there is more children than before asking for permission		
         *      then the dialog is still up                                                                                 <br/> 
		 *
		 */
		public function CameraDetection3 (stage:Stage):void {
			_stage = stage;
            _mediaPermissions = new MediaPermissions(_stage);
            _mediaPermissions.addEventListener(MediaPermissionsEvent.RESOLVE, onMediaPermissionsResolve);
            _cCheck = new CameraChecker();
            _cCheck.addEventListener(CameraDetectionEvent.RESOLVE, onCChecker);
		}
        
        
		/**
		 * begin searching for the first working Camera object. 														<br>
		 * 																												<br>
		 * This method first checks the defaultCamera. If using a Mac operating system, this class will check the last Camera
		 * object first because normally, the webcam Camera object on Mac laptops is at the bottom of the list.
		 */
		public function begin ():void {
			_numCameras = Camera.names.length;
			if (!mediaPermissions.isCameraAvailable()) {
/* FAIL */		dispatch (CameraDetectionResult.NO_CAMERAS);
                return;
            }
            _mediaPermissions.getPermission(Camera);
		}
		/**
		 * disposes of all objects holding memory in this class																				<br>
		 * 																																	<br>
		 * This method will prepare all objects in this class for garbage collection. This method can be called at any time during
		 * the process of searching for a Camera. 																							<br>
		 * 																																	<br>
		 */
		public function dispose ():void {
            _mediaPermissions.dispose();
            _cCheck.dispose();
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
		protected function nextCamera ():void {
			if (_currentCameraIndex < _numCameras) {
				var camera = Camera.getCamera ( String (_currentCameraIndex) );
				_currentCameraIndex ++;
				if (camera.name == _defaultCameraName) nextCamera ();  // skip it because it always gets checked first
				else _cCheck.check(camera);
			} else
/* FAIL */		dispatch (CameraDetectionResult.NO_SUCCESS);
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
            trace("CameraDetection2::onMediaPermissionsResolve()");
			_rememberedPermissions = e.remembered;
			if (e.code == MediaPermissionsResult.GRANTED)
				havePermissions();
			else if (e.code == MediaPermissionsResult.DENIED {
/*FAIL*/		dispatch (CameraDetectionResult.NO_PERMISSION);
            } else if (e.code == MediaPermissionsResult.NO_DEVICE) {
                dispatch (CameraDetectionResult.NO_CAMERAS);
            }
		}
        /** @private
		 *
		 * We were given permissions, so start checking the first camera
		 *
		 */
		private function havePermissions():void {
            var camera = Camera.getCamera ();
			_defaultCameraName = camera.name;
            _cCheck.check(camera);
		}
        /**
         * event handler for checking a camera
         * @param	e
         */
		private function onCChecker(e:CameraDetectionEvent):void {
            if (e.code == CameraDetectionResult.SUCCESS) {
                dispatch(e.code);
            } else {
                nextCamera();
            }
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
	}
}