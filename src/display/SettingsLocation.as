package display {
	import com.bit101.components.Label;
	import com.bit101.components.Panel;
	import com.bit101.components.Style;
	import com.bit101.components.TextArea;
	import flash.display.DisplayObjectContainer;
	import flash.events.Event;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	/**
	 * ...
	 * @author ktu
	 */
	public class SettingsLocation extends Panel {
		
		public function SettingsLocation(parent:DisplayObjectContainer = null, xpos:Number = 0, ypos:Number = 0) {
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			super(parent, xpos, ypos);
			setSize(215, 138);
		}
		
		private function onAddedToStage(e:Event):void {
			removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			x = (stage.stageWidth / 2) - (215 / 2);
			y = (stage.stageHeight / 2) - (138/ 2);
			
			var t:TextField = new TextField();
			t.defaultTextFormat = new TextFormat("anonymous", 16);
			t.x = 10;
			t.y = 10;
			t.width = 195;
			t.height = 118;
			t.wordWrap = true;
			t.multiline = true;
			t.text = "The Settings panel will appear over top of this";
			addChild(t);
			t.height = t.textHeight + 4;
			t.y = (138 / 2) - (t.height / 2);
		}
		
	}

}