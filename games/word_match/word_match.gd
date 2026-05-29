extends Control
## Word Match — wave-based word chase with combo, lives, targets, and specials.

const LETTER_SCENE_SIZE := 87.0
const WAVE_TIME_SEC := 40.0
const MIN_WORD_LEN := 3
const MAX_LIVES_INTERMEDIATE := 3
const MAX_LIVES_ADVANCED := 2
const COMBO_WINDOW_INTERMEDIATE := 6.0
const COMBO_WINDOW_ADVANCED := 4.0
const POOL_LENGTHS := [6, 7, 8]

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

const GOAL_TYPES := ["word_count", "long_words", "xp_target", "speed_burst", "use_special", "no_mistakes"]
const BASE_LENGTH_SCORE := {3: 10, 4: 20, 5: 40, 6: 80, 7: 160, 8: 320}
const TARGET_REWARD := {3: 40, 4: 80, 5: 150, 6: 300, 7: 600, 8: 900}
const SECRET_WORDS := {
	"nature": ["earth", "rain", "garden", "stream", "plant", "stone", "storm"],
	"food": ["orange", "meat", "toast", "pear", "tea"],
	"animals": ["horse", "mole", "rat", "tern", "lion"],
}

const UI := preload("res://scripts/results_ui.gd")
const Chrome := preload("res://scripts/screen_chrome.gd")
const Fx := preload("res://games/word_fight/fx.gd")

const BLUE_LIGHT := Color("#dceaf2")
const BLUE_DARK := Color("#3d8bb5")
const GOLD_LIGHT := Color("#fff1c4")
const GOLD_DARK := Color("#b48218")
const CURRENT_BG := Color("#e8f0f6")
const CURRENT_BORDER := Color("#a8c8de")

# Vibrant tokens matching the board / Word Fight FX.
const VIBRANT_BLUE := Color("#3aa8ff")
const VIBRANT_BLUE_DARK := Color("#0f5e9c")
const VIBRANT_GOLD := Color("#ffd027")
const VIBRANT_GOLD_DARK := Color("#7a4a00")
const VIBRANT_MAGENTA := Color("#ff3aa8")
const VIBRANT_MAGENTA_DARK := Color("#7a0e4a")
const DARK_CARD := Color("#1a1240")
const DARK_CARD_BORDER := Color("#3a2a78")
const READY_GREEN := Color("#3ad66e")
const ERROR_RED := Color("#ff4a5c")

const BURST_BLUE := [Color("#7fd4ff"), Color("#3aa8ff"), Color("#dff5ff")]
const BURST_GREEN := [Color("#5be68a"), Color("#2fc462"), Color("#d8ffd8")]
const BURST_PURPLE := [Color("#b07aff"), Color("#ff7ad1"), Color("#f0d8ff")]
const BURST_GOLD := [Color("#ffd027"), Color("#ff8a2a"), Color("#3aa8ff"), Color("#ff3aa8"), Color("#3ad6a8")]

var letters_holder: Control
var board_bg: Control
var preview_label: Label
var score_label: Label
var timer_label: Label
var timer_chip: Control
var wave_label: Label
var lives_label: Label
var combo_label: Label
var goal_label: Label
var target_label: Label
var powers_label: Label
var found_label: Label
var found_pills_row: HFlowContainer
var line: Line2D
var line_glow: Line2D
var back_btn: Button
var toast: Label
var word_card: PanelContainer
var xp_preview_label: Label
var shuffle_btn: Button
var mascot: Control
var mascot_icon: TextureRect
var mascot_speech: PanelContainer
var mascot_speech_label: Label
var dim_overlay: ColorRect
var _line_phase: float = 0.0
var _word_card_style: StyleBoxFlat
var _word_card_flash_id: int = 0

var _letters: Array[WMLetter] = []
var _chain: Array[WMLetter] = []   # ordered nodes selected
var _time_left: float = WAVE_TIME_SEC
var _running: bool = false
var _score: int = 0
var _found: Dictionary = {}        # word -> true
var _found_order: Array = []       # in order discovered, for results screen
var _fever_words: Dictionary = {}
var _is_dragging: bool = false
var _is_shuffling: bool = false
var _submittable_announced: bool = false
var _last_timer_second: int = -1
var _idle_phase: float = 0.0
var _pool: String = ""             # current round pool
var _used_pools: Array = []        # pools already used this session
var _dictionary_pools_by_length: Dictionary = {}
var _possible_words: Array = []    # all formable words from pool (length-desc)
var _wave: int = 1
var _lives: int = MAX_LIVES_INTERMEDIATE
var _max_lives: int = MAX_LIVES_INTERMEDIATE
var _wave_failures: int = 0
var _carry_time: float = 0.0
var _wave_score_start: int = 0
var _wave_words_start: int = 0
var _wave_invalids: int = 0
var _wave_lives_lost: int = 0
var _combo: int = 0
var _best_combo_this_wave: int = 0
var _combo_time_left: float = 0.0
var _fever_active: bool = false
var _fever_pause_left: float = 0.0
var _goal_type: String = "word_count"
var _goal_target: int = 0
var _goal_progress: int = 0
var _speed_words: int = 0
var _speed_time_left: float = 0.0
var _wave_transitioning: bool = false
var _target_word: String = ""
var _target_found: bool = false
var _secret_words: Dictionary = {}
var _powerups: Array[String] = []
var _used_special_this_wave: bool = false
var _fire_tile: WMLetter
var _poison_tile: WMLetter
var _fire_time_left: float = 0.0
var _poison_time_left: float = 0.0
var _double_xp_left: float = 0.0
var _freeze_left: float = 0.0

func _ready() -> void:
	_build_ui()
	back_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	line.width = 8
	line.default_color = Color(1.0, 0.45, 0.75, 0.9)
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	_start_round()

# ---------------- UI construction (wm_game layout) ----------------

func _build_ui() -> void:
	Chrome.bg_layer(self)
	back_btn = Chrome.header(self, "Word Match")
	_build_mascot()

	# Top stack (HUD chips, found card, current word).
	var top := VBoxContainer.new()
	top.anchor_right = 1.0
	top.offset_left = 16
	top.offset_top = Chrome.HEADER_H + 24
	top.offset_right = -16
	top.offset_bottom = 366
	top.add_theme_constant_override("separation", 8)
	add_child(top)

	# Timer + XP chips row.
	var hud := HFlowContainer.new()
	hud.add_theme_constant_override("h_separation", 6)
	hud.add_theme_constant_override("v_separation", 6)
	wave_label = _hud_chip("W1", VIBRANT_BLUE, Color.WHITE, VIBRANT_BLUE_DARK, "res://assets/icons/wave.svg")
	hud.add_child(wave_label.get_parent().get_parent())
	timer_label = _hud_chip("2:00", VIBRANT_BLUE, Color.WHITE, VIBRANT_BLUE_DARK, "res://assets/icons/clock.svg")
	timer_chip = timer_label.get_parent().get_parent() as Control
	hud.add_child(timer_chip)
	lives_label = _hud_chip("3", ERROR_RED, Color.WHITE, Color("#a21d2d"), "res://assets/icons/heart_broken.svg")
	hud.add_child(lives_label.get_parent().get_parent())
	score_label = _hud_chip("0 XP", VIBRANT_GOLD, VIBRANT_GOLD_DARK, Color("#dba830"), "res://assets/icons/star.svg")
	hud.add_child(score_label.get_parent().get_parent())
	top.add_child(hud)

	# Found-words card — dark vibrant card matching the board palette.
	var found_card := PanelContainer.new()
	var found_sb := StyleBoxFlat.new()
	found_sb.bg_color = DARK_CARD
	found_sb.set_corner_radius_all(14)
	found_sb.set_border_width_all(2)
	found_sb.border_color = DARK_CARD_BORDER
	found_sb.shadow_color = Color(0, 0, 0, 0.25)
	found_sb.shadow_size = 4
	found_sb.shadow_offset = Vector2i(0, 2)
	found_sb.content_margin_left = 12
	found_sb.content_margin_right = 12
	found_sb.content_margin_top = 8
	found_sb.content_margin_bottom = 8
	found_card.add_theme_stylebox_override("panel", found_sb)
	var found_box := VBoxContainer.new()
	found_box.add_theme_constant_override("separation", 2)
	found_label = Label.new()
	found_label.text = "Found: 0"
	found_label.add_theme_color_override("font_color", Color("#ffd027"))
	found_label.add_theme_font_size_override("font_size", 14)
	found_box.add_child(found_label)
	combo_label = Label.new()
	combo_label.text = "Combo: x1"
	combo_label.add_theme_color_override("font_color", Color("#ffb347"))
	combo_label.add_theme_font_size_override("font_size", 14)
	found_box.add_child(combo_label)
	goal_label = Label.new()
	goal_label.text = "Goal"
	goal_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	goal_label.add_theme_color_override("font_color", Color.WHITE)
	goal_label.add_theme_font_size_override("font_size", 14)
	found_box.add_child(goal_label)
	target_label = Label.new()
	target_label.text = "Target: _ _ _"
	target_label.add_theme_color_override("font_color", Color("#a7f8ff"))
	target_label.add_theme_font_size_override("font_size", 13)
	found_box.add_child(target_label)
	powers_label = Label.new()
	powers_label.text = "Power-ups: -"
	powers_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	powers_label.add_theme_color_override("font_color", Color("#d8ffd8"))
	powers_label.add_theme_font_size_override("font_size", 12)
	found_box.add_child(powers_label)
	found_pills_row = HFlowContainer.new()
	found_pills_row.add_theme_constant_override("h_separation", 4)
	found_pills_row.add_theme_constant_override("v_separation", 4)
	found_box.add_child(found_pills_row)
	found_card.add_child(found_box)
	top.add_child(found_card)

	# Current-word pill — vibrant magenta, mirrors the drag line / selected tiles.
	word_card = PanelContainer.new()
	var word_sb := StyleBoxFlat.new()
	word_sb.bg_color = VIBRANT_MAGENTA
	word_sb.set_corner_radius_all(24)
	word_sb.set_border_width_all(3)
	word_sb.border_color = VIBRANT_MAGENTA_DARK
	word_sb.shadow_color = Color(1.0, 0.4, 0.7, 0.45)
	word_sb.shadow_size = 6
	word_sb.shadow_offset = Vector2i(0, 2)
	word_sb.content_margin_top = 8
	word_sb.content_margin_bottom = 8
	_word_card_style = word_sb
	word_card.add_theme_stylebox_override("panel", word_sb)
	var word_stack := VBoxContainer.new()
	word_stack.add_theme_constant_override("separation", 2)
	preview_label = Label.new()
	preview_label.text = "—"
	preview_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	preview_label.add_theme_color_override("font_color", Color.WHITE)
	preview_label.add_theme_color_override("font_outline_color", Color(0.5, 0, 0.2, 0.55))
	preview_label.add_theme_constant_override("outline_size", 4)
	preview_label.add_theme_font_size_override("font_size", 24)
	word_stack.add_child(preview_label)
	xp_preview_label = Label.new()
	xp_preview_label.text = ""
	xp_preview_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	xp_preview_label.add_theme_color_override("font_color", Color("#d8ffd8"))
	xp_preview_label.add_theme_font_size_override("font_size", 13)
	xp_preview_label.modulate.a = 0.0
	word_stack.add_child(xp_preview_label)
	word_card.add_child(word_stack)
	top.add_child(word_card)

	# Animated vibrant backdrop stretches to fill the area between the top
	# stack and the footer hint — the previously-fixed 444×444 box left big
	# empty bands on tall screens. The ring's radius is derived from the
	# holder size, so a larger holder = larger ring automatically.
	const BOARD_AREA_TOP := 304   # below the compact HUD + found card + current-word pill
	const BOARD_AREA_BOTTOM := -48  # above the footer hint
	const BOARD_AREA_INSET := 8
	board_bg = Fx.BoardBG.new()
	board_bg.radius = 28.0
	board_bg.anchor_left = 0.0
	board_bg.anchor_right = 1.0
	board_bg.anchor_top = 0.0
	board_bg.anchor_bottom = 1.0
	board_bg.offset_left = BOARD_AREA_INSET
	board_bg.offset_top = Chrome.HEADER_H + BOARD_AREA_TOP
	board_bg.offset_right = -BOARD_AREA_INSET
	board_bg.offset_bottom = BOARD_AREA_BOTTOM
	board_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(board_bg)

	# Letters holder shares the same rect so taps land naturally over the ring.
	letters_holder = Control.new()
	letters_holder.anchor_left = 0.0
	letters_holder.anchor_right = 1.0
	letters_holder.anchor_top = 0.0
	letters_holder.anchor_bottom = 1.0
	letters_holder.offset_left = BOARD_AREA_INSET
	letters_holder.offset_top = Chrome.HEADER_H + BOARD_AREA_TOP
	letters_holder.offset_right = -BOARD_AREA_INSET
	letters_holder.offset_bottom = BOARD_AREA_BOTTOM
	letters_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(letters_holder)

	# Shuffle button — center of the letter ring.
	shuffle_btn = Button.new()
	shuffle_btn.text = ""
	shuffle_btn.focus_mode = Control.FOCUS_NONE
	shuffle_btn.custom_minimum_size = Vector2(56, 56)
	var shuf_icon_path := "res://assets/icons/shuffle.svg"
	if ResourceLoader.exists(shuf_icon_path):
		shuffle_btn.icon = load(shuf_icon_path)
		shuffle_btn.expand_icon = true
		shuffle_btn.add_theme_constant_override("icon_max_width", 24)
	else:
		shuffle_btn.text = "Mix"
		shuffle_btn.add_theme_font_size_override("font_size", 16)
	shuffle_btn.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	var shuf_sb := StyleBoxFlat.new()
	shuf_sb.bg_color = Color(0.08, 0.06, 0.14, 0.75)
	shuf_sb.set_corner_radius_all(28)
	shuf_sb.set_border_width_all(2)
	shuf_sb.border_color = Color(1, 1, 1, 0.15)
	shuf_sb.content_margin_left = 14
	shuf_sb.content_margin_right = 14
	shuf_sb.content_margin_top = 14
	shuf_sb.content_margin_bottom = 14
	var shuf_press := shuf_sb.duplicate() as StyleBoxFlat
	shuf_press.bg_color = Color(0.18, 0.12, 0.30, 0.9)
	shuffle_btn.add_theme_stylebox_override("normal", shuf_sb)
	shuffle_btn.add_theme_stylebox_override("hover", shuf_sb)
	shuffle_btn.add_theme_stylebox_override("pressed", shuf_press)
	shuffle_btn.add_theme_stylebox_override("focus", shuf_sb)
	shuffle_btn.pressed.connect(_shuffle_letters)
	letters_holder.add_child(shuffle_btn)

	# Drag line — glow underlay + bright magenta core (sibling so it draws above letters).
	line_glow = Line2D.new()
	line_glow.width = 18
	line_glow.default_color = Color(1, 1, 1, 0.35)
	line_glow.joint_mode = Line2D.LINE_JOINT_ROUND
	line_glow.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line_glow.end_cap_mode = Line2D.LINE_CAP_ROUND
	add_child(line_glow)
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
	toast.add_theme_font_size_override("font_size", 24)
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
	footer.add_theme_font_size_override("font_size", 14)
	footer.add_theme_color_override("font_color", Chrome.TEXT_SEC)
	add_child(footer)

	dim_overlay = ColorRect.new()
	dim_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim_overlay.color = Color(0, 0, 0, 0.0)
	dim_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim_overlay.z_index = 260
	add_child(dim_overlay)

func _build_mascot() -> void:
	mascot = PanelContainer.new()
	mascot.custom_minimum_size = Vector2(48, 48)
	mascot.size_flags_horizontal = Control.SIZE_SHRINK_END
	mascot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mascot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var avatar_sb := StyleBoxFlat.new()
	avatar_sb.bg_color = GOLD_LIGHT
	avatar_sb.set_corner_radius_all(24)
	avatar_sb.set_border_width_all(2)
	avatar_sb.border_color = VIBRANT_GOLD
	avatar_sb.shadow_color = Color(VIBRANT_GOLD.r, VIBRANT_GOLD.g, VIBRANT_GOLD.b, 0.2)
	avatar_sb.shadow_size = 4
	avatar_sb.shadow_offset = Vector2i(0, 2)
	avatar_sb.content_margin_left = 4
	avatar_sb.content_margin_top = 4
	avatar_sb.content_margin_right = 4
	avatar_sb.content_margin_bottom = 4
	(mascot as PanelContainer).add_theme_stylebox_override("panel", avatar_sb)
	var header_row := back_btn.get_parent() as HBoxContainer
	if header_row != null:
		header_row.add_child(mascot)
	else:
		add_child(mascot)

	mascot_icon = TextureRect.new()
	var path := "res://assets/avatars/%s.svg" % GameState.player_avatar
	if ResourceLoader.exists(path):
		mascot_icon.texture = load(path)
	mascot_icon.custom_minimum_size = Vector2(40, 40)
	mascot_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mascot_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mascot_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mascot.add_child(mascot_icon)

func _hud_chip(text: String, bg: Color, fg: Color, border: Color = Color(0, 0, 0, 0), icon_path: String = "") -> Label:
	# Returns the inner Label so the caller can update text. The parent is an
	# HBoxContainer (icon + label) wrapped in the PanelContainer; callers that
	# need the chip Control use lbl.get_parent().get_parent().
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(99)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	sb.shadow_color = Color(0, 0, 0, 0.22)
	sb.shadow_size = 4
	sb.shadow_offset = Vector2i(0, 2)
	if border.a > 0:
		sb.set_border_width_all(2)
		sb.border_color = border
	p.add_theme_stylebox_override("panel", sb)
	p.custom_minimum_size = Vector2(78, 0)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	p.add_child(row)
	if icon_path != "" and ResourceLoader.exists(icon_path):
		var icon := TextureRect.new()
		icon.texture = load(icon_path)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.custom_minimum_size = Vector2(16, 16)
		icon.modulate = fg
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(icon)
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 15)
	lbl.add_theme_color_override("font_color", fg)
	row.add_child(lbl)
	return lbl

func _start_round() -> void:
	_score = 0
	_wave = 1
	_max_lives = MAX_LIVES_INTERMEDIATE if GameState.mode == GameState.Mode.INTERMEDIATE else MAX_LIVES_ADVANCED
	_lives = _max_lives
	_wave_failures = 0
	_carry_time = 0.0
	_combo = 0
	_combo_time_left = 0.0
	_fever_active = false
	_powerups.clear()
	_running = true
	_found.clear()
	_found_order.clear()
	if dim_overlay != null:
		dim_overlay.color = Color(0, 0, 0, 0.0)
	_start_wave()

func _start_wave() -> void:
	_wave_transitioning = false
	_time_left = WAVE_TIME_SEC + _carry_time
	_carry_time = 0.0
	_submittable_announced = false
	_last_timer_second = int(ceil(_time_left))
	_wave_score_start = _score
	_wave_words_start = _found_order.size()
	_wave_invalids = 0
	_wave_lives_lost = 0
	_best_combo_this_wave = 0
	_goal_progress = 0
	_speed_words = 0
	_speed_time_left = 10.0
	_target_found = false
	_used_special_this_wave = false
	_fire_tile = null
	_poison_tile = null
	_fire_time_left = 0.0
	_poison_time_left = 0.0
	_select_goal()
	_spawn_wave()
	_pick_targets()
	_refresh_hud()
	_refresh_found()
	_refresh_goal_ui()
	preview_label.text = "—"
	_update_xp_preview()
	_reset_word_card_style()

func _spawn_wave() -> void:
	for c in _letters:
		c.queue_free()
	_letters.clear()
	_chain.clear()
	var picked := _pick_pool_with_words()
	var pool: String = picked.pool
	_pool = pool
	_possible_words = picked.words
	_spawn_letters(pool)
	_layout_letters()

func _pick_pool_with_words() -> Dictionary:
	var lengths := POOL_LENGTHS.duplicate()
	lengths.shuffle()
	for length: int in lengths:
		var picked := _pick_pool_for_length(length, false)
		if not picked.is_empty():
			return picked
	_used_pools.clear()
	for length: int in lengths:
		var picked := _pick_pool_for_length(length, true)
		if not picked.is_empty():
			return picked
	var fallback := str(POOLS_7.pick_random())
	return {"pool": fallback, "words": _sorted_possible_words(fallback)}

func _pick_pool_for_length(length: int, allow_used: bool) -> Dictionary:
	var src := _dictionary_pool_source(length)
	src.shuffle()
	for p: String in src:
		if not allow_used and _used_pools.has(p):
			continue
		var words := _sorted_possible_words(p)
		if _pool_supports_wave(words):
			_used_pools.append(p)
			return {"pool": p, "words": words}
	return {}

func _dictionary_pool_source(length: int) -> Array[String]:
	if _dictionary_pools_by_length.has(length):
		var cached: Array[String] = []
		for p: String in _dictionary_pools_by_length[length]:
			cached.append(p)
		return cached
	var pools: Array[String] = []
	for w: String in Words.words_of_length(length):
		var pool := w.to_upper()
		if _is_pool_candidate(pool):
			pools.append(pool)
	if pools.is_empty():
		pools = _fallback_pools_for_length(length)
	_dictionary_pools_by_length[length] = pools
	return pools.duplicate()

func _fallback_pools_for_length(length: int) -> Array[String]:
	match length:
		6:
			return POOLS_6.duplicate()
		8:
			return POOLS_8.duplicate()
		_:
			return POOLS_7.duplicate()

func _is_pool_candidate(pool: String) -> bool:
	if not POOL_LENGTHS.has(pool.length()) or _count_vowels_text(pool) < 2:
		return false
	for i in pool.length():
		var code := pool.unicode_at(i)
		if code < 65 or code > 90:
			return false
	return true

func _count_vowels_text(text: String) -> int:
	var v := 0
	for ch in text:
		if "AEIOU".find(ch) != -1:
			v += 1
	return v

func _sorted_possible_words(pool: String) -> Array[String]:
	var words: Array[String] = Words.words_from_letters(pool, MIN_WORD_LEN, false)
	words.sort_custom(func(a, b):
		if a.length() != b.length():
			return a.length() > b.length()
		return a < b
	)
	return words

func _pool_supports_wave(words: Array[String]) -> bool:
	if words.size() < maxi(8, _goal_target + 3):
		return false
	if _goal_type == "long_words":
		var long_count := 0
		for w: String in words:
			if w.length() >= 4:
				long_count += 1
		return long_count >= _goal_target
	for w: String in words:
		if w.length() >= 4:
			return true
	return false

func _select_goal() -> void:
	var goals := GOAL_TYPES.duplicate()
	if _wave < 4:
		goals.erase("use_special")
	goals.shuffle()
	_goal_type = goals[0]
	match _goal_type:
		"word_count":
			_goal_target = 4 + mini(_wave / 3, 4)
		"long_words":
			_goal_target = 2 + mini(_wave / 5, 3)
		"xp_target":
			_goal_target = int(120.0 * _wave_multiplier())
		"speed_burst":
			_goal_target = 3
			_speed_time_left = 10.0
		"use_special":
			_goal_target = 1
		"no_mistakes":
			_goal_target = 4 + mini(_wave / 4, 3)
		_:
			_goal_target = 4

func _pick_targets() -> void:
	_target_word = ""
	_secret_words.clear()
	var choices: Array = []
	for w: String in _possible_words:
		if w.length() >= 4:
			choices.append(w)
	if choices.is_empty():
		choices = _possible_words.duplicate()
	if not choices.is_empty():
		choices.shuffle()
		_target_word = str(choices[0])
	var secrets: Array = []
	var themed := []
	for key in SECRET_WORDS.keys():
		themed.append_array(SECRET_WORDS[key])
	for w: String in _possible_words:
		if w == _target_word:
			continue
		if w.length() >= 5 or themed.has(w):
			secrets.append(w)
	secrets.shuffle()
	for i in mini(3, secrets.size()):
		_secret_words[secrets[i]] = true

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
		n.letter_selected_fx.connect(_on_letter_selected_fx)
		letters_holder.add_child(n)
		_letters.append(n)
	_assign_special_tiles()

func _assign_special_tiles() -> void:
	for n in _letters:
		n.tile_kind = WMLetter.TileKind.REGULAR
	var special_count := _special_count_for_wave()
	var candidates := _letters.duplicate()
	candidates.shuffle()
	if _powerups.has("Wild") and not candidates.is_empty():
		var wild: WMLetter = candidates.pop_back()
		wild.tile_kind = WMLetter.TileKind.WILD
		_powerups.erase("Wild")
	if _wave >= 4 and special_count > 0 and not candidates.is_empty():
		_fire_tile = candidates.pop_back()
		_fire_tile.tile_kind = WMLetter.TileKind.FIRE
		_fire_time_left = _fire_timer_for_wave()
		special_count -= 1
	if ((GameState.mode == GameState.Mode.ADVANCED and _wave >= 2) or _wave >= 4) and special_count > 0 and not candidates.is_empty():
		_poison_tile = candidates.pop_back()
		_poison_tile.tile_kind = WMLetter.TileKind.POISON
		_poison_time_left = 20.0
		special_count -= 1
	if _wave >= 2 and special_count > 0 and not candidates.is_empty():
		candidates.pop_back().tile_kind = WMLetter.TileKind.GOLD
		special_count -= 1
	if _combo >= 3 and special_count > 0 and not candidates.is_empty():
		candidates.pop_back().tile_kind = WMLetter.TileKind.DIAMOND

func _special_count_for_wave() -> int:
	if _wave <= 3:
		return 0
	if _wave <= 6:
		return 1
	if _wave <= 10:
		return 1 + int(randf() < 0.45)
	if _wave <= 15:
		return 2
	return 2 + int(randf() < 0.45)

func _fire_timer_for_wave() -> float:
	if GameState.mode == GameState.Mode.ADVANCED:
		return 20.0
	if _wave >= 16:
		return 15.0
	if _wave >= 11:
		return 20.0
	if _wave >= 7:
		return 25.0
	return 30.0

func _on_letter_selected_fx(node: WMLetter, color: Color) -> void:
	var pos := node.global_position + node.size * 0.5 - global_position
	Fx.sparkle_burst(self, pos, color, 3)

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
	await get_tree().process_frame
	var center := letters_holder.size * 0.5
	var radius: float = minf(letters_holder.size.x, letters_holder.size.y) * 0.5 - LETTER_SCENE_SIZE * 0.5 - 8.0
	var n := _letters.size()
	for i in n:
		var angle := -PI * 0.5 + TAU * float(i) / float(n)
		var pos := center + Vector2(cos(angle), sin(angle)) * radius
		var node := _letters[i]
		node.position = pos - Vector2(LETTER_SCENE_SIZE, LETTER_SCENE_SIZE) * 0.5
		node.set_meta("rest_pos", node.position)
		node.play_pop_in(i * 0.05)
	if shuffle_btn != null:
		shuffle_btn.position = center - shuffle_btn.size * 0.5

func _shuffle_letters() -> void:
	if not _running or _is_dragging:
		return
	_is_shuffling = true
	_set_letters_to_rest()
	Audio.play("wm_pop", 0.02, 0.8, -4.0)
	_letters.shuffle()
	var center := letters_holder.size * 0.5
	var radius: float = minf(letters_holder.size.x, letters_holder.size.y) * 0.5 - LETTER_SCENE_SIZE * 0.5 - 8.0
	var n := _letters.size()
	for i in n:
		var angle := -PI * 0.5 + TAU * float(i) / float(n)
		var target := center + Vector2(cos(angle), sin(angle)) * radius - Vector2(LETTER_SCENE_SIZE, LETTER_SCENE_SIZE) * 0.5
		var tw := _letters[i].create_tween()
		tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(_letters[i], "position", target, 0.3)
		_letters[i].set_meta("rest_pos", target)
	if shuffle_btn != null:
		var tw := shuffle_btn.create_tween()
		tw.tween_property(shuffle_btn, "rotation", shuffle_btn.rotation + TAU, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		shuffle_btn.pivot_offset = shuffle_btn.size * 0.5
	await get_tree().create_timer(0.36).timeout
	_is_shuffling = false

func _process(delta: float) -> void:
	# Pulse the drag line continuously while it has points.
	_line_phase += delta * 4.0
	_idle_phase += delta
	if line != null and line.get_point_count() > 0:
		var pulse: float = 0.7 + 0.3 * (0.5 + 0.5 * sin(_line_phase))
		line.default_color = Color(1.0, 0.45, 0.75, pulse)
		line.width = 8 + 2 * sin(_line_phase * 0.6)
	_update_idle_letters()
	if not _running or _wave_transitioning:
		return
	_update_combo_timer(delta)
	_update_special_timers(delta)
	if _goal_type == "speed_burst" and _goal_progress < _goal_target:
		_speed_time_left = maxf(0.0, _speed_time_left - delta)
		if _speed_time_left <= 0.0:
			_speed_words = 0
			_goal_progress = 0
			_speed_time_left = 10.0
	if _double_xp_left > 0.0:
		_double_xp_left = maxf(0.0, _double_xp_left - delta)
	if _freeze_left > 0.0:
		_freeze_left = maxf(0.0, _freeze_left - delta)
	elif _fever_pause_left > 0.0:
		_fever_pause_left = maxf(0.0, _fever_pause_left - delta)
	else:
		_time_left -= delta
	if _time_left <= 0:
		_time_left = 0
		_fail_wave("Time!")
	_refresh_hud()

func _update_combo_timer(delta: float) -> void:
	if _combo <= 0 or _is_dragging:
		return
	_combo_time_left = maxf(0.0, _combo_time_left - delta)
	if _combo_time_left <= 0.0:
		_break_combo(true)

func _update_special_timers(delta: float) -> void:
	if _fire_tile != null:
		_fire_time_left = maxf(0.0, _fire_time_left - delta)
		if _fire_time_left <= 0.0:
			var burned := _fire_tile
			_fire_tile = null
			burned.tile_kind = WMLetter.TileKind.REGULAR
			_lose_life("Fire burned out")
	if _poison_tile != null:
		_poison_time_left = maxf(0.0, _poison_time_left - delta)
		if _poison_time_left <= 0.0:
			var expired := _poison_tile
			_poison_tile = null
			expired.tile_kind = WMLetter.TileKind.REGULAR
			_lose_life("Poison expired")
	_refresh_goal_ui()

func _refresh_hud() -> void:
	var m := int(_time_left) / 60
	var s := int(_time_left) % 60
	timer_label.text = "%d:%02d" % [m, s]
	score_label.text = "%d XP" % _score
	if wave_label != null:
		wave_label.text = "W%d" % _wave
	if lives_label != null:
		lives_label.text = "%d" % _lives
	if combo_label != null:
		var suffix := " FEVER" if _fever_active else ""
		combo_label.text = "Combo: x%d%s" % [maxi(1, _combo), suffix]
	var sec_left := int(ceil(_time_left))
	if sec_left != _last_timer_second:
		_last_timer_second = sec_left
		_on_timer_second(sec_left)
	# Shift the timer color as pressure rises.
	if timer_chip != null:
		if _time_left <= 10.0 and _running:
			var pulse: float = 0.72 + 0.28 * sin(Engine.get_process_frames() * 0.28)
			timer_chip.modulate = Color(1.0, pulse * 0.55, pulse * 0.55, 1.0)
		elif _time_left <= 30.0 and _running:
			timer_chip.modulate = Color(1.0, 0.78, 0.42, 1.0)
		else:
			timer_chip.modulate = Color(1, 1, 1, 1)

func _refresh_found() -> void:
	found_label.text = "Found: %d" % _found.size()
	# Replace pill row contents.
	for c in found_pills_row.get_children():
		c.queue_free()
	if _found.is_empty():
		return
	var start_idx := maxi(0, _found_order.size() - 4)
	for i in range(start_idx, _found_order.size()):
		var w: String = _found_order[i]
		var shown := ("FIRE " if _fever_words.has(w.to_lower()) else "") + w
		found_pills_row.add_child(UI.pill(shown, Color("#ffd027"), Color("#3a2a78")))

func _refresh_goal_ui() -> void:
	if goal_label != null:
		goal_label.text = "Goal: %s" % _goal_text()
	if target_label != null:
		var hint := _target_silhouette()
		target_label.text = "Target: %s" % hint
	if powers_label != null:
		var bits: Array[String] = []
		for p in _powerups:
			bits.append(str(p))
		if _fire_tile != null:
			bits.append("Fire %.0fs" % _fire_time_left)
		if _poison_tile != null:
			bits.append("Poison %.0fs" % _poison_time_left)
		if _double_xp_left > 0.0:
			bits.append("Double %.0fs" % _double_xp_left)
		if _freeze_left > 0.0:
			bits.append("Freeze %.0fs" % _freeze_left)
		powers_label.text = "Power-ups: %s" % (" - " if bits.is_empty() else ", ".join(bits))

func _goal_text() -> String:
	match _goal_type:
		"word_count":
			return "Find %d words (%d/%d)" % [_goal_target, _goal_progress, _goal_target]
		"long_words":
			return "Find %d words of 4+ letters (%d/%d)" % [_goal_target, _goal_progress, _goal_target]
		"xp_target":
			return "Earn %d XP this wave (%d/%d)" % [_goal_target, _goal_progress, _goal_target]
		"speed_burst":
			return "Find 3 words in 10s (%d/3, %.0fs)" % [_speed_words, maxf(_speed_time_left, 0)]
		"use_special":
			return "Use a special tile (%d/1)" % _goal_progress
		"no_mistakes":
			return "Find %d words with no mistakes (%d/%d)" % [_goal_target, _goal_progress, _goal_target]
		_:
			return "Find words"

func _target_silhouette() -> String:
	if _target_word.is_empty():
		return "-"
	if _target_found:
		return _target_word.to_upper()
	var parts: Array[String] = []
	for i in _target_word.length():
		if GameState.mode == GameState.Mode.INTERMEDIATE and i == 0:
			parts.append(_target_word.substr(0, 1).to_upper())
		else:
			parts.append("_")
	return " ".join(parts)

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
	_submittable_announced = false
	_set_letters_to_rest()
	for n in _chain:
		n.selected = false
	_chain.clear()
	_handle_chain_feedback(_try_add_letter_at(gpos))
	_update_line(gpos)
	_update_preview()

func _continue_drag(gpos: Vector2) -> void:
	if not _is_dragging:
		return
	_handle_chain_feedback(_try_add_letter_at(gpos))
	_update_line(gpos)
	_update_preview()

func _end_drag() -> void:
	if not _is_dragging:
		return
	_is_dragging = false
	line.clear_points()
	line_glow.clear_points()
	var chain_nodes := _chain.duplicate()
	# Capture chain positions for confetti BEFORE deselect.
	var chain_positions: Array = []
	var chain_colors: Array = []
	for n in chain_nodes:
		chain_positions.append(n.global_position + n.size * 0.5 - global_position)
		var g := Fx.gradient_for_letter(n.letter)
		chain_colors.append(g[1])
		n.selected = false
	_chain.clear()
	if chain_nodes.size() < MIN_WORD_LEN:
		_short_drag_feedback()
		preview_label.text = "—"
		_update_xp_preview()
		return
	var word := _resolve_chain_word(chain_nodes)
	if word.is_empty():
		_invalid_word_feedback()
		preview_label.text = "—"
		_update_xp_preview()
		return
	_submit(word.to_upper(), chain_positions, chain_colors, chain_nodes)
	preview_label.text = "—"
	_update_xp_preview()

func _try_add_letter_at(gpos: Vector2) -> int:
	for n in _letters:
		if n.contains_point(gpos):
			if _chain.size() >= 2 and _chain[-2] == n:
				var popped: WMLetter = _chain.pop_back()
				popped.selected = false
				return -1
			if _chain.has(n):
				return 0
			_chain.append(n)
			n.selected = true
			return 1
	return 0

func _handle_chain_feedback(change: int) -> void:
	if change == 1:
		if _chain.size() == 1:
			Audio.play("wm_pop", 0.02, 1.0, -3.0)
			_haptic(18, 0.22)
		else:
			var semitone := pow(2.0, float(_chain.size() - 1) / 12.0)
			Audio.play("select", 0.02, semitone, -2.5)
		if _chain.size() >= MIN_WORD_LEN and not _submittable_announced:
			_submittable_announced = true
			_pulse_ready_state()
	elif change == -1:
		Audio.play("wm_thud", 0.01, 1.0, -9.0)
	_update_xp_preview()

func _pulse_ready_state() -> void:
	Audio.play("wm_ready", 0.01, 1.0, -1.5)
	_haptic(20, 0.28)
	var tw := create_tween()
	for i in 2:
		tw.tween_callback(func(): _set_word_card_style(VIBRANT_MAGENTA, READY_GREEN, Color(0.25, 1.0, 0.45, 0.6)))
		tw.tween_interval(0.08)
		tw.tween_callback(_reset_word_card_style)
		tw.tween_interval(0.08)

func _update_line(cursor_gpos: Vector2) -> void:
	line.clear_points()
	line_glow.clear_points()
	for n in _chain:
		var center := n.global_position + n.size * 0.5
		var pt := line.to_local(center)
		line.add_point(pt)
		line_glow.add_point(line_glow.to_local(center))
	if _is_dragging:
		line.add_point(line.to_local(cursor_gpos))
		line_glow.add_point(line_glow.to_local(cursor_gpos))

func _current_word() -> String:
	var s := ""
	for n in _chain:
		if n.tile_kind == WMLetter.TileKind.WILD:
			s += "*"
		elif n.tile_kind == WMLetter.TileKind.POISON:
			s += "?"
		else:
			s += n.letter
	return s

func _update_preview() -> void:
	var w := _current_word()
	Fx.fit_label_font(preview_label, w if not w.is_empty() else "—", 28, maxf(get_viewport_rect().size.x - 48.0, 120.0))

# -------- scoring --------

func _resolve_chain_word(chain_nodes: Array) -> String:
	var raw := ""
	var has_wildcards := false
	for n: WMLetter in chain_nodes:
		raw += n.letter
		if n.tile_kind == WMLetter.TileKind.WILD or n.tile_kind == WMLetter.TileKind.POISON:
			has_wildcards = true
	if not has_wildcards:
		return raw if Words.is_valid(raw.to_lower()) else ""
	var candidates: Array[String] = []
	for w: String in _possible_words:
		if w.length() == chain_nodes.size() and _chain_matches_word(chain_nodes, w):
			candidates.append(w)
	candidates.sort_custom(func(a, b):
		var af := _found.has(a)
		var bf := _found.has(b)
		if af != bf:
			return not af
		return a < b
	)
	if not candidates.is_empty():
		return candidates[0].to_upper()
	return raw if Words.is_valid(raw.to_lower()) and _chain_matches_word(chain_nodes, raw.to_lower()) else ""

func _chain_matches_word(chain_nodes: Array, word: String) -> bool:
	if chain_nodes.size() != word.length():
		return false
	for i in chain_nodes.size():
		var n: WMLetter = chain_nodes[i]
		var ch := word.substr(i, 1).to_upper()
		match n.tile_kind:
			WMLetter.TileKind.WILD:
				continue
			WMLetter.TileKind.POISON:
				if "AEIOU".find(ch) == -1:
					return false
			_:
				if n.letter != ch:
					return false
	return true

func _submit(word_upper: String, chain_positions: Array = [], chain_colors: Array = [], chain_nodes: Array = []) -> void:
	var word := word_upper.to_lower()
	if _found.has(word):
		_already_found_feedback(word_upper)
		return
	if not Words.is_valid(word):
		_invalid_word_feedback()
		return
	_found[word] = true
	_found_order.append(word.to_upper())
	var combo_level := _advance_combo()
	var raw_earned := _score_word(word, chain_nodes, combo_level)
	var earned := _award_xp(raw_earned)
	_score += earned
	_update_goal_progress(word, earned, chain_nodes)
	_apply_tile_effects(chain_nodes)
	_refresh_hud()
	_refresh_found()
	_refresh_goal_ui()
	_show_toast("+%d XP   %s" % [earned, word_upper], Palette.GREEN)
	_success_feedback(word_upper, earned, chain_positions, chain_colors)
	if word == _target_word and not _target_found:
		_target_found = true
		_target_reward(word)
	if _secret_words.has(word):
		_secret_words.erase(word)
		_secret_reward(word)
	if _goal_complete():
		_clear_wave()
	elif _running and _all_words_found():
		_clear_wave()

func _score_word(word: String, chain_nodes: Array, combo_level: int) -> int:
	var base := _base_score_for_len(word.length())
	var total := float(base) * _special_multiplier(chain_nodes) * _combo_multiplier(combo_level) * _wave_multiplier()
	if _fever_active:
		total *= 2.0
	if _double_xp_left > 0.0:
		total *= 2.0
	if word == _target_word and not _target_found:
		total += float(_target_bonus_for_len(word.length()))
	if _secret_words.has(word):
		total += float(word.length() * 25)
	return maxi(1, int(round(total)))

func _award_xp(raw_amount: int) -> int:
	var base_for_state := int(round(float(raw_amount) / GameState.mode_multiplier()))
	return GameState.add_xp("word_match", maxi(1, base_for_state))

func _base_score_for_len(length: int) -> int:
	return int(BASE_LENGTH_SCORE.get(length, length * 20))

func _target_bonus_for_len(length: int) -> int:
	return int(TARGET_REWARD.get(length, length * 80))

func _special_multiplier(chain_nodes: Array) -> float:
	var mult := 1.0
	for n: WMLetter in chain_nodes:
		match n.tile_kind:
			WMLetter.TileKind.FIRE:
				mult *= 1.5
			WMLetter.TileKind.GOLD:
				mult *= 2.0
			WMLetter.TileKind.DIAMOND:
				mult *= 3.0
	return mult

func _combo_multiplier(combo_level: int = -1) -> float:
	var level := _combo if combo_level < 0 else combo_level
	if level >= 5:
		return 3.0
	if level == 4:
		return 2.5
	if level == 3:
		return 2.0
	if level == 2:
		return 1.5
	return 1.0

func _wave_multiplier() -> float:
	if _wave >= 16:
		return 2.5
	if _wave >= 11:
		return 2.0
	if _wave >= 7:
		return 1.5
	if _wave >= 4:
		return 1.2
	return 1.0

func _combo_window() -> float:
	return COMBO_WINDOW_INTERMEDIATE if GameState.mode == GameState.Mode.INTERMEDIATE else COMBO_WINDOW_ADVANCED

func _advance_combo() -> int:
	_combo += 1
	_combo_time_left = _combo_window()
	_best_combo_this_wave = maxi(_best_combo_this_wave, _combo)
	if _combo == 3:
		_add_powerup("Shuffle")
		_mascot_react("Combo x3")
	elif _combo == 4:
		_add_powerup("Wild")
		Fx.banner(self, "WILD EARNED", Color("#ff7ad1"), Color.WHITE)
	elif _combo == 5:
		_start_fever()
	return _combo

func _break_combo(natural: bool) -> void:
	if _combo >= 4 and natural:
		var bonus := _award_xp(_combo * 15)
		_score += bonus
		_show_toast("Combo bonus +%d" % bonus, VIBRANT_GOLD)
	_combo = 0
	_combo_time_left = 0.0
	_fever_active = false
	_refresh_hud()
	_refresh_goal_ui()

func _start_fever() -> void:
	_fever_active = true
	_fever_pause_left = 4.0
	Fx.banner(self, "FEVER MODE", Color("#ffd027"), VIBRANT_MAGENTA_DARK)
	Fx.board_rim_flash(self, board_bg, Color("#ffd027"), 4)
	Audio.play("wm_success_max", 0.02, 1.08, -0.5)
	_mascot_react("Fever!")

func _apply_tile_effects(chain_nodes: Array) -> void:
	for n: WMLetter in chain_nodes:
		if n.tile_kind != WMLetter.TileKind.REGULAR:
			_used_special_this_wave = true
		match n.tile_kind:
			WMLetter.TileKind.FIRE:
				if n == _fire_tile:
					_fire_tile = null
					_fire_time_left = 0.0
				n.tile_kind = WMLetter.TileKind.REGULAR
			WMLetter.TileKind.POISON:
				if n == _poison_tile:
					_poison_tile = null
					_poison_time_left = 0.0
				n.tile_kind = WMLetter.TileKind.REGULAR
				if _lives < _max_lives:
					_lives += 1
					Fx.banner(self, "LIFE RESTORED", READY_GREEN, Color.WHITE)
			WMLetter.TileKind.WILD:
				n.tile_kind = WMLetter.TileKind.REGULAR

func _chain_uses_special(chain_nodes: Array) -> bool:
	for n: WMLetter in chain_nodes:
		if n.tile_kind != WMLetter.TileKind.REGULAR:
			return true
	return false

func _target_reward(word: String) -> void:
	Fx.banner(self, "TARGET WORD", Color("#a7f8ff"), VIBRANT_BLUE_DARK)
	if word.length() >= 7:
		if _lives < _max_lives:
			_lives += 1
		_add_powerup("Wild")
	_refresh_goal_ui()

func _secret_reward(word: String) -> void:
	Fx.banner(self, "SECRET WORD", VIBRANT_GOLD, VIBRANT_MAGENTA_DARK)
	_add_powerup("Hint")
	_mascot_react("Secret!")

func _add_powerup(name: String) -> void:
	if _powerups.has(name):
		return
	_powerups.append(name)
	_refresh_goal_ui()

func _success_feedback(word_upper: String, earned: int, chain_positions: Array, chain_colors: Array) -> void:
	var n := word_upper.length()
	var center := _word_card_center()
	var palette := BURST_BLUE
	var count := 8
	var radius := 70.0
	var sound := "wm_success_low"
	var haptic_ms := 42
	var haptic_amp := 0.42
	var include_stars := false
	var include_confetti := false
	var xp_big := false
	var xp_color := Color("#ffd027")

	if n == 4:
		palette = BURST_GREEN
		count = 10
		radius = 88.0
		sound = "wm_success_mid"
	elif n == 5:
		palette = BURST_PURPLE
		count = 14
		radius = 112.0
		sound = "wm_success_mid"
		haptic_ms = 58
		haptic_amp = 0.58
		include_stars = true
		xp_big = true
	elif n >= 6:
		palette = BURST_GOLD
		count = 24
		radius = 170.0
		sound = "wm_success_max"
		haptic_ms = 86
		haptic_amp = 0.82
		include_stars = true
		include_confetti = true
		xp_big = true

	_flash_word_card(READY_GREEN)
	Fx.word_burst(self, center, count, palette, radius, include_stars, include_confetti)
	Audio.play(sound, 0.02, 1.0, -1.0)
	_haptic(haptic_ms, haptic_amp)

	if board_bg != null:
		var popup_pos := board_bg.global_position + Vector2(board_bg.size.x * 0.5 - 20, -10) - global_position
		Fx.score_popup(self, popup_pos, "+%d" % earned, xp_big, xp_color)
	if score_label != null and not chain_positions.is_empty():
		var chip := score_label.get_parent() as Control
		var target: Vector2 = chip.global_position + chip.size * 0.5 - global_position
		Fx.confetti_to(self, chain_positions, target, chain_colors)
	if n >= 5:
		_mascot_react("Great!" if n == 5 else "Amazing!")
	if n >= 6:
		Fx.banner(self, "AMAZING!", Color("#ffd027"), VIBRANT_MAGENTA_DARK)
		Fx.board_rim_flash(self, board_bg, Color("#ffd027"), 3)
		Fx.shake(self, 3.0, 0.2)
		await get_tree().create_timer(0.11).timeout
		_haptic(45, 0.7)

func _invalid_word_feedback() -> void:
	_wave_invalids += 1
	_break_combo(false)
	_show_toast("Not a word", Palette.RED)
	_flash_word_card(ERROR_RED)
	Audio.play("invalid", 0.02, 1.0, -1.5)
	_haptic_error()
	if word_card != null:
		Fx.shake(word_card, 7.0, 0.35)

func _already_found_feedback(word_upper: String) -> void:
	_show_toast("Already found", Palette.RED)
	_flash_word_card(Color("#ff9a2e"))
	Audio.play("wm_known", 0.02, 1.0, -3.0)
	_haptic(30, 0.36)
	if word_card != null:
		Fx.shake(word_card, 5.0, 0.24)
		Fx.stamp(self, _word_card_center(), "X", Color("#ff9a2e"))
	_highlight_found_pill(word_upper)

func _short_drag_feedback() -> void:
	Audio.play("wm_thud", 0.01, 0.75, -15.0)
	_haptic(12, 0.12)

func _update_goal_progress(word: String, earned: int, chain_nodes: Array) -> void:
	match _goal_type:
		"word_count":
			_goal_progress = _found_order.size() - _wave_words_start
		"long_words":
			if word.length() >= 4:
				_goal_progress += 1
		"xp_target":
			_goal_progress = _score - _wave_score_start
		"speed_burst":
			if _speed_time_left > 0.0:
				_speed_words += 1
				_goal_progress = _speed_words
		"use_special":
			if _chain_uses_special(chain_nodes) or _used_special_this_wave:
				_goal_progress = 1
		"no_mistakes":
			_goal_progress = 0 if _wave_invalids > 0 else (_found_order.size() - _wave_words_start)
	if _goal_type == "speed_burst" and _goal_progress < _goal_target:
		_speed_time_left = maxf(0.0, _speed_time_left)

func _goal_complete() -> bool:
	if _goal_type == "no_mistakes" and _wave_invalids > 0:
		return false
	return _goal_progress >= _goal_target

func _clear_wave() -> void:
	if not _running or _wave_transitioning:
		return
	_wave_transitioning = true
	var bonus := 0
	if _time_left > 30.0:
		bonus += 60
		_carry_time = 10.0
	elif _time_left > 20.0:
		bonus += 30
		_carry_time = 5.0
	if _wave_invalids == 0 and _wave_lives_lost == 0:
		bonus += 50
		_add_powerup("Wild")
		_add_powerup("Freeze")
	if _fever_active:
		bonus += 80
	if bonus > 0:
		var earned := _award_xp(bonus)
		_score += earned
		_show_toast("Wave bonus +%d" % earned, VIBRANT_GOLD)
	var stars := 1
	if _wave_lives_lost == 0:
		stars = 2
	if _wave_lives_lost == 0 and _best_combo_this_wave >= 3:
		stars = 3
	Fx.banner(self, "WAVE %d CLEAR  %s" % [_wave, _stars_text(stars)], VIBRANT_GOLD, VIBRANT_BLUE_DARK)
	Audio.play("victory", 0.02, 1.0, -2.0)
	if _wave % 5 == 0:
		if _lives < _max_lives:
			_lives += 1
		_double_xp_left = 15.0
		Fx.banner(self, "MILESTONE BONUS", READY_GREEN, Color.WHITE)
	_wave += 1
	_wave_failures = 0
	if _powerups.has("Freeze"):
		_freeze_left = 8.0
		_powerups.erase("Freeze")
	await get_tree().create_timer(0.55).timeout
	if _running:
		_start_wave()

func _stars_text(stars: int) -> String:
	if stars >= 3:
		return "***"
	if stars == 2:
		return "**"
	return "*"

func _fail_wave(reason: String) -> void:
	if not _running or _wave_transitioning:
		return
	_wave_transitioning = true
	_wave_failures += 1
	_break_combo(false)
	Fx.banner(self, "%s  %d/3" % [reason, _wave_failures], ERROR_RED, Color.WHITE)
	Audio.play("invalid", 0.02, 0.9, -1.0)
	if _wave_failures >= 3:
		_wave_failures = 0
		_lose_life("Wave failed")
		if not _running:
			return
	await get_tree().create_timer(0.55).timeout
	if _running:
		_start_wave()

func _lose_life(reason: String) -> void:
	if not _running:
		return
	_lives = maxi(0, _lives - 1)
	_wave_lives_lost += 1
	_break_combo(false)
	Fx.banner(self, reason.to_upper(), ERROR_RED, Color.WHITE)
	_show_toast("%s -1 life" % reason, Palette.RED)
	_haptic_error()
	_refresh_hud()
	if _lives <= 0:
		_end_round("Game Over")

func _all_words_found() -> bool:
	for w: String in _possible_words:
		if not _found.has(w):
			return false
	return true

func _new_pool() -> void:
	Fx.banner(self, "All Found!", Color("#3aa8ff"), Color.WHITE)
	Fx.fireworks(self, Vector2(size.x * 0.5, size.y * 0.35))
	_spawn_wave()
	_refresh_found()

func _show_toast(msg: String, color: Color) -> void:
	toast.text = msg
	toast.add_theme_color_override("font_color", color)
	toast.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(0.6)
	tw.tween_property(toast, "modulate:a", 0.0, 0.4)

func _word_card_center() -> Vector2:
	if word_card == null:
		return size * 0.5
	return word_card.global_position + word_card.size * 0.5 - global_position

func _set_word_card_style(bg: Color, border: Color, shadow: Color) -> void:
	if _word_card_style == null:
		return
	_word_card_style.bg_color = bg
	_word_card_style.border_color = border
	_word_card_style.shadow_color = shadow
	word_card.add_theme_stylebox_override("panel", _word_card_style)

func _reset_word_card_style() -> void:
	_set_word_card_style(VIBRANT_MAGENTA, VIBRANT_MAGENTA_DARK, Color(1.0, 0.4, 0.7, 0.45))

func _flash_word_card(color: Color) -> void:
	_word_card_flash_id += 1
	var id := _word_card_flash_id
	_set_word_card_style(Color.WHITE, color, Color(color.r, color.g, color.b, 0.7))
	var tw := create_tween()
	tw.tween_interval(0.08)
	tw.tween_callback(func(): _set_word_card_style(color, color, Color(color.r, color.g, color.b, 0.55)))
	tw.tween_interval(0.42)
	tw.tween_callback(func():
		if id == _word_card_flash_id:
			_reset_word_card_style()
	)

func _update_xp_preview() -> void:
	if xp_preview_label == null:
		return
	var w := _current_word()
	if _chain.size() >= MIN_WORD_LEN and _is_dragging:
		var preview_word := _resolve_chain_word(_chain)
		var shown_len := _chain.size() if preview_word.is_empty() else preview_word.length()
		var preview_key := preview_word.to_lower()
		if preview_key.is_empty():
			for i in shown_len:
				preview_key += "x"
		var preview := _score_word(preview_key, _chain, maxi(1, _combo + 1))
		xp_preview_label.text = "+%d XP" % preview
		xp_preview_label.modulate.a = 1.0
	else:
		xp_preview_label.text = ""
		xp_preview_label.modulate.a = 0.0

func _highlight_found_pill(word_upper: String) -> void:
	for c in found_pills_row.get_children():
		if c is Label and (c as Label).text == word_upper:
			var lbl := c as Label
			var sb := lbl.get_theme_stylebox("normal") as StyleBoxFlat
			if sb == null:
				return
			var old := sb.bg_color
			var fresh := sb.duplicate() as StyleBoxFlat
			lbl.add_theme_stylebox_override("normal", fresh)
			var tw := create_tween()
			tw.tween_callback(func(): fresh.bg_color = Color("#fff1a8"))
			tw.tween_interval(0.28)
			tw.tween_callback(func(): fresh.bg_color = old)
			return

func _set_letters_to_rest() -> void:
	for n in _letters:
		if n.has_meta("rest_pos"):
			n.position = n.get_meta("rest_pos")

func _update_idle_letters() -> void:
	if _is_dragging or _is_shuffling:
		return
	for i in _letters.size():
		var n := _letters[i]
		if not n.has_meta("rest_pos"):
			continue
		var rest: Vector2 = n.get_meta("rest_pos")
		var period := 2.5 + float(i % 4) * 0.28
		var phase := _idle_phase / period * TAU + float(i) * 0.7
		n.position = rest + Vector2(0, sin(phase) * 3.5)

func _on_timer_second(sec_left: int) -> void:
	if not _running or sec_left <= 0:
		return
	if sec_left <= 10:
		Audio.play("wm_tick_fast", 0.0, 1.0, -1.0)
		_haptic(12, 0.18)
		_pulse_timer_chip(1.10)
	elif sec_left <= 30:
		Audio.play("wm_tick", 0.0, 1.0, -6.0)

func _pulse_timer_chip(target_scale: float) -> void:
	if timer_chip == null:
		return
	timer_chip.pivot_offset = timer_chip.size * 0.5
	var tw := timer_chip.create_tween()
	tw.tween_property(timer_chip, "scale", Vector2.ONE * target_scale, 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(timer_chip, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _mascot_react(message: String) -> void:
	if mascot == null:
		return
	mascot.pivot_offset = mascot.size * 0.5
	var tw := mascot.create_tween()
	tw.tween_property(mascot, "scale", Vector2.ONE * 1.12, 0.13).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(mascot, "scale", Vector2.ONE, 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if mascot_speech != null and mascot_speech_label != null:
		mascot_speech_label.text = message
		mascot_speech.scale = Vector2.ZERO
		var st := mascot_speech.create_tween()
		st.tween_property(mascot_speech, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		st.tween_interval(1.0)
		st.tween_property(mascot_speech, "scale", Vector2.ZERO, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)

func _haptic(duration_ms: int, amplitude: float) -> void:
	Input.vibrate_handheld(duration_ms, clampf(amplitude, 0.0, 1.0))

func _haptic_error() -> void:
	_haptic(24, 0.55)
	await get_tree().create_timer(0.07).timeout
	_haptic(24, 0.55)

func _end_round(reason: String = "Game Over") -> void:
	_running = false
	preview_label.text = "%s! %d XP, W%d" % [reason, _score, _wave]
	Audio.play("victory" if _score > 0 else "defeat", 0.02, 1.0, -1.5)
	if _score > 0:
		_haptic(80, 0.55)
		await get_tree().create_timer(0.08).timeout
		_haptic(80, 0.55)
	else:
		_haptic(60, 0.35)
	if dim_overlay != null:
		var dt := create_tween()
		dt.tween_property(dim_overlay, "color", Color(0, 0, 0, 0.30), 0.4)
	if _found.size() >= 3:
		Fx.fireworks(self, Vector2(size.x * 0.5, size.y * 0.35))
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
		"time_used": 0.0,
		"wave": _wave,
		"lives": _lives,
		"best_combo": _best_combo_this_wave,
		"reason": reason,
	}
	# Brief pause so the player sees the "Time!" message before transitioning.
	await get_tree().create_timer(0.8).timeout
	get_tree().change_scene_to_file("res://games/word_match/results.tscn")
