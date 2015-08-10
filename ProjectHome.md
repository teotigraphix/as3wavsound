<font color='grey' size='1'>
<ul><li>release v0.9: (finally) fixed playback of sample rates below 44khz!<br>
</li><li>release v1.0: will also support 8khz sample rate<br>
</font></li></ul>

# Introducing AS3WavSound as AWS #

The Flex SDK does not natively support playing (embedded) .wav files. Thus far developers worked around this using ugly hacks (generating swf bytedata to trick the Flash Player).

Not anymore.

AWS in the slimmest sense simply a copy of Adobe's [Sound](http://help.adobe.com/en_US/FlashPlatform/reference/actionscript/3/flash/media/Sound.html) class. It mimics the Sound class but has support for playing back WAVE data. You don't need this sound class if you are working with the Flash IDE or Flex Builder, as they convert .wav data directly to Sound objects. The open source SDK compiler however, does not support this feature. But it does now!

AWS currently needs Flash Player 10 or higher.

# How it works #

AWS uses a Wav decoder that converts ByteData into mono / stereo, 44100 / 22050 / 11025 samplerate, 8 / 16 bitrate sample data, that is playable by the Sound class using the [SampleDataEvent technique](http://help.adobe.com/en_US/FlashPlatform/reference/actionscript/3/flash/events/SampleDataEvent.html). This way no obscure swf generation hack is necessary, which has become the defacto standard work-around. Sample rates below 44100hz are upsampled to 44100hz.

To add .wav files to your project you embed a .wav file as a ByteArray with mimetype 'application/octet-stream' and AWS will be able to decode this and playback this sound.

**[more info](Documentation.md)**

# Example #

```
public class Demo {
		
	[Embed(source = "assets/drum_loop.wav", mimeType = "application/octet-stream")]
	public const DrumLoop:Class;
		
	public function foo():void {
		var drumLoop:WavSound = new WavSound(new DrumLoop() as ByteArray);
		var playingChannel = drumLoop.play();
		// playingChannel.stop();
	}
}
```

It's that easy. No generating swf's required and no Flash IDE or Flex Builder required. The library totals up to about 40kb (a swc component is planned for the future).