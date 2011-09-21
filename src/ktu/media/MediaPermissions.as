package ktu.media {
	import flash.display.Stage;
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.media.Camera;
	import flash.media.Microphone;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.system.Capabilities;
	import flash.system.Security;
	import flash.system.SecurityPanel;
	import flash.utils.Timer;
	import ktu.events.MediaPermissionsEvent;
	/**
	 * 	
	 *  CameraPermissionRequest is an object that will tell you if you have permission to use the camera, and also
	 *  ask the user for permission and give you the response.
	 * 
	 * 	This is preffered over using your own method because this is more clear than the native AS3 code, and can take care
	 * of more scenarios.
	 * 
	 * 
	 * 
	 *  *	PERMISSIONS TESTING:
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
     *      Yes 	= Remember my decision
     *      No 		= do not remember my decision
     *      ACCESS 	= the short permissions dialog
     *      PRIVACY = the full settings dialog (which requires at least two clicks)
     *      Deny 	= I chose to deny permission
     *      Allow 	= I chose to allow permission
     *
     * _video.attachCamera(_camera);
     *
     *  Yes - ACCESS    - Deny   =   NO_PERMISSION
     * 	Yes - ACCESS    - Allow  =   SUCCESS
     *  No  - ACCESS    - Deny	 =	 NO_PERMISSION
     *  No  - ACCESS	- Allow  =   SUCCESS
     *
     *
     * Security.showSettings
     *
     * 	No  - PRIVACY	- Deny	 =   NO_PERMISSION
     * 	No  - PRIVACY 	- Allow	 =   SUCCESS
     * 	Yes - PRIVACY 	- Deny   =   NO_PERMISSION
     * 	Yes - PRIVACY 	- Allow  =   SUCCESS
     *
     *
     *
     *
     *
     *
     *
	 * I chose to implement Grant Skinners IDisposable because I think its good practice
	 *
	 * 
	 * ...
	 * @author ktu
	 */
	public class MediaPermissions extends EventDispatcher {
		
		public static const CAMERA						:String = "camera";
		public static const MICROPHONE					:String = "microphone";
		
		public static const QUICK_ACCESS				:String = "quickAccess";
		public static const PRIVACY_DIALOG				:String = "privacyDialog";
		
		public var 	mode								:String = QUICK_ACCESS;
		public var 	permissionsTimerDelay				:uint		= 200;                  // the default delay for checking permissions
		
		private var _stage								:Stage;
		private var _numChildren						:int;
		
		private var _microphone							:Microphone;
		private var _netStream							:NetStream;
		private var _netConnect							:NetConnection;
		
		private var _timer								:Timer;
			private var _permissionsDialogClosedMax		:uint		= 2;                    // max number of times the dialog should register as closed before confirming
			private var _permissionsDialogClosedCount	:uint 		= 0;					// number of times the dailog being closed has been recorded
		
		private var _remembered							:Boolean	= true;
		
		
		/**
		 * 
		 * requires the stage because of Flash's bullshit
		 * 
		 */
		public function MediaPermissions(stageRef:Stage) {
			_stage = stageRef;
		}
		
		/**
		 * returns whether you have permission to use any media devices or not
		 */
		public function havePermission():Boolean {
			if (checkMicrophoneAvailability()) 
				return !Microphone.getMicrophone().muted;
			else if (checkCameraAvailability())
				return !Camera.getCamera().muted;
			else
				return false;
		}
		/**
		 * This must be an async request 
		 */
		public function getPermission(mediaType:Class):void {
			trace("MediaPermissions::getPermission() - type: " + mediaType);
			if (!checkMediaAvailability(mediaType)) {
				dispatch(MediaPermissionsResult.NO_DEVICE); // stop, I can't do shit, it don't matter about permissions
				return;
			}
			
			// store the current number of children on the stage. the dialog makes it one more...
			_numChildren = _stage.numChildren;
			// setup the timer 
			_timer = new Timer(permissionsTimerDelay);
			_timer.addEventListener(TimerEvent.TIMER, tickNumChildren);
			_timer.start();
			
			// start this thing
			switch (mode) {
				case QUICK_ACCESS:
					quickAccessPermissions();
					break;
				case PRIVACY_DIALOG:
					privacyDialogPermissions();
					break;
			}
		}
		
		public function checkMediaAvailability(mediaType:Class):Boolean {
			switch(mediaType) {
				case Microphone:
					return checkMicrophoneAvailability();
				case Camera:
				default:
					return checkCameraAvailability();
			}
		}
		
		public function checkCameraAvailability():Boolean {
			trace("MediaPermissions::checkCameraAvailability()");
			if (Camera.names.length == 0 || !Capabilities.hasVideoEncoder)
				return false;
			if (!Camera.getCamera())
				return false;
			return true;
		}
		public function checkMicrophoneAvailability():Boolean {
			trace("MediaPermissions::checkMicrophoneAvailability()");
			if (Microphone.names.length == 0 || !Capabilities.hasAudioEncoder)
				return false;
			if (!Microphone.getMicrophone()) 
				return false;
			return true;
		}
		
		private function quickAccessPermissions():void {
			trace("MediaPermissions::quickAccessPermissions()");
			_microphone = Microphone.getMicrophone();
			_netConnect = new NetConnection();
			_netConnect.connect(null);
			_netStream = new NetStream(_netConnect);
			_netStream.attachAudio(_microphone);
		}
		private function privacyDialogPermissions():void {
			trace("MediaPermissions::privacyDialogPermissions()");
			Security.showSettings(SecurityPanel.PRIVACY);
		}
		
		
		
		
		
		
		
		
		
		/**
		 * keeps checking the status of the Microphone.muted. 
		 * If .muted = false, then we have permission.
		 * If not, we check to see if the dialog is closed,
		 * 
		 * @param	e
		 */
		private function tickNumChildren(e:TimerEvent):void {
			trace("MediaPermissions::tickNumChildren()");
			var muted:Boolean = _microphone.muted;
			if (!muted) { // permision was granted
				trace("MediaPermissions::tickNumChildren() - camera.muted = false");
				_timer.stop();
                permissionGranted();
			} else if (isPermissionDialogClosed()) {	// if box is closed
				trace("MediaPermissions::tickNumChildren() - dialog is closed");
				//_permissionsDialogClosedCount++;
				//if ( _permissionsDialogClosedCount >= _permissionsDialogClosedMax ) {
					//trace("MediaPermissions::tickNumChildren() - closed for so long, we ain't gettin permission");
					_timer.stop();
					permissionDenied();
				//}
			}
		}
		
		
		
		
		
		
		
		/**
		 * if the box is open, then there is one more child on the stage than there should be
		 * 
		 * @return
		 */
		private function isPermissionDialogClosed():Boolean {
			var closed:Boolean = (_stage.numChildren <= _numChildren) ? true : false;
			trace("MediaPermissions::isPermissionDialogClosed() - " + closed);
			if (_stage.numChildren <= _numChildren) {
				return true;
			} else {
				_remembered = false; // if in QUICK_ACCESS mode and the dialog opens, then they did not remember their decision 
				return false;		 // if in PRIVACY_DIALOG, best to ignore this value, as it won't matter if you remember or not.
			}
		}
		
		
		/**
		 * 	Permission was granted to use the Camera
		 */
		private function permissionGranted():void {
			trace("MediaPermissions::permissionGranted()");
			dispose();
			dispatch(MediaPermissionsResult.GRANTED);
		}
		
		/**
		 * Permission was denied to use the Camera
		 */
		private function permissionDenied():void {
			trace("MediaPermissions::permissionDenied()");
			dispose();
			dispatch(MediaPermissionsResult.DENIED);
		}
		
		/**
		 * Tell the world what you found...
		 * 
		 * @param	result - what happened?
		 */
		private function dispatch (result:String):void {
			trace("MediaPermissions::dispatch() - " + result);
			var permissionEvent:MediaPermissionsEvent = new MediaPermissionsEvent(MediaPermissionsEvent.RESOLVE, result);
			dispatchEvent(permissionEvent);
		}
		/**
		 * 	Dump everything, stop in your tracks. You're done.
		 */
		public function dispose():void {
			trace("MediaPermissions::dispose()");
			if (_timer) {
				_timer.stop();
				_timer.removeEventListener(TimerEvent.TIMER, tickNumChildren);
				_timer = null;
			}
			if (_netConnect) {
				_netConnect.close();
				_netConnect = null;
			}
			if (_netStream) {
				_netStream.attachAudio(null);
				_netStream.close();
				_netStream = null;
			}
			_microphone = null;
		}
	}
}