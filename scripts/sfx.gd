extends RefCounted
## Original sound effects, synthesized in code at startup (no audio files, so
## nothing to license). Static helpers: Sfx.play(self, "jump"), Sfx.play(self, "land", 0.8).

const RATE := 22050
static var _cache := {}


static func play(parent: Node, sound: String, volume := 1.0, pitch := 1.0) -> void:
	var p := AudioStreamPlayer.new()
	p.stream = _get(sound)
	p.volume_db = linear_to_db(clampf(volume, 0.01, 1.0)) - 4.0
	p.pitch_scale = pitch
	parent.add_child(p)
	p.finished.connect(p.queue_free)
	p.play()


static func _get(sound: String) -> AudioStreamWAV:
	if not _cache.has(sound):
		_cache[sound] = _make(sound)
	return _cache[sound]


static func _make(sound: String) -> AudioStreamWAV:
	match sound:
		"jump":  # springy upward "boing"
			return _synth(0.28, func(t: float, n: float) -> float:
				var f := 300.0 + 700.0 * n + sin(t * 40.0) * 25.0
				return sin(TAU * f * t) * pow(1.0 - n, 1.5))
		"land":  # soft low thud
			return _synth(0.22, func(t: float, n: float) -> float:
				var f := 140.0 - 90.0 * n
				return (sin(TAU * f * t) + 0.25 * sin(TAU * f * 2.0 * t)) * pow(1.0 - n, 2.5))
		"out":  # sad slide down
			return _synth(0.6, func(t: float, n: float) -> float:
				var f := 520.0 - 380.0 * n
				return sin(TAU * f * t + sin(t * 30.0) * 1.5) * (1.0 - n))
		"win":  # happy rising arpeggio
			return _synth(0.7, func(t: float, n: float) -> float:
				var notes := [523.25, 659.25, 783.99, 1046.5]
				var i := mini(int(t / 0.14), 3)
				var local := t - i * 0.14
				return sin(TAU * notes[i] * t) * exp(-local * 6.0) * (1.0 - n * 0.4))
	return _synth(0.1, func(_t: float, _n: float) -> float: return 0.0)


## Renders fn(time_seconds, normalized_progress) -> sample in [-1, 1] to a 16-bit mono stream.
static func _synth(seconds: float, fn: Callable) -> AudioStreamWAV:
	var count := int(RATE * seconds)
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in count:
		var t := float(i) / RATE
		var s := clampf(fn.call(t, float(i) / count) * 0.6, -1.0, 1.0)
		data.encode_s16(i * 2, int(s * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = data
	return w
