extends Control
## Word Found — GDD §4.
## Row 1 = available letters (10–12), Row 2 = letters currently moved down.
## Tap Row 1 letter to move it to Row 2; tap Row 2 letter to return.
## Submit a word to consume its letters and tick its length toward the wave target.
## Bonus words (above/below target lengths) score extra. Unlimited waves; ends
## on wave fail (no remaining letters can form a still-needed target word).

const Tile := preload("res://games/word_found/tile_node.gd")
const TileState := Tile.State

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
	back_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	submit_btn.pressed.connect(_submit_word)
	clear_btn.pressed.connect(_clear_chain)
	_style_buttons()
	_start_wave(1)

func _style_buttons() -> void:
	Palette.style_button(submit_btn, Palette.PINK, Color.WHITE, 14)
	Palette.style_button(clear_btn, Palette.BG_SOFT, Palette.TEXT, 14)
	submit_btn.add_theme_font_size_override("font_size", 16)
	clear_btn.add_theme_font_size_override("font_size", 16)
	submit_btn.disabled = true

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
			pip.color = Palette.SAGE
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
