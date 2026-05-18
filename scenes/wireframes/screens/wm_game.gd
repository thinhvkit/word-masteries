extends Control
## Word Match — live gameplay (wireframe styling).
## 6-letter circle, drag across to spell, 2-minute timer, dictionary-validated.

const WF := preload("res://scripts/wf/wf.gd")
const Screen := preload("res://scripts/wf/wf_screen.gd")

const ROUND_TIME := 120.0
const MIN_LEN := 3
const POOLS := [
	"BRIGHT","PLATES","MOTHER","HEARTS","ANSWER","REPLAY",
	"BREATH","GARDEN","LEARNS","STREAM","CAMERA","PAINTER",
]

var _letters: Array[String] = []
var _phone: Control
var _circle: Control
var _current_lbl: Label
var _timer_lbl: Label
var _score_lbl: Label
var _found_pills_row: HBoxContainer
var _toast: Label
var _time_left: float = ROUND_TIME
var _score: int = 0
var _found: Dictionary = {}
var _chain: Array = []   # letter indices
var _dragging: bool = false

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_layout()
	Screen.wire_nav(self)
	_start_round()

func _build_layout() -> void:
	_phone = WF.Phone.new()
	_phone.set_anchors_preset(Control.PRESET_FULL_RECT)
	_phone.set_header(WF.app_head("Word Match", true, _mode_label()))
	add_child(_phone)
	var body: VBoxContainer = _phone.padded_body(Vector4(16, 16, 16, 16), 12)
	# Top: timer + score
	var top := HBoxContainer.new()
	var tb := PanelContainer.new()
	var tsb := StyleBoxFlat.new()
	tsb.bg_color = WF.ACCENT_BG
	tsb.set_border_width_all(1)
	tsb.border_color = WF.ACCENT
	tsb.set_corner_radius_all(20)
	tsb.content_margin_left = 12
	tsb.content_margin_right = 12
	tsb.content_margin_top = 4
	tsb.content_margin_bottom = 4
	tb.add_theme_stylebox_override("panel", tsb)
	_timer_lbl = WF.make_label("⏱ 2:00", 20, WF.ACCENT, true)
	tb.add_child(_timer_lbl)
	top.add_child(tb)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)
	var sc_col := VBoxContainer.new()
	sc_col.alignment = BoxContainer.ALIGNMENT_CENTER
	var sc_label := WF.make_label("Score", 14, WF.MUTED)
	sc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sc_col.add_child(sc_label)
	_score_lbl = WF.make_label("0", 28, WF.ACCENT, true)
	_score_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sc_col.add_child(_score_lbl)
	top.add_child(sc_col)
	body.add_child(top)
	# Found words
	var found_card := WF.card(WF.PAPER, WF.BORDER_LITE, 12, 12, 2)
	var found_box := VBoxContainer.new()
	found_box.add_child(WF.make_label("Found words", 14, WF.MUTED))
	_found_pills_row = HBoxContainer.new()
	_found_pills_row.add_theme_constant_override("separation", 6)
	found_box.add_child(_found_pills_row)
	found_card.add_child(found_box)
	body.add_child(found_card)
	# Current word
	var cur := WF.card(WF.ACCENT_BG, WF.ACCENT, 8, 10, 2)
	_current_lbl = WF.make_label("—", 24, WF.ACCENT, true)
	_current_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cur.add_child(_current_lbl)
	body.add_child(cur)
	# Circle
	_circle = _Circle.new()
	var holder := CenterContainer.new()
	holder.add_child(_circle)
	body.add_child(holder)
	# Note + toast
	body.add_child(WF.note("Drag across letters to form words — lift to submit"))
	_toast = WF.make_label("", 18, WF.SUCCESS, true)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(_toast)

func _mode_label() -> String:
	return "Intermediate" if GameState.mode == GameState.Mode.INTERMEDIATE else "Advanced"

func _start_round() -> void:
	var pool: String = POOLS[randi() % POOLS.size()]
	_letters.clear()
	var arr := []
	for ch in pool:
		arr.append(ch)
	arr.shuffle()
	for ch: String in arr:
		_letters.append(ch)
	_circle.set_letters(_letters)
	_time_left = ROUND_TIME
	_score = 0
	_found.clear()
	_chain.clear()
	_refresh_hud()
	_refresh_found_pills()

func _process(delta: float) -> void:
	if _time_left <= 0:
		return
	_time_left -= delta
	_refresh_hud()
	if _time_left <= 0:
		_time_left = 0
		_end_round()

func _refresh_hud() -> void:
	var m := int(_time_left) / 60
	var sec := int(_time_left) % 60
	_timer_lbl.text = "⏱ %d:%02d" % [m, sec]
	_score_lbl.text = str(_score)

func _refresh_found_pills() -> void:
	for c in _found_pills_row.get_children():
		c.queue_free()
	if _found.is_empty():
		_found_pills_row.add_child(WF.make_label("(none yet)", 14, WF.MUTED))
		return
	for w in _found.keys():
		_found_pills_row.add_child(WF.pill(String(w).to_upper(), WF.SUCCESS, WF.SUCCESS_BG))

# ─────────── input ───────────

func _gui_input(event: InputEvent) -> void:
	if _time_left <= 0:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_begin_drag(event.position)
			else:
				_end_drag()
	elif event is InputEventMouseMotion and _dragging:
		_extend_drag(event.position)
	elif event is InputEventScreenTouch:
		if event.pressed:
			_begin_drag(event.position)
		else:
			_end_drag()
	elif event is InputEventScreenDrag:
		_extend_drag(event.position)

func _begin_drag(local_pos: Vector2) -> void:
	_dragging = true
	_chain.clear()
	_circle.set_chain(_chain)
	_try_add(local_pos)
	_circle.set_cursor(_to_circle_space(local_pos), true)
	_current_lbl.text = _chain_text() if not _chain.is_empty() else "—"

func _extend_drag(local_pos: Vector2) -> void:
	if not _dragging:
		return
	_try_add(local_pos)
	_circle.set_cursor(_to_circle_space(local_pos), true)
	_current_lbl.text = _chain_text() if not _chain.is_empty() else "—"

func _end_drag() -> void:
	if not _dragging:
		return
	_dragging = false
	_circle.set_cursor(Vector2.ZERO, false)
	var w := _chain_text().to_lower()
	if w.length() >= MIN_LEN:
		_submit(w)
	_chain.clear()
	_circle.set_chain(_chain)
	_current_lbl.text = "—"

func _to_circle_space(local_pos: Vector2) -> Vector2:
	return _circle.get_global_transform().affine_inverse() * (global_position + local_pos)

func _try_add(local_pos: Vector2) -> void:
	var p := _to_circle_space(local_pos)
	var idx: int = _circle.letter_at_point(p)
	if idx < 0:
		return
	if _chain.size() > 0 and _chain[-1] == idx:
		return
	_chain.append(idx)
	_circle.set_chain(_chain)

func _chain_text() -> String:
	var s := ""
	for i in _chain:
		s += _letters[i]
	return s

func _submit(word: String) -> void:
	if _found.has(word):
		_show_toast("Already found", WF.DANGER); return
	if not Words.is_valid(word):
		_show_toast("Not a word", WF.DANGER); return
	_found[word] = true
	var earned := GameState.add_xp("word_match", word.length() * 10)
	_score += earned
	_refresh_hud()
	_refresh_found_pills()
	_show_toast("+%d  %s" % [earned, word.to_upper()], WF.SUCCESS)

func _show_toast(text: String, color: Color) -> void:
	_toast.text = text
	_toast.add_theme_color_override("font_color", color)
	_toast.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(0.6)
	tw.tween_property(_toast, "modulate:a", 0.0, 0.4)

func _end_round() -> void:
	GameState.set_meta("wm_last_score", _score)
	GameState.set_meta("wm_last_found", _found.keys())
	var nav: Node = Engine.get_main_loop().get_root().get_node_or_null("Navigator")
	if nav != null:
		nav.replace("wm_results")

# ─────────── circle widget ───────────

class _Circle extends Control:
	const R := 80.0
	const TILE_R := 24.0
	var letters: Array = []
	var chain: Array = []
	var cursor_pos: Vector2 = Vector2.ZERO
	var has_cursor: bool = false
	func _ready() -> void:
		custom_minimum_size = Vector2(200, 200)
		size = Vector2(200, 200)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func set_letters(l: Array) -> void:
		letters = l; queue_redraw()
	func set_chain(c: Array) -> void:
		chain = c; queue_redraw()
	func set_cursor(p: Vector2, active: bool) -> void:
		cursor_pos = p; has_cursor = active; queue_redraw()
	func letter_at_point(p: Vector2) -> int:
		var center := size * 0.5
		var step: float = TAU / max(1.0, float(letters.size()))
		for i in letters.size():
			var ang: float = i * step - PI * 0.5
			var pos: Vector2 = center + Vector2(cos(ang), sin(ang)) * R
			if p.distance_to(pos) <= TILE_R:
				return i
		return -1
	func _draw() -> void:
		var center := size * 0.5
		var step: float = TAU / max(1.0, float(letters.size()))
		for i in range(chain.size() - 1):
			var a1: float = float(chain[i]) * step - PI * 0.5
			var a2: float = float(chain[i + 1]) * step - PI * 0.5
			var p1: Vector2 = center + Vector2(cos(a1), sin(a1)) * R
			var p2: Vector2 = center + Vector2(cos(a2), sin(a2)) * R
			draw_line(p1, p2, WF.ACCENT, 3)
		if has_cursor and chain.size() > 0:
			var a: float = float(chain[-1]) * step - PI * 0.5
			var p: Vector2 = center + Vector2(cos(a), sin(a)) * R
			draw_line(p, cursor_pos, WF.ACCENT, 2)
		for i in letters.size():
			var ang: float = i * step - PI * 0.5
			var pos: Vector2 = center + Vector2(cos(ang), sin(ang)) * R
			var sel := i in chain
			draw_circle(pos, TILE_R, WF.ACCENT_BG if sel else WF.PAPER)
			draw_arc(pos, TILE_R, 0, TAU, 48, WF.ACCENT if sel else WF.BORDER, 3.0 if sel else 2.0, true)
			var f := WF.font_bold()
			var fs := 22
			var ts := f.get_string_size(letters[i], HORIZONTAL_ALIGNMENT_CENTER, -1, fs)
			draw_string(f, pos - ts * 0.5 + Vector2(0, fs * 0.36),
				letters[i], HORIZONTAL_ALIGNMENT_CENTER, -1, fs,
				WF.ACCENT if sel else WF.TEXT)
