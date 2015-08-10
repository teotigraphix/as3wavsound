## Quick note on the SoundChannel problem ##

To maintain complete transparent backwards compatibility with the Sound API, AS3WavSound would need to support _soundChannel.stop()_, which currently is impossible. The reason for this is because SoundChannel has been declared _final_ by Adobe's developers. And so it cannot be subclassed to redefine behavior for stop() to stop playing a WavSoundChannel. No work-around is currently known.

A solution could be to get support for a SOUND\_STOP event alongside the SOUND\_COMPLETE event. But alas.

## current state ##

Backwards compatibility has been dropped in favor of a working solution. Instead all Adobe's sound classes have a analog wav counterpart now.

  * Sound -> WavSound
  * SoundChannel -> WavSoundChannel

Now wavSoundChannel.stop() works for .wav files.

[back](Documentation.md)