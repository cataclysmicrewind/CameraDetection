/**
 * * File:	MultiTest.as;
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
 * 		I did this for testing, because really, who uses the IDE anymore except for assets?
 *
 */
package  {
	
    import com.bit101.components.Label;
    import com.bit101.components.NumericStepper;
    import com.bit101.components.Panel;
    import com.bit101.components.PushButton;
    import com.bit101.components.Style;
    import com.bit101.components.Text;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.media.Camera;
    import flash.media.Video;
    import flash.text.TextFormat;
    import ktu.events.CameraDetectionEvent;
    import ktu.events.MediaPermissionsEvent;
    import ktu.media.CameraDetection;
    import ktu.media.CameraDetectionResult;
    import ktu.media.MediaPermissions;
    import ktu.media.MediaPermissionsResult;
    import tests.Output;
	
	
	/**
	 *
	 * 		This class is a test class to see how CameraDetection functions when an application tries to use the camera multiple times  <br/>
	 * 																																	<br/>
	 * 		This is a document class.																									<br/>
	 * 																																	<br/>
	 *
	 */
	public class MultiTest extends Sprite{
		
		private var _video:Video;
		private var _camera:Camera;
		
        private var _onOff:PushButton;
        private var _videoArea:Panel;
        
        private var _output:Output;
        
		private var _cd:CameraDetection;
        private var _permissionsModeLabel:Label;
        private var _permissionsModeQuick:PushButton;
        private var _permissionsModePrivacy:PushButton;
        private var _secLengthToCheckNumStepper:NumericStepper;
        private var _blackoutDelayNumStepper:NumericStepper;
		
		public function MultiTest() {
			if (stage) init ();
			else addEventListener (Event.ADDED_TO_STAGE, init);
		}
		
		private function init (e:Event = null):void {
			if (e) removeEventListener (Event.ADDED_TO_STAGE, init);
			// entry point
            
            _cd = new CameraDetection (stage);
            _cd.addEventListener(MediaPermissionsEvent.DIALOG_STATUS, onDialogStatus);
            _cd.addEventListener(MediaPermissionsEvent.RESOLVE, onPermissionsResolve);
			_cd.addEventListener (CameraDetectionEvent.RESOLVE, onResolve);
            
            //
            _onOff = new PushButton(this, 120, 50, "start CameraDetection", onStartClick);
            _onOff.setSize(140, 35);
            
            _videoArea = new Panel(this, 320, 30);
            _videoArea.setSize(75, 75);
            var _videoAreaText:Text = new Text(_videoArea, 0, 15, "video displays here");
            _videoAreaText.setSize(75, 45);
            _videoAreaText.textField.defaultTextFormat = new TextFormat(null, null, null, null, null, null, null, null, "center");
            _videoAreaText.editable = false;
            _videoAreaText.selectable = false;
            
            _output = new Output(this, 25,  220);
            _output.setSize(450, 155);
            
            // make ui for permissionsMode
            _permissionsModeLabel = new Label(this, 62, 135, "permissions mode");
            _permissionsModeQuick = new PushButton(this, 25, 165, "quickAccess", onPermissionsModeButton);
            _permissionsModeQuick.toggle = true;
            _permissionsModeQuick.setSize(80, 25);
            _permissionsModePrivacy = new PushButton(this, 25+80+10, 165, "privacyDialog", onPermissionsModeButton);
            _permissionsModePrivacy.toggle = true;
            _permissionsModePrivacy.setSize(80, 25);
            _permissionsModeQuick.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
            // make a numstepper for secLengthToCheck
            var _secLengthToCheckLabel:Label = new Label(this, 240, 135, "secLengthToCheck");
            _secLengthToCheckNumStepper = new NumericStepper(this, 250, 165+2);
            _secLengthToCheckNumStepper.setSize(80, 20);
            _secLengthToCheckNumStepper.step = .2;
            _secLengthToCheckNumStepper.minimum = .1;
            _secLengthToCheckNumStepper.maximum = 20;
            _secLengthToCheckNumStepper.value = 3;
            // make a numstepper for blackoutDelay
            var _blackoutDelayLabel:Label = new Label(this, 398, 135, "blackoutDelay");
            _blackoutDelayNumStepper = new NumericStepper(this, 395, 165 + 2);
            _blackoutDelayNumStepper.setSize(80, 20);
            _blackoutDelayNumStepper.minimum = 0;
            _blackoutDelayNumStepper.maximum = 20000;
            _blackoutDelayNumStepper.step = 200;
            _blackoutDelayNumStepper.value = 0;
            
		}
		
        private function onPermissionsModeButton (e:MouseEvent):void {
            var on:PushButton = e.target == _permissionsModeQuick ? _permissionsModeQuick : _permissionsModePrivacy;
            var off:PushButton = e.target == _permissionsModePrivacy ? _permissionsModeQuick : _permissionsModePrivacy;
            on.selected = true;
            off.selected = false;
            _cd.permissionsMode = on.labelText;
        }
		private function onStartClick(e:MouseEvent):void {
			if (_onOff.labelText == "start CameraDetection") {
				_onOff.labelText = "detecting camera...";
                _onOff.toggle = true;
                _onOff.selected = true;
                _onOff.enabled = false;
				run ();
			} else {
				_onOff.labelText = "start CameraDetection";
				close ();
			}
		}
		
		
		private function run():void {
			_cd.permissionsMode = _permissionsModeQuick.selected ? MediaPermissions.QUICK_ACCESS : MediaPermissions.PRIVACY_DIALOG;
            _cd.blackoutDelay = _blackoutDelayNumStepper.value;
            _cd.secLengthToCheck = _secLengthToCheckNumStepper.value;
            _cd.cameraMode = { width: 75, height: 75 };
            _video = new Video(75, 75);
			_cd.begin (_video);
		}
        
        private function onPermissionsResolve(e:MediaPermissionsEvent):void {
            switch (e.code) {
                case MediaPermissionsResult.GRANTED:
                    _output.log("MediaPermissionsEvent.GRANTED" + (e.remembered ? " - remembered" : ""));
                    _output.log("waiting for camera to be detected");
                    break;
                case MediaPermissionsResult.DENIED:
                    _output.log("MediaPermissionsEvent.DENIED" + (e.remembered ? " - remembered" : ""));
                    break;
                case MediaPermissionsResult.NO_DEVICE: 
                    _output.log("MediaPermissionsEvent.NO_DEVICE");
                    break;
            }
        }
        
        private function onDialogStatus(e:MediaPermissionsEvent):void {
            var log:String = ""
            switch (e.code) {
                case MediaPermissionsResult.DIALOG_OPEN:
                    _output.log("MediaPermissionsEvent.DIALOG_OPEN - " + MediaPermissions(e.target).mode );
                    _output.log("waiting for user input");
                    break;
                case MediaPermissionsResult.DIALOG_CLOSED:
                    _output.log("MediaPermissionsEvent.DIALOG_CLOSED - " + MediaPermissions(e.target).mode);
                    break;
            }
        }
		
		private function onResolve(e:CameraDetectionEvent):void {
			switch (e.code) {
				case CameraDetectionResult.SUCCESS:
                    e.video.x = 320;
                    e.video.y = 30;
					addChild (e.video);
                    _output.log("CameraDetectionResult.SUCCESS");
				break;
                case CameraDetectionResult.NO_SUCCESS:
					_output.log("CameraDetectionResult.NO_SUCCESS");
				break;
				case CameraDetectionResult.NO_PERMISSION:
					_output.log("CameraDetectionResult.NO_PERMISSIONS");
				break;
				case CameraDetectionResult.NO_CAMERAS:
					_output.log("CameraDetectionResult.NO_CAMERAS");
				break;
			}
            _onOff.selected = false;
            _onOff.toggle = false;
            _onOff.labelText = "reset";
            _onOff.enabled = true;
		}
        private function close ():void {
			if (_video) {
				_video.attachCamera (null);
				if (_video.parent) removeChild (_video);
			}
			_cd.dispose ();
		}
	}

}