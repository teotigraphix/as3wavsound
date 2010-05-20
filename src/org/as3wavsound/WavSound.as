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

		// play-time information
		private var startPhase:Number; // made global to avoid recalculating all the time
		private var phase:Number = 0;
		private var loopsLeft:Number;
		private var finished:Boolean;
		private var buffersize:Number;
		
		public function WavSound(wavData:ByteArray, audioSettings:AudioSetting = null, buffersize:Number = MAX_BUFFERSIZE) {
			loadWav(wavData, audioSettings, buffersize);
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
				return super.play(0, loops, sndTransform);
			}
		}
		
		private function onSamplesCallback(e:SampleDataEvent):void {
			for (var i:int = 0; i < buffersize; i++) {
				if (!finished) {
					e.data.writeFloat(samples.left[phase]);
					if (playbackSettings.channels == 2) {
						var hasRightChannel:Boolean = samples.setting.channels == 2;
						e.data.writeFloat((hasRightChannel) ? samples.right[phase] : samples.left[phase]);
					}
					finished = ++phase >= samples.length;
		
					if (finished) {
						phase = startPhase;
						if (loopsLeft-- > 0) 
						finished = false;
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
			removeEventListener(SampleDataEvent.SAMPLE_DATA, onSamplesCallback);
			legacyMode = true;
			super.load(stream, context);
		}

		/// Initiates loading of an external WAV sound from the specified ByteArray.
		public function loadWav(wavData:ByteArray, audioSettings:AudioSetting = null, buffersize:Number = MAX_BUFFERSIZE): void {
			this.wavData = wavData;
			this.samples = new Wav().decode(wavData);
			this.playbackSettings = (audioSettings != null) ? audioSettings : new AudioSetting();
			this.buffersize = buffersize;
			this._length = samples.length / samples.setting.sampleRate * 1000;
			addEventListener(SampleDataEvent.SAMPLE_DATA, onSamplesCallback);
			legacyMode = false;
		}
	}
}