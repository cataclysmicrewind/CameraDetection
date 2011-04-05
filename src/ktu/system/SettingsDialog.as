
package ktu.system {
    
	import flash.display.Sprite;
	
	/**
     * 
     *  This class is a proxy for the Settings Dialog
     * 
     * Use this instead of flash.system.Security::showSettings(panel:String = "default");
     * 
     * This class will make it much easier to deal with the settings dialog. It will actually notify you when it closes, 
     *  and hopefully will tell you of any values that changed during the time it was open.
     * 
     * 
     * 
     * 
     * For first, let it be useful for CameraDetection...
     * 
     * 
     * 
     *      new SettingsDialog ();
     *      sd.
     * 
     * 
     * ...
     * @author Ktu
     */
    public class SettingsDialog extends Sprite {
        
        public function SettingsDialog() {
            
        }
        
    }

}