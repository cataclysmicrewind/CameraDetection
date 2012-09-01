package ktu.media {
	import flash.events.TimerEvent;
	import flash.media.Camera;
	import flash.media.Video;
	import flash.utils.getTimer;
	
	
	/**
	 *
	 * this class will track and hold onto all important information while checking a camera...
	 *
	 * tick delay
	 * timer repeat Count
	 *
	 * camera name
	 * num ticks till past activity init
	 * each tick:
	 *      activity reading
	 *      fps reading
	 *
	 * ...
	 * @author ktu
	 */
	public class CameraCheckerLogger extends CameraChecker {
		
		protected var _log:Object = { };
		public function get log():Object { return _log; }
		
		
		public function CameraCheckerLogger(){
		
		}
		
		override public function check(camera:Camera, video:Video = null):void {
			_log.name = camera.name
			_log.startTime = getTimer();
			_log.timerDelay = _timerDelay;
			_log.timerRepeatCount = _timerRepeatCount;
			_log.minTimesGood = _minTimesGood;
			_log.cameraActivityInitCompleteTick = -1;
			_log.cameraActivityAverage = -1;
			_log.cameraFPSAverage = -1;
			//_log.ticks = [];
			_log.completeFired = false;
			_log.dispatches = [];
			super.check(camera, video);
		}
		
		override protected function tickCheckCamera(e:TimerEvent):void {
			if (e.type == TimerEvent.TIMER){
				//_log.ticks[_timer.currentCount] = {activity: _camera.activityLevel, fps: _camera.fps, activityInit: _camActivityInit }
			} else {
				_log.completeFired = true;
			}
			super.tickCheckCamera(e);
		}
		
		override protected function dispatch(result:String):void {
            _log.completeTime = getTimer();
			super.dispatch(result);
		}
		
	}

}