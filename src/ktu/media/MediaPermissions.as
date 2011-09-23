


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
	 * I am using Martin Arvisais' suggested workaround for not knowing when the settings dialog closes:
     * 		http://bugs.adobe.com/jira/browse/FP-41?page=com.atlassian.jira.plugin.system.issuetabpanels:comment-tabpanel&focusedCommentId=443688#action_443688
     *
     *
	 * ...
	 * @author ktu
	 */
	public class MediaPermissions extends EventDispatcher {
		
		static public const QUICK_ACCESS				:String = "quickAccess";			// quick access dialog mode of requesting permission
		static public const PRIVACY_DIALOG				:String = "privacyDialog";			// full privacy settings dialog mode of requestion permission
		
		public var 	mode								:String = QUICK_ACCESS;				// permissions request mode
		public var 	permissionsTimerDelay				:uint		= 200;                  // the default delay for checking permissions
		
		private var _stage								:Stage;								// needed to hack the dialog
		private var _numChildren						:int;								// need this to keep track of when the dialog closes
		
		private var _microphone							:Microphone;						// used for requesting permission and tracking it
		private var _netStream							:NetStream;							// used to invoke the quick access mode
		private var _netConnect							:NetConnection;						// needed for the netstream to work
		
		private var _timer								:Timer;								// what checks to see if permissions change
		
		private var _remembered							:Boolean	= true;					// whether the user had selected remember. (only works with quick access)
		
		
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
		 * 	give a reference to the Micropone or Camera class, it will get permissions for that media device.
		 * The dialogs and the way this class functions does not change depending on the device you are looking for
		 * except that this class will check to see if there are any devices at all before requesting permission.
		 * 
		 * If you pass null, then it will check both, and if either are in failure (no device) then you will get a 
		 * NO_DEVICE response.
		 * 
		 * 
		 */
		public function getPermission(mediaType:Class = null):void {
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
			
			_microphone = Microphone.getMicrophone();
			
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
					return checkCameraAvailability();
				default:
					var cam:Boolean = checkCameraAvailability();
					var mic:Boolean = checkMicrophoneAvailability();
					if (cam && mic) return true;
					else return false;
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
		 * If it is closed, then we did not get permission
		 * 
		 * 
		 * These variables are used to put a delay on the box being closed... 
		 * thought it would help in the past not sure it does now
		 * 
		 * 	private var _permissionsDialogClosedMax		:uint		= 2;                    // max number of times the dialog should register as closed before confirming
		 * 	private var _permissionsDialogClosedCount	:uint 		= 0;					// number of times the dailog being closed has been recorded
		 * 
		 * @param	e
		 */
		private function tickNumChildren(e:TimerEvent):void {
			//trace("MediaPermissions::tickNumChildren()");
			var muted:Boolean = _microphone.muted;
			if (!muted) { // permision was granted
				//trace("MediaPermissions::tickNumChildren() - camera.muted = false");
				_timer.stop();
                dispatch(MediaPermissionsResult.GRANTED);
			} else if (isPermissionDialogClosed()) {	// if box is closed
				//trace("MediaPermissions::tickNumChildren() - dialog is closed");
				//_permissionsDialogClosedCount++;
				//if ( _permissionsDialogClosedCount >= _permissionsDialogClosedMax ) {
					//trace("MediaPermissions::tickNumChildren() - closed for so long, we ain't gettin permission");
					_timer.stop();
					dispatch(MediaPermissionsResult.DENIED);
				//}
			}
		}
		/**
		 * if the box is open, then there is one more child on the stage than there should be
		 * 
		 * @return
		 */
		private function isPermissionDialogClosed():Boolean {
			//trace("MediaPermissions::isPermissionDialogClosed() - " + (_stage.numChildren <= _numChildren));
			if (_stage.numChildren <= _numChildren) {
				return true;
			} else {
				_remembered = false; // if in QUICK_ACCESS mode and the dialog opens, then they did not remember their decision 
				return false;		 // if in PRIVACY_DIALOG, best to ignore this value, as it won't matter if you remember or not.
			}
		}
		
		
		
		
		
		
		
		/**
		 * Tell the world what you found...
		 * 
		 * @param	result - what happened?
		 */
		private function dispatch (result:String):void {
			trace("MediaPermissions::dispatch() - " + result);
			var permissionEvent:MediaPermissionsEvent = new MediaPermissionsEvent(MediaPermissionsEvent.RESOLVE, result, _remembered);
			dispatchEvent(permissionEvent);
			dispose();
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