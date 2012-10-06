package tests {
	import com.bit101.components.PushButton;
    import com.bit101.components.Style;
	import com.bit101.components.Text;
	import com.bit101.components.Window;
	import flash.display.DisplayObjectContainer;
	import flash.events.MouseEvent;
	import flash.events.NetStatusEvent;
	import flash.text.TextFormat;
	
	
	/**
	 *
	 *  Each test window has:
	 *
	 *      Description & Instruction  buttons
	 *
	 *      toggle text in box. has scroll bar if neccessary
	 *
	 *      start button
	 *
	 *      [expected result]
	 *
	 * @author ktu
	 */
	public class TestWindow extends Window {
		
		private var _data:Object;
		
		public var description:PushButton;
		public var instructions:PushButton;
		public var text:Text;
		public var start:PushButton;
		
		public function TestWindow(parent:DisplayObjectContainer = null, xpos:Number = 0, ypos:Number = 0, title:String = "Window"){
			super(parent, xpos, ypos, title);
			width = 170;
			height = 240 + 20; // height of titleBar
		}
		
		override protected function addChildren():void {
			super.addChildren();
			
			_titleLabel.mouseEnabled = false;
			_titleLabel.textField.defaultTextFormat = new TextFormat(null, null, null, true);
			
			//_titleBar.buttonMode = true;
			//_titleBar.mouseChildren = true;
			
			description = new PushButton(_panel, 5, 10, "description", onButtonClick);
			description.width = 80;
			description.height = 20;
			description.toggle = true;
            description.upColor = Style.BUTTON_DOWN;
            description.downColor = Style.BUTTON_FACE;
			instructions = new PushButton(_panel, 85, 10, "instructions", onButtonClick);
			instructions.width = 80;
			instructions.height = 20;
			instructions.toggle = true;
            instructions.upColor = Style.BUTTON_DOWN;
            instructions.downColor = Style.BUTTON_FACE;
			text = new Text(_panel, 5, 40);
			text.width = 160;
			text.height = 140;
			text.selectable = false;
			text.editable = false;
			start = new PushButton(_panel, 50, 207 - 20, "start", onButtonClick);
			start.width = 60;
			start.height = 25;
		}
		
		override public function get draggable():Boolean { return super.draggable; }
		override public function set draggable(value:Boolean):void { _draggable = value; }
		
		public function setData(data:Object):void {
			_data = data;
			title = data.title;
			text.text = data.description;
            description.selected = true;
		}
		
		
		
		protected function onButtonClick(e:MouseEvent):void {
			if (e.target == description) {
                if (description.selected == false) {
                    description.selected = true;
                }
				//description.toggle = true;
				instructions.selected = false;
				text.text = _data.description;
			} else if (e.target == instructions) {
                if (instructions.selected == false) {
                    instructions.selected = true;
                }
				description.selected = false;
				//instructions.toggle = true;
				text.text = _data.instructions + "\n\nexpectation: " + _data.expectation;
			} else {
				// pushed start, dispatch
				dispatchEvent(new NetStatusEvent("start", false, false, _data));
			}
		}
	}
}