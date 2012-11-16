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
	 * Enumeration of possible results from using CameraDetection
	 * 
	 * 	Used in conjunction with CameraDetectionEvent as the code property
	 */
	public class CameraDetectionResult {
		
		/**
		 * code value for when no Cameras were found
		 */
		public static const NO_CAMERAS		:String = "noCameras";
		/**
		 * code value for when user denies permission to the Camera                                 <br/>
         * this is only dispatched during detection and when mediaPermission result is denied       <br/>
         * carefule however, because while CameraDetection dispatches this code, it will still 
         * dispatch the MediaPermissionResult.DENIED
		 */
		public static const NO_PERMISSION	:String = "noPermission";
        /**
         * code value for when at least one camera is found, but none work <br/>
         * 
         * this means there is at least one camera listed, but none of them worked
         * 
         * possible issues:
         *      camera already in use
         *      camera isn't really connected (ask them to connect better)
         *      camera is just slow as balls and didn't respond
         */
        public static const NO_SUCCESS      :String = "noSuccess";
		/**
		 * code value for when a Cameras was found that works
		 */
		public static const SUCCESS			:String = "success";
	}
}