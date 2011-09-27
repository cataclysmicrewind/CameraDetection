package display {
	import com.bit101.components.CheckBox;
	import com.bit101.components.HUISlider;
	import com.bit101.components.Label;
	import com.bit101.components.NumericStepper;
	import com.bit101.components.Panel;
	import com.bit101.components.TabPanel;
	import flash.display.DisplayObjectContainer;
	import flash.events.Event;
	import flash.media.Camera;
	import flash.media.Microphone;
	
	/**
	 * ...
	 * @author ktu
	 */
	public class SettingsDialogValues extends Panel {
		private var _name:String;
		
		public function SettingsDialogValues(parent:DisplayObjectContainer = null, xpos:Number = 0, ypos:Number = 0, name:String = "" ) {
			super(parent, xpos, ypos);
			_name = name;
			init();
		}
		
		override protected function init():void {
			super.init();
			var p:Panel = this;
			//setTabNameAt("Old Values", 0);
			// Microphone:
			// gain
			// muted
			// echo
			var mic:Microphone = Microphone.getMicrophone();
			var micLabel:Label = new Label(p, 10, 10, "Mic:");
			var gain:HUISlider = new HUISlider(p, micLabel.x + 10-9, micLabel.y + micLabel.height);
			gain.width -= 100;
			gain.maximum = 100;
			gain.minimum = 0;
			gain.tick = 1;
			gain.labelPrecision = 1;
			//var gain:NumericStepper = new NumericStepper(p, gainLabel.x + gainLabel.width, micLabel.y + micLabel.height);
			//gain.maximum = 100;
			//gain.minimum = 0;
			//gain.step = 1;
			var echo:CheckBox = new CheckBox(p, micLabel.x + 10, gain.y + gain.height + 5-2, "useEcho");
			var muted:CheckBox = new CheckBox(p, micLabel.x + 10, echo.y + echo.height+5, "muted");
			// Camera:
			// muted
			var cam:Camera = Camera.getCamera();
			var camLabel:Label = new Label(p, micLabel.x, muted.y + muted.height+5, "Camera");
			var mutedCam:CheckBox = new CheckBox(p, camLabel.x + 10, camLabel.y + camLabel.height, "muted");
			
			width = gain.x + gain.width + 10;
			height = mutedCam.y + mutedCam.height + 10;
		}
		
	}

}