package org.as3wavsound.demo
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.media.Sound;
	import flash.utils.ByteArray;
	import org.as3wavsound.WavSound;
	import org.as3wavsound.WavSoundChannel;
	
	/**
	 * ...
	 * @author Benny Bottema
	 */
	public class Main extends Sprite  {
		
		[Embed(source = "../../../assets/rain_loop.wav", mimeType = "application/octet-stream")]
		public const RainLoop:Class;
		public const rain:WavSound = new WavSound(new RainLoop() as ByteArray);
		
		public function Main():void {
			rain.play(0, int.MAX_VALUE);
		}
	}
}