## About this documentation ##

Documentation for AS3WavSound may seem minimal, but there's a good reason for this.

  * _A WavSound object doesn't do anything particular a Sound object doesn't do as well_

The WavSound class, AS3WavSound's pivot point, was designed to use the same API as the existing Sound classes and acts exactly the same. In fact, it adds no additional features _except the ability to playback WAVE sound data_. Therefor it makes sense that no more documentation is needed than Adobe already provides on the entire Sound framework!

Due to limitations of Adobe's Sound framework (specifically the [SoundChannel](http://help.adobe.com/en_US/FlashPlatform/reference/actionscript/3/flash/media/SoundChannel.html) class is made _final_), backwards compatibility has been dropped, but the WavSound as well as the WavSoundChannel are designed to work exactly like Sound and good old SoundChannel. The intent is to keep the API the same while simply adding Wave sound support. You just can't play mp3 files with this library anymore, because we're not extending the existing sound library anymore.

## Transparent API ##

There is no additional API to the standard Flash Sound API. AS3WavSound simply completely mimicks the existing system.

The reason for aforementioned grade of backwards API compatibility is because AS3WavSound aims to be as simple to use as possible and simply fill the gap of WAVE playback support. Nothing more. Certainly not another library API for users to learn.

<strong>Example</strong>

```
public class Demo {
		
	[Embed(source = "assets/drum_loop.wav", mimeType = "application/octet-stream")]
	public const DrumLoop:Class;
		
	public function foo():void {
		var drumLoop:WavSound = new WavSound(new DrumLoop() as ByteArray);
		var channel:WavSoundChannel = drumLoop.play();
		channel.stop();
	}
}
```

## Current state / Roadmap ##

AS3WavSound is mostly finished except for the following features and remaining bugs:

  1. complete [SoundTransform](http://help.adobe.com/en_US/FlashPlatform/reference/actionscript/3/flash/media/SoundTransform.html) support, such as leftToleft en rightToLeft properties (currently only panning and volume are supported)
  1. streaming support (ie. Sound.load() or Sound.loadWav())
  1. better upsampling algorithm. The current one is a rudimentary one that provides low quality upsampling (quality degrades for lower source rates).

[Quick note on the SoundChannel problem](SoundChannelBug.md)

## About performance ##

A performance hit is to be expected the moment one generates sound on the fly using the [Adobe sanctioned SAMPLE\_DATA event approach](http://www.adobe.com/devnet/flash/articles/dynamic_sound_generation/index.html).

However, AS3WavSound has completely minimized this hit by pooling all playing WavSounds into a single Sound. In effect, in this fashion always exactly one Sound is really playing samples generated and mixed from all WavSounds active, combined. It is still not as fast as native playback however, in which Flash directly delegates to the sound card.


## Some factoids ##

&lt;wiki:gadget url="http://www.ohloh.net/p/483136/widgets/project\_factoids.xml" border="0" width="400"/&gt;
&lt;wiki:gadget url="http://www.ohloh.net/p/483136/widgets/project\_languages.xml" border="0" width="400" height="200"/&gt;