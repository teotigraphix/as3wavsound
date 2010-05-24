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
	 * Make sure you provide mimetype 'application/octet-stream' when embedding to 
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
		
		// used to switch the runtime behavior of this Sound object, for backwards compatibility
		private var legacyMode:Boolean;
		
		// the master Sound player, which mixes all playing WavSound samples on any given moment
		private static const player:WavSoundPlayer = new WavSoundPlayer();
		
		/*
		 * creation-time information 
		 */
		
		// original encoded wav data
		private var wavData:ByteArray;
		// extracted sound data for mixing
		private var samples:AudioSamples;
		// each sound can be configured to be played mono/stereo using AudioSetting
		private var playbackSettings:AudioSetting;
		// calculated length of the entire sound in milliseconds, made global to avoid recalculating all the time
		private var _length:Number;
		
		/*
		 * play-time information *per WavSound*
		 */
		
		// starting phase if not at the beginning, made global to avoid recalculating all the time
		private var startPhase:Number; 
		// current phase of the sound, basically matches a single current sample frame for each WavSound
		private var phase:Number = 0;
		// how many loops we need to buffer
		private var loopsLeft:Number;
		// indicates if the phase has reached total sample count and no loops are left
		private var finished:Boolean;
		
		/**
		 * Constructor: loads wavdata using loadWav().
		 * 
		 * @param	wavData A ByteArray containing uncmopressed wav data.
		 * @param	audioSettings An optional playback configuration (mono/stereo, 
		 * 			sample rate and bit rate).
		 */
		public function WavSound(wavData:ByteArray, audioSettings:AudioSetting = null) {
			loadWav(wavData, audioSettings);
		}

		/**
		 * Loads WAVE data.
		 * 
		 * Resets this WavSound and turns off legacy mode to act as a WavSound object.
		 * 
		 * @param	wavData
		 * @param	audioSettings
		 */
		public function loadWav(wavData:ByteArray, audioSettings:AudioSetting = null): void {
			legacyMode = false;
			this.wavData = wavData;
			this.samples = new Wav().decode(wavData);
			this.playbackSettings = (audioSettings != null) ? audioSettings : new AudioSetting();
			this._length = samples.length / samples.setting.sampleRate * 1000;
		}

		/**
		 * Loads MP3 data.
		 * 
		 * Resets this WavSound and turns on legacy mode to act as if it were a basic Sound object.
		 * Also stops all playing channels for this WavSound.
		 */
		public override function load(stream:URLRequest, context:SoundLoaderContext = null) : void {
			legacyMode = true;
			player.stop(this);
			super.load(stream, context);
		}

		/**
		 * Playback function that performs the following tasks:
		 * 
		 * - calculates the startingPhase, bases on startTime in ms.
		 * - initializes loopsLeft variable
		 * - registers a dummy function for SampleDataEvent.SAMPLE_DATA to avoid 'invalid Sound' error
		 * - adds the playing channel in combination with its originating WavSound to the playingWavSounds
		 * 
		 * @param	startTime The starting time in milliseconds, applies to each loop (as with regular MP3 Sounds).
		 * @param	loops The number of loops to take in *addition* to the default playback (loops == 2 -> 3 playthroughs).
		 * @param	sndTransform An optional soundtransform to apply for playback that controls volume and panning.
		 * @return The SoundChannel used for playing back the sound.
		 */
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
				
				addEventListener(SampleDataEvent.SAMPLE_DATA, function():void{});
				var channel:SoundChannel = super.play(0, loops, sndTransform);
				player.playingWavSounds.push(new WavSoundChannel(this, channel));
				return channel;
			}
		}
		
		/**
		 * Fills a target samplebuffer with optionally transformed samples from the current WavSound.
		 * 
		 * Keeps filling the buffer for each loop the sound should be mixed in the target buffer.
		 * When the buffer is full, phase and loopsLeft keep track of how which and many samples 
		 * still need to be buffered in the next buffering cycle (when this method is called again).
		 * 
		 * @param	sampleBuffer The target buffer to mix in the current (transformed) samples.
		 * @param	soundTransform The soundtransform that belongs to a single channel being played 
		 * 			(containing volume, panning etc.).
		 */
		public function buffer(sampleBuffer:AudioSamples, soundTransform:SoundTransform):void {
			for (var i:int = 0; i < sampleBuffer.length; i++) {
				if (!finished) {
					// calculate volume and panning
					var volume: Number = (soundTransform.volume / 1);
					var volumeLeft: Number = volume * (1 - soundTransform.pan) / 2;
					var volumeRight: Number = volume * (1 + soundTransform.pan) / 2;
					
					// write (transformed) samples to buffer
					sampleBuffer.left[i] += samples.left[phase] * volumeLeft;
					var needRightChannel:Boolean = playbackSettings.channels == 2;
					var hasRightChannel:Boolean = samples.setting.channels == 2;
					sampleBuffer.right[i] += ((needRightChannel && hasRightChannel) ? samples.right[phase] : samples.left[phase]) * volumeRight;
					
					// check playing and looping state
					finished = ++phase >= samples.length;
					if (finished) {
						phase = startPhase;
						finished = loopsLeft-- == 0;
					}
				}
			}
		}
		
		/**
		 * Returns the total bytes of the wavData the current WavSound was created with.
		 */
		public override function get bytesLoaded () : uint {
			return (legacyMode) ? super.bytesLoaded : wavData.length;
		}

		/**
		 * Returns the total bytes of the wavData the current WavSound was created with.
		 */
		public override function get bytesTotal () : int {
			return (legacyMode) ? super.bytesTotal : wavData.length;
		}

		/**
		 * Returns the total length of the sound in milliseconds.
		 */
		public override function get length() : Number {
			return (legacyMode) ? super.length : _length;
		}
		
		/**
		 * No idea if this works. Alpha state. Read up on Sound.extract():
		 * http://help.adobe.com/en_US/FlashPlatform/reference/actionscript/3/flash/media/Sound.html#extract()
		 */
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
	}
}