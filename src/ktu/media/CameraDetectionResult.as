/**
 * * File:	CameraDetectionResult.as;
 * Author:	Ktu; 							[blog.cataclysmicrewind.com]
 * Updated:	12.17.10;
 * Thanks: Pavel fljot
 * 
 * This class is free to use and modify, however I request that the header (except example code),
 * and original package remain intact.
 * If you choose to modify it, please contact me before releasing the product.
 * 		[ktu_flash@cataclysmicrewind.com]
 * 
 */
package ktu.media {
	
	/**
	 * 
	 * Enumeration of possible results from using CameraDetection
	 * 
	 * 	Used in conjunction with CameraDetectionEvent as the code property
	 * 
	 * 
	 */
	public class CameraDetectionResult {
		
		/**
		 * code value for when no Cameras were found
		 */
		public static const NO_CAMERAS		:String = "noCameras";
		/**
		 * code value for when user denies permission to the Camera
		 */
		public static const NO_PERMISSION	:String = "noPermission";
        /**
         * code value for when at least one camera is found, but none work
         */
        public static const NO_SUCCESS      :String = "noSuccess";
		/**
		 * code value for when a Cameras was found that works
		 */
		public static const SUCCESS			:String = "success";
	}
}