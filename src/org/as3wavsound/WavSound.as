package org.as3wavsound {
	import flash.events.SampleDataEvent;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundLoaderContext;
	import flash.media.SoundTransform;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	import org.as3wavsound.sazameki.core.AudioSamples;
	import org.as3wavsound.sazameki.core.AudioSetting;
	import org.as3wavsound.sazameki.format.wav.Wav;
	import org.as3wavsound.WavSoundChannel;
	
	/* 
	 * --------------------------------------
	 * b.bottema [Codemonkey] -- WavSound Sound adaption
	 * http://blog.projectnibble.org/
	 * --------------------------------------
	 * sazameki -- audio manipulating library
	 * http://sazameki.org/
	 * --------------------------------------
	 * 
	 * - developed by:
	 * 						Benny Bottema (Codemonkey)
	 * 						blog.projectnibble.org
	 *   hosted by: 
	 *  					Google Code (code.google.com)
	 * 						code.google.com/p/as3wavsound/
	 * 
	 * - audio library in its original state developed by:
	 * 						Takaaki Yamazaki
	 * 						www.zkdesign.jp
	 *   hosted by: 
	 *  					Spark project (www.libspark.org)
	 * 						www.libspark.org/svn/as3/sazameki/branches/fp10/
	 */
	
	/*
	 * Licensed under the MIT License
	 * 
	 * Copyright (c) 2008 Takaaki Yamazaki
	 * 
	 * Permission is hereby granted, free of charge, to any person obtaining a copy
	 * of this software and associated documentation files (the "Software"), to deal
	 * in the Software without restriction, including without limitation the rights
	 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	 * copies of the Software, and to permit persons to whom the Software is
	 * furnished to do so, subject to the following conditions:
	 * 
	 * The above copyright notice and this permission notice shall be included in
	 * all copies or substantial portions of the Software.
	 * 
	 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
	 * THE SOFTWARE.
	 */
	
	/**
	 * Sound extension that directly plays WAVE data. Also backwards compatible with 
	 * MP3's played through the load() method.
	 * 
	 * Simply embed .wav files as you would mp3's and play with this Sound class.
	 * Make sure you provide mimtype 'application/octet-stream' when embedding to 
	 * ensure Flash embeds the data as ByteArray.
	 * 
	 * Example:
	 * [Embed(source = "drumloop.wav", mimeType = "application/octet-stream")]
	 * public const DrumLoop:Class;
	 * public const rain:Sound = new WavSound(new DrumLoop() as ByteArray);
	 * 
	 * 
	 * @author b.bottema [Codemonkey]
	 */
	public class WavSound extends Sound {
		private static const MAX_BUFFERSIZE:Number = 8192;
		
		// used to switch the runtime behavior of this Sound object, for backwards compatibility
		private var legacyMode:Boolean;
		
		// creation-time information
		private var wavData:ByteArray;
		private var samples:AudioSamples;
		private var playbackSettings:AudioSetting;
		private var _length:Number;

		// play-time information *per WavSound*
		private var startPhase:Number; // made global to avoid recalculating all the time
		private var phase:Number = 0;
		private var loopsLeft:Number;
		private var finished:Boolean;
		
		// play-time information *overall playback* 
		private static const sampleBuffer:AudioSamples = new AudioSamples(new AudioSetting(), MAX_BUFFERSIZE);
		private static const playingWavSounds:Vector.<WavSoundChannel> = new Vector.<WavSoundChannel>();
		private static const player:Sound = configurePlayer();
		
		private static function configurePlayer():Sound {
			var player:Sound = new Sound();
			player.addEventListener(SampleDataEvent.SAMPLE_DATA, onSamplesCallback);
			player.play();
			return player;
		}
		
		public function WavSound(wavData:ByteArray, audioSettings:AudioSetting = null) {
			loadWav(wavData, audioSettings);
		}

		public override function play(startTime:Number = 0, loops:int = 0, sndTransform:SoundTransform = null) : SoundChannel {
			if (legacyMode) {
				return super.play(startTime, loops, sndTransform);
			} else {
				var startPositionInMillis:Number = Math.floor(startTime);
				var maxPositionInMillis:Number = Math.floor(length);
				if (startPositionInMillis > maxPositionInMillis) {
					throw new Error("startTime greater than sound's length, max startTime is " + maxPositionInMillis);
				}
				phase = startPhase = Math.floor(startPositionInMillis * samples.length / _length);
				finished = false;
				loopsLeft = loops;
				
				// reset SampleDataEvent handlers on all playing WavSounds and add handler to the current one
				for each (var playingWavSound:WavSoundChannel in playingWavSounds) {
					//playingWavSound.wavSound.removeEventListener(SampleDataEvent.SAMPLE_DATA, onSamplesCallback);
				}
				addEventListener(SampleDataEvent.SAMPLE_DATA, function():void{});
				var channel:SoundChannel = super.play(0, loops, sndTransform);
				playingWavSounds.push(new WavSoundChannel(this, channel));
				return channel;
			}
		}
		
		private static function onSamplesCallback(e:SampleDataEvent):void {
			sampleBuffer.clearSamples();
			
			for each (var playingWavSound:WavSoundChannel in playingWavSounds) {
				playingWavSound.buffer(sampleBuffer);
			}
			
			for (var i:int = 0; i < sampleBuffer.length; i++) {
				e.data.writeFloat(sampleBuffer.left[i]);
				e.data.writeFloat(sampleBuffer.right[i]);
			}
		}
		
		public function buffer(sampleBuffer:AudioSamples, soundTransform:SoundTransform):void {
			for (var i:int = 0; i < sampleBuffer.length; i++) {
				if (!finished) {
					// calculate volume and panning
					var volume: Number = (soundTransform.volume / 1);
					var volumeLeft: Number = volume * (1 - soundTransform.pan) / 2;
					var volumeRight: Number = volume * (1 + soundTransform.pan) / 2;
					
					// write buffer to outputstream
					sampleBuffer.left[i] += samples.left[phase] * volumeLeft;
					if (playbackSettings.channels == 2) {
						var hasRightChannel:Boolean = samples.setting.channels == 2;
						sampleBuffer.right[i] += ((hasRightChannel) ? samples.right[phase] : samples.left[phase]) * volumeRight;
					}
					
					// check playing and looping state
					finished = ++phase >= samples.length;
					if (finished) {
						phase = startPhase;
						finished = loopsLeft-- == 0;
					}
				}
			}
		}
		
		/// Returns the currently available number of bytes in this sound object.
		public override function get bytesLoaded () : uint {
			return (legacyMode) ? super.bytesLoaded : wavData.length;
		}

		/// Returns the total number of bytes in this sound object.
		public override function get bytesTotal () : int {
			return (legacyMode) ? super.bytesTotal : wavData.length;
		}

		/// The length of the current sound in milliseconds.
		public override function get length() : Number {
			return (legacyMode) ? super.length : _length;
		}

		/// Extracts raw sound data from a Sound object.
		public override function extract(target:ByteArray, length:Number, startPosition:Number = -1): Number {
			if (legacyMode) {
				return super.extract(target, length, startPosition);
			} else {
				var start:Number = Math.max(startPosition, 0);
				var end:Number = Math.min(length, samples.length);
				
				for (var i:Number = start; i < end; i++) {
					target.writeFloat(samples.left[phase]);
					if (samples.setting.channels == 2) {
						target.writeFloat(samples.right[phase]);
					} else {
						target.writeFloat(samples.left[phase]);
					}
				}
				
				return samples.length;
			}
		}

		/// Initiates loading of an external MP3 file from the specified URL.
		public override function load(stream:URLRequest, context:SoundLoaderContext = null) : void {
			legacyMode = true;
			// remove all playing channels that are associated with this WavSound
			for each (var playingWavSound:WavSoundChannel in playingWavSounds) {
				if (playingWavSound.wavSound == this) {
					playingWavSounds.splice(playingWavSounds.lastIndexOf(playingWavSound), 1);
				}
			}
			// stop playing this sound for all channels
			//removeEventListener(SampleDataEvent.SAMPLE_DATA, onSamplesCallback);
			super.load(stream, context);
		}

		/// Initiates loading of an external WAV sound from the specified ByteArray.
		public function loadWav(wavData:ByteArray, audioSettings:AudioSetting = null): void {
			legacyMode = false;
			this.wavData = wavData;
			this.samples = new Wav().decode(wavData);
			this.playbackSettings = (audioSettings != null) ? audioSettings : new AudioSetting();
			this._length = samples.length / samples.setting.sampleRate * 1000;
		}
	}
}