package ktu.media
{
	import flash.external.ExternalInterface;

	public class ChromeCameraDetectionHelper
	{		
		
		public static function triggerBrowserWebcamPrompt(success:Function,failure:Function):void
		{
			var prefix:String= "_"+ uint( 0xffff * Math.random() ).toString(16);
			var successCallbackName:String = prefix+'browserWebcamAllow';
			var failureCallbackName:String = prefix+'browserWebcamDeny';
			ExternalInterface.addCallback( successCallbackName, success );
			ExternalInterface.addCallback( failureCallbackName, failure );
			ExternalInterface.call([
'			function(id){',
'				var flashObject = (document[id] || window[id] );',
'				var success = function(){ flashObject["'+successCallbackName+'"]() };',
'				var failure = function(){ flashObject["'+failureCallbackName+'"]() };',
'				navigator.webkitGetUserMedia({video: true, audio: true}, success, failure);',
'			}'
			].join('\n'),ExternalInterface.objectID);		
			
		}
		
		public static function get isPepperPlayer():Boolean
		{
			return ExternalInterface.call([
				'			function(){',
				'				var isPPAPI = false;',
				'				var type = "application/x-shockwave-flash";',
				'				var mimeTypes = navigator.mimeTypes;',
				'				return mimeTypes && mimeTypes[type] && mimeTypes[type].enabledPlugin && ( mimeTypes[type].enabledPlugin.filename.toLowerCase().search("pepperflashplayer") === 0 ); ',
				'			}'
			].join('\n'));
		}
	}
}