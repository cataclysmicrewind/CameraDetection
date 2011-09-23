package  {
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.media.Microphone;
	import ktu.events.MediaPermissionsEvent;
	import ktu.media.CameraDetection2;
	import ktu.media.MediaPermissions;
	
	/**
	 * ...
	 * @author ktu
	 */
	public class Permissions extends Sprite {
		
		public function Permissions() {
			stage.addEventListener(MouseEvent.CLICK, onClick);
			
		}
		
		private function onClick(e:MouseEvent):void {
			var p:MediaPermissions = new MediaPermissions(stage);
			p.mode = MediaPermissions.PRIVACY_DIALOG;
			p.addEventListener (MediaPermissionsEvent.RESOLVE, onPermissionsResolve);
			p.getPermission(Microphone);
		}
		
		private function onPermissionsResolve(e:MediaPermissionsEvent):void {
			trace("PermissionsEvent came back with: " + e.code);
			e.target.removeEventListener (MediaPermissionsEvent.RESOLVE, onPermissionsResolve);
		}
		
	}

}