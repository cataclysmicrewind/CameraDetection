package  {
	import com.bit101.components.ComboBox;
	import com.bit101.components.IndicatorLight;
	import com.bit101.components.Label;
	import com.bit101.components.Style;
	import display.SettingsDialogValues;
	import display.SettingsLocation;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.media.Microphone;
	import flash.system.Security;
	import flash.system.SecurityPanel;
	import ktu.system.SecurityPanelProxy;
	
	/**
	 * ...
	 * @author ktu
	 */
	public class PanelTest extends Sprite {
		
		public function PanelTest() {
			init();
		}
		
		private function init():void {
			Style.setStyle(Style.KTU);
			//var settingsLocation:SettingsLocation = new SettingsLocation(this);
			var isOpen:IndicatorLight = new IndicatorLight(this, 50, 10, 0xFF0000, "is open");
			isOpen.isLit = true;
			var oldSettings:SettingsDialogValues = new SettingsDialogValues(this, 200, 10, "Old Values");
			var newSettings:SettingsDialogValues = new SettingsDialogValues(this, 200, 280, "New Values");
			
			var options:ComboBox = new ComboBox(this, 50, 50, "::dialog options::");
			options.width += 30
			options.items = [
				{ label: SecurityPanelProxy.MEDIA_PERMISSIONS },
				{ label: SecurityPanel.CAMERA },
				{ label: SecurityPanel.DEFAULT },
				{ label: SecurityPanel.DISPLAY },
				{ label: SecurityPanel.LOCAL_STORAGE },
				{ label: SecurityPanel.MICROPHONE },
				{ label: SecurityPanel.PRIVACY }
			];
			options.addEventListener(Event.SELECT, onSelectionOption);
		}
		
		private function onSelectionOption(e:Event):void {
			var spp:SecurityPanelProxy = new SecurityPanelProxy(stage);
			spp.addEventListener("closed", onSPPClosed);
			spp.addEventListener("open", onSPPOpen);
			spp.showPanel(e.target.selectedItem.label);
		}
		
		private function onSPPOpen(e:Event):void {
			trace("OPEN");
		}
		
		private function onSPPClosed(e:Event):void {
			trace("CLOSED");
		}
		
	}

}