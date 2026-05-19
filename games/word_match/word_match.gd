extends Control
## Word Match — 6–8 letters in a circle, drag to form words.

const LETTER_SCENE_SIZE := 64.0
const ROUND_TIME_SEC := 120.0
const MIN_WORD_LEN := 3

# Curated letter pools known to produce many valid sub-words.
# (Picked to satisfy the vowel guarantee — each has ≥2 vowels.)
const POOLS_7 := [
	"PASTERN", "MASTERS", "PAINTER", "STORIED", "EARTHLY",
	"PLAYERS", "RAINBOW", "TROUBLE", "GARDENS", "PARTIES",
	"ORANGES", "SECTION", "READING", "PLANETS", "TEACHER",
]
const POOLS_6 := [
	"PLATES", "MOTHER", "HEARTS", "ANSWER", "REPLAY",
	"BREATH", "GARDEN", "LEARNS", "STREAM", "CAMERA",
]
const POOLS_8 := [
	"REACTION", "TEACHERS", "STRANGER", "MOUNTAIN", "RAINBOWS",
	"PAINTERS", "PLANETSS", "STARTERS",
]

const UI := preload("res://scripts/results_ui.gd")
const Chrome := preload("res://scripts/screen_chrome.gd")

const BLUE_LIGHT := Color("#dceaf2")
const BLUE_DARK := Color("#3d8bb5")
const GOLD_LIGHT := Color("#fff1c4")
const GOLD_DARK := Color("#b48218")
const CURRENT_BG := Color("#e8f0f6")
const CURRENT_BORDER := Color("#a8c8de")

var letters_holder: Control
var preview_label: Label
var score_label: Label
var timer_label: Label
var found_label: Label
var found_pills_row: HFlowContainer
var line: Line2D
var back_btn: Button
var toast: Label

var _letters: Array[WMLetter] = []
var _chain: Array[WMLetter] = []   # ordered nodes selected
var _time_left: float = ROUND_TIME_SEC
var _running: bool = false
var _score: int = 0
var _found: Dictionary = {}        # word -> true
var _found_order: Array = []       # in order discovered, for results screen
var _is_dragging: bool = false
var _pool: String = ""             # current round pool
var _possible_words: Array = []    # all formable words from pool (length-desc)

func _ready() -> void:
	_build_ui()
	back_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	line.width = 8
	line.default_color = Color(Palette.PINK.r, Palette.PINK.g, Palette.PINK.b, 0.6)
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	_start_round()

# ---------------- UI construction (wm_game layout) ----------------

func _build_ui() -> void:
	Chrome.bg_layer(self)
	back_btn = Chrome.header(self, "Word Match", "word_match", BLUE_LIGHT, BLUE_DARK)

	# Top stack (HUD chips, found card, current word).
	var top := VBoxContainer.new()
	top.anchor_right = 1.0
	top.offset_left = 16
	top.offset_top = Chrome.HEADER_H + 12
	top.offset_right = -16
	top.offset_bottom = 320
	top.add_theme_constant_override("separation", 12)
	add_child(top)

	# Timer + XP chips row.
	var hud := HBoxContainer.new()
	hud.add_theme_constant_override("separation", 12)
	timer_label = _hud_chip("⏱ 2:00", BLUE_LIGHT, BLUE_DARK)
	hud.add_child(timer_label.get_parent())
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hud.add_child(spacer)
	score_label = _hud_chip("★ 0 XP", GOLD_LIGHT, GOLD_DARK)
	hud.add_child(score_label.get_parent())
	top.add_child(hud)

	# Found-words card (white rounded card with shadow, summary + hint inside).
	var found_card := PanelContainer.new()
	var found_sb := StyleBoxFlat.new()
	found_sb.bg_color = Chrome.SURFACE
	found_sb.set_corner_radius_all(14)
	found_sb.set_border_width_all(1)
	found_sb.border_color = Chrome.BORDER
	found_sb.shadow_color = Color(0, 0, 0, 0.05)
	found_sb.shadow_size = 3
	found_sb.shadow_offset = Vector2i(0, 1)
	found_sb.content_margin_left = 14
	found_sb.content_margin_right = 14
	found_sb.content_margin_top = 12
	found_sb.content_margin_bottom = 12
	found_card.add_theme_stylebox_override("panel", found_sb)
	var found_box := VBoxContainer.new()
	found_box.add_theme_constant_override("separation", 4)
	found_label = Label.new()
	found_label.text = "Found: 0"
	found_label.add_theme_color_override("font_color", Chrome.TEXT_SEC)
	found_label.add_theme_font_size_override("font_size", 13)
	found_box.add_child(found_label)
	var hint := Label.new()
	hint.text = "Drag to form words!"
	hint.add_theme_color_override("font_color", Chrome.TEXT_SEC)
	hint.add_theme_font_size_override("font_size", 14)
	found_box.add_child(hint)
	found_pills_row = HFlowContainer.new()
	found_pills_row.add_theme_constant_override("h_separation", 6)
	found_pills_row.add_theme_constant_override("v_separation", 6)
	found_box.add_child(found_pills_row)
	found_card.add_child(found_box)
	top.add_child(found_card)

	# Current-word pill (light-blue rounded bar, matching the design).
	var word_card := PanelContainer.new()
	var word_sb := StyleBoxFlat.new()
	word_sb.bg_color = CURRENT_BG
	word_sb.set_corner_radius_all(22)
	word_sb.set_border_width_all(2)
	word_sb.border_color = CURRENT_BORDER
	word_sb.content_margin_top = 12
	word_sb.content_margin_bottom = 12
	word_card.add_theme_stylebox_override("panel", word_sb)
	preview_label = Label.new()
	preview_label.text = ""
	preview_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_label.add_theme_color_override("font_color", BLUE_DARK)
	preview_label.add_theme_font_size_override("font_size", 22)
	word_card.add_child(preview_label)
	top.add_child(word_card)

	# Letters holder, anchored to bottom-center.
	letters_holder = Control.new()
	letters_holder.anchor_left = 0.5
	letters_holder.anchor_top = 1.0
	letters_holder.anchor_right = 0.5
	letters_holder.anchor_bottom = 1.0
	letters_holder.offset_left = -180
	letters_holder.offset_top = -380
	letters_holder.offset_right = 180
	letters_holder.offset_bottom = -20
	letters_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(letters_holder)

	# Drag line (sibling so it draws above letters_holder children).
	line = Line2D.new()
	add_child(line)

	# Toast above the letter circle.
	toast = Label.new()
	toast.anchor_left = 0.5
	toast.anchor_right = 0.5
	toast.offset_left = -200
	toast.offset_top = 280
	toast.offset_right = 200
	toast.offset_bottom = 320
	toast.text = ""
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.add_theme_font_size_override("font_size", 22)
	add_child(toast)

	# Static footer hint under the letter circle, matching the design.
	var footer := Label.new()
	footer.anchor_left = 0.0
	footer.anchor_right = 1.0
	footer.anchor_top = 1.0
	footer.anchor_bottom = 1.0
	footer.offset_top = -36
	footer.offset_bottom = -12
	footer.offset_left = 16
	footer.offset_right = -16
	footer.text = "Drag across letters to form words — lift to submit"
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_font_size_override("font_size", 13)
	footer.add_theme_color_override("font_color", Chrome.TEXT_SEC)
	add_child(footer)

func _hud_chip(text: String, bg: Color, fg: Color) -> Label:
	# Returns the inner Label so the caller can update text; parented PanelContainer is added.
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(99)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	p.add_theme_stylebox_override("panel", sb)
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", fg)
	p.add_child(lbl)
	return lbl

func _start_round() -> void:
	for c in _letters:
		c.queue_free()
	_letters.clear()
	_chain.clear()
	_found.clear()
	_found_order.clear()
	_score = 0
	_time_left = ROUND_TIME_SEC
	_running = true
	var pool := _pick_pool()
	_pool = pool
	# Precompute every dictionary word formable from the pool (with reuse,
	# since the circle allows re-tapping the same letter non-consecutively).
	_possible_words = Words.words_from_letters(pool, MIN_WORD_LEN, true)
	# Length-desc, then alpha — used for capped missed-words list on results.
	_possible_words.sort_custom(func(a, b):
		if a.length() != b.length():
			return a.length() > b.length()
		return a < b
	)
	_spawn_letters(pool)
	_layout_letters()
	_refresh_hud()
	_refresh_found()
	preview_label.text = ""

func _pick_pool() -> String:
	var src: Array
	if GameState.mode == GameState.Mode.INTERMEDIATE:
		src = POOLS_6 + POOLS_7
	else:
		src = POOLS_7 + POOLS_8
	return src[randi() % src.size()]

func _spawn_letters(pool: String) -> void:
	# Shuffle letters but enforce vowel guarantee: at least 2 vowels visible.
	var arr := []
	for ch in pool:
		arr.append(ch)
	arr.shuffle()
	if _count_vowels(arr) < 2:
		# rare for curated pools but guard anyway
		arr = _force_vowels(arr)
	var Letter := preload("res://games/word_match/letter_node.gd")
	for ch: String in arr:
		var n: WMLetter = Letter.new()
		n.letter = ch
		letters_holder.add_child(n)
		_letters.append(n)

func _count_vowels(arr: Array) -> int:
	var v := 0
	for ch: String in arr:
		if "AEIOU".find(ch) != -1:
			v += 1
	return v

func _force_vowels(arr: Array) -> Array:
	# Replace a consonant with 'A' to guarantee a vowel.
	for i in arr.size():
		if "AEIOU".find(arr[i]) == -1:
			arr[i] = "A"
			break
	return arr

func _layout_letters() -> void:
	# Wait one frame so the holder size is finalized.
	await get_tree().process_frame
	var center := letters_holder.size * 0.5
	var radius: float = minf(letters_holder.size.x, letters_holder.size.y) * 0.5 - LETTER_SCENE_SIZE * 0.5 - 8.0
	var n := _letters.size()
	for i in n:
		var angle := -PI * 0.5 + TAU * float(i) / float(n)
		var pos := center + Vector2(cos(angle), sin(angle)) * radius
		var node := _letters[i]
		node.position = pos - Vector2(LETTER_SCENE_SIZE, LETTER_SCENE_SIZE) * 0.5

func _process(delta: float) -> void:
	if not _running:
		return
	_time_left -= delta
	if _time_left <= 0:
		_time_left = 0
		_end_round()
	_refresh_hud()

func _refresh_hud() -> void:
	var m := int(_time_left) / 60
	var s := int(_time_left) % 60
	timer_label.text = "⏱ %d:%02d" % [m, s]
	score_label.text = "★ %d XP" % _score

func _refresh_found() -> void:
	found_label.text = "Found: %d" % _found.size()
	# Replace pill row contents.
	for c in found_pills_row.get_children():
		c.queue_free()
	if _found.is_empty():
		return
	for w: String in _found_order:
		found_pills_row.add_child(UI.pill(w, Color("#e6f5ea"), Palette.SAGE_DARK))

# -------- input / drag chain --------

func _gui_input(event: InputEvent) -> void:
	if not _running:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_begin_drag(event.global_position)
			else:
				_end_drag()
	elif event is InputEventMouseMotion and _is_dragging:
		_continue_drag(event.global_position)
	elif event is InputEventScreenTouch:
		if event.pressed:
			_begin_drag(event.position)
		else:
			_end_drag()
	elif event is InputEventScreenDrag:
		_continue_drag(event.position)

func _begin_drag(gpos: Vector2) -> void:
	_is_dragging = true
	for n in _chain:
		n.selected = false
	_chain.clear()
	_try_add_letter_at(gpos)
	_update_line(gpos)
	_update_preview()

func _continue_drag(gpos: Vector2) -> void:
	if not _is_dragging:
		return
	_try_add_letter_at(gpos)
	_update_line(gpos)
	_update_preview()

func _end_drag() -> void:
	if not _is_dragging:
		return
	_is_dragging = false
	line.clear_points()
	var word := _current_word()
	for n in _chain:
		n.selected = false
	_chain.clear()
	if word.length() < MIN_WORD_LEN:
		_shake_feedback("Too short!")
		preview_label.text = ""
		return
	_submit(word)
	preview_label.text = ""

func _try_add_letter_at(gpos: Vector2) -> void:
	for n in _letters:
		if n.contains_point(gpos):
			# Allow same-tile reuse, but not back-to-back duplicate of last.
			if _chain.size() > 0 and _chain[-1] == n:
				return
			_chain.append(n)
			n.selected = true
			return

func _update_line(cursor_gpos: Vector2) -> void:
	line.clear_points()
	for n in _chain:
		var center := n.global_position + n.size * 0.5
		line.add_point(line.to_local(center))
	if _is_dragging:
		line.add_point(line.to_local(cursor_gpos))

func _current_word() -> String:
	var s := ""
	for n in _chain:
		s += n.letter
	return s

func _update_preview() -> void:
	preview_label.text = _current_word()

# -------- scoring --------

func _submit(word_upper: String) -> void:
	var word := word_upper.to_lower()
	if _found.has(word):
		_shake_feedback("Already found")
		return
	if not Words.is_valid(word):
		_shake_feedback("Not a word")
		return
	_found[word] = true
	_found_order.append(word.to_upper())
	# Base = length × 10. Mode multiplier applied inside GameState.add_xp().
	var base := word.length() * 10
	var earned := GameState.add_xp("word_match", base)
	_score += earned
	_refresh_hud()
	_refresh_found()
	_show_toast("+%d XP   %s" % [earned, word_upper], Palette.GREEN)

func _shake_feedback(msg: String) -> void:
	_show_toast(msg, Palette.RED)

func _show_toast(msg: String, color: Color) -> void:
	toast.text = msg
	toast.add_theme_color_override("font_color", color)
	toast.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(0.6)
	tw.tween_property(toast, "modulate:a", 0.0, 0.4)

func _end_round() -> void:
	_running = false
	preview_label.text = "Time! %d XP, %d words" % [_score, _found.size()]
	# Build a capped list of missed words (top by length) for the results screen.
	var missed_top: Array = []
	var cap := 16
	for w: String in _possible_words:
		if missed_top.size() >= cap:
			break
		if not _found.has(w):
			missed_top.append(w.to_upper())
	GameState.wm_session = {
		"pool": _pool,
		"found_words": _found_order.duplicate(),
		"possible_count": _possible_words.size(),
		"missed_top": missed_top,
		"score": _score,
		"time_used": ROUND_TIME_SEC,
	}
	# Brief pause so the player sees the "Time!" message before transitioning.
	await get_tree().create_timer(0.8).timeout
	get_tree().change_scene_to_file("res://games/word_match/results.tscn")
