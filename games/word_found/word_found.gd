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
	"STREAMING",         # 9 — STREAM/STING/TRAIN/MAIN/RAIN/...
	"PAINTERS",          # 8
	"REACTIONS",         # 9
	"STRANGER",          # 8
	"TEACHERS",          # 8
	"PLANETARY",         # 9
	"MOUNTAIN",          # 8
	"PARENTING",         # 9
	"SCRAMBLED",         # 9 — RAMBLE/SCALE/CRAB/LACED/...
	"GARDENER",          # 8
	"BREATHING",         # 9 — BREATH/BRING/HEAT/NEAR/...
	"TROUBLES",          # 8 — ROBES/STOLE/LOSER/TUBE/...
	"DREAMING",          # 8
	"LANTERNS",          # 8
	"PROBLEM",           # 7
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
var _row1_bg: Control                # animated vibrant backdrop behind Row 1
var _row1_card: Control              # parent card so we can layer bg under grid
var _submit_glow: Panel              # glowing shadow ring on Submit when chain is ready
var _score_chip: Control             # captured for confetti targeting
var _wave_chip: Control
var _row2_pill: PanelContainer
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
	clear_btn.pressed.connect(_clear_chain)
	_apply_design()
	_start_wave(1)

func _apply_design() -> void:
	Chrome.bg_layer(self)
	var hdr_back := Chrome.header(self, "Word Found", "word_found", GREEN_LIGHT, GREEN_DARK)
	hdr_back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	# Body needs to clear the header band.
	var v := $V as Control
	v.offset_top = Chrome.HEADER_H + 12

	# HUD row — vibrant chip pills.
	wave_lbl.add_theme_font_size_override("font_size", 17)
	wave_lbl.add_theme_color_override("font_color", Color.WHITE)
	score_lbl.add_theme_font_size_override("font_size", 17)
	score_lbl.add_theme_color_override("font_color", VIBRANT_GOLD_DARK)
	_wave_chip = _wrap_in_vibrant_chip(wave_lbl, VIBRANT_BLUE, VIBRANT_BLUE_DARK)
	_score_chip = _wrap_in_vibrant_chip(score_lbl, VIBRANT_GOLD, Color("#dba830"))

	# Targets section — dark vibrant card.
	var targets_label_node: Label = $V/TargetsLabel
	targets_label_node.text = "Targets"
	targets_label_node.add_theme_color_override("font_color", VIBRANT_GOLD)
	targets_label_node.add_theme_font_size_override("font_size", 16)
	_wrap_in_dark_card([targets_label_node, targets_box], v)

	# Row2: vibrant magenta current-word pill.
	row2_label.add_theme_color_override("font_color", Color.WHITE)
	row2_label.add_theme_color_override("font_outline_color", Color(0.5, 0, 0.2, 0.55))
	row2_label.add_theme_constant_override("outline_size", 4)
	row2_label.add_theme_font_size_override("font_size", 28)
	var row2_node: Control = $V/Row2
	var caption := Label.new()
	caption.text = "Your word (tap a letter to undo)"
	caption.add_theme_font_size_override("font_size", 14)
	caption.add_theme_color_override("font_color", Chrome.TEXT_SEC)
	v.add_child(caption)
	v.move_child(caption, row2_node.get_index())
	_row2_pill = PanelContainer.new()
	var pill_sb := StyleBoxFlat.new()
	pill_sb.bg_color = VIBRANT_MAGENTA
	pill_sb.set_corner_radius_all(24)
	pill_sb.set_border_width_all(3)
	pill_sb.border_color = VIBRANT_MAGENTA_DARK
	pill_sb.shadow_color = Color(1.0, 0.4, 0.7, 0.4)
	pill_sb.shadow_size = 10
	pill_sb.shadow_offset = Vector2i(0, 3)
	pill_sb.content_margin_left = 16
	pill_sb.content_margin_right = 16
	pill_sb.content_margin_top = 12
	pill_sb.content_margin_bottom = 12
	_row2_pill.add_theme_stylebox_override("panel", pill_sb)
	v.add_child(_row2_pill)
	v.move_child(_row2_pill, row2_node.get_index())
	row2_node.reparent(_row2_pill, false)

	# Row1 — animated vibrant backdrop behind the grid.
	var row1_lbl: Label = $V/Row1Label
	row1_lbl.text = "Available letters — tap to use"
	row1_lbl.add_theme_color_override("font_color", Chrome.TEXT_SEC)
	row1_lbl.add_theme_font_size_override("font_size", 14)
	_wrap_row1_with_bg(row1_grid, v)

	# Status text styling.
	status_lbl.add_theme_color_override("font_color", Chrome.TEXT)
	status_lbl.add_theme_font_size_override("font_size", 16)
	bonus_lbl.add_theme_color_override("font_color", VIBRANT_GOLD_DARK)
	bonus_lbl.add_theme_font_size_override("font_size", 15)

	# Action buttons — Clear (white pill) + Submit (vibrant magenta with glow).
	_pill_btn(clear_btn, Chrome.SURFACE, Chrome.TEXT)
	clear_btn.add_theme_stylebox_override("normal", _pill_sb(Chrome.SURFACE, Chrome.BORDER, true))
	clear_btn.add_theme_stylebox_override("hover", _pill_sb(Chrome.SURFACE, Chrome.BORDER, true))
	clear_btn.add_theme_stylebox_override("pressed", _pill_sb(Chrome.BORDER, Chrome.BORDER, true))
	_pill_btn(submit_btn, VIBRANT_MAGENTA, Color.WHITE)
	# Wrap submit in a glow panel that activates on chain ≥ MIN_WORD_LEN.
	var submit_parent := submit_btn.get_parent() as Control
	var submit_idx := submit_btn.get_index()
	var submit_wrap := Control.new()
	submit_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	submit_wrap.custom_minimum_size = Vector2(0, 52)
	submit_parent.add_child(submit_wrap)
	submit_parent.move_child(submit_wrap, submit_idx)
	_submit_glow = Panel.new()
	_submit_glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	_submit_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var glow_sb := StyleBoxFlat.new()
	glow_sb.bg_color = Color(1, 0.5, 0.7, 0.0)
	glow_sb.set_corner_radius_all(32)
	glow_sb.shadow_color = Color(1.0, 0.4, 0.7, 0.0)
	glow_sb.shadow_size = 18
	_submit_glow.add_theme_stylebox_override("panel", glow_sb)
	submit_wrap.add_child(_submit_glow)
	submit_btn.reparent(submit_wrap, false)
	submit_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
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

func _wrap_row1_with_bg(grid: GridContainer, parent: Control) -> void:
	var idx := grid.get_index()
	var card := PanelContainer.new()
	# Card stylebox = transparent shell; the animated bg fills it.
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	sb.set_corner_radius_all(20)
	sb.shadow_color = Color(0, 0, 0, 0.2)
	sb.shadow_size = 5
	sb.shadow_offset = Vector2i(0, 3)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 14
	sb.content_margin_bottom = 14
	card.add_theme_stylebox_override("panel", sb)
	# Card itself must expand for the parent VBox to grant it leftover height.
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(card)
	parent.move_child(card, idx)
	# Stack: animated bg fills card; grid sits on top.
	var stack := Control.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.custom_minimum_size = Vector2(0, 240)
	card.add_child(stack)
	_row1_bg = _AnimatedBoardBG.new()
	_row1_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_row1_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(_row1_bg)
	var grid_center := CenterContainer.new()
	grid_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	stack.add_child(grid_center)
	grid.reparent(grid_center, false)
	_row1_card = card

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
		var avail := _bucket_words(p)
		if _template_satisfiable(template, avail):
			return {"pool": p, "targets": _annotate_targets(template)}
	# Fallback: STREAMING is reliable.
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
	row1_grid.columns = mini(_pool_letters.length(), 6)
	var letters := []
	for ch in _pool_letters:
		letters.append(ch)
	letters.shuffle()
	for i in letters.size():
		var ch: String = letters[i]
		var t: WFoundTile = Tile.new()
		t.letter = ch
		t.pressed.connect(_on_row1_tile_pressed)
		t.tile_picked_fx.connect(_on_tile_picked_fx)
		row1_grid.add_child(t)
		_row1_tiles.append(t)
		t.play_pop_in(i * 0.035)

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
		# Move into Row 2
		t.state = TileState.MOVED
		_row2_chain.append(t)
		_refresh_row2_label()
		_update_submit_state()

func _on_row2_tile_pressed(t: WFoundTile) -> void:
	# Tap a Row-2 tile returns it to Row 1 (full undo).
	if not _running or t.state != TileState.MOVED:
		return
	t.state = TileState.AVAILABLE
	_row2_chain.erase(t)
	_refresh_row2_label()
	_update_submit_state()

func _clear_chain() -> void:
	for t: WFoundTile in _row2_chain.duplicate():
		_on_row2_tile_pressed(t)

func _refresh_row2_label() -> void:
	# Render the current word using a transient label list rather than moving
	# tile widgets between rows (keeps Row 1 layout stable).
	for c in row2_holder.get_children():
		c.queue_free()
	for t: WFoundTile in _row2_chain:
		var mini_btn := Button.new()
		mini_btn.text = t.letter
		mini_btn.custom_minimum_size = Vector2(36, 40)
		mini_btn.add_theme_font_size_override("font_size", 18)
		mini_btn.focus_mode = Control.FOCUS_NONE
		Palette.style_button(mini_btn, Palette.PINK, Color.WHITE, 10)
		mini_btn.pressed.connect(func(): _on_row2_tile_pressed(t))
		row2_holder.add_child(mini_btn)
	var word := _chain_word()
	row2_label.text = word if not word.is_empty() else "—"

func _chain_word() -> String:
	var s := ""
	for t: WFoundTile in _row2_chain:
		s += t.letter
	return s

func _update_submit_state() -> void:
	var len_ok := _chain_word().length() >= MIN_WORD_LEN
	submit_btn.disabled = not len_ok
	if _submit_glow != null:
		var sb := _submit_glow.get_theme_stylebox("panel") as StyleBoxFlat
		if sb != null:
			var fresh: StyleBoxFlat = sb.duplicate()
			fresh.shadow_color = Color(1.0, 0.4, 0.7, 0.55 if len_ok else 0.0)
			fresh.shadow_size = 22 if len_ok else 0
			_submit_glow.add_theme_stylebox_override("panel", fresh)

# ---------------- targets box ----------------

func _build_targets_box() -> void:
	for c in targets_box.get_children():
		c.queue_free()
	for t in _targets:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var head := Label.new()
		head.text = "%d-letter:" % t.len
		head.add_theme_color_override("font_color", Color.WHITE)
		head.add_theme_font_size_override("font_size", 14)
		head.custom_minimum_size = Vector2(80, 0)
		row.add_child(head)
		for i in t.count:
			var pip := _Pip.new()
			pip.filled = i < t.done
			pip.color = VIBRANT_GOLD
			row.add_child(pip)
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

	# Letters stay usable — return them to AVAILABLE so the player can reuse them.
	for t: WFoundTile in _row2_chain:
		t.state = TileState.AVAILABLE
	_row2_chain.clear()
	_refresh_row2_label()
	_update_submit_state()
	_refresh_targets_box()
	_refresh_hud()
	_refresh_bonus()

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

# ---------------- small pip widget ----------------

func _invalid_shake() -> void:
	if _row2_pill != null:
		Fx.shake(_row2_pill, 6.0, 0.28)
	if _row1_card != null:
		Fx.shake(_row1_card, 4.0, 0.2)

class _Pip extends Control:
	var filled: bool = false :
		set(v): filled = v; queue_redraw()
	var color: Color = Color("#ffd027") :
		set(v): color = v; queue_redraw()
	func _ready() -> void:
		custom_minimum_size = Vector2(18, 18)
		size = Vector2(18, 18)
	func _draw() -> void:
		var center := size * 0.5
		if filled:
			draw_circle(center, 8, color)
			draw_arc(center, 8, 0, TAU, 24, color.darkened(0.25), 1.5, true)
		else:
			draw_arc(center, 8, 0, TAU, 24, Color(1, 1, 1, 0.35), 2.0, true)

# ---------------- animated vibrant backdrop ----------------
class _AnimatedBoardBG extends Control:
	var _t: float = 0.0
	func _ready() -> void:
		set_process(true)
		clip_contents = true
	func _process(delta: float) -> void:
		_t += delta * 0.35
		queue_redraw()
	func _draw() -> void:
		var palette := [
			Color("#3aa8ff"), Color("#7a55ff"), Color("#ff3aa8"),
			Color("#ff7a1f"), Color("#ffd027"), Color("#3ad6a8"),
		]
		var radius := 18.0
		_round_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.04, 0.12, 1), radius)
		var bands := 18
		var w := size.x
		var h := size.y
		for i in bands:
			var t0: float = float(i) / float(bands)
			var t1: float = float(i + 1) / float(bands)
			var phase: float = fmod(t0 + _t, 1.0) * palette.size()
			var idx: int = int(phase) % palette.size()
			var nxt: int = (idx + 1) % palette.size()
			var f: float = phase - floor(phase)
			var col: Color = palette[idx].lerp(palette[nxt], f)
			col.a = 0.5
			draw_rect(Rect2(Vector2(0, h * t0), Vector2(w, h * (t1 - t0))), col)
		_round_rect(Rect2(Vector2(4, 4), size - Vector2(8, 8)), Color(1, 1, 1, 0.05), radius - 4)
		_outline(Rect2(Vector2.ZERO, size), Color(1, 1, 1, 0.25), radius, 2.0)
	func _round_rect(rect: Rect2, color: Color, radius: float) -> void:
		var r: float = minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
		draw_rect(Rect2(rect.position + Vector2(r, 0), Vector2(rect.size.x - 2*r, rect.size.y)), color)
		draw_rect(Rect2(rect.position + Vector2(0, r), Vector2(rect.size.x, rect.size.y - 2*r)), color)
		draw_circle(rect.position + Vector2(r, r), r, color)
		draw_circle(rect.position + Vector2(rect.size.x - r, r), r, color)
		draw_circle(rect.position + Vector2(r, rect.size.y - r), r, color)
		draw_circle(rect.position + Vector2(rect.size.x - r, rect.size.y - r), r, color)
	func _outline(rect: Rect2, color: Color, radius: float, width: float) -> void:
		var r: float = minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
		draw_line(rect.position + Vector2(r, 0), rect.position + Vector2(rect.size.x - r, 0), color, width)
		draw_line(rect.position + Vector2(r, rect.size.y), rect.position + Vector2(rect.size.x - r, rect.size.y), color, width)
		draw_line(rect.position + Vector2(0, r), rect.position + Vector2(0, rect.size.y - r), color, width)
		draw_line(rect.position + Vector2(rect.size.x, r), rect.position + Vector2(rect.size.x, rect.size.y - r), color, width)
		draw_arc(rect.position + Vector2(r, r), r, PI, PI * 1.5, 16, color, width)
		draw_arc(rect.position + Vector2(rect.size.x - r, r), r, -PI * 0.5, 0, 16, color, width)
		draw_arc(rect.position + Vector2(r, rect.size.y - r), r, PI * 0.5, PI, 16, color, width)
		draw_arc(rect.position + Vector2(rect.size.x - r, rect.size.y - r), r, 0, PI * 0.5, 16, color, width)
