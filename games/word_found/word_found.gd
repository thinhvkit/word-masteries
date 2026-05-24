extends Control
## Word Found — GDD §4.
## Row 1 = available letters (10–12), Row 2 = letters currently moved down.
## Tap Row 1 letter to move it to Row 2; tap Row 2 letter to return.
## Submit a word to consume its letters and tick its length toward the wave target.
## Bonus words (above/below target lengths) score extra. Unlimited waves; ends
## on wave fail (no remaining letters can form a still-needed target word).

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

const MIN_WORD_LEN := 3
const MAX_WAVE := 40                      # GDD hard ceiling
const BONUS_LONG_MULT := 1.5              # >target length → base × 1.5

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

# Wave target templates by tier and difficulty mode.
# Each template: [{count:int, len:int}, ...]
const TEMPLATES := {
	"easy": {
		"intermediate": [{"count": 2, "len": 3}, {"count": 1, "len": 4}],
		"advanced":     [{"count": 2, "len": 4}, {"count": 1, "len": 5}],
	},
	"medium": {
		"intermediate": [{"count": 3, "len": 3}, {"count": 2, "len": 4}],
		"advanced":     [{"count": 3, "len": 4}, {"count": 2, "len": 5}],
	},
	"hard": {
		"intermediate": [{"count": 4, "len": 3}, {"count": 2, "len": 4}, {"count": 1, "len": 5}],
		"advanced":     [{"count": 3, "len": 4}, {"count": 3, "len": 5}, {"count": 1, "len": 6}],
	},
}

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
var _total_words: int = 0
var _pool_letters: String = ""
var _row1_tiles: Array = []          # all 10-12 tiles in Row 1; their state tells the rest
var _row2_chain: Array = []          # ordered subset currently in Row 2
var _targets: Array = []             # [{"count":N,"len":L,"done":k}, ...]
var _bonus_words: Array = []
var _used_words: Dictionary = {}
var _running: bool = false

func _ready() -> void:
	back_btn.visible = false  # replaced by chrome header
	submit_btn.pressed.connect(_submit_word)
	_apply_design()
	if not _load_session():
		_start_wave(1)

func _apply_design() -> void:
	# Dark arena backdrop instead of cream.
	var arena_bg := Fx.ArenaBG.new()
	arena_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	arena_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	arena_bg.set_world(0)
	add_child(arena_bg)
	move_child(arena_bg, 0)

	# Dark header matching Word Fight.
	var hdr_panel := PanelContainer.new()
	hdr_panel.anchor_right = 1.0
	hdr_panel.offset_bottom = Chrome.HEADER_H
	var hdr_sb := StyleBoxFlat.new()
	hdr_sb.bg_color = Color(0.06, 0.04, 0.10, 0.85)
	hdr_sb.shadow_color = Color(0, 0, 0, 0.4)
	hdr_sb.shadow_size = 6
	hdr_sb.shadow_offset = Vector2i(0, 2)
	hdr_sb.content_margin_left = 16
	hdr_sb.content_margin_right = 16
	hdr_sb.content_margin_top = 18
	hdr_sb.content_margin_bottom = 16
	hdr_panel.add_theme_stylebox_override("panel", hdr_sb)
	add_child(hdr_panel)
	var hdr_row := HBoxContainer.new()
	hdr_row.add_theme_constant_override("separation", 12)
	hdr_panel.add_child(hdr_row)
	var hdr_back := Button.new()
	hdr_back.text = ""
	hdr_back.focus_mode = Control.FOCUS_NONE
	var arrow_path := "res://assets/icons/arrow_left.svg"
	if ResourceLoader.exists(arrow_path):
		hdr_back.icon = load(arrow_path)
		hdr_back.expand_icon = false
		hdr_back.modulate = Color("#c0b4a6")
	var empty_sb := StyleBoxEmpty.new()
	for s_name in ["normal", "hover", "pressed", "focus"]:
		hdr_back.add_theme_stylebox_override(s_name, empty_sb)
	hdr_back.custom_minimum_size = Vector2(48, 48)
	hdr_row.add_child(hdr_back)
	var title_lbl := Label.new()
	title_lbl.text = "Word Found"
	title_lbl.add_theme_font_size_override("font_size", 20)
	title_lbl.add_theme_color_override("font_color", Color("#f5efe8"))
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hdr_row.add_child(title_lbl)
	hdr_back.pressed.connect(func():
		_save_session()
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	)

	var v := $V as Control
	v.offset_top = Chrome.HEADER_H + 8

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

	# Row2: dark word display pill with green border.
	row2_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.3))
	row2_label.add_theme_font_size_override("font_size", 14)
	row2_label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	var row2_node: Control = $V/Row2
	_row2_pill = PanelContainer.new()
	var pill_sb := StyleBoxFlat.new()
	pill_sb.bg_color = Color(0.08, 0.12, 0.08, 0.85)
	pill_sb.set_corner_radius_all(16)
	pill_sb.set_border_width_all(2)
	pill_sb.border_color = Color(0.35, 0.7, 0.4, 0.35)
	pill_sb.shadow_color = Color(0, 0, 0, 0.3)
	pill_sb.shadow_size = 6
	pill_sb.shadow_offset = Vector2i(0, 3)
	pill_sb.content_margin_left = 20
	pill_sb.content_margin_right = 20
	pill_sb.content_margin_top = 14
	pill_sb.content_margin_bottom = 14
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

	# Pick a pool that supports the wave's targets. Try up to N pools.
	var template := _template_for_wave(_wave)
	var picked := _pick_pool(template)
	_pool_letters = picked.pool
	_targets = picked.targets
	_build_row1()
	_build_row2()
	_build_targets_box()
	_refresh_bonus()
	_refresh_hud()
	_set_status("Wave %d — fill the targets below." % _wave)
	_save_session()

func _template_for_wave(w: int) -> Array:
	var tier := "easy"
	if w >= 16: tier = "hard"
	elif w >= 6: tier = "medium"
	var mode_key := "advanced" if GameState.mode == GameState.Mode.ADVANCED else "intermediate"
	return (TEMPLATES[tier][mode_key] as Array).duplicate(true)

func _pick_pool(template: Array) -> Dictionary:
	var attempts := POOLS.duplicate()
	attempts.shuffle()
	for p: String in attempts:
		if p == _pool_letters:
			continue
		var avail := _bucket_words(p)
		if _template_satisfiable(template, avail):
			return {"pool": p, "targets": _annotate_targets(template)}
	for p: String in attempts:
		var avail := _bucket_words(p)
		if _template_satisfiable(template, avail):
			return {"pool": p, "targets": _annotate_targets(template)}
	return {"pool": "STREAMING", "targets": _annotate_targets(template)}

func _bucket_words(pool: String) -> Dictionary:
	# Returns {length: [word, ...]} of all dictionary words formable from pool
	# (each letter used at most once).
	var words: Array[String] = Words.words_from_letters(pool, MIN_WORD_LEN, false)
	var buckets: Dictionary = {}
	for w: String in words:
		var k: int = w.length()
		if not buckets.has(k):
			buckets[k] = []
		buckets[k].append(w)
	return buckets

func _template_satisfiable(template: Array, buckets: Dictionary) -> bool:
	for t: Dictionary in template:
		var have: int = (buckets.get(t.len, []) as Array).size()
		if have < t.count:
			return false
	return true

func _annotate_targets(template: Array) -> Array:
	var out: Array = []
	for t: Dictionary in template:
		out.append({"count": t.count, "len": t.len, "done": 0})
	return out

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
		_refresh_row2_label()
		_update_submit_state()
	elif t.state == TileState.MOVED:
		var idx := _row2_chain.find(t)
		if idx >= 0:
			var to_revert := _row2_chain.slice(idx)
			for rt: WFoundTile in to_revert:
				rt.state = TileState.AVAILABLE
			_row2_chain.resize(idx)
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
		_dungeon_btn(submit_btn, Color("#1a5a2a"), Color("#3a8a4a"), Color.WHITE)
	else:
		_dungeon_btn(submit_btn, Color(0.08, 0.12, 0.08), Color(0.35, 0.7, 0.4, 0.25), Color(1, 1, 1, 0.2))

# ---------------- targets box ----------------

func _build_targets_box() -> void:
	for c in targets_box.get_children():
		c.queue_free()
	targets_box.add_theme_constant_override("separation", 6)
	for t in _targets:
		var row := _TargetRow.new()
		row.word_len = t.len
		row.total = t.count
		row.done = t.done
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
		if t.len == word.length() and t.done < t.count:
			t.done += 1
			matched_target = true
			break
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
	if _score_chip != null:
		var target: Vector2 = _score_chip.global_position + _score_chip.size * 0.5 - global_position
		Fx.confetti_to(self, froms, target, cols)
		Fx.score_popup(self, target + Vector2(-10, 24), "+%d" % earned, word.length() >= 5, VIBRANT_GOLD)
	if word.length() >= 5:
		Fx.banner(self, word_up, VIBRANT_MAGENTA, Color.WHITE)
		Fx.shake(self, 3.0, 0.22)
		Fx.fireworks(self, Vector2(size.x * 0.5, size.y * 0.4))

	_total_words += 1
	if _words_count_lbl != null:
		_words_count_lbl.text = str(_total_words)
	for t: WFoundTile in _row2_chain:
		t.state = TileState.AVAILABLE
	_row2_chain.clear()
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
		_running = false
		await get_tree().create_timer(0.9).timeout
		_start_wave(_wave + 1)
		return

	_set_status("+%d XP — %s" % [earned, word_up])

func _targets_complete() -> bool:
	for t in _targets:
		if t.done < t.count:
			return false
	return true

func _max_target_length() -> int:
	var m := 0
	for t in _targets:
		m = maxi(m, int(t.len))
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
			_targets.append({"count": int(t.count), "len": int(t.len), "done": int(t.done)})
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
	if _row2_pill != null:
		Fx.shake(_row2_pill, 6.0, 0.28)
	if _row1_card != null:
		Fx.shake(_row1_card, 4.0, 0.2)

class _TargetRow extends Control:
	const _FONT: Font = preload("res://assets/fonts/LilitaOne-Regular.ttf")
	var word_len: int = 3 :
		set(v): word_len = v; queue_redraw()
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
		var tc: Dictionary = _TIER.get(word_len, _TIER[3])
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
		var ns := str(word_len)
		var nfs := 16
		var nw := _FONT.get_string_size(ns, HORIZONTAL_ALIGNMENT_CENTER, -1, nfs)
		var na := _FONT.get_ascent(nfs)
		var nd := _FONT.get_descent(nfs)
		draw_string(_FONT, bp + Vector2(-nw.x * 0.5, (na - nd) * 0.5), ns, HORIZONTAL_ALIGNMENT_CENTER, -1, nfs, Color.WHITE)
		var sx := 58.0
		var sp := 30.0
		var sr := 10.0
		for i in total:
			var c := Vector2(sx + float(i) * sp, h * 0.5)
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
		var pg := "%d/%d" % [done, total]
		var pfs := 14
		var pw := _FONT.get_string_size(pg, HORIZONTAL_ALIGNMENT_RIGHT, -1, pfs)
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
