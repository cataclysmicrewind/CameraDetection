
package ktu.system {
	
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.media.Microphone;
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
		
		public static const MEDIA_PERMISSIONS:String = "mediaPermissions";
		
		private var _stageRef:Stage;
		
		
		public function SecurityPanelProxy(stage:Stage) {
			_stageRef = stage;
			stage.addEventListener(Event.ADDED, captureNewChildOfStage);
		}
		/**
		 * tells you what the Microphone.useEchoSurpression value is
		 */
		public function get useEchoSurpression ():Boolean {
			
		}
		/**
		 * tells you what the Microphone.gain value is
		 */
		public function get gain ():Boolean {
			
		}
		/**
		 * tesll you if you have permission to use media devices
		 */
		public function get mediaDevicePermission ():Boolean {
			
		}
		/**
		 * tells you if the dialog is currently closed
		 */
		public function get isClosed ():Boolean {
			
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