package org.as3wavsound.sazameki.core {
	
	/**
	 * ...
	 * @author Takaaki Yamazaki(zk design), modified by b.bottema [Codemonkey]
	 */
	public class AudioSetting {
		
		private var _channels:uint;
		private var _sampleRate:uint;
		private var _sampleRateIndex:uint;
		private var _bitRate:uint;

		
		public function AudioSetting(channels:uint=2,sampleRate:uint=44100,bitRate:uint=16) {
			//TODO: throw error if not valid value passed.
			
			if(sampleRate==44100){
				_sampleRateIndex = 3;
			}else if(sampleRate == 22050){
				_sampleRateIndex = 2;
			}else if(sampleRate == 11025){
				_sampleRateIndex = 1;
			}else{
				throw(new Error("bad sample rate. sample rate must be 44100,22050,11025"));
			}
			
			if(!(channels == 1 || channels == 2)){
				throw(new Error("channels must be 1 or 2"));
			}
			
			if(!(bitRate == 16 || bitRate == 8)){
				throw(new Error("bitRate must be 8 or 16"));
			}
			_channels=channels;
			_sampleRate=sampleRate;
			_bitRate=bitRate;
		}
		
		public function get channels():uint{
			return _channels;
		}
		
		public function get sampleRate():uint{
			return _sampleRate;
		}
		
		public function get bitRate():uint{
			return _bitRate;
		}
	}	
}