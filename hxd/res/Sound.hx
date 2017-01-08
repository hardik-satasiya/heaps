package hxd.res;

enum SoundFormat {
	Wav;
	Mp3;
	OggVorbis;
}

class Sound extends Resource {

	var data : hxd.snd.Data;
	var channel : hxd.snd.Channel;
	public var lastPlay(default, null) = 0.;

	public static function supportedFormat( fmt : SoundFormat ) {
		return switch( fmt ) {
		case Wav:
			return true;
		case Mp3:
			#if (flash || js)
			return true;
			#else
			return false;
			#end
		case OggVorbis:
			#if stb_ogg_sound
			return true;
			#else
			return false;
			#end
		}
	}

	public function getData() : hxd.snd.Data {
		if( data != null )
			return data;
		var bytes = entry.getBytes();

		#if flash
		if( bytes.length == 0 )
			return new hxd.snd.LoadingData(this);
		#end

		switch( bytes.get(0) ) {
		case 'R'.code: // RIFF (wav)
			data = new hxd.snd.WavData(bytes);
		case 255, 'I'.code: // MP3 (or ID3)
			data = new hxd.snd.Mp3Data(bytes);
		case 'O'.code: // Ogg (vorbis)
			#if stb_ogg_sound
			data = new hxd.snd.OggData(bytes);
			#else
			throw "OGG format requires -lib stb_ogg_sound (for " + entry.path+")";
			#end
		default:
		}
		if( data == null )
			throw "Unsupported sound format " + entry.path;
		return data;
	}

	public function dispose() {
		stop();
		data = null;
	}

	public function stop() {
		if( channel != null ) {
			channel.stop();
			channel = null;
		}
	}

	public function play( ?loop = false, ?channelGroup, ?soundGroup ) {
		lastPlay = haxe.Timer.stamp();
		channel = hxd.snd.Driver.get().play(this, channelGroup, soundGroup);
		channel.loop = loop;
		return channel;
	}

}