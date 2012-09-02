


package ktu.media {
	
	import flash.display.BitmapData;
	import flash.display.Stage;
	import flash.events.EventDispatcher;
	import flash.events.StatusEvent;
	import flash.events.TimerEvent;
	import flash.media.Camera;
	import flash.media.Microphone;
	import flash.media.Video;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.system.Capabilities;
	import flash.system.Security;
	import flash.system.SecurityPanel;
	import flash.utils.Timer;
	import ktu.events.MediaPermissionsEvent;
	/**
	 * 	
	 *  MediaPermissions is an object that will tell you if you have permission to use the camera, and also
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
     * There are two methods. One, using netStream.attachAudio() to pop up the 'quick' permission dialog,
     * and the Security.showSettings() method which will ignore any choice of remember, and cause a two click process (on average)
     *
     * Below are the results from my testing. Here is the procedure of each test:
     *
     * Open
     * mediaPermissions.getPermission(Camera);
     * permission box shows up
     * I make a choice
     *      depending on the criteria for the test, I choose remember or not
     * Wait for MediaPermissionsResult
     * dispose of microphone
     * mediaPermissions.getPermission(Camera)
     * Wait for MediaPermissionsResult
     *
     * The idea, is that if you use the quick settings, and you selected to remember my decision, the dialog will not show up at all
     * So, if you 'remember' allow, it should be ok. If you 'remember' deny, then MediaPermissions should dispatch with DENIED and so on...
     *
     *
     *  LEGEND:
     *      Rembember 	= remember my decision
     *      Forget 		= do not remember my decision
     *      ACCESS 		= the short permissions dialog
     *      PRIVACY		= the full settings dialog (which requires at least two clicks)
     *      Deny 		= I chose to deny permission
     *      Allow 		= I chose to allow permission
     *
     * _netStream.attachAudio(_microphone);
     *
     * 	ACCESS  - Allow  - remember	=   GRANTED
     *  ACCESS	- Allow  - forget	=   GRANTED
     *  ACCESS  - Deny   - remember	=   DENIED
     *  ACCESS  - Deny	 - forget	=	DENIED
     *
     *
     * Security.showSettings()
     *
     * 	PRIVACY - Allow	 - remember	=   GRANTED
     * 	PRIVACY - Allow  - forget	=   GRANTED
     * 	PRIVACY	- Deny	 - remember	=   DENIED
     * 	PRIVACY - Deny   - forget	=   DENIED
     *
     *
     *
     *
	 * I am using Philippe Piernot's suggested workaround for knowing when the settings dialog closes:
     * 		http://bugs.adobe.com/jira/browse/FP-41?focusedCommentId=187534&page=com.atlassian.jira.plugin.system.issuetabpanels%3Acomment-tabpanel#action_187534
     *
     *
	 * ...
	 * @author ktu
	 */
	public class MediaPermissions extends EventDispatcher {
		
		static public const QUICK_ACCESS			:String = "quickAccess";			// quick access dialog mode of requesting permission
		static public const PRIVACY_DIALOG			:String = "privacyDialog";			// full privacy settings dialog mode of requestion permission
		
		public var 	timerDelay		       			:uint		= 100;                  // the default delay for checking permissions
		
		private var _timer							:Timer;								// what checks to see if permissions change
		
		private var _mode							:String = QUICK_ACCESS;				// permissions request mode
		
		private var _stage							:Stage;								// needed to hack the dialog
		
		private var _microphone						:Microphone;						// used for requesting permission and tracking it
		private var _netStream						:NetStream;							// used to invoke the quick access mode
		private var _netConnect						:NetConnection;						// needed for the netstream to work
		private var _video							:Video;								// used for requesting permissions for Camera
		private var _camera							:Camera;
		
		private var _remembered						:Boolean	= true;					// whether the user had selected remember. (only works with quick access)
		
		private var _permissionsDialogClosedMax		:uint		= 4;                    // max number of times the dialog should register as closed before confirming
		private var _permissionsDialogClosedCount	:uint 		= 0;					// number of times the dailog being closed has been recorded
		
		public function get mode():String { return _mode; }
		public function set mode(value:String):void { 
			if (value == MediaPermissions.QUICK_ACCESS || value == MediaPermissions.PRIVACY_DIALOG) _mode = value;
		}
        
        public function get stage():Stage { return _stage; }
        public function set stage(value:Stage):void { _stage = value; }
		
		
		/**
		 * 
		 * requires the stage because of Flash's bullshit
		 * 
		 */
		public function MediaPermissions(stageRef:Stage = null) {
			_stage = stageRef;
		}
		
		/**
		 * 	give a reference to the Micropone or Camera class, it will get permissions for that media device.
		 * The dialogs and the way this class functions does not change depending on the device you are looking for
		 * except that this class will check to see if there are any devices at all before requesting permission.
		 * 
		 * If you pass null, then it will check both, and if either are in failure (no device) then you will get a 
		 * NO_DEVICE response.
		 * 
		 * 
		 */
		public function getPermission(mediaType:Class = null, mode:String = ""):void {
			trace("MediaPermissions::getPermission() - type: " + mediaType);
			if (!checkMediaAvailability(mediaType)) {
/*FAIL*/		dispatch(MediaPermissionsResult.NO_DEVICE);
				return;
			}
            if (havePermission()) {
                _remembered = true;
/*SUCCESS*/		dispatch(MediaPermissionsResult.GRANTED);
				return;
            }
			
			_timer = new Timer(timerDelay);
			_timer.addEventListener(TimerEvent.TIMER, tickCheckPermission);
			_timer.start();
			
			mode = mode || this.mode;
			
			if      (mode == QUICK_ACCESS)   quickAccessPermissions   (mediaType);
			else if (mode == PRIVACY_DIALOG) privacyDialogPermissions (mediaType);
		}
		
        /**
		 * returns whether you have permission to use any media devices or not
		 */
		public function havePermission():Boolean {
			if (isMicrophoneAvailable()) 
				return !Microphone.getMicrophone().muted;
			else if (isCameraAvailable())
				return !Camera.getCamera().muted;
			else
				return false;
		}
        /**
         *  send this function either Camera, Microphone, or null and it will return if the media is available.
		 * if you pass null it will return true only if both Camera and Microphone are available
         * @param	mediaType
         * @return
         */
		public function checkMediaAvailability(mediaType:Class = null):Boolean {
			switch(mediaType) {
				case Microphone:
					return isMicrophoneAvailable();
				case Camera:
					return isCameraAvailable();
				default:
					var cam:Boolean = isCameraAvailable();
					var mic:Boolean = isMicrophoneAvailable();
					if (cam && mic) return true;
					else return false;
			}
		}
		
		public function isCameraAvailable():Boolean {
			if (Camera.names.length == 0 || !Capabilities.hasVideoEncoder || Capabilities.avHardwareDisable) {
				trace("MediaPermissions::isCameraAvailable() - false (no cameras, or !hasVideoEncoder");
				return false;
			}
			if (!Camera.getCamera()) {
				trace("MediaPermissions::isCameraAvailable() - false");
				return false;
			}
			trace("MediaPermissions::isCameraAvailable() - true");
			return true;
		}
		public function isMicrophoneAvailable():Boolean {
			trace("MediaPermissions::checkMicrophoneAvailability()");
			if (Microphone.names.length == 0 || !Capabilities.hasAudioEncoder || Capabilities.avHardwareDisable)
				return false;
			if (!Microphone.getMicrophone()) 
				return false;
			return true;
		}
		
        /**
         * TODO: make this aware of device availability. if no cameras, it should check microphone, and vice versa.
         * but maybe not, because i should still be able to ask for 
         * 
         */
		private function quickAccessPermissions(mediaType:Class):void {
			trace("MediaPermissions::quickAccessPermissions()");
			if (mediaType == Camera) {
				connectToCamera();
			} else if (mediaType == Microphone) {
				connectToMicrophone();
			} else {
				if (isMicrophoneAvailable()) connectToMicrophone();
				else if (isCameraAvailable()) connectToCamera();
/*FAIL*/		else dispatch(MediaPermissionsResult.NO_DEVICE);
			}
		}
		
		
		private function privacyDialogPermissions(mediaType:Class):void {
			trace("MediaPermissions::privacyDialogPermissions()");
			if (mediaType == Camera) {
				_camera = Camera.getCamera();
			} else if (mediaType == Microphone) {
				_microphone = Microphone.getMicrophone();
			} else {
				if (isMicrophoneAvailable()) _microphone = Microphone.getMicrophone();
				else if (isCameraAvailable()) _camera = Camera.getCamera();
			}
			Security.showSettings(SecurityPanel.PRIVACY);
		}
		
		
		private function connectToCamera():void {
			trace("MediaPermissions::connectToCamera()");
			_video = new Video();
			_camera = Camera.getCamera();
			_camera.addEventListener(StatusEvent.STATUS, onMediaStatus);
			_video.attachCamera(_camera);
		}
		
		private function connectToMicrophone ():void {
			trace("MediaPermissions::connectToMicrophone()");
			_netConnect = new NetConnection();
			_netConnect.connect(null);
			_netStream = new NetStream(_netConnect);
			_microphone = Microphone.getMicrophone();
			_microphone.addEventListener(StatusEvent.STATUS, onMediaStatus);
			_netStream.attachAudio(_microphone);
		}
		
		private function onMediaStatus(e:StatusEvent):void {
			trace("MediaPermissions::onMediaStatus() - " + e.code);
			if (e.code == "Camera.Muted") {
/*FAIL*/		dispatch(MediaPermissionsResult.DENIED);
			} else {
/*SUCCESS*/    	dispatch(MediaPermissionsResult.GRANTED);
			}
		}
		
		
		
		
		
		/**
		 * keeps checking the status of the Microphone.muted / Camera.muted. 
		 * If .muted = false, then we have permission.
		 * If not, we check to see if the dialog is closed,
		 * If it is closed, then we did not get permission
		 * 
		 * 
		 * 
		 * 
		 * @param	e
		 */
		private function tickCheckPermission(e:TimerEvent):void {
			var muted:Boolean = (_microphone ? _microphone.muted : (_camera ? _camera.muted : true));
			trace("MediaPermissions::tickNumChildren() - muted = " + muted);
			if (!muted) { // permision was granted
				trace("MediaPermissions::tickNumChildren() - camera.muted = false");
/*SUCCESS*/     dispatch(MediaPermissionsResult.GRANTED);
			} else if (isPermissionDialogClosed()) {	// if box is closed
				trace("MediaPermissions::tickNumChildren() - dialog is closed");
				_permissionsDialogClosedCount++;
				if ( _permissionsDialogClosedCount >= _permissionsDialogClosedMax ) {
					trace("MediaPermissions::tickNumChildren() - closed for so long, we ain't gettin permission");
/*FAIL*/			dispatch(MediaPermissionsResult.DENIED);
				}
			} else _permissionsDialogClosedCount = 0;
		}
		/**
		 * if the box is open, then i can't draw the stage
         * 
         * this is the bread and butter to the workaround. if i try to draw the stage and i get an error,
         * then the dialog is still up. thanks Philippe Piernot.
		 * 
		 * @return
		 */
		private function isPermissionDialogClosed():Boolean {
			var closed:Boolean = true;
			var dummy:BitmapData = new BitmapData(1, 1);
			
			try { 	 dummy.draw(_stage);
			} catch (error:Error) { closed = false; }
			
			trace("MediaPermissions::isPermissionDialogClosed() - " + closed);
			dummy.dispose();
			return closed;
		}
		
		
		
		
		
		
		
		/**
		 * this function disposes the object and dispatches an event.
         * 
		 * 
		 * @param	result - what happened?
		 */
		private function dispatch (result:String):void {
			trace("MediaPermissions::dispatch() - " + result);
			var permissionEvent:MediaPermissionsEvent = new MediaPermissionsEvent(MediaPermissionsEvent.RESOLVE, result, _remembered);
			dispose();
			dispatchEvent(permissionEvent);
		}
		/**
		 * 	this functions prepares the object for garbage collection.
         *  this will stop any logic from occuring and will prevent any results from firing.
         * 
         * if for some reason you want this object to stop and go away, make sure you call this function first so you avoid a memory leak
		 */
		public function dispose():void {
			trace("MediaPermissions::dispose()");
			if (_timer) {
				_timer.stop();
				_timer.removeEventListener(TimerEvent.TIMER, tickCheckPermission);
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
			if (_video) {
				_video.attachCamera(null);
				_video = null;
			}
			if (_microphone) {
				_microphone.removeEventListener(StatusEvent.STATUS, onMediaStatus);
				_microphone = null;
			}
			if (_camera) {
				_camera.removeEventListener(StatusEvent.STATUS, onMediaStatus);
				_camera = null;
			}
		}
	}
}