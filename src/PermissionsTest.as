/**
 * author:	ktu; 							[blog.cataclysmicrewind.com]
 * updated:	2012.10.06;
 * 
 * This class is free to use and modify, however I request that the header (except example code),
 * and original package remain intact.
 * If you choose to modify it, please contact me before releasing the product.
 * 		[ktu_flash@cataclysmicrewind.com]
 * 
 */
package {
	
	import com.bit101.components.Accordion;
	import com.bit101.components.Style;
    import com.bit101.components.Text;
	import com.bit101.components.VScrollBar;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.NetStatusEvent;
	import flash.geom.Rectangle;
    import flash.media.Camera;
	import flash.media.Microphone;
	import ktu.events.MediaPermissionsEvent;
	import ktu.media.MediaPermissions;
    import ktu.media.MediaPermissionsResult;
	import tests.DialogArea;
    import tests.Output;
	import tests.PermissionTestAccordion;
	import tests.TestData;
	import tests.TestWindow;
	
	
	/**
	 * This Document class is designed to test that the MediaPermissions object works like it should.
	 *
	 *
	 * cases:
	 *
	 *      remembered? - popup - choice = result
	 *
	 *      false - quick - allow = granted
	 *      false - quick - deny = denied
	 *      false - security - allow = granted
	 *      false - security - deny = denied
	 *      true(allow) - quick - n/a = granted
	 *      true(allow) - security - allow = granted
	 *      true(allow) - security - deny = denied
	 *      true(deny) - quick - n/a = denied
	 *      true(deny) - security - allow = allow
	 *      true(deny) - security - deny = denied
	 *      true(deny) - security - close = denied
	 *
	 *
	 *
	 *
	 *
	 *
	 * @author ktu
	 */
	public class PermissionsTest extends Sprite {
        private var output:Output;
        private var mediaPermissions:MediaPermissions;
		
		public function PermissionsTest(){
			if (stage)
				init();
			else
				addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null):void {
			removeEventListener(Event.ADDED_TO_STAGE, init);
			//
			//stage.addEventListener(MouseEvent.CLICK, onClick);
			Style.setStyle(Style.KTU);
			
			
			
			var accordion:PermissionTestAccordion = new PermissionTestAccordion(this, 20, 10);
			accordion.width = 170;
			accordion.height = 480;
			accordion.addEventListener("start", onStart);
			
			var accordionMask:Sprite = new Sprite();
			accordionMask.graphics.beginFill(0);
			accordionMask.graphics.drawRect(0, 0, 170, 360);
			accordionMask.x = 20;
			accordionMask.y = 10;
			accordion.mask = accordionMask;
			
			var accordionSlider:VScrollBar = new VScrollBar(this, 10, 10);
			accordionSlider.height = 360;
			accordionSlider.setThumbPercent(360 / accordion.height);
			accordionSlider.setSliderParams(0, 1, 0);
			accordionSlider.addEventListener(Event.CHANGE, function(e:Event):void {
					accordion.y = 10 - (120 * accordionSlider.value);
				});
			
			var dialogArea:DialogArea = new DialogArea(this, 200, 121);
            dialogArea.setSize(215, 138);
            
            output = new Output(this, 200, 121+138+10);
            output.setSize(215 + 190, 101);
            
            var accordionInstructions:Text = new Text(this, 200, 10, "legend:\nrememberd? False, True(Allow/Deny)\ndialog? Quick or Privacy\nUser Action? Allow/Deny/Close/n/a" );
            accordionInstructions.setSize(215, 91);
            
            
		}
		
		private function onStart(e:NetStatusEvent):void {
            output.log("start clicked");
			mediaPermissions = new MediaPermissions(stage);
			mediaPermissions.mode = e.info.mode;
            output.log("mode = MediaPermissions." + (mediaPermissions.mode == MediaPermissions.QUICK_ACCESS ? "QUICK_ACCESS" : "PRIVACY_DIALOG"));
			mediaPermissions.addEventListener(MediaPermissionsEvent.RESOLVE, onPermissionsResolve);
			mediaPermissions.addEventListener(MediaPermissionsEvent.DIALOG_STATUS, onDialogStatus);
			mediaPermissions.getPermission(Camera);
		}
		
		private function onPermissionsResolve(e:MediaPermissionsEvent):void {
            if (e.remembered) output.log("user 'remembered' their decision");
            var log:String = "MediaPermissionsResult.";
            switch (e.code) {
                case MediaPermissionsResult.GRANTED :
                    log += "GRANTED";
                    break;
                case MediaPermissionsResult.DENIED:
                    log += "DENIED";
                    break;
                case MediaPermissionsResult.NO_DEVICE:
                    log += "NO_DEVICE";
                    break;
            }
            output.log(log);
		}
        private function onDialogStatus(e:MediaPermissionsEvent):void {
            if (mediaPermissions.mode == MediaPermissions.QUICK_ACCESS) {
                if (e.code == MediaPermissionsResult.DIALOG_OPEN) {
                    output.log("MediaPermissionsResult.DIALOG_OPEN - quick access");
                    output.log("waiting for user input");
                } else {
                    output.log("MediaPermissionsResult.DIALOG_CLOSED - quick access");
                }
            } else {
                if (e.code == MediaPermissionsResult.DIALOG_OPEN) {
                    output.log("MediaPermissionsResult.DIALOG_OPEN - privacy dialog");
                    output.log("waiting for user input");
                } else {
                    output.log("MediaPermissionsResult.DIALOG_CLOSED - privacy dialog");
                }
            }
        }
	}
}