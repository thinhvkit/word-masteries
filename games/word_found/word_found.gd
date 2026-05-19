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

	# HUD row — replace plain labels with pill chips.
	wave_lbl.add_theme_font_size_override("font_size", 14)
	wave_lbl.add_theme_color_override("font_color", GREEN_DARK)
	score_lbl.add_theme_font_size_override("font_size", 14)
	score_lbl.add_theme_color_override("font_color", GOLD_DARK)
	_wrap_in_chip(wave_lbl, GREEN_LIGHT)
	_wrap_in_chip(score_lbl, GOLD_LIGHT)

	# Targets section — wrap label + box in a purple card.
	var targets_label_node: Label = $V/TargetsLabel
	targets_label_node.add_theme_color_override("font_color", PURPLE_DARK)
	targets_label_node.add_theme_font_size_override("font_size", 14)
	_wrap_in_card([targets_label_node, targets_box], v, PURPLE_LIGHT, PURPLE_BORDER, 14)

	# Row2: relabel + style the current-word pill (pink).
	row2_label.add_theme_color_override("font_color", Chrome.TEXT_SEC)
	row2_label.add_theme_font_size_override("font_size", 18)
	var row2_node: Control = $V/Row2
	# Insert caption above the pill.
	var caption := Label.new()
	caption.text = "Your word ↓ (tap to undo)"
	caption.add_theme_font_size_override("font_size", 12)
	caption.add_theme_color_override("font_color", Chrome.TEXT_SEC)
	v.add_child(caption)
	v.move_child(caption, row2_node.get_index())
	# Wrap the Current label + Tiles row in a pink pill panel.
	var pill := PanelContainer.new()
	var pill_sb := StyleBoxFlat.new()
	pill_sb.bg_color = PINK_LIGHT
	pill_sb.set_corner_radius_all(20)
	pill_sb.set_border_width_all(2)
	pill_sb.border_color = PINK_BORDER
	pill_sb.content_margin_left = 16
	pill_sb.content_margin_right = 16
	pill_sb.content_margin_top = 10
	pill_sb.content_margin_bottom = 10
	pill.add_theme_stylebox_override("panel", pill_sb)
	v.add_child(pill)
	v.move_child(pill, row2_node.get_index())
	row2_node.reparent(pill, false)

	# Row1 — caption + white card around the grid.
	var row1_lbl: Label = $V/Row1Label
	row1_lbl.text = "Available letters ↓ tap to use"
	row1_lbl.add_theme_color_override("font_color", Chrome.TEXT_SEC)
	row1_lbl.add_theme_font_size_override("font_size", 12)
	_wrap_in_card([row1_grid], v, Chrome.SURFACE, Chrome.BORDER, 16)

	# Status text styling.
	status_lbl.add_theme_color_override("font_color", Chrome.TEXT_SEC)
	bonus_lbl.add_theme_color_override("font_color", Chrome.TEXT_SEC)

	# Action buttons — Clear (white pill) + Submit (sage-green pill).
	_pill_btn(clear_btn, Chrome.SURFACE, Chrome.TEXT)
	clear_btn.add_theme_stylebox_override("normal", _pill_sb(Chrome.SURFACE, Chrome.BORDER, true))
	clear_btn.add_theme_stylebox_override("hover", _pill_sb(Chrome.SURFACE, Chrome.BORDER, true))
	clear_btn.add_theme_stylebox_override("pressed", _pill_sb(Chrome.BORDER, Chrome.BORDER, true))
	_pill_btn(submit_btn, SUBMIT_GREEN, SUBMIT_GREEN_TEXT)
	submit_btn.disabled = true

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
	for ch: String in letters:
		var t: WFoundTile = Tile.new()
		t.letter = ch
		t.pressed.connect(_on_row1_tile_pressed)
		row1_grid.add_child(t)
		_row1_tiles.append(t)

func _build_row2() -> void:
	for c in row2_holder.get_children():
		c.queue_free()
	_row2_chain.clear()
	_refresh_row2_label()

func _on_row1_tile_pressed(t: WFoundTile) -> void:
	if not _running:
		return
	if t.state == TileState.USED:
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
	submit_btn.disabled = _chain_word().length() < MIN_WORD_LEN

# ---------------- targets box ----------------

func _build_targets_box() -> void:
	for c in targets_box.get_children():
		c.queue_free()
	for t in _targets:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var head := Label.new()
		head.text = "%d-letter:" % t.len
		head.add_theme_color_override("font_color", Palette.TEXT)
		head.add_theme_font_size_override("font_size", 13)
		head.custom_minimum_size = Vector2(80, 0)
		row.add_child(head)
		for i in t.count:
			var pip := _Pip.new()
			pip.filled = i < t.done
			pip.color = PURPLE_DARK
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
		return
	if not Words.is_valid(word):
		_set_status("Not a word: %s" % word_up)
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

	# Consume letters
	for t: WFoundTile in _row2_chain:
		t.state = TileState.USED
	_row2_chain.clear()
	_refresh_row2_label()
	_update_submit_state()
	_refresh_targets_box()
	_refresh_hud()
	_refresh_bonus()

	if _targets_complete():
		_set_status("Wave %d cleared! +%d XP" % [_wave, earned])
		_running = false
		await get_tree().create_timer(0.9).timeout
		_start_wave(_wave + 1)
		return

	if _is_wave_failed():
		_set_status("Out of usable letters — wave failed.")
		_running = false
		submit_btn.disabled = true
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

func _is_wave_failed() -> bool:
	# We fail if no remaining (AVAILABLE) letter can possibly form any word
	# satisfying a still-needed target length.
	var remaining := ""
	for t: WFoundTile in _row1_tiles:
		if t.state == TileState.AVAILABLE:
			remaining += t.letter
	if remaining.length() < MIN_WORD_LEN:
		return true
	var still_need_lengths: Array = []
	for t in _targets:
		if t.done < t.count:
			still_need_lengths.append(int(t.len))
	if still_need_lengths.is_empty():
		return false
	# Quick filter: enumerate dictionary words formable from remaining letters
	# for the minimum still-needed length; any unused word at any still-needed
	# length saves us.
	for needed_len: int in still_need_lengths:
		var candidates: Array[String] = Words.words_from_letters(remaining, needed_len, false)
		for w in candidates:
			if w.length() == needed_len and not _used_words.has(w):
				return false
	return true

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

class _Pip extends Control:
	var filled: bool = false :
		set(v): filled = v; queue_redraw()
	var color: Color = Color("#6dd68a") :
		set(v): color = v; queue_redraw()
	func _ready() -> void:
		custom_minimum_size = Vector2(18, 18)
		size = Vector2(18, 18)
	func _draw() -> void:
		var center := size * 0.5
		if filled:
			draw_circle(center, 8, color)
			draw_arc(center, 8, 0, TAU, 24, color.darkened(0.18), 1.5, true)
		else:
			draw_arc(center, 8, 0, TAU, 24, Color("#cdbfb2"), 2.0, true)
