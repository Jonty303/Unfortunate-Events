extends Node
## Small deterministic original effects. No streaming assets or external sound dependencies.
const RATE := 22050
var muted := false
var voices: Array[AudioStreamPlayer] = []
var sounds: Dictionary = {}
var voice_index := 0
var unlocked := false

func _ready() -> void:
	var specs := {"cannon": [0.09, 920.0, 170.0, 0.17], "enemy": [0.14, 460.0, 100.0, 0.32],
		"rocket": [0.30, 115.0, 280.0, 0.58], "impact": [0.09, 540.0, 70.0, 0.7],
		"vehicle": [0.56, 85.0, 28.0, 0.78], "building": [0.85, 65.0, 20.0, 0.82]}
	var noise := RandomNumberGenerator.new()
	noise.seed = 10301
	for key in specs:
		var spec: Array = specs[key]
		var count := int(float(spec[0]) * RATE)
		var bytes := PackedByteArray()
		bytes.resize(count * 2)
		var phase := 0.0
		var filtered_noise := 0.0
		for i in count:
			var t := float(i) / count
			phase += lerpf(spec[1], spec[2], t) * TAU / RATE
			filtered_noise = lerpf(filtered_noise, noise.randf_range(-1, 1), 0.25)
			var wave := lerpf(sin(phase) * 0.55 + sin(phase * 1.9) * 0.15, filtered_noise, spec[3])
			var envelope := minf(t * 45, 1) * pow(1.0 - t, 1.9)
			bytes.encode_s16(i * 2, int(clampf(wave * envelope, -1, 1) * 19000))
		var sample := AudioStreamWAV.new()
		sample.format = AudioStreamWAV.FORMAT_16_BITS
		sample.mix_rate = RATE
		sample.data = bytes
		sounds[key] = sample
	for i in 8:
		var voice := AudioStreamPlayer.new()
		voice.volume_db = -13
		add_child(voice)
		voices.append(voice)

func play_effect(kind: String) -> void:
	if muted or not unlocked or not sounds.has(kind) or voices.is_empty(): return
	var voice := voices[voice_index]
	voice_index = (voice_index + 1) % voices.size()
	voice.stream = sounds[kind]
	voice.play()

func stop_all() -> void:
	for voice in voices: voice.stop()

func set_muted(value: bool) -> void:
	muted = value
	if value: stop_all()

func _exit_tree() -> void:
	stop_all()
	for voice in voices: voice.stream = null
	sounds.clear()
