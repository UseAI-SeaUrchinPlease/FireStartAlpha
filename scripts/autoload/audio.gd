extends Node

const MIX_RATE := 22050
const POOL_SIZE := 8
const AMPLITUDE := 0.3

var _streams: Dictionary[StringName, AudioStreamWAV] = {}
var _players: Array[AudioStreamPlayer] = []
var _next_player := 0


func _ready() -> void:
	_streams[&"dig"] = _to_stream(_noise(0.05, 30.0))
	_streams[&"break"] = _to_stream(_mix(_noise(0.12, 18.0), _sweep(140.0, 60.0, 0.14, 12.0, false)))
	_streams[&"pickup"] = _to_stream(_notes([660.0, 990.0], 0.06, true))
	_streams[&"attack"] = _to_stream(_noise(0.09, 22.0))
	_streams[&"hurt"] = _to_stream(_sweep(220.0, 110.0, 0.2, 8.0, true))
	_streams[&"enemy_hit"] = _to_stream(_sweep(320.0, 260.0, 0.06, 20.0, true))
	_streams[&"enemy_die"] = _to_stream(_sweep(420.0, 90.0, 0.3, 6.0, true))
	_streams[&"fire_success"] = _to_stream(_notes([523.0, 659.0, 784.0, 1047.0], 0.1, true))
	_streams[&"fire_fail"] = _to_stream(_notes([392.0, 330.0, 262.0], 0.16, false))
	_streams[&"menu_move"] = _to_stream(_sweep(800.0, 800.0, 0.03, 30.0, true))
	_streams[&"menu_select"] = _to_stream(_sweep(600.0, 900.0, 0.08, 15.0, true))
	_streams[&"sunset"] = _to_stream(_notes([523.0, 392.0], 0.22, false))
	for i in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)


func play(sound: StringName) -> void:
	var player := _players[_next_player]
	_next_player = (_next_player + 1) % POOL_SIZE
	player.stream = _streams[sound]
	player.play()


func _sweep(from_hz: float, to_hz: float, duration: float, decay: float, square: bool) -> PackedFloat32Array:
	var count := int(MIX_RATE * duration)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var phase := 0.0
	for i in count:
		var t := float(i) / count
		phase += TAU * lerpf(from_hz, to_hz, t) / MIX_RATE
		var wave := signf(sin(phase)) if square else sin(phase)
		samples[i] = wave * exp(-decay * t)
	return samples


func _noise(duration: float, decay: float) -> PackedFloat32Array:
	var count := int(MIX_RATE * duration)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var smoothed := 0.0
	for i in count:
		var t := float(i) / count
		smoothed = lerpf(smoothed, rng.randf_range(-1.0, 1.0), 0.35)
		samples[i] = smoothed * exp(-decay * t)
	return samples


func _notes(frequencies: Array[float], note_duration: float, square: bool) -> PackedFloat32Array:
	var samples := PackedFloat32Array()
	for hz in frequencies:
		samples.append_array(_sweep(hz, hz, note_duration, 6.0, square))
	return samples


func _mix(a: PackedFloat32Array, b: PackedFloat32Array) -> PackedFloat32Array:
	var samples := PackedFloat32Array()
	samples.resize(maxi(a.size(), b.size()))
	for i in samples.size():
		var value := 0.0
		if i < a.size():
			value += a[i]
		if i < b.size():
			value += b[i]
		samples[i] = value
	return samples


func _to_stream(samples: PackedFloat32Array) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		bytes.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * AMPLITUDE * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = bytes
	return stream
