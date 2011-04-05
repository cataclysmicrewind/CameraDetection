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
	
	import ktu.events.CameraDetectionEvent;
	import ktu.media.CameraDetection;
	import ktu.media.CameraDetectionResult;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.media.Camera;
	import flash.media.Video;
	import flash.text.TextField;
	
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
		
		private var _button:Sprite;
		private var _textField:TextField;
		private var _cd:CameraDetection;
		
		public function MultiTest() {
			if (stage) init ();
			else addEventListener (Event.ADDED_TO_STAGE, init);
		}
		
		private function init (e:Event = null):void {
			if (e) removeEventListener (Event.ADDED_TO_STAGE, init);
			// entry point
			
			createButton ();
			createTextField ();
		}
		
		private function createVideo (camera:Camera):void {
			camera.setMode (75, 75, 15, true);
			_video = new Video (75, 75);
			_video.x = 50;
			_video.y = 100;
			addChild (_video);
			_video.attachCamera (camera);
		}
		
		private function createTextField():void{
			_textField = new TextField ();
			_textField.autoSize = "left";
			_textField.x = 50;
			_textField.y = 35;
			_textField.text = "Turn On";
			addChild (_textField);
		}
		
		private function createButton():void{
			_button = new Sprite ();
			_button.graphics.beginFill (0x046793);
			_button.graphics.drawRect (0, 0, 75, 20);
			_button.graphics.endFill ();
			_button.x = _button.y = 50;
			addChild (_button);
			_button.addEventListener (MouseEvent.CLICK, onButtonClick);
		}
		
		private function onButtonClick(e:MouseEvent):void {
			if (_textField.text == "Turn On") {
				_textField.text = "Turn Off";
				run ();
			} else {
				_textField.text = "Turn On";
				close ();
			}
			
		}
		
		private function close ():void {
			if (_video) {
				_video.attachCamera (null);
				removeChild (_video);
			}
			_cd.dispose ();
		}
		
		private function run():void{
			_cd = new CameraDetection (stage);
			_cd.addEventListener (CameraDetectionEvent.RESOLVE, onResolve);
			_cd.begin ();1
		}
		
		private function onResolve(e:CameraDetectionEvent):void {
			switch (e.code) {
				case CameraDetectionResult.SUCCESS:
					createVideo (e.camera);
				break;
				case CameraDetectionResult.NO_PERMISSION:
					trace ("NO PERMISSION");
				break;
				case CameraDetectionResult.NO_CAMERAS:
					trace ("NO CAMERAS");
				break;
			}
		}
		
	}

}