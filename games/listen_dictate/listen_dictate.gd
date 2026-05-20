extends Control
## Listen & Dictate — TTS speaks a word, user types it letter-by-letter.
## Scoring rewards accuracy and penalizes replays.

const Chrome := preload("res://scripts/screen_chrome.gd")
const Fx := preload("res://games/word_fight/fx.gd")

const PINK := Color("#e07a8c")
const PINK_DARK := Color("#c95e74")
const PINK_LIGHT := Color("#fde6ec")
const BLUE := Color("#3d8bb5")
const BLUE_LIGHT := Color("#dceaf2")
const SAGE := Color("#a7d99a")
const SAGE_DARK := Color("#4a7d4a")
const SAGE_LIGHT := Color("#e6f5ea")
const TERRA := Color("#c95e3e")
const TERRA_LIGHT := Color("#fbeaea")
const GOLD_DARK := Color("#b48218")

const VIBRANT_GOLD := Color("#ffd027")
const VIBRANT_GOLD_DARK := Color("#7a4a00")
const VIBRANT_MAGENTA := Color("#ff3aa8")
const VIBRANT_MAGENTA_DARK := Color("#7a0e4a")
const VIBRANT_GREEN := Color("#3ad6a8")
const VIBRANT_GREEN_DARK := Color("#0a6650")
const DARK_CARD := Color("#1a1240")
const DARK_CARD_BORDER := Color("#3a2a78")

const WORDS := [
	{"word": "BEAUTIFUL", "sentence": "The sunset was beautiful — a mix of orange and pink filled the sky."},
	{"word": "ELEPHANT",  "sentence": "The elephant walked slowly through the tall grass of the savanna."},
	{"word": "TREASURE",  "sentence": "They discovered a hidden treasure buried beneath the old oak tree."},
	{"word": "KNOWLEDGE", "sentence": "Knowledge is the key to understanding the world around us."},
]

var _word: String
var _sentence: String
var _typed: String = ""
var _replays: int = 0
var _body: VBoxContainer
var _letter_row: HBoxContainer
var _input: LineEdit
var _submit: Button
var _replays_lbl: Label

func _ready() -> void:
	_pick_word()
	var bg := Fx.AnimatedBoardBG.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var back := Chrome.header(self, "Listen & Dictate", "listen_dictate", PINK_LIGHT, PINK_DARK)
	back.pressed.connect(_back)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_top = Chrome.HEADER_H
	scroll.offset_left = 16
	scroll.offset_right = -16
	scroll.offset_bottom = -16
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 14)
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_body)
	_build_form()

func _pick_word() -> void:
	var entry: Dictionary = WORDS[randi() % WORDS.size()]
	_word = entry.word
	_sentence = entry.sentence
	_typed = ""
	_replays = 0

func _build_form() -> void:
	_clear_body()

	var hint := Label.new()
	hint.text = "Listen to the word and type it"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 17)
	hint.add_theme_color_override("font_color", VIBRANT_GOLD)
	hint.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.45))
	hint.add_theme_constant_override("outline_size", 3)
	_body.add_child(hint)

	# Audio bar — dark vibrant card.
	var bar_card := PanelContainer.new()
	var bar_sb := StyleBoxFlat.new()
	bar_sb.bg_color = Color(DARK_CARD.r, DARK_CARD.g, DARK_CARD.b, 0.82)
	bar_sb.set_corner_radius_all(18)
	bar_sb.set_border_width_all(2)
	bar_sb.border_color = DARK_CARD_BORDER
	bar_sb.shadow_color = Color(0, 0, 0, 0.25)
	bar_sb.shadow_size = 5
	bar_sb.shadow_offset = Vector2i(0, 2)
	bar_sb.content_margin_left = 14
	bar_sb.content_margin_right = 14
	bar_sb.content_margin_top = 14
	bar_sb.content_margin_bottom = 14
	bar_card.add_theme_stylebox_override("panel", bar_sb)
	var bar_row := HBoxContainer.new()
	bar_row.add_theme_constant_override("separation", 12)
	bar_card.add_child(bar_row)

	var play_btn := Button.new()
	play_btn.text = ""
	if ResourceLoader.exists("res://assets/icons/play.svg"):
		play_btn.icon = load("res://assets/icons/play.svg")
		play_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		play_btn.expand_icon = false
		play_btn.add_theme_constant_override("icon_max_width", 22)
	play_btn.custom_minimum_size = Vector2(44, 44)
	play_btn.focus_mode = Control.FOCUS_NONE
	var pb_sb := StyleBoxFlat.new()
	pb_sb.bg_color = VIBRANT_MAGENTA
	pb_sb.set_corner_radius_all(22)
	pb_sb.shadow_color = Color(1.0, 0.4, 0.7, 0.5)
	pb_sb.shadow_size = 8
	pb_sb.shadow_offset = Vector2i(0, 2)
	pb_sb.content_margin_left = 0
	pb_sb.content_margin_right = 0
	pb_sb.content_margin_top = 0
	pb_sb.content_margin_bottom = 0
	play_btn.add_theme_stylebox_override("normal", pb_sb)
	play_btn.add_theme_stylebox_override("hover", pb_sb)
	play_btn.add_theme_stylebox_override("pressed", pb_sb)
	play_btn.add_theme_stylebox_override("focus", pb_sb)
	play_btn.pressed.connect(_play_word)
	bar_row.add_child(play_btn)

	var fill := Control.new()
	fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fill.custom_minimum_size = Vector2(0, 6)
	var track_sb := StyleBoxFlat.new()
	track_sb.bg_color = Color(1, 1, 1, 0.3)
	track_sb.set_corner_radius_all(3)
	var track := Panel.new()
	track.add_theme_stylebox_override("panel", track_sb)
	track.set_anchors_preset(Control.PRESET_FULL_RECT)
	fill.add_child(track)
	bar_row.add_child(fill)

	var replay_btn := Button.new()
	replay_btn.text = "Replay"
	replay_btn.flat = true
	replay_btn.focus_mode = Control.FOCUS_NONE
	replay_btn.add_theme_font_size_override("font_size", 14)
	replay_btn.add_theme_color_override("font_color", VIBRANT_GOLD)
	replay_btn.add_theme_color_override("font_hover_color", Color.WHITE)
	replay_btn.pressed.connect(_replay_word)
	bar_row.add_child(replay_btn)
	_body.add_child(bar_card)

	_replays_lbl = Label.new()
	_replays_lbl.text = ""
	_replays_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_replays_lbl.add_theme_font_size_override("font_size", 14)
	_replays_lbl.add_theme_color_override("font_color", VIBRANT_GOLD)
	_body.add_child(_replays_lbl)
	_refresh_replays_label()

	# Letter boxes.
	_letter_row = HBoxContainer.new()
	_letter_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_letter_row.add_theme_constant_override("separation", 6)
	_body.add_child(_letter_row)
	_refresh_letter_boxes()

	var count := Label.new()
	count.text = "%d letters" % _word.length()
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count.add_theme_font_size_override("font_size", 13)
	count.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
	_body.add_child(count)

	# Text input — chunky white card with magenta glow on focus.
	var input_wrap := Control.new()
	input_wrap.custom_minimum_size = Vector2(0, 56)
	var input_glow := Panel.new()
	input_glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	input_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ig_sb := StyleBoxFlat.new()
	ig_sb.bg_color = Color(0, 0, 0, 0)
	ig_sb.set_corner_radius_all(14)
	ig_sb.shadow_color = Color(1.0, 0.4, 0.7, 0.0)
	ig_sb.shadow_size = 0
	input_glow.add_theme_stylebox_override("panel", ig_sb)
	input_wrap.add_child(input_glow)
	var input_card := PanelContainer.new()
	input_card.set_anchors_preset(Control.PRESET_FULL_RECT)
	input_card.mouse_filter = Control.MOUSE_FILTER_PASS
	var input_sb := StyleBoxFlat.new()
	input_sb.bg_color = Color.WHITE
	input_sb.set_corner_radius_all(14)
	input_sb.set_border_width_all(2)
	input_sb.border_color = Color("#e0d8c8")
	input_sb.shadow_color = Color(0, 0, 0, 0.18)
	input_sb.shadow_size = 4
	input_card.add_theme_stylebox_override("panel", input_sb)
	input_wrap.add_child(input_card)
	_input = LineEdit.new()
	_input.placeholder_text = "Type the word…"
	_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_input.add_theme_font_size_override("font_size", 22)
	_input.add_theme_color_override("font_color", VIBRANT_MAGENTA_DARK)
	_input.max_length = _word.length()
	_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_input.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_input.focus_mode = Control.FOCUS_ALL
	_input.mouse_filter = Control.MOUSE_FILTER_STOP
	var le_box := StyleBoxFlat.new()
	le_box.bg_color = Color(0, 0, 0, 0)
	le_box.content_margin_left = 12
	le_box.content_margin_right = 12
	le_box.content_margin_top = 14
	le_box.content_margin_bottom = 14
	_input.add_theme_stylebox_override("normal", le_box)
	_input.add_theme_stylebox_override("focus", le_box)
	_input.add_theme_stylebox_override("read_only", le_box)
	_input.text_changed.connect(_on_typed)
	input_card.add_child(_input)
	_input.focus_entered.connect(func(): _set_input_glow_on(input_glow, true))
	_input.focus_exited.connect(func(): _set_input_glow_on(input_glow, false))
	input_card.gui_input.connect(func(event: InputEvent):
		if (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed):
			_input.grab_focus())
	_body.add_child(input_wrap)

	# Submit wrapped in magenta glow.
	var submit_wrap := Control.new()
	submit_wrap.custom_minimum_size = Vector2(0, 56)
	var submit_glow := Panel.new()
	submit_glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	submit_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sg_sb := StyleBoxFlat.new()
	sg_sb.bg_color = Color(0, 0, 0, 0)
	sg_sb.set_corner_radius_all(32)
	sg_sb.shadow_color = Color(1.0, 0.4, 0.7, 0.0)
	sg_sb.shadow_size = 0
	submit_glow.add_theme_stylebox_override("panel", sg_sb)
	submit_wrap.add_child(submit_glow)
	_submit = Chrome.pill_button("Submit", VIBRANT_MAGENTA, Color.WHITE)
	_submit.set_anchors_preset(Control.PRESET_FULL_RECT)
	_submit.disabled = true
	_submit.pressed.connect(_check_submit)
	submit_wrap.add_child(_submit)
	_submit.set_meta("glow_panel", submit_glow)
	_body.add_child(submit_wrap)

func _set_input_glow_on(glow: Panel, on: bool) -> void:
	var sb := glow.get_theme_stylebox("panel") as StyleBoxFlat
	if sb == null: return
	var fresh: StyleBoxFlat = sb.duplicate()
	fresh.shadow_color = Color(1.0, 0.4, 0.7, 0.5 if on else 0.0)
	fresh.shadow_size = 12 if on else 0
	glow.add_theme_stylebox_override("panel", fresh)

func _on_typed(text: String) -> void:
	_typed = text
	_refresh_letter_boxes()
	var ready := _typed.length() == _word.length()
	_submit.disabled = not ready
	# Pulse glow on the submit ring when the word is the right length.
	var sg: Panel = _submit.get_meta("glow_panel") as Panel if _submit.has_meta("glow_panel") else null
	if sg != null:
		var sb := sg.get_theme_stylebox("panel") as StyleBoxFlat
		if sb != null:
			var fresh: StyleBoxFlat = sb.duplicate()
			fresh.shadow_color = Color(1.0, 0.4, 0.7, 0.55 if ready else 0.0)
			fresh.shadow_size = 22 if ready else 0
			sg.add_theme_stylebox_override("panel", fresh)

func _refresh_letter_boxes() -> void:
	for c in _letter_row.get_children():
		c.queue_free()
	for i in _word.length():
		var ch := ""
		if i < _typed.length():
			ch = _typed[i].to_upper()
		_letter_row.add_child(_letter_box(ch, not ch.is_empty()))

func _letter_box(ch: String, filled: bool) -> Control:
	var p := Panel.new()
	p.custom_minimum_size = Vector2(34, 46)
	var sb := StyleBoxFlat.new()
	sb.bg_color = VIBRANT_MAGENTA if filled else Color(1, 1, 1, 0.1)
	sb.set_corner_radius_all(8)
	sb.set_border_width_all(2)
	sb.border_color = VIBRANT_MAGENTA_DARK if filled else Color(1, 1, 1, 0.35)
	if filled:
		sb.shadow_color = Color(1.0, 0.4, 0.7, 0.5)
		sb.shadow_size = 4
	p.add_theme_stylebox_override("panel", sb)
	if not ch.is_empty():
		var lbl := Label.new()
		lbl.text = ch
		lbl.add_theme_font_size_override("font_size", 20)
		lbl.add_theme_color_override("font_color", Color.WHITE)
		lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.55))
		lbl.add_theme_constant_override("outline_size", 3)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
		p.add_child(lbl)
	return p

func _refresh_replays_label() -> void:
	_replays_lbl.text = "" if _replays <= 0 else "Replays: %d (-%d pts)" % [_replays, _replays * 10]

func _play_word() -> void:
	if DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
		var voices := DisplayServer.tts_get_voices_for_language("en")
		var voice_id: String = voices[0] if voices.size() > 0 else ""
		DisplayServer.tts_stop()
		DisplayServer.tts_speak(_word.to_lower(), voice_id, 50, 1.0, 0.85)
	# else: silent fallback — the letter count + length is the hint.

func _replay_word() -> void:
	_replays += 1
	_refresh_replays_label()
	_play_word()

func _check_submit() -> void:
	var correct: bool = _typed.to_upper() == _word
	var base: int = (_word.length() * 10) if correct else int(round(_word.length() * 3.0))
	var penalty: int = _replays * 10
	var earned: int = maxi(0, base - penalty)
	GameState.add_xp("listen_dictate", earned)
	_build_results(correct, earned)

func _build_results(correct: bool, earned: int) -> void:
	_clear_body()
	DisplayServer.tts_stop() if DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH) else null

	# Heading row: status icon + label.
	var head_row := HBoxContainer.new()
	head_row.alignment = BoxContainer.ALIGNMENT_CENTER
	head_row.add_theme_constant_override("separation", 10)
	_body.add_child(head_row)
	var head_icon_path: String = "res://assets/icons/check.svg" if correct else "res://assets/icons/xmark.svg"
	if ResourceLoader.exists(head_icon_path):
		var head_icon := TextureRect.new()
		head_icon.texture = load(head_icon_path)
		head_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		head_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		head_icon.custom_minimum_size = Vector2(30, 30)
		head_icon.modulate = VIBRANT_GREEN if correct else VIBRANT_MAGENTA
		head_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		head_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		head_row.add_child(head_icon)
	var head := Label.new()
	head.text = "Correct!" if correct else "Not quite!"
	head.add_theme_font_size_override("font_size", 32)
	head.add_theme_color_override("font_color", VIBRANT_GREEN if correct else VIBRANT_MAGENTA)
	head.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.55))
	head.add_theme_constant_override("outline_size", 4)
	head_row.add_child(head)

	# Reveal FX.
	await get_tree().process_frame
	Fx.score_popup(self, Vector2(size.x * 0.5 - 24, 130), "+%d XP" % earned, true, VIBRANT_GOLD)
	if correct:
		Fx.banner(self, "CORRECT!", VIBRANT_GREEN, VIBRANT_GREEN_DARK)
		Fx.fireworks(self, Vector2(size.x * 0.5, size.y * 0.35))
	else:
		Fx.shake(self, 4.0, 0.25)

	# Letter comparison row.
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 5)
	for i in _word.length():
		var actual := _word[i]
		var typed_ch := _typed[i].to_upper() if i < _typed.length() else ""
		var match_ok := typed_ch == actual
		var p := Panel.new()
		p.custom_minimum_size = Vector2(30, 38)
		var sb := StyleBoxFlat.new()
		sb.bg_color = SAGE_LIGHT if match_ok else TERRA_LIGHT
		sb.set_corner_radius_all(6)
		sb.set_border_width_all(2)
		sb.border_color = SAGE if match_ok else TERRA
		p.add_theme_stylebox_override("panel", sb)
		var lbl := Label.new()
		lbl.text = actual
		lbl.add_theme_font_size_override("font_size", 16)
		lbl.add_theme_color_override("font_color", SAGE_DARK if match_ok else TERRA)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
		p.add_child(lbl)
		row.add_child(p)
	_body.add_child(row)

	if not correct:
		var typed := Label.new()
		typed.text = "You typed: %s" % _typed.to_upper()
		typed.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		typed.add_theme_font_size_override("font_size", 13)
		typed.add_theme_color_override("font_color", Chrome.TEXT_SEC)
		_body.add_child(typed)

	# Stats.
	var stats := HBoxContainer.new()
	stats.alignment = BoxContainer.ALIGNMENT_CENTER
	stats.add_theme_constant_override("separation", 18)
	var correct_pct := 100 if correct else int(round(_count_matches() * 100.0 / _word.length()))
	stats.add_child(_stat("Accuracy", "%d%%" % correct_pct, SAGE_DARK if correct else TERRA))
	stats.add_child(_stat("Replays", str(_replays), GOLD_DARK))
	stats.add_child(_stat("XP", "+%d" % earned, PINK_DARK))
	_body.add_child(stats)

	# Sentence card.
	var sent_card := PanelContainer.new()
	var sc_sb := StyleBoxFlat.new()
	sc_sb.bg_color = BLUE_LIGHT
	sc_sb.set_corner_radius_all(14)
	sc_sb.set_border_width_all(2)
	sc_sb.border_color = BLUE
	sc_sb.content_margin_left = 14
	sc_sb.content_margin_right = 14
	sc_sb.content_margin_top = 12
	sc_sb.content_margin_bottom = 12
	sent_card.add_theme_stylebox_override("panel", sc_sb)
	var sc_box := VBoxContainer.new()
	sc_box.add_theme_constant_override("separation", 4)
	var sc_head := Label.new()
	sc_head.text = "Example sentence"
	sc_head.add_theme_font_size_override("font_size", 13)
	sc_head.add_theme_color_override("font_color", BLUE)
	sc_box.add_child(sc_head)
	var sent_lbl := Label.new()
	sent_lbl.text = _sentence
	sent_lbl.add_theme_font_size_override("font_size", 14)
	sent_lbl.add_theme_color_override("font_color", Chrome.TEXT)
	sent_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sc_box.add_child(sent_lbl)
	sent_card.add_child(sc_box)
	_body.add_child(sent_card)

	var next := Chrome.pill_button("Next Word", PINK, Color.WHITE, "res://assets/icons/arrow_right.svg")
	next.pressed.connect(func():
		_pick_word()
		_build_form())
	_body.add_child(next)
	var back := Chrome.pill_button("Back to Menu", Chrome.SURFACE, Chrome.TEXT)
	back.pressed.connect(_back)
	_body.add_child(back)

func _count_matches() -> int:
	var n := 0
	for i in _word.length():
		if i < _typed.length() and _typed[i].to_upper() == _word[i]:
			n += 1
	return n

func _stat(label: String, value: String, color: Color) -> Control:
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	var v := Label.new()
	v.text = value
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_theme_font_size_override("font_size", 18)
	v.add_theme_color_override("font_color", color)
	box.add_child(v)
	var l := Label.new()
	l.text = label
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 11)
	l.add_theme_color_override("font_color", Chrome.TEXT_SEC)
	box.add_child(l)
	return box

func _clear_body() -> void:
	for c in _body.get_children():
		c.queue_free()

func _back() -> void:
	if DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
		DisplayServer.tts_stop()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
