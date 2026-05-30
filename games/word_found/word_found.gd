extends Control
## Word Found — GDD §4.
## Row 1 = available letters (10–12), Row 2 = letters currently moved down.
## Tap Row 1 letter to move it to Row 2; tap Row 2 letter to return.
## Submit a word to tick any matching quest targets.
## Bonus words score extra when they do not advance a target.

const Tile := preload("res://games/word_found/tile_node.gd")
const TileState := Tile.State
const Chrome := preload("res://scripts/screen_chrome.gd")
const Fx := preload("res://games/word_fight/fx.gd")

const GREEN_LIGHT := Color("#dff1e0")
const GREEN_DARK := Color("#5ba36b")
const GOLD_LIGHT := Color("#fff1c4")
const GOLD_DARK := Color("#b48218")
const PURPLE_LIGHT := Color("#ece1f5")
const PURPLE_BORDER := Color("#b89fd6")
const PURPLE_DARK := Color("#7a4caf")
const PINK_LIGHT := Color("#fde0e7")
const PINK_BORDER := Color("#f2a6b6")
const SUBMIT_GREEN := Color("#b6dfb2")
const SUBMIT_GREEN_TEXT := Color("#4a7d4a")

# Vibrant tokens matching Word Fight / Word Match.
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

const MIN_WORD_LEN := 3
const MAX_WAVE := 40                      # GDD hard ceiling
const BONUS_LONG_MULT := 1.5              # >target length → base × 1.5
const TARGETS_PER_WAVE := 4
const ANCHOR_POOL_LENGTHS := [8, 9, 10, 11, 12]
const MAX_DICTIONARY_POOL_ATTEMPTS := 160
const TARGET_FIRST_LETTERS := ["G", "H", "B", "R", "E", "T", "N"]
const TARGET_END_LETTERS := ["N", "R", "T"]

const ANIMAL_WORDS := {
	"ant": true, "ape": true, "bat": true, "bear": true, "bee": true, "bird": true,
	"cat": true, "cow": true, "deer": true, "dog": true, "duck": true, "eagle": true,
	"fish": true, "fox": true, "frog": true, "goat": true, "hare": true, "horse": true,
	"lion": true, "mole": true, "mouse": true, "owl": true, "rat": true, "seal": true,
	"shark": true, "sheep": true, "snake": true, "swan": true, "tiger": true, "whale": true,
	"wolf": true, "worm": true
}
const NATURE_WORDS := {
	"air": true, "beach": true, "branch": true, "brook": true, "cloud": true, "dew": true,
	"earth": true, "field": true, "fire": true, "flower": true, "forest": true, "garden": true,
	"grass": true, "hill": true, "lake": true, "leaf": true, "moon": true, "mountain": true,
	"rain": true, "river": true, "root": true, "sea": true, "sky": true, "snow": true,
	"soil": true, "star": true, "stone": true, "storm": true, "stream": true, "sun": true,
	"tree": true, "water": true, "wind": true, "wood": true
}
const ACTION_WORDS := {
	"act": true, "add": true, "bend": true, "bring": true, "build": true, "call": true,
	"carry": true, "climb": true, "cook": true, "draw": true, "dream": true, "drive": true,
	"eat": true, "find": true, "give": true, "grow": true, "hear": true, "hold": true,
	"jump": true, "learn": true, "listen": true, "look": true, "make": true, "move": true,
	"paint": true, "play": true, "read": true, "run": true, "say": true, "sing": true,
	"speak": true, "teach": true, "think": true, "throw": true, "walk": true, "write": true
}
const NOUN_WORDS := {
	"air": true, "art": true, "book": true, "boy": true, "branch": true, "car": true,
	"child": true, "city": true, "day": true, "door": true, "dream": true, "field": true,
	"fire": true, "friend": true, "garden": true, "girl": true, "hand": true, "home": true,
	"house": true, "idea": true, "letter": true, "light": true, "line": true, "man": true,
	"map": true, "moon": true, "mountain": true, "name": true, "night": true, "parent": true,
	"plant": true, "river": true, "room": true, "school": true, "song": true, "star": true,
	"story": true, "teacher": true, "thing": true, "tree": true, "water": true, "word": true,
	"world": true
}

# Curated 10–12 letter anchor pools rich in sub-words. Each is verified by
# the dictionary at runtime; if a pool fails the target-count check we resample.
const POOLS := [
	"STREAMING",         # 9
	"PAINTERS",          # 8
	"REACTIONS",         # 9
	"STRANGER",          # 8
	"TEACHERS",          # 8
	"PLANETARY",         # 9
	"MOUNTAIN",          # 8
	"PARENTING",         # 9
	"SCRAMBLED",         # 9
	"GARDENER",          # 8
	"BREATHING",         # 9
	"TROUBLES",          # 8
	"DREAMING",          # 8
	"LANTERNS",          # 8
	"PROBLEM",           # 7
	"CHAPTERS",          # 8
	"HOMELAND",          # 8
	"CREATION",          # 8
	"SPEAKING",          # 8
	"PRODUCTS",          # 8
	"WONDERED",          # 8
	"STRONGER",          # 8
	"CLIMBING",          # 8
	"TRAMPLED",          # 8
	"BRANCHES",          # 8
	"SCOLDING",          # 8
	"MATERIAL",          # 8
	"DISCOVER",          # 8
	"ORDERING",          # 8
	"PLATFORM",          # 8
]

@onready var wave_lbl: Label = $V/Top/Wave
@onready var score_lbl: Label = $V/Top/Score
@onready var targets_box: VBoxContainer = $V/TargetsBox
@onready var row2_label: Label = $V/Row2/Current
@onready var row2_holder: HBoxContainer = $V/Row2/Tiles
@onready var row1_grid: GridContainer = $V/Row1
@onready var bonus_lbl: Label = $V/Bonus
@onready var status_lbl: Label = $V/Status
@onready var submit_btn: Button = $V/Actions/Submit
@onready var clear_btn: Button = $V/Actions/Clear
@onready var back_btn: Button = $BackBtn

var _wave: int = 1
var _score: int = 0
var _row1_bg: Control                # wooden backdrop behind Row 1
var _row1_card: Control              # parent card so we can layer bg under grid
var _row1_stack: Control             # host that the grid is scaled + centered in
var _submit_glow: Panel              # glowing shadow ring on Submit when chain is ready
var _score_chip: Control             # captured for confetti targeting
var _wave_chip: Control
var _row2_pill: PanelContainer
var _words_count_lbl: Label
var _mascot: Control
var _mascot_icon: TextureRect
var _mascot_speech: PanelContainer
var _mascot_speech_label: Label
var _total_words: int = 0
var _pool_letters: String = ""
var _used_pools: Array = []          # pools already used this session
var _dictionary_anchor_pools_by_length: Dictionary = {}
var _row1_tiles: Array = []          # all 10-12 tiles in Row 1; their state tells the rest
var _row2_chain: Array = []          # ordered subset currently in Row 2
var _targets: Array = []             # [{"id":String,"kind":String,"label":String,"count":N,"done":k}, ...]
var _bonus_words: Array = []
var _used_words: Dictionary = {}
var _running: bool = false
var _submit_ready_announced: bool = false

func _ready() -> void:
	back_btn.visible = false  # replaced by chrome header
	submit_btn.pressed.connect(_submit_word)
	_apply_design()
	if not _load_session():
		_start_wave(1)

func _apply_design() -> void:
	Chrome.bg_layer(self)
	var hdr_back := Chrome.header(self, "Word Found")
	_build_header_avatar(hdr_back)
	hdr_back.pressed.connect(func():
		_save_session()
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	)

	var v := $V as Control
	v.offset_top = Chrome.HEADER_H + 24

	# HUD row — vibrant chip pills.
	wave_lbl.add_theme_font_size_override("font_size", 20)
	wave_lbl.add_theme_color_override("font_color", Color.WHITE)
	score_lbl.add_theme_font_size_override("font_size", 20)
	score_lbl.add_theme_color_override("font_color", Color("#4a3000"))
	_wave_chip = _wrap_in_vibrant_chip(wave_lbl, VIBRANT_BLUE, VIBRANT_BLUE_DARK)
	_score_chip = _wrap_in_vibrant_chip(score_lbl, VIBRANT_GOLD, Color("#dba830"))

	# Targets section — dark vibrant card.
	var targets_label_node: Label = $V/TargetsLabel
	targets_label_node.text = "Targets"
	targets_label_node.add_theme_color_override("font_color", Color("#ffe680"))
	targets_label_node.add_theme_font_size_override("font_size", 16)
	_wrap_in_dark_card([targets_label_node, targets_box], v)

	# Row2: Word Match-style current-word pill.
	row2_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.3))
	row2_label.add_theme_font_size_override("font_size", 14)
	row2_label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	var row2_node: Control = $V/Row2
	_row2_pill = PanelContainer.new()
	var pill_sb := StyleBoxFlat.new()
	pill_sb.bg_color = VIBRANT_MAGENTA
	pill_sb.set_corner_radius_all(22)
	pill_sb.set_border_width_all(3)
	pill_sb.border_color = VIBRANT_MAGENTA_DARK
	pill_sb.shadow_color = Color(1.0, 0.4, 0.7, 0.38)
	pill_sb.shadow_size = 6
	pill_sb.shadow_offset = Vector2i(0, 2)
	pill_sb.content_margin_left = 20
	pill_sb.content_margin_right = 20
	pill_sb.content_margin_top = 10
	pill_sb.content_margin_bottom = 10
	_row2_pill.add_theme_stylebox_override("panel", pill_sb)
	_row2_pill.custom_minimum_size = Vector2(0, 60)
	v.add_child(_row2_pill)
	v.move_child(_row2_pill, row2_node.get_index())
	row2_node.reparent(_row2_pill, false)
	row2_holder.visible = false

	# Row1 — stone slab backdrop behind the grid.
	var row1_lbl: Label = $V/Row1Label
	row1_lbl.visible = false
	_wrap_row1_with_bg(row1_grid, v)

	# Status/feedback — subtle text below the word pill.
	status_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.35))
	status_lbl.add_theme_font_size_override("font_size", 14)
	bonus_lbl.add_theme_color_override("font_color", Color("#fff0b0"))
	bonus_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.5))
	bonus_lbl.add_theme_constant_override("outline_size", 3)
	bonus_lbl.add_theme_font_size_override("font_size", 17)

	# Bottom: WORDS counter + Submit button.
	clear_btn.get_parent().remove_child(clear_btn)
	clear_btn.queue_free()
	var actions_row := submit_btn.get_parent() as HBoxContainer

	# WORDS counter box.
	var words_box := PanelContainer.new()
	var wb_sb := StyleBoxFlat.new()
	wb_sb.bg_color = Color(0, 0, 0, 0.4)
	wb_sb.set_corner_radius_all(14)
	wb_sb.set_border_width_all(1)
	wb_sb.border_color = Color(0.4, 0.7, 0.4, 0.3)
	wb_sb.content_margin_left = 12
	wb_sb.content_margin_right = 12
	wb_sb.content_margin_top = 6
	wb_sb.content_margin_bottom = 6
	words_box.add_theme_stylebox_override("panel", wb_sb)
	words_box.custom_minimum_size = Vector2(72, 52)
	var wb_col := VBoxContainer.new()
	wb_col.alignment = BoxContainer.ALIGNMENT_CENTER
	wb_col.add_theme_constant_override("separation", 1)
	words_box.add_child(wb_col)
	var wb_head := Label.new()
	wb_head.text = "WORDS"
	wb_head.add_theme_font_size_override("font_size", 9)
	wb_head.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
	wb_head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wb_col.add_child(wb_head)
	_words_count_lbl = Label.new()
	_words_count_lbl.text = "0"
	_words_count_lbl.add_theme_font_size_override("font_size", 22)
	_words_count_lbl.add_theme_color_override("font_color", Color.WHITE)
	_words_count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wb_col.add_child(_words_count_lbl)
	actions_row.add_child(words_box)
	actions_row.move_child(words_box, 0)

	# Submit button — dark green.
	_dungeon_btn(submit_btn, Color(0.08, 0.12, 0.08), Color(0.35, 0.7, 0.4, 0.25), Color(1, 1, 1, 0.2))
	submit_btn.text = "Submit"
	_submit_glow = null
	submit_btn.disabled = true

func _build_header_avatar(hdr_back: Button) -> void:
	_mascot = PanelContainer.new()
	_mascot.custom_minimum_size = Vector2(48, 48)
	_mascot.size_flags_horizontal = Control.SIZE_SHRINK_END
	_mascot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_mascot.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	(_mascot as PanelContainer).add_theme_stylebox_override("panel", avatar_sb)
	var header_row := hdr_back.get_parent() as HBoxContainer
	if header_row != null:
		header_row.add_child(_mascot)
	else:
		add_child(_mascot)

	_mascot_icon = TextureRect.new()
	var path := "res://assets/avatars/%s.svg" % GameState.player_avatar
	if ResourceLoader.exists(path):
		_mascot_icon.texture = load(path)
	_mascot_icon.custom_minimum_size = Vector2(40, 40)
	_mascot_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_mascot_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_mascot_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mascot.add_child(_mascot_icon)

func _wrap_in_vibrant_chip(lbl: Label, bg: Color, border: Color) -> Control:
	var parent := lbl.get_parent() as Control
	var idx := lbl.get_index()
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(99)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	sb.set_border_width_all(2)
	sb.border_color = border
	sb.shadow_color = Color(0, 0, 0, 0.22)
	sb.shadow_size = 4
	sb.shadow_offset = Vector2i(0, 2)
	p.add_theme_stylebox_override("panel", sb)
	parent.add_child(p)
	parent.move_child(p, idx)
	lbl.reparent(p, false)
	return p

func _wrap_in_dark_card(nodes: Array, parent: Control) -> void:
	if nodes.is_empty():
		return
	var first_idx: int = (nodes[0] as Node).get_index()
	var card := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = DARK_CARD
	sb.set_corner_radius_all(18)
	sb.set_border_width_all(2)
	sb.border_color = DARK_CARD_BORDER
	sb.shadow_color = Color(0, 0, 0, 0.25)
	sb.shadow_size = 6
	sb.shadow_offset = Vector2i(0, 3)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	card.add_theme_stylebox_override("panel", sb)
	parent.add_child(card)
	parent.move_child(card, first_idx)
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 8)
	card.add_child(inner)
	for n: Node in nodes:
		n.reparent(inner, false)

func _wrap_row1_with_bg(grid_node: GridContainer, parent: Control) -> void:
	var idx := grid_node.get_index()
	var wrap := Control.new()
	wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(wrap)
	parent.move_child(wrap, idx)
	_row1_bg = Fx.BoardBG.new()
	_row1_bg.radius = 16.0
	_row1_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(_row1_bg)
	grid_node.reparent(wrap, false)
	_row1_stack = wrap
	_row1_card = wrap
	wrap.resized.connect(_fit_row1)
	grid_node.resized.connect(_fit_row1)
	_fit_row1.call_deferred()

func _fit_row1() -> void:
	if row1_grid == null or _row1_stack == null:
		return
	var gs := row1_grid.get_combined_minimum_size()
	if gs.x <= 0.0 or gs.y <= 0.0:
		return
	var wrap_w := _row1_stack.size.x
	if wrap_w <= 0.0:
		wrap_w = gs.x + 24.0
	var padded_h := gs.y + 24.0
	_row1_stack.custom_minimum_size = Vector2(0, padded_h)
	_row1_bg.position = Vector2.ZERO
	_row1_bg.size = Vector2(wrap_w, padded_h)
	var grid_x := (wrap_w - gs.x) * 0.5
	row1_grid.position = Vector2(grid_x, 12)

func _wrap_in_chip(lbl: Label, bg: Color) -> void:
	var parent := lbl.get_parent() as Control
	var idx := lbl.get_index()
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(99)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 5
	sb.content_margin_bottom = 5
	p.add_theme_stylebox_override("panel", sb)
	parent.add_child(p)
	parent.move_child(p, idx)
	lbl.reparent(p, false)

func _wrap_in_card(nodes: Array, parent: Control, bg: Color, border: Color, radius: int) -> void:
	# Wraps `nodes` (in order, already children of parent) into a single PanelContainer
	# placed at the first node's original index.
	if nodes.is_empty():
		return
	var first_idx: int = (nodes[0] as Node).get_index()
	var card := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(radius)
	sb.set_border_width_all(1)
	sb.border_color = border
	sb.shadow_color = Color(0, 0, 0, 0.05)
	sb.shadow_size = 3
	sb.shadow_offset = Vector2i(0, 1)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	card.add_theme_stylebox_override("panel", sb)
	parent.add_child(card)
	parent.move_child(card, first_idx)
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 8)
	card.add_child(inner)
	for n: Node in nodes:
		n.reparent(inner, false)

func _dungeon_btn(btn: Button, bg: Color, border: Color, fg: Color) -> void:
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_size_override("font_size", 17)
	btn.add_theme_color_override("font_color", fg)
	btn.add_theme_color_override("font_hover_color", fg)
	btn.add_theme_color_override("font_pressed_color", fg)
	btn.add_theme_color_override("font_disabled_color", Color(fg.r, fg.g, fg.b, 0.4))
	btn.custom_minimum_size = Vector2(0, 52)
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(14)
	sb.set_border_width_all(2)
	sb.border_color = border
	sb.shadow_color = Color(0, 0, 0, 0.3)
	sb.shadow_size = 4
	sb.shadow_offset = Vector2i(0, 2)
	sb.content_margin_left = 20
	sb.content_margin_right = 20
	sb.content_margin_top = 14
	sb.content_margin_bottom = 14
	var press := sb.duplicate() as StyleBoxFlat
	press.bg_color = bg.darkened(0.15)
	press.shadow_size = 1
	var dis := sb.duplicate() as StyleBoxFlat
	dis.bg_color = bg.darkened(0.3)
	dis.border_color = border.darkened(0.3)
	dis.shadow_size = 2
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb)
	btn.add_theme_stylebox_override("pressed", press)
	btn.add_theme_stylebox_override("focus", sb)
	btn.add_theme_stylebox_override("disabled", dis)

func _pill_btn(btn: Button, bg: Color, fg: Color) -> void:
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_size_override("font_size", 16)
	btn.add_theme_color_override("font_color", fg)
	btn.add_theme_color_override("font_hover_color", fg)
	btn.add_theme_color_override("font_pressed_color", fg)
	# Keep disabled text readable against the lightened pill background.
	btn.add_theme_color_override("font_disabled_color", Color(fg.r, fg.g, fg.b, 0.55))
	btn.custom_minimum_size = Vector2(0, 52)
	btn.add_theme_stylebox_override("normal", _pill_sb(bg, bg.darkened(0.1), false))
	btn.add_theme_stylebox_override("hover", _pill_sb(bg, bg.darkened(0.1), false))
	btn.add_theme_stylebox_override("pressed", _pill_sb(bg.darkened(0.05), bg.darkened(0.15), false))
	btn.add_theme_stylebox_override("focus", _pill_sb(bg, bg.darkened(0.1), false))
	btn.add_theme_stylebox_override("disabled", _pill_sb(bg.lightened(0.4), bg.lightened(0.4), false))

func _pill_sb(bg: Color, border: Color, with_border: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(28)
	if with_border:
		sb.set_border_width_all(1)
		sb.border_color = border
	sb.shadow_color = Color(0, 0, 0, 0.08)
	sb.shadow_size = 3
	sb.shadow_offset = Vector2i(0, 1)
	sb.content_margin_left = 20
	sb.content_margin_right = 20
	sb.content_margin_top = 14
	sb.content_margin_bottom = 14
	return sb

# ---------------- wave setup ----------------

func _start_wave(w: int) -> void:
	_wave = mini(w, MAX_WAVE)
	_score = 0 if w == 1 else _score   # carry score across waves
	_used_words.clear()
	_bonus_words.clear()
	_row2_chain.clear()
	_running = true

	# Pick a pool that supports four randomized quest targets.
	var picked := _pick_pool()
	_pool_letters = picked.pool
	_targets = picked.targets
	_build_row1()
	_build_row2()
	_build_targets_box()
	_refresh_bonus()
	_refresh_hud()
	_set_status("Wave %d — fill the targets below." % _wave)
	_save_session()

func _pick_pool() -> Dictionary:
	var picked := _pick_dictionary_pool(false)
	if not picked.is_empty():
		return picked
	_used_pools.clear()
	picked = _pick_dictionary_pool(true)
	if not picked.is_empty():
		return picked
	return _pick_curated_pool()

func _pick_dictionary_pool(allow_used: bool) -> Dictionary:
	var lengths := ANCHOR_POOL_LENGTHS.duplicate()
	lengths.shuffle()
	var checked := 0
	for length: int in lengths:
		var attempts := _dictionary_anchor_source(length)
		attempts.shuffle()
		for p: String in attempts:
			if checked >= MAX_DICTIONARY_POOL_ATTEMPTS:
				return {}
			checked += 1
			if not allow_used and _used_pools.has(p):
				continue
			var targets := _choose_targets_for_pool(p)
			if targets.size() >= TARGETS_PER_WAVE:
				_used_pools.append(p)
				return {"pool": p, "targets": targets}
	return {}

func _dictionary_anchor_source(length: int) -> Array[String]:
	if _dictionary_anchor_pools_by_length.has(length):
		var cached: Array[String] = []
		for p: String in _dictionary_anchor_pools_by_length[length]:
			cached.append(p)
		return cached
	var pools: Array[String] = []
	for w: String in Words.words_of_length(length):
		var pool := w.to_upper()
		if _is_anchor_candidate(pool):
			pools.append(pool)
	if pools.is_empty():
		pools = POOLS.duplicate()
	_dictionary_anchor_pools_by_length[length] = pools
	return pools.duplicate()

func _is_anchor_candidate(pool: String) -> bool:
	if not ANCHOR_POOL_LENGTHS.has(pool.length()) or _count_vowels_text(pool) < 3:
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

func _pick_curated_pool() -> Dictionary:
	var attempts := POOLS.duplicate()
	attempts.shuffle()
	for p: String in attempts:
		var targets := _choose_targets_for_pool(p)
		if targets.size() >= TARGETS_PER_WAVE:
			_used_pools.append(p)
			return {"pool": p, "targets": targets}
	return {"pool": "STREAMING", "targets": _fallback_targets_for_pool("STREAMING")}

func _choose_targets_for_pool(pool: String) -> Array:
	var words: Array[String] = Words.words_from_letters(pool, MIN_WORD_LEN, false)
	var candidates: Array = []
	for def: Dictionary in _all_target_defs():
		var goal := _goal_for_target(def)
		var have := 0
		for w: String in words:
			if _target_def_matches_word(def, w.to_upper()):
				have += 1
		if have >= goal:
			candidates.append(_annotate_target_def(def, goal))
	candidates.shuffle()
	return _select_target_mix(candidates)

func _fallback_targets_for_pool(pool: String) -> Array:
	var targets := _choose_targets_for_pool(pool)
	if targets.size() >= TARGETS_PER_WAVE:
		return targets
	return [
		{"id": "len_3", "kind": "length_exact", "label": "3 letter words", "badge": "3", "category": "length", "value": 3, "count": 2, "done": 0, "tone": 3},
		{"id": "len_4", "kind": "length_exact", "label": "4 letter words", "badge": "4", "category": "length", "value": 4, "count": 1, "done": 0, "tone": 4},
		{"id": "vowels_2", "kind": "min_vowels", "label": "Has 2+ vowels", "badge": "V", "category": "pattern", "value": 2, "count": 2, "done": 0, "tone": 5},
		{"id": "long_5", "kind": "length_min", "label": "Long words", "badge": "5+", "category": "length", "value": 5, "count": 1, "done": 0, "tone": 6},
	]

func _all_target_defs() -> Array:
	var defs: Array = [
		{"id": "len_3", "kind": "length_exact", "label": "3 letter words", "badge": "3", "category": "length", "value": 3, "tone": 3},
		{"id": "len_4", "kind": "length_exact", "label": "4 letter words", "badge": "4", "category": "length", "value": 4, "tone": 4},
		{"id": "len_5", "kind": "length_exact", "label": "5 letter words", "badge": "5", "category": "length", "value": 5, "tone": 5},
		{"id": "len_6_plus", "kind": "length_min", "label": "6+ letter words", "badge": "6+", "category": "length", "value": 6, "tone": 6},
		{"id": "short_3", "kind": "length_max", "label": "Short words", "badge": "<=3", "category": "length", "value": 3, "tone": 3},
		{"id": "long_5", "kind": "length_min", "label": "Long words", "badge": "5+", "category": "length", "value": 5, "tone": 6},
		{"id": "nouns", "kind": "word_type", "label": "Nouns", "badge": "N", "category": "type", "value": "noun", "tone": 4},
		{"id": "verbs", "kind": "word_type", "label": "Verbs / Actions", "badge": "A", "category": "type", "value": "action", "tone": 5},
		{"id": "animals", "kind": "word_type", "label": "Animals", "badge": "AN", "category": "type", "value": "animal", "tone": 3},
		{"id": "nature", "kind": "word_type", "label": "Nature words", "badge": "NW", "category": "type", "value": "nature", "tone": 6},
		{"id": "vowels_2", "kind": "min_vowels", "label": "Has 2+ vowels", "badge": "V", "category": "pattern", "value": 2, "tone": 5},
		{"id": "repeated", "kind": "repeated_letter", "label": "Has repeated letter", "badge": "RR", "category": "pattern", "tone": 4},
	]
	for letter: String in TARGET_FIRST_LETTERS:
		defs.append({"id": "starts_%s" % letter.to_lower(), "kind": "starts", "label": "Starts with %s" % letter, "badge": letter, "category": "first", "value": letter, "tone": 4})
	for letter: String in TARGET_END_LETTERS:
		defs.append({"id": "ends_%s" % letter.to_lower(), "kind": "ends", "label": "Ends with %s" % letter, "badge": letter, "category": "pattern", "value": letter, "tone": 3})
	return defs

func _select_target_mix(candidates: Array) -> Array:
	var selected: Array = []
	var used_ids: Dictionary = {}
	var categories := ["length", "first", "type", "pattern"]
	categories.shuffle()
	for cat: String in categories:
		var matches: Array = []
		for t: Dictionary in candidates:
			if t.category == cat:
				matches.append(t)
		if not matches.is_empty():
			var picked: Dictionary = matches.pick_random()
			selected.append(picked)
			used_ids[picked.id] = true
	for t: Dictionary in candidates:
		if selected.size() >= TARGETS_PER_WAVE:
			break
		if not used_ids.has(t.id):
			selected.append(t)
			used_ids[t.id] = true
	return selected.slice(0, TARGETS_PER_WAVE)

func _goal_for_target(def: Dictionary) -> int:
	var tier := 0
	if _wave >= 16:
		tier = 2
	elif _wave >= 6:
		tier = 1
	var kind := def.kind as String
	var value: Variant = def.get("value", 0)
	if kind == "length_exact":
		var n := int(value)
		if n <= 4:
			return 2 + tier
		if n == 5:
			return 1 + tier
		return 1 + int(tier >= 2)
	if kind == "length_min" and int(value) >= 6:
		return 1 + int(tier >= 2)
	if kind == "starts" or kind == "word_type":
		return 1 + int(tier >= 1)
	return 2 + int(tier >= 1)

func _annotate_target_def(def: Dictionary, goal: int) -> Dictionary:
	var out := def.duplicate(true)
	out["count"] = goal
	out["done"] = 0
	return out

func _legacy_length_target(word_len: int, count: int, done: int) -> Dictionary:
	return {
		"id": "len_%d" % word_len,
		"kind": "length_exact",
		"label": "%d letter words" % word_len,
		"badge": str(word_len),
		"category": "length",
		"value": word_len,
		"count": count,
		"done": done,
		"tone": clampi(word_len, 3, 6),
	}

func _target_def_matches_word(target: Dictionary, word_up: String) -> bool:
	var kind := target.get("kind", "") as String
	var value: Variant = target.get("value", null)
	match kind:
		"length_exact":
			return word_up.length() == int(value)
		"length_min":
			return word_up.length() >= int(value)
		"length_max":
			return word_up.length() <= int(value)
		"starts":
			return word_up.begins_with(value as String)
		"ends":
			return word_up.ends_with(value as String)
		"min_vowels":
			return _count_vowels_text(word_up) >= int(value)
		"repeated_letter":
			return _has_repeated_letter(word_up)
		"word_type":
			return _word_matches_type(word_up.to_lower(), value as String)
	return false

func _has_repeated_letter(word_up: String) -> bool:
	var seen := {}
	for ch in word_up:
		if seen.has(ch):
			return true
		seen[ch] = true
	return false

func _word_matches_type(word: String, word_type: String) -> bool:
	match word_type:
		"animal":
			return ANIMAL_WORDS.has(word)
		"nature":
			return NATURE_WORDS.has(word)
		"action":
			return ACTION_WORDS.has(word) or word.ends_with("ing") or word.ends_with("ed")
		"noun":
			return NOUN_WORDS.has(word) or _looks_like_noun(word)
	return false

func _looks_like_noun(word: String) -> bool:
	for suffix in ["tion", "ment", "ness", "ity", "age", "ship", "ance", "ence", "hood", "ism"]:
		if word.ends_with(suffix):
			return true
	return ANIMAL_WORDS.has(word) or NATURE_WORDS.has(word)

# ---------------- Row 1 / Row 2 ----------------

func _build_row1() -> void:
	for c in row1_grid.get_children():
		c.queue_free()
	_row1_tiles.clear()
	row1_grid.columns = mini(_pool_letters.length(), 4)
	var letters := []
	for ch in _pool_letters:
		letters.append(ch)
	letters.shuffle()
	for i in letters.size():
		var ch: String = letters[i]
		var t: WFoundTile = Tile.new()
		t.letter = ch
		t.tile_pressed.connect(_on_row1_tile_pressed)
		t.tile_picked_fx.connect(_on_tile_picked_fx)
		row1_grid.add_child(t)
		_row1_tiles.append(t)
		t.play_pop_in(i * 0.035)
	_fit_row1.call_deferred()

func _on_tile_picked_fx(t: WFoundTile, color: Color) -> void:
	var pos := t.global_position + t.size * 0.5 - global_position
	Fx.sparkle_burst(self, pos, color, 8)

func _build_row2() -> void:
	for c in row2_holder.get_children():
		c.queue_free()
	_row2_chain.clear()
	_refresh_row2_label()

func _on_row1_tile_pressed(t: WFoundTile) -> void:
	if not _running:
		return
	if t.state == TileState.AVAILABLE:
		t.state = TileState.MOVED
		t.selection_index = _row2_chain.size()
		_row2_chain.append(t)
		Audio.play("select", 0.02, pow(2.0, float(_row2_chain.size() - 1) / 12.0), -2.5)
		_haptic(16, 0.2)
		_refresh_row2_label()
		_update_submit_state()
	elif t.state == TileState.MOVED:
		var idx := _row2_chain.find(t)
		if idx >= 0:
			var to_revert := _row2_chain.slice(idx)
			for rt: WFoundTile in to_revert:
				rt.state = TileState.AVAILABLE
			_row2_chain.resize(idx)
		Audio.play("wm_thud", 0.01, 1.0, -10.0)
		_reindex_chain()
		_refresh_row2_label()
		_update_submit_state()

func _on_row2_tile_pressed(t: WFoundTile) -> void:
	if not _running or t.state != TileState.MOVED:
		return
	t.state = TileState.AVAILABLE
	_row2_chain.erase(t)
	_reindex_chain()
	_refresh_row2_label()
	_update_submit_state()

func _clear_chain() -> void:
	for t: WFoundTile in _row2_chain.duplicate():
		t.state = TileState.AVAILABLE
	_row2_chain.clear()
	_submit_ready_announced = false
	_refresh_row2_label()
	_update_submit_state()

func _reindex_chain() -> void:
	for i in _row2_chain.size():
		(_row2_chain[i] as WFoundTile).selection_index = i

func _refresh_row2_label() -> void:
	var word := _chain_word()
	row2_holder.visible = false
	row2_label.visible = true
	if word.is_empty():
		row2_label.text = "Tap letters to spell a word"
		row2_label.add_theme_font_size_override("font_size", 28)
		row2_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.2))
	else:
		row2_label.text = _spaced_word(word)
		row2_label.add_theme_font_size_override("font_size", 28)
		row2_label.add_theme_color_override("font_color", Color.WHITE)
	_refresh_word_feedback()

func _spaced_word(w: String) -> String:
	var out := ""
	for i in w.length():
		if i > 0:
			out += "  "
		out += w[i]
	return out

func _refresh_word_feedback() -> void:
	var word := _chain_word()
	if word.length() < MIN_WORD_LEN:
		_set_status("")
		return
	var lower := word.to_lower()
	if _used_words.has(lower):
		_set_status("Already used!")
	elif not Words.is_valid(lower):
		_set_status("not a word")
	else:
		_set_status("")

func _chain_word() -> String:
	var s := ""
	for t: WFoundTile in _row2_chain:
		s += t.letter
	return s

func _update_submit_state() -> void:
	var word := _chain_word()
	var len_ok := word.length() >= MIN_WORD_LEN
	var valid := len_ok and Words.is_valid(word.to_lower()) and not _used_words.has(word.to_lower())
	submit_btn.disabled = not valid
	if valid:
		_dungeon_btn(submit_btn, READY_GREEN, Color("#159447"), Color.WHITE)
		if not _submit_ready_announced:
			_submit_ready_announced = true
			Audio.play("wm_ready", 0.01, 1.0, -2.0)
			_haptic(20, 0.28)
	else:
		_submit_ready_announced = false
		_dungeon_btn(submit_btn, Color(0.08, 0.12, 0.08), Color(0.35, 0.7, 0.4, 0.25), Color(1, 1, 1, 0.2))

# ---------------- targets box ----------------

func _build_targets_box() -> void:
	for c in targets_box.get_children():
		c.queue_free()
	targets_box.add_theme_constant_override("separation", 6)
	for t in _targets:
		var row := _TargetRow.new()
		row.badge = t.get("badge", str(t.get("value", "?"))) as String
		row.title = t.get("label", "Target") as String
		row.total = int(t.get("count", 1))
		row.done = int(t.get("done", 0))
		row.tone = int(t.get("tone", 4))
		targets_box.add_child(row)

func _refresh_targets_box() -> void:
	# Re-render to reflect updated `done` counts.
	_build_targets_box()

# ---------------- submit ----------------

func _submit_word() -> void:
	if not _running:
		return
	var word_up := _chain_word()
	if word_up.length() < MIN_WORD_LEN:
		return
	var word := word_up.to_lower()
	if _used_words.has(word):
		_set_status("Already used: %s" % word_up)
		_invalid_shake()
		return
	if not Words.is_valid(word):
		_set_status("Not a word: %s" % word_up)
		_invalid_shake()
		return
	_used_words[word] = true

	# Score
	var matched_target := false
	for t in _targets:
		if int(t.get("done", 0)) < int(t.get("count", 1)) and _target_def_matches_word(t, word_up):
			t.done = int(t.get("done", 0)) + 1
			matched_target = true
	var base := word.length() * 10
	if not matched_target and word.length() > _max_target_length():
		base = int(base * BONUS_LONG_MULT)
	var earned := GameState.add_xp("word_found", base)
	_score += earned

	if not matched_target:
		_bonus_words.append(word_up)

	# ----- WIN FX (capture positions before tiles snap back) -----
	var froms: Array = []
	var cols: Array = []
	for t: WFoundTile in _row2_chain:
		froms.append(t.global_position + t.size * 0.5 - global_position)
		var g := Fx.gradient_for_letter(t.letter)
		cols.append(g[1])
	_success_feedback(word_up, earned, matched_target, froms, cols)

	_total_words += 1
	if _words_count_lbl != null:
		_words_count_lbl.text = str(_total_words)
	for t: WFoundTile in _row2_chain:
		t.state = TileState.AVAILABLE
	_row2_chain.clear()
	_submit_ready_announced = false
	_refresh_row2_label()
	_update_submit_state()
	_refresh_targets_box()
	_refresh_hud()
	_refresh_bonus()

	_save_session()
	if _targets_complete():
		_set_status("Wave %d cleared! +%d XP" % [_wave, earned])
		Fx.banner(self, "WAVE %d!" % _wave, VIBRANT_GOLD, VIBRANT_GOLD_DARK)
		Fx.fireworks(self, Vector2(size.x * 0.5, size.y * 0.4))
		_mascot_react("Wave!")
		_running = false
		await get_tree().create_timer(0.9).timeout
		_start_wave(_wave + 1)
		return

	_set_status("+%d XP — %s" % [earned, word_up])

func _success_feedback(word_up: String, earned: int, matched_target: bool, froms: Array, cols: Array) -> void:
	var n := word_up.length()
	var palette := BURST_BLUE
	var count := 8
	var radius := 70.0
	var sound := "wm_success_low"
	var haptic_ms := 38
	var haptic_amp := 0.38
	var include_stars := false
	var include_confetti := false
	var big_score := false

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
		haptic_ms = 56
		haptic_amp = 0.56
		include_stars = true
		big_score = true
	elif n >= 6:
		palette = BURST_GOLD
		count = 24
		radius = 160.0
		sound = "wm_success_max"
		haptic_ms = 82
		haptic_amp = 0.78
		include_stars = true
		include_confetti = true
		big_score = true

	var center := _row2_center()
	_flash_row2_pill(READY_GREEN if matched_target else VIBRANT_GOLD)
	Fx.word_burst(self, center, count, palette, radius, include_stars, include_confetti)
	Audio.play(sound, 0.02, 1.0, -1.0)
	_haptic(haptic_ms, haptic_amp)

	if _score_chip != null:
		var target: Vector2 = _score_chip.global_position + _score_chip.size * 0.5 - global_position
		Fx.confetti_to(self, froms, target, cols)
		Fx.score_popup(self, target + Vector2(-10, 24), "+%d" % earned, big_score, VIBRANT_GOLD)
	if matched_target:
		Fx.board_rim_flash(self, targets_box, READY_GREEN, 2)
	elif n >= 4:
		Fx.banner(self, "BONUS WORD", VIBRANT_GOLD, VIBRANT_GOLD_DARK)
	if n >= 5:
		Fx.banner(self, word_up, VIBRANT_MAGENTA, Color.WHITE)
		Fx.shake(self, 3.0, 0.2)
		_mascot_react("Great!" if n == 5 else "Amazing!")
	if n >= 6:
		Fx.fireworks(self, Vector2(size.x * 0.5, size.y * 0.4))

func _row2_center() -> Vector2:
	if _row2_pill == null:
		return size * 0.5
	return _row2_pill.global_position + _row2_pill.size * 0.5 - global_position

func _targets_complete() -> bool:
	for t in _targets:
		if int(t.get("done", 0)) < int(t.get("count", 1)):
			return false
	return true

func _max_target_length() -> int:
	var m := 0
	for t in _targets:
		var kind := t.get("kind", "") as String
		if kind == "length_exact" or kind == "length_min":
			m = maxi(m, int(t.get("value", 0)))
	return m

# ---------------- HUD ----------------

func _refresh_hud() -> void:
	wave_lbl.text = "Wave %d" % _wave
	score_lbl.text = "%d XP" % _score

func _refresh_bonus() -> void:
	if _bonus_words.is_empty():
		bonus_lbl.text = "Bonus words: —"
	else:
		bonus_lbl.text = "Bonus: " + ", ".join(_bonus_words)

func _set_status(s: String) -> void:
	status_lbl.text = s

# ---------------- session save / load ----------------

func _save_session() -> void:
	var used_list: Array = []
	for w: String in _used_words.keys():
		used_list.append(w)
	GameState.wfound_save = {
		"wave": _wave,
		"score": _score,
		"pool": _pool_letters,
		"targets": _targets.duplicate(true),
		"used_words": used_list,
		"bonus_words": _bonus_words.duplicate(),
		"total_words": _total_words,
	}
	GameState.save()

func _clear_session() -> void:
	GameState.wfound_save = {}
	GameState.save()

func _load_session() -> bool:
	var s: Dictionary = GameState.wfound_save
	if s.is_empty():
		return false
	_wave = int(s.get("wave", 1))
	_score = int(s.get("score", 0))
	_pool_letters = s.get("pool", "") as String
	if _pool_letters.is_empty():
		return false
	_targets = []
	for t: Variant in s.get("targets", []):
		if t is Dictionary:
			if (t as Dictionary).has("kind"):
				var restored := (t as Dictionary).duplicate(true)
				restored["count"] = int(restored.get("count", 1))
				restored["done"] = int(restored.get("done", 0))
				if not restored.has("label"):
					restored["label"] = "Target"
				if not restored.has("badge"):
					restored["badge"] = str(restored.get("value", "?"))
				_targets.append(restored)
			elif (t as Dictionary).has("len"):
				_targets.append(_legacy_length_target(int((t as Dictionary).get("len", 3)), int((t as Dictionary).get("count", 1)), int((t as Dictionary).get("done", 0))))
	if _targets.is_empty():
		return false
	_used_words.clear()
	for w: Variant in s.get("used_words", []):
		_used_words[w as String] = true
	_bonus_words.clear()
	for w: Variant in s.get("bonus_words", []):
		_bonus_words.append(w as String)
	_total_words = int(s.get("total_words", 0))
	_running = true
	_row2_chain.clear()
	_build_row1()
	_build_row2()
	_build_targets_box()
	_refresh_bonus()
	_refresh_hud()
	if _words_count_lbl != null:
		_words_count_lbl.text = str(_total_words)
	_set_status("Wave %d resumed" % _wave)
	return true

# ---------------- small pip widget ----------------

func _invalid_shake() -> void:
	Audio.play("invalid", 0.02, 1.0, -1.5)
	_haptic_error()
	_flash_row2_pill(ERROR_RED)
	if _row2_pill != null:
		Fx.shake(_row2_pill, 6.0, 0.28)
	if _row1_card != null:
		Fx.shake(_row1_card, 4.0, 0.2)

func _flash_row2_pill(color: Color) -> void:
	if _row2_pill == null:
		return
	var sb := _row2_pill.get_theme_stylebox("panel") as StyleBoxFlat
	if sb == null:
		return
	var old_bg := sb.bg_color
	var old_border := sb.border_color
	var old_shadow := sb.shadow_color
	var tw := create_tween()
	tw.tween_callback(func():
		sb.bg_color = color
		sb.border_color = color
		sb.shadow_color = Color(color.r, color.g, color.b, 0.55)
	)
	tw.tween_interval(0.16)
	tw.tween_callback(func():
		sb.bg_color = old_bg
		sb.border_color = old_border
		sb.shadow_color = old_shadow
	)

func _mascot_react(message: String) -> void:
	if _mascot == null:
		return
	_mascot.pivot_offset = _mascot.size * 0.5
	var tw := _mascot.create_tween()
	tw.tween_property(_mascot, "scale", Vector2.ONE * 1.12, 0.13).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_mascot, "scale", Vector2.ONE, 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if _mascot_speech != null and _mascot_speech_label != null:
		_mascot_speech_label.text = message
		_mascot_speech.scale = Vector2.ZERO
		var st := _mascot_speech.create_tween()
		st.tween_property(_mascot_speech, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		st.tween_interval(0.85)
		st.tween_property(_mascot_speech, "scale", Vector2.ZERO, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)

func _haptic(duration_ms: int, amplitude: float) -> void:
	Input.vibrate_handheld(duration_ms, clampf(amplitude, 0.0, 1.0))

func _haptic_error() -> void:
	_haptic(24, 0.55)
	await get_tree().create_timer(0.07).timeout
	_haptic(24, 0.55)

class _TargetRow extends Control:
	const _FONT: Font = preload("res://assets/fonts/LilitaOne-Regular.ttf")
	var badge: String = "3" :
		set(v): badge = v; queue_redraw()
	var title: String = "3 letter words" :
		set(v): title = v; queue_redraw()
	var tone: int = 3 :
		set(v): tone = v; queue_redraw()
	var total: int = 3 :
		set(v): total = v; queue_redraw()
	var done: int = 0 :
		set(v): done = v; queue_redraw()
	const _TIER := {
		3: {"top": Color("#FF6B8A"), "bot": Color("#D4345A"), "glow": Color("#FF9DB5")},
		4: {"top": Color("#5BC0FF"), "bot": Color("#1A7FD4"), "glow": Color("#8DD6FF")},
		5: {"top": Color("#B07AFF"), "bot": Color("#7030D4"), "glow": Color("#D0ACFF")},
		6: {"top": Color("#FFD740"), "bot": Color("#FFB300"), "glow": Color("#FFE57F")},
	}
	func _ready() -> void:
		custom_minimum_size = Vector2(0, 48)
	func _draw() -> void:
		var tc: Dictionary = _TIER.get(tone, _TIER[3])
		var h := size.y
		var full := done >= total
		var pill_a := 0.15 if full else 0.08
		_fill_pill(Rect2(Vector2.ZERO, size), Color(tc.top.r, tc.top.g, tc.top.b, pill_a), 12.0)
		if full:
			_outline_pill(Rect2(Vector2.ZERO, size), Color(tc.glow.r, tc.glow.g, tc.glow.b, 0.3), 12.0, 1.5)
		var br := 15.0
		var bp := Vector2(26, h * 0.5)
		draw_circle(bp, br + 4, Color(tc.top.r, tc.top.g, tc.top.b, 0.18))
		_gradient_circle(bp, br, tc.top, tc.bot)
		draw_arc(bp, br, 0, TAU, 24, tc.glow, 1.5, true)
		draw_circle(bp + Vector2(-br * 0.25, -br * 0.28), br * 0.12, Color(1, 1, 1, 0.45))
		var ns := badge
		var nfs := 16 if ns.length() <= 2 else 11
		var nw := _FONT.get_string_size(ns, HORIZONTAL_ALIGNMENT_CENTER, -1, nfs)
		var na := _FONT.get_ascent(nfs)
		var nd := _FONT.get_descent(nfs)
		draw_string(_FONT, bp + Vector2(-nw.x * 0.5, (na - nd) * 0.5), ns, HORIZONTAL_ALIGNMENT_CENTER, -1, nfs, Color.WHITE)
		var sp := 22.0
		var sr := 10.0
		var pg := "%d/%d" % [done, total]
		var pfs := 14
		var pw := _FONT.get_string_size(pg, HORIZONTAL_ALIGNMENT_RIGHT, -1, pfs)
		var pip_start := maxf(150.0, size.x - pw.x - 42.0 - float(maxi(total - 1, 0)) * sp)
		var title_width := maxf(40.0, pip_start - 66.0)
		var tfs := 13
		var ta := _FONT.get_ascent(tfs)
		var td := _FONT.get_descent(tfs)
		var title_color := Color(1, 1, 1, 0.92) if full else Color(1, 1, 1, 0.72)
		draw_string(_FONT, Vector2(58, h * 0.5 + (ta - td) * 0.5), title, HORIZONTAL_ALIGNMENT_LEFT, title_width, tfs, title_color)
		for i in total:
			var c := Vector2(pip_start + float(i) * sp, h * 0.5)
			var pts := _star_pts(c, sr)
			if i < done:
				draw_circle(c, sr + 3, Color(tc.glow.r, tc.glow.g, tc.glow.b, 0.25))
				draw_polygon(pts, [tc.top])
				var ol := pts.duplicate()
				ol.append(pts[0])
				draw_polyline(ol, tc.glow, 1.5, true)
				draw_circle(c + Vector2(-sr * 0.22, -sr * 0.28), sr * 0.13, Color(1, 1, 1, 0.55))
			else:
				var ol := pts.duplicate()
				ol.append(pts[0])
				draw_polyline(ol, Color(1, 1, 1, 0.18), 1.5, true)
		var pa := _FONT.get_ascent(pfs)
		var pd := _FONT.get_descent(pfs)
		var pc: Color = tc.glow if full else Color(1, 1, 1, 0.4)
		draw_string(_FONT, Vector2(size.x - pw.x - 14, h * 0.5 + (pa - pd) * 0.5), pg, HORIZONTAL_ALIGNMENT_LEFT, -1, pfs, pc)
	func _star_pts(center: Vector2, r: float) -> PackedVector2Array:
		var pts := PackedVector2Array()
		var ir := r * 0.42
		for i in 10:
			var a := -PI * 0.5 + float(i) * PI / 5.0
			var rd := r if i % 2 == 0 else ir
			pts.append(center + Vector2(cos(a), sin(a)) * rd)
		return pts
	func _gradient_circle(center: Vector2, r: float, top: Color, bot: Color) -> void:
		for i in 12:
			var t0 := float(i) / 12.0
			var t1 := float(i + 1) / 12.0
			var c: Color = top.lerp(bot, (t0 + t1) * 0.5)
			var y0 := center.y - r + 2.0 * r * t0
			var y1 := center.y - r + 2.0 * r * t1
			var mid := (y0 + y1) * 0.5 - center.y
			var hw := sqrt(maxf(r * r - mid * mid, 0.0))
			draw_rect(Rect2(Vector2(center.x - hw, y0), Vector2(hw * 2, y1 - y0)), c)
	func _fill_pill(rect: Rect2, color: Color, r: float) -> void:
		var rr := minf(r, minf(rect.size.x, rect.size.y) * 0.5)
		draw_rect(Rect2(rect.position + Vector2(rr, 0), Vector2(rect.size.x - 2.0 * rr, rect.size.y)), color)
		draw_rect(Rect2(rect.position + Vector2(0, rr), Vector2(rect.size.x, rect.size.y - 2.0 * rr)), color)
		draw_circle(rect.position + Vector2(rr, rr), rr, color)
		draw_circle(rect.position + Vector2(rect.size.x - rr, rr), rr, color)
		draw_circle(rect.position + Vector2(rr, rect.size.y - rr), rr, color)
		draw_circle(rect.position + Vector2(rect.size.x - rr, rect.size.y - rr), rr, color)
	func _outline_pill(rect: Rect2, color: Color, r: float, w: float) -> void:
		var rr := minf(r, minf(rect.size.x, rect.size.y) * 0.5)
		var p := rect.position
		var sz := rect.size
		draw_line(p + Vector2(rr, 0), p + Vector2(sz.x - rr, 0), color, w)
		draw_line(p + Vector2(rr, sz.y), p + Vector2(sz.x - rr, sz.y), color, w)
		draw_line(p + Vector2(0, rr), p + Vector2(0, sz.y - rr), color, w)
		draw_line(p + Vector2(sz.x, rr), p + Vector2(sz.x, sz.y - rr), color, w)
		draw_arc(p + Vector2(rr, rr), rr, PI, PI * 1.5, 12, color, w)
		draw_arc(p + Vector2(sz.x - rr, rr), rr, -PI * 0.5, 0, 12, color, w)
		draw_arc(p + Vector2(rr, sz.y - rr), rr, PI * 0.5, PI, 12, color, w)
		draw_arc(p + Vector2(sz.x - rr, sz.y - rr), rr, 0, PI * 0.5, 12, color, w)
