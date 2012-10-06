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
package ktu.media {
    
	/**
	 * Enumeration of possible results from using MediaPermissions
	 * 
	 * 	Used in conjunction with MediaPermissionsEvent as the code property
	 */
	public class MediaPermissionsResult {
        
        /**
         * value for when permission is granted to use media
         */
		static public const GRANTED:String = "granted";
        /**
         * value for when permission is denied to use media
         */
		static public const DENIED:String = "denied";
        /**
         * value for when there are no devices to use on the machine
         */
		static public const NO_DEVICE:String = "noDevice";
		/**
         * value for when a dialog is opened 
         */
        static public const DIALOG_OPEN:String = "dialogOpen";
        /**
         * value for when a dialog is closed
         */
        static public const DIALOG_CLOSED:String = "dialogClosed";
	}
}