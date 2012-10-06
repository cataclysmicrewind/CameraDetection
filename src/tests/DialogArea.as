package tests {
	import com.bit101.components.Panel;
	import com.bit101.components.Text;
	import flash.display.DisplayObjectContainer;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	
	
	/**
	 * ...
	 * @author ktu
	 */
	public class DialogArea extends Panel {
    
        private var text:Text;
		
		public function DialogArea(parent:DisplayObjectContainer = null, xpos:Number = 0, ypos:Number = 0){
			super(parent, xpos, ypos);
		}
		
		override protected function addChildren():void {
			super.addChildren();
			// add text and center that shit
            text = new Text(content, 0, 0, "dialog pops up here\n\nbelow is the output from MediaPermissions");
			text.height = 22;
            text.textField.autoSize = "left";
			text.textField.defaultTextFormat = new TextFormat(null, 20, null, true, null, null, null, null, TextFormatAlign.CENTER);
		}
		
		override public function setSize(w:Number, h:Number):void {
			super.setSize(w, h);
            text.y = (h / 2) - (text.height / 2);
            text.x = (w / 2) - (text.width / 2);
            text.width = 185;
            text.height = 60
		}
	}
}