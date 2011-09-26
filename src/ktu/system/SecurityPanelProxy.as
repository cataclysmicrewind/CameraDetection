
package ktu.system {
	
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.media.Microphone;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.system.Security;
	import flash.utils.Timer;
	/**
	 * 
	 * This is a proxy for using the SecurityPanel.
	 * 
	 * The security panel is the dialog that pops up when the user right clicks in Flash and chooses 'Settings...'
	 * or it can be triggered through code via Security.showSettings();
	 * 
	 * 
	 * This class is a more simple interface to using that panel. 
	 * 
	 * 
	 * Features:
	 * 		Dispatches events when it is displayed and closed
	 * 		Trigger the panel however you choose:
	 * 			quick permissions for media
	 * 			quick settings for LSO
	 * 			Continue using SecurtyPanel.CONST to open the panel at the specified page
	 * 
	 * 
	 * 	Tracks whether the user changes the microphone.useEchoSurpression
	 * 	Tracks whether the user changes the microphone.gain
	 * 
	 *  Tracks whether permission is given to use media devices
	 * 
	 * 
	 * ...
	 * @author Ktu
	 */
	public class SecurityPanelProxy extends EventDispatcher {
		
		public static const MEDIA_PERMISSIONS	:String = "mediaPermissions";
		
		private var _stageRef					:Stage;
		private var _numChildren				:int;
		
		private var _microphone					:Microphone;
		private var _netStream					:NetStream;							// used to invoke the quick access mode
		private var _netConnect					:NetConnection;						// needed for the netstream to work
		
		private var _timer						:Timer;
		public var 	permissionsTimerDelay		:uint		= 200;                  // the default delay for checking permissions
		
		
		public function SecurityPanelProxy(stage:Stage) {
			_stageRef = stage;
			stage.addEventListener(Event.ADDED, captureNewChildOfStage);
		}
		/**
		 * tells you what the Microphone.useEchoSurpression value is
		 */
		public function get useEchoSurpression ():Boolean {
			return true
		}
		/**
		 * tells you what the Microphone.gain value is
		 */
		public function get gain ():Boolean {
			
			return true
		}
		/**
		 * tesll you if you have permission to use media devices
		 */
		public function get mediaDevicePermission ():Boolean {
			
			return true
		}
		/**
		 * tells you if the dialog is currently closed
		 */
		public function get isClosed ():Boolean {
			
			return true
		}
		/**
		 * display the Security Dialog Panel.
		 * 
		 * the page paramater can be any of the constants from SecurityPanel or any of the constants in this class.
		 * 
		 * 
		 * if you choose the MEDIA_PERMISSIONS, then it triggers the quick access dialog with the accept or deny options
		 * if you choose anything else, then it opens the dialog at the specified page.
		 * 
		 * 
		 * 
		 * 
		 * @param	page
		 */
		public function showPanel (page:String):void {
			listen();
			if (page == MEDIA_PERMISSIONS) {
				_microphone = Microphone.getMicrophone();
				_netConnect = new NetConnection();
				_netConnect.connect(null);
				_netStream = new NetStream(_netConnect);
				_netStream.attachAudio(_microphone);
			} else 
				Security.showSettings(page);
				dispatch("open");
		}
		
		/**
		 * 
		 * Start the process to keep track of the dialog
		 * 
		 */
		private function listen():void {
			// store the current number of children on the stage. the dialog makes it one more...
			_numChildren = _stageRef.numChildren;
			// setup the timer 
			_timer = new Timer(permissionsTimerDelay);
			_timer.addEventListener(TimerEvent.TIMER, tickNumChildren);
			_timer.start();
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
			if (_stageRef.numChildren <= _numChildren) {	// if box is closed
				_timer.stop();
				dispatch("closed");
			}
		}
		
		private function dispatch (type:String):void {
			dispatchEvent(new SecurityPanelEvent(type, true));
		}
		
		
		/**
		 * this function will run whenever the stage gets a new child. 
		 * It will try to grab that child, if it is null, then I am going to assume that the dialog is open...
		 * Since it opens, I will keep track of when it closes. Also, I will set the initial values of all its configurable options
		 * and notify if there is any change.
		 * 
		 * @param	e
		 */
		private function captureNewChildOfStage(e:Event):void {
			
		}
		
		/**
		 * 
		 * CODE TO KEEP TRACK OF WHEN THE DIALOG IS OPEN
		 * 
		 */
	}
}