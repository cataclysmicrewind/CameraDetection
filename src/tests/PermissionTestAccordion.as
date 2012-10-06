package tests {
	import com.bit101.components.Accordion;
    import com.bit101.components.Style;
    import com.bit101.components.VBox;
    import com.bit101.components.Window;
	import flash.display.DisplayObjectContainer;
    import flash.events.Event;
    import flash.events.NetStatusEvent;
	
	
	/**
	 * this accordion contains all of the tests... when a test's start is clicked, an event is dispatched to say which one and the data for the test
	 *  aka the expected response
	 *
	 *
	 *
	 * @author ktu
	 */
	public class PermissionTestAccordion extends Accordion {
		
		public function PermissionTestAccordion(parent:DisplayObjectContainer = null, xpos:Number = 0, ypos:Number = 0){
			super(parent, xpos, ypos);
		
		}
		
		override protected function addChildren():void {
			_vbox = new VBox(this);
			_vbox.spacing = 0;
            
			_windows = new Array();
            
            // loop through and create all of the test Windows
            var td:Array = TestData.data;
			for(var i:int = 0; i < td.length; i++) {
				var window:TestWindow = new TestWindow(_vbox, 0, 0);
                window.setData(td[i]);
				window.grips.visible = false;
				window.draggable = false;
				window.addEventListener(Event.SELECT, onWindowSelect);
                window.addEventListener("start", function (e:NetStatusEvent):void { dispatchEvent(e); } );
				if (i != 0) window.minimized = true;
                window.titleColor = i % 2 == 0 ? Style.LIST_DEFAULT : Style.LIST_ALTERNATE;
                window.color = i % 2 == 0 ? Style.LIST_DEFAULT : Style.LIST_ALTERNATE;
				_windows.push(window);
			}
		}
	}

}