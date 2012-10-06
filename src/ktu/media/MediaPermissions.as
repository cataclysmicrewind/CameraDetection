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
	 * 	Listen to MediaPermissionsEvent.DIALOG_STATUS to find out when the dialog box opens and closes!
     *  Listen to MediaPermissionsEvent.RESOLVE to find out if you got permission or not!
     * 
     *  super simple!
     * 
     * var mp:MediaPermissions = new MediaPermissions();
     * mp.mode = MediaPermissions.PRIVACY_DIALOG;
     * mp.addEventListener (MediaPermissionsEvent.DIALOG_STATUS, onDialogStatus);
     * mp.addEventListener (MediaPermissionsEvent.RESOLVE, onPermissionsResolve);
     * mp.getPermission(Camera);
     * 
     * function onDialogStatus (e:MediaPermissionsEvent):void {
     *      if (e.code == MediaPermissionsResult.DIALOG_OPEN)
     *          trace ("dialog opened");
     *      else if (e.code == MediaPermissionsResult.DIALOG_CLOSED)
     *          trace ("dialog closed");
     * }
     * 
     * function onPermissionsResolve (e:MediaPermissionsEvent):void {
     *      switch (e.code) {
     *          case MediaPermissionsResult.GRANTED :
     *              trace ("permissions granted");
     *              break;
     *          case MediaPermissionsResult.DENIED:
     *              trace("permissions denied");
     *              break;
     *          case MediaPermissionsResult.NO_DEVICE:
     *              trace("there was no device to use!");
     *              break;
     *      }
     * }
	 * 
     * 
     * 
     * this object can also tell you whether or not the user 'remembered' their decision. 
     * 
     * on the very first (and most afterward) media permissions resolve events, there is a boolean property on the event called 'remembered'
     * if true, then that means the user had selected 'remember' with some decision (allow or deny). 
     * 
     * finally a pretty good solution to dealing with media permission!!!
	 * 
	 * 
     * please look at my PermissionsTest.as and compile the MediaPermissionsTest project or go to #$^@#^@%$@&%$&#^^#$&&^$# to see this in action and test all scenarios
     * 
     * 
     * 
     *
     *
	 * I am using Philippe Piernot's suggested workaround for not knowing when the settings dialog closes:
     * 		http://bugs.adobe.com/jira/browse/FP-41?focusedCommentId=187534&page=com.atlassian.jira.plugin.system.issuetabpanels%3Acomment-tabpanel#action_187534
     *
     *
	 * ...
	 * @author ktu
	 */
	public class MediaPermissions extends EventDispatcher {
		
		static public const QUICK_ACCESS			:String = "quickAccess";			// quick access dialog mode of requesting permission
		static public const PRIVACY_DIALOG			:String = "privacyDialog";			// full privacy settings dialog mode of requestion permission
		
		public var 	timerDelay		       			:uint		= 200;                  // the default delay for checking permissions
		public var  stage							:Stage;								// needed to hack the dialog
		
		private var _timer							:Timer;								// what checks to see if permissions change
		
		private var _mode							:String = QUICK_ACCESS;				// permissions request mode
		
		private var _microphone						:Microphone;						// used for requesting permission and tracking it
		private var _netStream						:NetStream;							// used to invoke the quick access mode
		private var _netConnect						:NetConnection;						// needed for the netstream to work
		private var _video							:Video;								// used for requesting permissions for Camera
		private var _camera							:Camera;                            // used for requesting permissions for Camera
		
        private var _dispatched                     :Boolean    = false;                // if i have dispatched at least once before
		private var _remembered						:Boolean	= false;				// whether the user had selected remember. (only works with quick access)
        private var _dialogIsOpen                   :Boolean    = false;                // is the dialog open now?!?!?
		
		private var _permissionsDialogClosedMax		:uint		= 4;                    // max number of times the dialog should register as closed before confirming
		private var _permissionsDialogClosedCount	:uint 		= 0;					// number of times the dailog being closed has been recorded
        
		
		public function get mode():String { return _mode; }
		public function set mode(value:String):void { 
			if (value == MediaPermissions.QUICK_ACCESS || value == MediaPermissions.PRIVACY_DIALOG) _mode = value;
		}
        /**
         * whether or not the user has the 'remembered' checkbox selected in the privacy settings dialog
         * 
         * this boolean is only accurate in a specific setting:
         *      the very first time permission is request, and we already have permission.
         * 
         * in normal circumstances, when a user runs your flash application, they will not have remembered a setting for your domain,
         * thus, the vast majority of the time, you will need to ask for permission. 
         * 
         * in the odd chance that they have remembered a decision
         * 
         * @see getPermission
         */
        public function get remembered():Boolean { return _remembered; }
        public function set remembered(value:Boolean):void { _remembered = value; }
		/**
		 * is the dialog currently on screen?
		 */
        public function get dialogIsOpen():Boolean { return _dialogIsOpen; }
		/**
		 * _requires_ the stage because of Flash's bullshit
		 */
		public function MediaPermissions(stageRef:Stage = null) {
			stage = stageRef;
		}
        /**
		 * returns whether you have permission to use any media devices or not
		 */
		public function havePermission():Boolean {
			if (isCameraAvailable())            return !Camera.getCamera().muted;
			else if (isMicrophoneAvailable())   return !Microphone.getMicrophone().muted;
			else return false;
		}
        /**
         *  send this function either Camera, Microphone, or null and it will return if the media is available.
		 * if you pass null it will return true only if both Camera and Microphone are available
         * @param	mediaType a Class, either Camera or Microphone or null (check both, both must be true to get true)
         * @return if that media type is available (has at least one object and the computer supports it)
         */
		public function checkMediaAvailability(mediaType:Class = null):Boolean {
			switch(mediaType) {
				case Microphone:
					return isMicrophoneAvailable();
				case Camera:
					return isCameraAvailable();
				case null:
					var cam:Boolean = isCameraAvailable();
					var mic:Boolean = isMicrophoneAvailable();
					if (cam && mic) return true;
					else return false;
                default:
                    return false;
			}
		}
		/**
		 * is a camera available? makes sure the computer supports cameras and has at least one to use
		 * @return
		 */
		public function isCameraAvailable():Boolean {
			if (Camera.names.length == 0 || !Capabilities.hasVideoEncoder || Capabilities.avHardwareDisable) return false;
			if (!Camera.getCamera()) return false; 
			return true;
		}
        /**
		 * is a microphone available? makes sure the computer supports microphones and has at least one to use
		 * @return
		 */
		public function isMicrophoneAvailable():Boolean {
			if (Microphone.names.length == 0 || !Capabilities.hasAudioEncoder || Capabilities.avHardwareDisable) return false;
			if (!Microphone.getMicrophone()) return false;
			return true;
		}
		
        /**
		 * 	give a reference to the Micropone or Camera class, it will get permissions for that media device.
		 * The dialogs and the way this class functions does not change depending on the device you are looking for
		 * except that this class will check to see if there are any devices at all before requesting permission.
         * @param mediaType reference to the media class, either Camera or Microphone
         * @param mode whether to use the QUICK_ACCESS dialog or PRIVACY_DIALOG
		 */
		public function getPermission(mediaType:Class, mode:String = ""):void {
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
         * 
         */
		private function quickAccessPermissions(mediaType:Class):void {
			if (mediaType == Camera) {
				_video = new Video();
                _camera = Camera.getCamera();
                _camera.addEventListener(StatusEvent.STATUS, onMediaStatus);
                _video.attachCamera(_camera);
			} else if (mediaType == Microphone) {
				_netConnect = new NetConnection();
                _netConnect.connect(null);
                _netStream = new NetStream(_netConnect);
                _microphone = Microphone.getMicrophone();
                _microphone.addEventListener(StatusEvent.STATUS, onMediaStatus);
                _netStream.attachAudio(_microphone);
			}
		}
		
		
		private function privacyDialogPermissions(mediaType:Class):void {
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
		
		private function onMediaStatus(e:StatusEvent):void {
/*SUCCESS*/	if      (e.code == "Camera.Unmuted") dispatch(MediaPermissionsResult.GRANTED); 
/*FAIL*/    else if (e.code == "Camera.Muted")   dispatch(MediaPermissionsResult.DENIED);
		}
		
		/**
		 * keeps checking the status of the Microphone.muted / Camera.muted. 
		 * If .muted = false, then we have permission.
		 * If not, we check to see if the dialog is closed,
		 * If it is closed, then we did not get permission
		 * 
		 */
		private function tickCheckPermission(e:TimerEvent):void {
			var muted:Boolean = (_microphone ? _microphone.muted : (_camera ? _camera.muted : true));
/*SUCCESS*/ if (!muted) dispatch(MediaPermissionsResult.GRANTED);
			if (isPermissionDialogClosed()) {	// if box is closed
				_permissionsDialogClosedCount++;
				if ( _permissionsDialogClosedCount >= _permissionsDialogClosedMax ) {
                    _timer.stop();
/*FAIL*/			dispatch(MediaPermissionsResult.DENIED);
                    setDialogIsOpen(false);
				}
			} else {
                _permissionsDialogClosedCount = 0;
                setDialogIsOpen(true);
            }
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
			try { dummy.draw(stage); } 
            catch (error:Error) { closed = false; }
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
            if (_dispatched) dispose();
            else {
                var permissionEvent:MediaPermissionsEvent = new MediaPermissionsEvent(MediaPermissionsEvent.RESOLVE, result, _remembered);
                dispose();
                dispatchEvent(permissionEvent);
                _dispatched = true;
            }
		}
        private function setDialogIsOpen(value:Boolean):void {
            if (value != _dialogIsOpen) {
                _dialogIsOpen = value;
                dispatchEvent(new MediaPermissionsEvent(MediaPermissionsEvent.DIALOG_STATUS, value? MediaPermissionsResult.DIALOG_OPEN : MediaPermissionsResult.DIALOG_CLOSED));
            }
        }
		/**
		 * 	this functions prepares the object for garbage collection.
         *  this will stop any logic from occuring and will prevent any results from firing.
         * 
         * if for some reason you want this object to stop and go away, make sure you call this function first so you avoid a memory leak
		 */
		public function dispose():void {
			if (_timer && !_timer.running) {
				_timer.removeEventListener(TimerEvent.TIMER, tickCheckPermission);
				_timer = null;
                _permissionsDialogClosedCount = 0;
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