

package ktu.media {
	
	import flash.display.Stage;
	import flash.media.Camera;
	import flash.media.Video;
	import flash.system.Capabilities;
	import flash.utils.getTimer;
	import ktu.events.CameraDetectionEvent;
	
	
	/**
	 * ...
	 * @author ktu
	 */
	public class CameraDetectionLogger extends CameraDetection3 {
		
		private var _log:Object = { };
		public function get log():Object { return _log; }
		
		public function CameraDetectionLogger() {
			super();
			_cCheck = new CameraCheckerLogger();
            _log.os = Capabilities.os;
            _log.version = Capabilities.version;
            _log.playerType = Capabilities.playerType;
            _log.isDebugger = Capabilities.isDebugger;
		}
	
		override public function begin(stage:Stage, customVideo:Video = null):void {
			_log.start = getTimer();
            _log.cameras = Camera.names;
			_log.camerasChecked = [];
			super.begin(stage, customVideo);
		}
		override public function dispose():void {
			_log.disposed = true;
			super.dispose();
		}
		override protected function havePermissions():void {
			super.havePermissions();
			_log.defaultCamera = _defaultCameraName;
		}
		override protected function onCChecker(e:CameraDetectionEvent):void {
			_log.camerasChecked.push(CameraCheckerLogger(_cCheck).log);
			super.onCChecker(e);
		}
		override protected function dispatch(result:String, camera:Camera = null, video:Video = null):void {
			_log.end = getTimer();
			_log.result = result;
			super.dispatch(result, camera, video);
            //call out myself
		}
	}
}