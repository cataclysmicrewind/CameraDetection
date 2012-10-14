package tests {
	import com.bit101.components.Panel;
    import com.bit101.components.PushButton;
    import com.bit101.components.Text;
    import com.bit101.components.VScrollBar;
	import flash.display.DisplayObjectContainer;
    import flash.events.Event;
	
	
	/**
	 * ...
	 * @author ktu
	 */
	public class Output extends Panel {
		
        public var text:Text;
        public var scrollBar:VScrollBar;
        public var clear:PushButton;
        
		public function Output(parent:DisplayObjectContainer = null, xpos:Number = 0, ypos:Number = 0){
			super(parent, xpos, ypos);
		
		}
		
		override protected function addChildren():void {
			super.addChildren();
            
            text = new Text(content);
            //text.width = 205 + 190;
            //text.height = 101;
            text.editable = false;
            scrollBar = new VScrollBar(content);
            //scrollBar.x = 205 + 190;
            //scrollBar.height = 101;
            
            clear = new PushButton(content, 205 + 190 - 60-10, 0, "clear", function (e:Event):void { text.text = ""; } );
            clear.width = 60;
		}
        override public function setSize(w:Number, h:Number):void {
            super.setSize(w, h);
            text.width = w - scrollBar.width;
            text.height = h;
            scrollBar.x = w - scrollBar.width
            scrollBar.height = h;
            clear.x = w - scrollBar.width - clear.width;
        }
        public function log(msg:String):void {
            text.textField.appendText(msg + "\n");
            text.textField.scrollV = text.textField.maxScrollV;
            scrollBar.setSliderParams(1, text.textField.maxScrollV, text.textField.maxScrollV);
            scrollBar.setThumbPercent(text.textField.numLines / text.textField.maxScrollV);
        }
	}
}