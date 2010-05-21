package org.as3wavsound {
	import flash.media.SoundChannel;
	import org.as3wavsound.sazameki.core.AudioSamples;
	import org.as3wavsound.WavSound;

	/**
	 * This class is used to keep track of open channels during playback.
	 * 	 
	 * since we need the channel to retrieve the SoundTransform from (for volume 
	 * and panning) and the Sound object provides no way to get this, we keep 
	 * track of it manually.      
	 *     	 
	 * @author b.bottema [Codemonkey]
	 */
	internal class WavSoundChannel {
		private var _wavSound:WavSound;
		private var _channel:SoundChannel;
		
		public function WavSoundChannel(wavSound:WavSound, channel:SoundChannel) {
			this._wavSound = wavSound;
			this._channel = channel;
		}
		
		/**
		 * Makes the current SoundWav buffer its samples while passing on the
		 * SoundTransform for the channel currently playing.		 
		 */		
		public function buffer(sampleBuffer:AudioSamples):void {
			wavSound.buffer(sampleBuffer, channel.soundTransform);
		}
		
		public function get wavSound():WavSound {
			return _wavSound
		}
		
		public function get channel():SoundChannel {
			return _channel
		}
	}
}