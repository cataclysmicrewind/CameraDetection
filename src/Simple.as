/**
 * * File:	Simple.as;
 * Author:	Ktu; 							[blog.cataclysmicrewind.com]
 * Updated:	12.17.10;
 *
 * This class is free to use and modify, however I request that the header (except example code),
 * and original package remain intact.
 * If you choose to modify it, please contact me before releasing the product.
 * 		[ktu_flash@cataclysmicrewind.com]
 *
 *
 *
 * 		This is a document class for a swf.
 * 		This swf is meant for Always Compile in FlashDevelop
 *
 * 		This is the same code as the simple example.fla
 *
 * 		I did this for testing, because really, who uses the IDE anymore except for assets?
 *
 *
 */
package {
	
    import flash.media.Camera;
	import ktu.events.CameraDetectionEvent;
    import ktu.events.MediaPermissionsEvent;
    import ktu.media.CameraChecker;
	import ktu.media.CameraDetection;
	import ktu.media.CameraDetectionResult;
    import ktu.media.MediaPermissions;
    import ktu.media.MediaPermissionsResult;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.media.Video;
	
	/**
	 *
	 * 		This class is a simple example of how to use CameraDetection																<br/>
	 * 																																	<br/>
	 * 		This is a document class.																									<br/>
	 * 																																	<br/>
	 * 		Very simple.																												<br/>
	 * 		Create an instance																											<br/><listing version="3">
	 *			var cd:CameraDetection = new CameraDetection(stage);																	</listing><br/>
	 * 		Add the event listener 																										<br/><listing version="3">
	 *			cd.addEventListener (CameraDetectionEvent.RESOLVE, onCameraResolve);													</listing><br/>
	 * 		Write function onCameraResolve to handle the results																		<br/><listing version="3">
	 *			function onCameraResolve (e:CameraDetectionEvent):void {
	 *				switch (e.code) {
	 * 					case CameraDetectionResult.SUCCESS:
	 * 					case CameraDetectionResult.NO_SUCCESS:
	 * 					case CameraDetectionResult.NO_PERMISSION:
	 * 					case CameraDetectionResult.NO_CAMERAS:
	 * 																																	</listing>
	 */
	public class Simple extends Sprite {
		
		private var video:Video;
		private var cd:CameraDetection;
		
		
		public function Simple() {
			if (stage) init ();
			else addEventListener (Event.ADDED_TO_STAGE, init);
		}
		
		private function init (e:Event = null):void {
			if (e) removeEventListener (Event.ADDED_TO_STAGE, init);
			// entry point
			video = new Video();
			addChild(video);
			
			cd = new CameraDetection (stage);
            cd.secLengthToCheck = 5;
			cd.addEventListener (CameraDetectionEvent.RESOLVE, onResolve);
            cd.addEventListener(MediaPermissionsEvent.DIALOG_STATUS, onDialogStatus);
			cd.begin(video);
            
		}
        private function onDialogStatus (e:MediaPermissionsEvent):void {
            if (e.code == MediaPermissionsResult.DIALOG_OPEN) {
                trace("dialog opened");
            } else if (e.code == MediaPermissionsResult.DIALOG_CLOSED) {
                trace("dialog closed");
            }
        }
		private function onResolve(e:CameraDetectionEvent):void {
			switch (e.code) {
				case CameraDetectionResult.SUCCESS :
                    trace("got a camera!!!");
					video.attachCamera(e.camera);
					break;
				case CameraDetectionResult.NO_PERMISSION :
					trace("Camera access denied");
					break;
				case CameraDetectionResult.NO_CAMERAS :
					trace("There are no cameras connected to the computer");
					break;
                case CameraDetectionResult.NO_SUCCESS:
                    trace("there was at least one camera, but none worked!!");
			}
		}
	}

}