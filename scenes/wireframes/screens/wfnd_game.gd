extends Control
## Word Found — live gameplay (wireframe styling).
## Row 1 = available letters, Row 2 = the word being built.
## Targets per wave; bonus words allowed; unlimited waves until fail.

const WF := preload("res://scripts/wf/wf.gd")
const Screen := preload("res://scripts/wf/wf_screen.gd")

const MIN_LEN := 3
const MAX_WAVE := 40
const BONUS_MULT := 1.5

const POOLS := [
	"STREAMING","PAINTERS","REACTIONS","STRANGER","TEACHERS",
	"PLANETARY","MOUNTAIN","PARENTING","SCRAMBLED","GARDENER",
	"BREATHING","TROUBLES","DREAMING","LANTERNS","PROBLEM",
]
const TEMPLATES := {
	"easy": {
		"intermediate": [{"count":2,"len":3},{"count":1,"len":4}],
		"advanced":     [{"count":2,"len":4},{"count":1,"len":5}],
	},
	"medium": {
		"intermediate": [{"count":3,"len":3},{"count":2,"len":4}],
		"advanced":     [{"count":3,"len":4},{"count":2,"len":5}],
	},
	"hard": {
		"intermediate": [{"count":4,"len":3},{"count":2,"len":4},{"count":1,"len":5}],
		"advanced":     [{"count":3,"len":4},{"count":3,"len":5},{"count":1,"len":6}],
	},
}

# UI refs
var _phone: Control
var _wave_tag: Control
var _score_box: Control
var _score_lbl: Label
var _wave_lbl_in_tag: Label
var _targets_pills_row: HBoxContainer
var _row2_holder: HBoxContainer
var _row2_current_lbl: Label
var _row1_grid: GridContainer
var _bonus_pills_row: HBoxContainer
var _submit_btn: Button
var _clear_btn: Button

# State
var _wave: int = 1
var _score: int = 0
var _pool: String = ""
var _row1_tiles: Array = []           # All tiles (with state)
var _row2_chain: Array = []           # Tiles currently in Row 2
var _targets: Array = []              # [{count, len, done}]
var _bonus: Array = []
var _used: Dictionary = {}
var _running: bool = false

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_layout()
	Screen.wire_nav(self)
	_start_wave(1)

func _build_layout() -> void:
	_phone = WF.Phone.new()
	_phone.set_anchors_preset(Control.PRESET_FULL_RECT)
	_phone.set_header(WF.app_head("Word Found", true, _mode_label()))
	add_child(_phone)
	var body: VBoxContainer = _phone.padded_body(Vector4(16, 16, 16, 16), 12)
	# Top row: wave tag + score
	var top := HBoxContainer.new()
	_wave_tag = WF.wave_tag(1)
	# wave_tag returns a PanelContainer containing a Label; cache the label.
	_wave_lbl_in_tag = _find_label_in(_wave_tag)
	top.add_child(_wave_tag)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(sp)
	var sc := VBoxContainer.new()
	sc.alignment = BoxContainer.ALIGNMENT_CENTER
	var sc_l := WF.make_label("Score", 14, WF.MUTED)
	sc_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sc.add_child(sc_l)
	_score_lbl = WF.make_label("0", 28, WF.ACCENT, true)
	_score_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sc.add_child(_score_lbl)
	top.add_child(sc)
	body.add_child(top)
	# Target card
	var tcard := WF.card(WF.PURPLE_BG, WF.PURPLE, 12, 12, 2)
	var tbox := VBoxContainer.new()
	tbox.add_child(WF.make_label("Target: find these words", 14, WF.PURPLE, true))
	_targets_pills_row = HBoxContainer.new()
	_targets_pills_row.add_theme_constant_override("separation", 6)
	tbox.add_child(_targets_pills_row)
	tcard.add_child(tbox)
	body.add_child(tcard)
	# Row 2
	body.add_child(WF.make_label("Your word ↓", 14, WF.MUTED))
	var r2card := WF.card(WF.ACCENT_BG, WF.ACCENT, 8, 12, 2)
	var r2_v := VBoxContainer.new()
	_row2_holder = HBoxContainer.new()
	_row2_holder.add_theme_constant_override("separation", 6)
	r2_v.add_child(_row2_holder)
	_row2_current_lbl = WF.make_label("(tap letters below to build a word)", 13, WF.MUTED)
	r2_v.add_child(_row2_current_lbl)
	r2card.add_child(r2_v)
	body.add_child(r2card)
	# Row 1
	body.add_child(WF.make_label("Available letters ↓ tap to use", 14, WF.MUTED))
	var r1card := WF.card(WF.PAPER, WF.BORDER_LITE, 8, 12, 2)
	_row1_grid = GridContainer.new()
	_row1_grid.add_theme_constant_override("h_separation", 6)
	_row1_grid.add_theme_constant_override("v_separation", 6)
	r1card.add_child(_row1_grid)
	body.add_child(r1card)
	# Bonus
	var bcard := WF.card(Color("#f5f5f3"), Color(0,0,0,0), 10, 10, 0)
	var brow := HBoxContainer.new()
	brow.add_theme_constant_override("separation", 6)
	brow.add_child(WF.make_label("Bonus words:", 14, WF.MUTED))
	_bonus_pills_row = HBoxContainer.new()
	_bonus_pills_row.add_theme_constant_override("separation", 6)
	brow.add_child(_bonus_pills_row)
	bcard.add_child(brow)
	body.add_child(bcard)
	# Actions
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	_clear_btn = WF.wf_btn("Clear", false, true)
	_clear_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_clear_btn.pressed.connect(_on_clear)
	actions.add_child(_clear_btn)
	_submit_btn = WF.wf_btn("Submit Word", true)
	_submit_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_submit_btn.pressed.connect(_on_submit)
	_submit_btn.disabled = true
	actions.add_child(_submit_btn)
	body.add_child(actions)

func _find_label_in(n: Node) -> Label:
	if n is Label: return n
	for c in n.get_children():
		var l := _find_label_in(c)
		if l != null: return l
	return null

func _mode_label() -> String:
	return "Intermediate" if GameState.mode == GameState.Mode.INTERMEDIATE else "Advanced"

# ─────────── wave setup ───────────

func _start_wave(w: int) -> void:
	_wave = mini(w, MAX_WAVE)
	_used.clear()
	_bonus.clear()
	_row2_chain.clear()
	_row1_tiles.clear()
	_targets = _template_for_wave(_wave)
	_pool = _pick_pool()
	_build_row1()
	_refresh_targets()
	_refresh_row2()
	_refresh_bonus()
	_refresh_hud()
	_running = true

func _template_for_wave(w: int) -> Array:
	var tier := "easy"
	if w >= 16: tier = "hard"
	elif w >= 6: tier = "medium"
	var key := "advanced" if GameState.mode == GameState.Mode.ADVANCED else "intermediate"
	var out: Array = []
	for t in (TEMPLATES[tier][key] as Array):
		out.append({"count": int(t.count), "len": int(t.len), "done": 0})
	return out

func _pick_pool() -> String:
	var shuffled := POOLS.duplicate()
	shuffled.shuffle()
	for p in shuffled:
		var buckets := _buckets_for(p)
		var ok := true
		for t in _targets:
			if (buckets.get(t.len, []) as Array).size() < t.count:
				ok = false; break
		if ok: return p
	return "STREAMING"

func _buckets_for(pool: String) -> Dictionary:
	var b: Dictionary = {}
	var words: Array[String] = Words.words_from_letters(pool, MIN_LEN, false)
	for w in words:
		var k: int = w.length()
		if not b.has(k): b[k] = []
		b[k].append(w)
	return b

func _build_row1() -> void:
	for c in _row1_grid.get_children():
		c.queue_free()
	_row1_grid.columns = mini(_pool.length(), 6)
	var arr := []
	for ch in _pool:
		arr.append(ch)
	arr.shuffle()
	for ch: String in arr:
		var t := _Tile.new()
		t.letter = ch
		t.tile_pressed.connect(_on_row1_pressed)
		_row1_grid.add_child(t)
		_row1_tiles.append(t)

# ─────────── input ───────────

func _on_row1_pressed(t: Control) -> void:
	if not _running: return
	if t.state == 2: return  # used
	if t.state == 1: return  # already moved
	t.state = 1
	_row2_chain.append(t)
	_refresh_row2()
	_update_submit()

func _on_row2_pressed(t: Control) -> void:
	if not _running: return
	t.state = 0
	_row2_chain.erase(t)
	_refresh_row2()
	_update_submit()

func _on_clear() -> void:
	for t in _row2_chain.duplicate():
		_on_row2_pressed(t)

func _refresh_row2() -> void:
	for c in _row2_holder.get_children():
		c.queue_free()
	if _row2_chain.is_empty():
		_row2_current_lbl.text = "(tap letters below to build a word)"
		return
	for t in _row2_chain:
		var b := Button.new()
		b.text = (t as Control).letter
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_override("font", WF.font_bold())
		b.add_theme_font_size_override("font_size", 18)
		b.add_theme_color_override("font_color", Color.WHITE)
		var sb := StyleBoxFlat.new()
		sb.bg_color = WF.ACCENT
		sb.set_corner_radius_all(8)
		sb.set_border_width_all(2)
		sb.border_color = WF.ACCENT.darkened(0.18)
		sb.content_margin_left = 8; sb.content_margin_right = 8
		sb.content_margin_top = 4; sb.content_margin_bottom = 4
		b.add_theme_stylebox_override("normal", sb)
		b.add_theme_stylebox_override("hover", sb)
		b.add_theme_stylebox_override("pressed", sb)
		b.custom_minimum_size = Vector2(34, 38)
		var tile_ref: Control = t
		b.pressed.connect(func(): _on_row2_pressed(tile_ref))
		_row2_holder.add_child(b)
	_row2_current_lbl.text = _chain_word()

func _chain_word() -> String:
	var s := ""
	for t in _row2_chain: s += (t as Control).letter
	return s

func _update_submit() -> void:
	_submit_btn.disabled = _chain_word().length() < MIN_LEN

# ─────────── submit ───────────

func _on_submit() -> void:
	if not _running: return
	var word_up := _chain_word()
	var word := word_up.to_lower()
	if word.length() < MIN_LEN: return
	if _used.has(word): return
	if not Words.is_valid(word): return
	_used[word] = true
	# Score
	var matched := false
	for t in _targets:
		if t.len == word.length() and t.done < t.count:
			t.done += 1
			matched = true
			break
	var base := word.length() * 10
	if not matched and word.length() > _max_target_len():
		base = int(base * BONUS_MULT)
	var earned := GameState.add_xp("word_found", base)
	_score += earned
	if not matched:
		_bonus.append(word_up)
	# Consume letters
	for t in _row2_chain:
		(t as Control).state = 2
	_row2_chain.clear()
	_refresh_row2()
	_update_submit()
	_refresh_targets()
	_refresh_bonus()
	_refresh_hud()
	if _targets_complete():
		_running = false
		GameState.set_meta("wfnd_wave_done", _wave)
		var nav: Node = Engine.get_main_loop().get_root().get_node_or_null("Navigator")
		await get_tree().create_timer(0.7).timeout
		if nav != null: nav.goto("wfnd_wave")
		return
	if _is_wave_failed():
		_running = false
		_submit_btn.disabled = true
		var nav: Node = Engine.get_main_loop().get_root().get_node_or_null("Navigator")
		await get_tree().create_timer(0.7).timeout
		if nav != null: nav.goto("wfnd_over")

func _targets_complete() -> bool:
	for t in _targets:
		if t.done < t.count: return false
	return true

func _max_target_len() -> int:
	var m := 0
	for t in _targets: m = maxi(m, int(t.len))
	return m

func _is_wave_failed() -> bool:
	var remaining := ""
	for t in _row1_tiles:
		if (t as Control).state == 0: remaining += (t as Control).letter
	if remaining.length() < MIN_LEN: return true
	var need: Array = []
	for t in _targets:
		if t.done < t.count: need.append(int(t.len))
	if need.is_empty(): return false
	for n_len: int in need:
		var candidates: Array[String] = Words.words_from_letters(remaining, n_len, false)
		for w in candidates:
			if w.length() == n_len and not _used.has(w): return false
	return true

# ─────────── HUD ───────────

func _refresh_targets() -> void:
	for c in _targets_pills_row.get_children():
		c.queue_free()
	for t in _targets:
		for i in t.count:
			var done: bool = i < t.done
			var text: String = "%d-letter %d/%d" % [t.len, t.done, t.count] if i == 0 else ""
			# Show one pill per slot — filled vs blank.
			if i == 0:
				_targets_pills_row.add_child(WF.pill("%d-letter %d/%d" % [t.len, t.done, t.count],
					WF.SUCCESS if t.done >= t.count else WF.PURPLE,
					WF.SUCCESS_BG if t.done >= t.count else WF.PURPLE_BG))

func _refresh_bonus() -> void:
	for c in _bonus_pills_row.get_children():
		c.queue_free()
	if _bonus.is_empty():
		_bonus_pills_row.add_child(WF.make_label("—", 14, WF.MUTED))
		return
	for w in _bonus:
		_bonus_pills_row.add_child(WF.pill(w, WF.SUCCESS, WF.SUCCESS_BG))

func _refresh_hud() -> void:
	if _wave_lbl_in_tag != null:
		_wave_lbl_in_tag.text = "Wave %d" % _wave
	_score_lbl.text = str(_score)

# ─────────── tile widget ───────────

class _Tile extends Control:
	signal tile_pressed(tile)
	const SZ := 40.0
	var letter: String = "A" :
		set(v): letter = v.to_upper(); queue_redraw()
	# 0 = available, 1 = moved (in row 2), 2 = used (consumed)
	var state: int = 0 :
		set(v): state = v; queue_redraw()
	func _ready() -> void:
		custom_minimum_size = Vector2(SZ, SZ)
		size = Vector2(SZ, SZ)
		mouse_filter = Control.MOUSE_FILTER_STOP
	func _gui_input(ev: InputEvent) -> void:
		if state == 2: return
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			tile_pressed.emit(self)
		elif ev is InputEventScreenTouch and ev.pressed:
			tile_pressed.emit(self)
	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, size)
		var bg: Color = WF.PAPER
		var border: Color = WF.BORDER
		var text_col: Color = WF.TEXT
		if state == 1:
			bg = WF.ACCENT_BG; border = WF.ACCENT; text_col = WF.ACCENT
		elif state == 2:
			bg = Color("#e8e8e6"); border = WF.BORDER_LITE; text_col = WF.MUTED
		draw_rect(rect, bg, true)
		draw_rect(rect, border, false, 2.0)
		var f := WF.font_bold()
		var fs := 20
		var ts := f.get_string_size(letter, HORIZONTAL_ALIGNMENT_CENTER, -1, fs)
		draw_string(f, size * 0.5 - ts * 0.5 + Vector2(0, fs * 0.36),
			letter, HORIZONTAL_ALIGNMENT_CENTER, -1, fs, text_col)
