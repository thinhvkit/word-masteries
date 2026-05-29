extends Node
## Procedural sound engine. Synthesizes every SFX and the battle music bed at
## runtime as 16-bit PCM AudioStreamWAV resources — the project ships no audio
## asset files. Autoloaded as `Audio`; call `Audio.play("hit")` from anywhere.

const SR := 22050                     # sample rate (Hz)
const VOICES := 10                    # polyphony for overlapping SFX

enum { WAVE_SINE, WAVE_SQUARE, WAVE_TRI, WAVE_SAW, WAVE_NOISE }

var sfx_enabled := true
var music_enabled := true

var _bank: Dictionary = {}            # name -> AudioStreamWAV
var _pool: Array[AudioStreamPlayer] = []
var _next := 0
var _music: AudioStreamPlayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_pool.append(p)
	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	add_child(_music)
	_build_bank()
	_music.stream = _build_music()

# ---------------- public API ----------------

## Plays a one-shot SFX by name. `pitch_var` randomizes pitch ±value; `pitch`
## is the base pitch multiplier; `vol_db` offsets loudness.
func play(sound: String, pitch_var: float = 0.0, pitch: float = 1.0, vol_db: float = 0.0) -> void:
	if not sfx_enabled:
		return
	var s: AudioStreamWAV = _bank.get(sound)
	if s == null:
		return
	var p := _pool[_next]
	_next = (_next + 1) % _pool.size()
	p.stream = s
	p.pitch_scale = clampf(pitch + randf_range(-pitch_var, pitch_var), 0.25, 4.0)
	p.volume_db = vol_db
	p.play()

func start_music() -> void:
	if music_enabled and _music != null and not _music.playing:
		_music.play()

func stop_music() -> void:
	if _music != null:
		_music.stop()

func set_music_enabled(on: bool) -> void:
	music_enabled = on
	if on:
		start_music()
	else:
		stop_music()

func set_sfx_enabled(on: bool) -> void:
	sfx_enabled = on

# ---------------- WAV packing ----------------

func _wav(buf: PackedFloat32Array, loop: bool = false) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(buf.size() * 2)
	for i in buf.size():
		var v := clampf(buf[i], -1.0, 1.0)
		bytes.encode_s16(i * 2, int(v * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = SR
	w.stereo = false
	w.data = bytes
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = buf.size()
	return w

# ---------------- synthesis core ----------------

func _osc(phase: float, wave: int) -> float:
	match wave:
		WAVE_SQUARE: return 1.0 if sin(phase) >= 0.0 else -1.0
		WAVE_TRI:    return asin(sin(phase)) * 0.63662
		WAVE_SAW:    return fposmod(phase, TAU) / PI - 1.0
		WAVE_NOISE:  return randf() * 2.0 - 1.0
		_:           return sin(phase)

## A single synth voice. Glides f0->f1, attack ramp then exponential decay.
func _voice(f0: float, f1: float, dur: float, wave: int, atk: float,
		decay: float, vol: float, vib_hz: float = 0.0, vib: float = 0.0) -> PackedFloat32Array:
	var n := int(dur * SR)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / SR
		var tn := float(i) / maxf(float(n), 1.0)
		var f: float = lerpf(f0, f1, tn)
		if vib > 0.0:
			f *= 1.0 + sin(TAU * vib_hz * t) * vib
		phase += TAU * f / SR
		var a: float = minf(t / maxf(atk, 0.0001), 1.0)
		var d: float = exp(-t / maxf(decay, 0.0001))
		buf[i] = _osc(phase, wave) * a * d * vol
	return buf

## One-pole low-pass — softens noise into a thud. `c` in 0..1 (lower = duller).
func _lowpass(buf: PackedFloat32Array, c: float) -> PackedFloat32Array:
	var y := 0.0
	for i in buf.size():
		y += (buf[i] - y) * c
		buf[i] = y
	return buf

## Mixes `src` into `dst` starting at sample `at`, growing `dst` as needed.
func _mix(dst: PackedFloat32Array, src: PackedFloat32Array, at: int = 0) -> PackedFloat32Array:
	var need := at + src.size()
	if dst.size() < need:
		dst.resize(need)
	for i in src.size():
		dst[at + i] += src[i]
	return dst

# ---------------- SFX bank ----------------

func _build_bank() -> void:
	# UI click — crisp triangle blip.
	_bank["click"] = _wav(_voice(900.0, 600.0, 0.08, WAVE_TRI, 0.002, 0.03, 0.34))

	# Tile select — bright rising ping with a sparkle harmonic.
	var sel := _voice(720.0, 1180.0, 0.13, WAVE_SINE, 0.003, 0.07, 0.36)
	_mix(sel, _voice(1440.0, 2360.0, 0.10, WAVE_SINE, 0.003, 0.045, 0.12))
	_bank["select"] = _wav(sel)

	# Tile deselect — soft falling blip.
	_bank["deselect"] = _wav(_voice(640.0, 360.0, 0.11, WAVE_SINE, 0.003, 0.06, 0.32))

	# Invalid word — buzzy low square.
	_bank["invalid"] = _wav(_voice(190.0, 130.0, 0.30, WAVE_SQUARE, 0.004, 0.16, 0.26))

	# Word Match micro feedback.
	_bank["wm_pop"] = _wav(_voice(500.0, 560.0, 0.05, WAVE_SINE, 0.002, 0.025, 0.24))
	_bank["wm_thud"] = _wav(_voice(300.0, 200.0, 0.04, WAVE_SINE, 0.001, 0.025, 0.16))
	_bank["wm_ready"] = _wav(_voice(523.25, 523.25, 0.08, WAVE_SINE, 0.004, 0.05, 0.26))

	# Word Match success tiers.
	var wm_low := PackedFloat32Array()
	var wm_low_notes := [523.25, 659.25, 783.99]
	for k in wm_low_notes.size():
		_mix(wm_low, _voice(wm_low_notes[k], wm_low_notes[k], 0.12, WAVE_SINE, 0.003, 0.06, 0.24), int(k * 0.055 * SR))
	_bank["wm_success_low"] = _wav(wm_low)

	var wm_mid := PackedFloat32Array()
	var wm_mid_notes := [523.25, 659.25, 783.99, 1046.50]
	for k in wm_mid_notes.size():
		_mix(wm_mid, _voice(wm_mid_notes[k], wm_mid_notes[k], 0.13, WAVE_TRI, 0.003, 0.07, 0.25), int(k * 0.05 * SR))
	_mix(wm_mid, _voice(1600.0, 2600.0, 0.22, WAVE_SINE, 0.01, 0.11, 0.08), int(0.05 * SR))
	_bank["wm_success_mid"] = _wav(wm_mid)

	var wm_max := PackedFloat32Array()
	var wm_max_notes := [392.00, 523.25, 659.25, 783.99, 1046.50, 1318.51, 1567.98]
	for k in wm_max_notes.size():
		var dur := 0.20 if k == wm_max_notes.size() - 1 else 0.11
		_mix(wm_max, _voice(wm_max_notes[k], wm_max_notes[k], dur, WAVE_TRI, 0.003, dur * 0.5, 0.26), int(k * 0.045 * SR))
	_mix(wm_max, _voice(1800.0, 4200.0, 0.34, WAVE_SINE, 0.012, 0.18, 0.10), int(0.08 * SR))
	_bank["wm_success_max"] = _wav(wm_max)

	_bank["wm_known"] = _wav(_voice(240.0, 190.0, 0.16, WAVE_SQUARE, 0.004, 0.10, 0.14))
	_bank["wm_tick"] = _wav(_voice(520.0, 520.0, 0.055, WAVE_TRI, 0.001, 0.025, 0.14))
	_bank["wm_tick_fast"] = _wav(_voice(800.0, 800.0, 0.065, WAVE_TRI, 0.001, 0.03, 0.22))

	# Player hit — noise crack over a low thump.
	var hit := _lowpass(_voice(1.0, 1.0, 0.10, WAVE_NOISE, 0.001, 0.05, 0.5), 0.42)
	_mix(hit, _voice(220.0, 90.0, 0.16, WAVE_SINE, 0.002, 0.09, 0.5))
	_bank["hit"] = _wav(hit)

	# Big hit — fuller crack + deep boom + body.
	var big := _lowpass(_voice(1.0, 1.0, 0.16, WAVE_NOISE, 0.001, 0.08, 0.6), 0.5)
	_mix(big, _voice(150.0, 52.0, 0.34, WAVE_SINE, 0.002, 0.16, 0.6))
	_mix(big, _voice(300.0, 110.0, 0.20, WAVE_SQUARE, 0.002, 0.1, 0.18))
	_bank["big_hit"] = _wav(big)

	# Enemy hit on the player — duller, heavier thud.
	var ehit := _lowpass(_voice(1.0, 1.0, 0.14, WAVE_NOISE, 0.001, 0.07, 0.45), 0.22)
	_mix(ehit, _voice(170.0, 64.0, 0.22, WAVE_SINE, 0.002, 0.12, 0.55))
	_bank["enemy_hit"] = _wav(ehit)

	# Heal — warm rising two-note chime with gentle vibrato.
	var heal := _voice(523.0, 540.0, 0.5, WAVE_SINE, 0.02, 0.34, 0.26, 5.0, 0.012)
	_mix(heal, _voice(784.0, 810.0, 0.55, WAVE_SINE, 0.06, 0.36, 0.2, 5.0, 0.012), int(0.08 * SR))
	_bank["heal"] = _wav(heal)

	# Gem pickup — quick sparkly ascending arpeggio.
	var gem := PackedFloat32Array()
	var gem_notes := [1046.0, 1318.0, 1568.0, 2093.0]
	for k in gem_notes.size():
		_mix(gem, _voice(gem_notes[k], gem_notes[k] * 1.01, 0.16, WAVE_SINE, 0.002, 0.06, 0.22),
			int(k * 0.045 * SR))
	_bank["gem"] = _wav(gem)

	# Rainbow — iridescent upward sweep with shimmer tail.
	var rb := _voice(280.0, 2100.0, 0.5, WAVE_SAW, 0.01, 0.3, 0.2)
	_mix(rb, _voice(560.0, 3000.0, 0.45, WAVE_SINE, 0.02, 0.22, 0.12), int(0.05 * SR))
	_bank["rainbow"] = _wav(rb)

	# Hazard / enemy ability — ominous low wobble.
	_bank["hazard"] = _wav(_voice(210.0, 150.0, 0.42, WAVE_SQUARE, 0.01, 0.24, 0.24, 9.0, 0.06))

	# Victory — bright four-note fanfare (C-E-G-C).
	var win := PackedFloat32Array()
	var win_notes := [523.0, 659.0, 784.0, 1046.0]
	for k in win_notes.size():
		var nd: float = 0.34 if k == win_notes.size() - 1 else 0.16
		_mix(win, _voice(win_notes[k], win_notes[k], nd, WAVE_TRI, 0.004, nd * 0.7, 0.3),
			int(k * 0.13 * SR))
	_bank["victory"] = _wav(win)

	# Defeat — slow descending minor sigh.
	var lose := PackedFloat32Array()
	var lose_notes := [440.0, 392.0, 330.0, 247.0]
	for k in lose_notes.size():
		_mix(lose, _voice(lose_notes[k], lose_notes[k] * 0.99, 0.4, WAVE_SINE, 0.01, 0.28, 0.28, 5.0, 0.02),
			int(k * 0.2 * SR))
	_bank["defeat"] = _wav(lose)

# ---------------- music bed ----------------

## Builds a gentle looping arpeggio over a vi-IV-I-V progression.
func _build_music() -> AudioStreamWAV:
	var eighth := 0.27
	var bar_chords := [
		[440.00, 523.25, 659.25],     # Am
		[349.23, 440.00, 523.25],     # F
		[523.25, 659.25, 783.99],     # C
		[392.00, 493.88, 587.33],     # G
	]
	var bass := [110.00, 87.31, 130.81, 98.00]
	var arp := [0, 1, 2, 1, 0, 1, 2, 1]
	var track := PackedFloat32Array()
	var step := 0
	for bar in bar_chords.size():
		var chord: Array = bar_chords[bar]
		for e in arp.size():
			var f: float = chord[arp[e]]
			var at := int(step * eighth * SR)
			_mix(track, _voice(f, f, eighth * 1.7, WAVE_TRI, 0.012, eighth * 0.95, 0.13), at)
			step += 1
		# Bass note on beats 1 and 3 of the bar.
		var bar_at := int(bar * arp.size() * eighth * SR)
		_mix(track, _voice(bass[bar], bass[bar], eighth * 2.6, WAVE_SINE, 0.02, eighth * 1.6, 0.22), bar_at)
		_mix(track, _voice(bass[bar], bass[bar], eighth * 2.6, WAVE_SINE, 0.02, eighth * 1.6, 0.16),
			bar_at + int(arp.size() * 0.5 * eighth * SR))
	return _wav(track, true)
