extends Control
## Word Fight — live gameplay (wireframe styling).
## 5×5 shared board, turns, AI, topic ×2 bonus, rainbow streak per GDD §2.

const WF := preload("res://scripts/wf/wf.gd")
const Screen := preload("res://scripts/wf/wf_screen.gd")
const Topics := preload("res://games/word_fight/topics.gd")

const ROWS := 5
const COLS := 5
const MIN_LEN := 3
const MIN_VOWELS := 4
const DMG_PER_LETTER := 10
const TOPIC_MULT := 2.0
const RAINBOW_STREAK := 4
const RAINBOW_MAX := 3
const PLAYER_HP := 100
const LETTER_WEIGHTS := {
	"E":12,"A":9,"I":9,"O":8,"N":6,"R":6,"T":6,"L":4,
	"S":4,"U":4,"D":4,"G":3,"B":2,"C":2,"M":2,"P":2,
	"F":2,"H":2,"V":2,"W":2,"Y":2,"K":1,"J":1,"X":1,"Q":1,"Z":1,
}
const VOWELS := "AEIOU"
const ENEMIES := [
	{"name":"Goblin","hp":80,"skill":0.4},
	{"name":"Wraith","hp":110,"skill":0.6},
	{"name":"Dragon","hp":160,"skill":0.9},
]

# ---- UI refs ----
var _phone: Control
var _player_hp_canvas: ProgressBar
var _enemy_hp_canvas: ProgressBar
var _player_hp_lbl: Label
var _enemy_hp_lbl: Label
var _enemy_name_lbl: Label
var _topic_chip: Label
var _word_lbl: Label
var _dmg_lbl: Label
var _board_grid: GridContainer
var _booster_row: HBoxContainer
var _streak_dots_holder: Control
var _log_box: VBoxContainer
var _submit_btn: Button
var _clear_btn: Button

# ---- state ----
var _tiles: Array = []      # row-major Array of _Tile, 25 cells
var _chain: Array = []      # ordered _Tile in current word
var _used_words: Dictionary = {}
var _player_hp_val: int = PLAYER_HP
var _enemy_hp_val: int = 0
var _enemy_max: int = 0
var _enemy_idx: int = 0
var _topic: String = "food"
var _streak_5plus: int = 0
var _rainbows: int = 0
var _busy: bool = false
var _player_turn: bool = true

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_layout()
	Screen.wire_nav(self)
	_start_battle()

func _build_layout() -> void:
	_phone = WF.Phone.new()
	_phone.set_anchors_preset(Control.PRESET_FULL_RECT)
	_phone.set_header(WF.app_head("Word Fight", true, _topic.capitalize()))
	add_child(_phone)
	var body: VBoxContainer = _phone.padded_body(Vector4(12, 12, 12, 12), 8)
	# Player HP row
	var pr := HBoxContainer.new()
	pr.add_theme_constant_override("separation", 12)
	pr.add_child(WF.avatar("", 32))
	var pcol := VBoxContainer.new()
	pcol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_player_hp_lbl = WF.make_label("You: 100/100", 13, WF.TEXT)
	pcol.add_child(_player_hp_lbl)
	_player_hp_canvas = ProgressBar.new()
	_player_hp_canvas.max_value = PLAYER_HP
	_player_hp_canvas.value = PLAYER_HP
	_player_hp_canvas.show_percentage = false
	_player_hp_canvas.custom_minimum_size = Vector2(0, 12)
	_apply_bar_style(_player_hp_canvas, WF.SUCCESS)
	pcol.add_child(_player_hp_canvas)
	pr.add_child(pcol)
	body.add_child(pr)
	# Enemy HP row
	var er := HBoxContainer.new()
	er.add_theme_constant_override("separation", 12)
	er.add_child(WF.avatar("", 32, true))
	var ecol := VBoxContainer.new()
	ecol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_enemy_name_lbl = WF.make_label("Enemy", 13, WF.DANGER, true)
	ecol.add_child(_enemy_name_lbl)
	_enemy_hp_canvas = ProgressBar.new()
	_enemy_hp_canvas.show_percentage = false
	_enemy_hp_canvas.custom_minimum_size = Vector2(0, 12)
	_apply_bar_style(_enemy_hp_canvas, WF.DANGER)
	ecol.add_child(_enemy_hp_canvas)
	_enemy_hp_lbl = WF.make_label("0/0", 13, WF.MUTED)
	ecol.add_child(_enemy_hp_lbl)
	er.add_child(ecol)
	body.add_child(er)
	# Topic
	_topic_chip = WF.make_label("Topic: —", 14, WF.WARN)
	_topic_chip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(_topic_chip)
	# Current word
	var wc := WF.card(WF.ACCENT_BG, WF.ACCENT, 8, 12, 2)
	var wrow := HBoxContainer.new()
	wrow.alignment = BoxContainer.ALIGNMENT_CENTER
	wrow.add_theme_constant_override("separation", 8)
	wrow.add_child(WF.make_label("Your word:", 14, WF.MUTED))
	_word_lbl = WF.make_label("—", 24, WF.ACCENT, true)
	wrow.add_child(_word_lbl)
	_dmg_lbl = WF.make_label("", 14, WF.SUCCESS)
	wrow.add_child(_dmg_lbl)
	wc.add_child(wrow)
	body.add_child(wc)
	# Board
	var board_card := WF.card(WF.PAPER, WF.BORDER, 8, 16, 2)
	_board_grid = GridContainer.new()
	_board_grid.columns = COLS
	_board_grid.add_theme_constant_override("h_separation", 6)
	_board_grid.add_theme_constant_override("v_separation", 6)
	board_card.add_child(_board_grid)
	body.add_child(board_card)
	# Boosters row
	_booster_row = HBoxContainer.new()
	_booster_row.add_theme_constant_override("separation", 6)
	_streak_dots_holder = Control.new()
	_streak_dots_holder.custom_minimum_size = Vector2(120, 14)
	_booster_row.add_child(_streak_dots_holder)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_booster_row.add_child(sp)
	_booster_row.add_child(WF.make_label("Boosters:", 14, WF.MUTED))
	# rainbow slots added in _refresh_boosters
	body.add_child(_booster_row)
	# Action buttons
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
	# Log
	var log_card := WF.card(Color("#f5f5f3"), Color(0,0,0,0), 8, 8, 0)
	_log_box = VBoxContainer.new()
	_log_box.add_child(WF.make_label("Tap tiles to spell, then Submit.", 13, WF.MUTED))
	log_card.add_child(_log_box)
	body.add_child(log_card)

func _apply_bar_style(b: ProgressBar, color: Color) -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = WF.BORDER_LITE
	bg.set_corner_radius_all(7)
	b.add_theme_stylebox_override("background", bg)
	var fg := StyleBoxFlat.new()
	fg.bg_color = color
	fg.set_corner_radius_all(7)
	b.add_theme_stylebox_override("fill", fg)

# ─────────── battle setup ───────────

func _start_battle() -> void:
	var e: Dictionary = ENEMIES[_enemy_idx % ENEMIES.size()]
	_enemy_max = int(e.hp)
	_enemy_hp_val = _enemy_max
	_enemy_hp_canvas.max_value = _enemy_max
	_topic = Topics.random_topic()
	_used_words.clear()
	_streak_5plus = 0
	_chain.clear()
	_enemy_name_lbl.text = "%s — %d HP" % [e.name, _enemy_max]
	_topic_chip.text = "Topic: %s — words match for ×2" % _topic.capitalize()
	_player_turn = true
	_busy = false
	_build_board()
	_refresh_hud()
	_refresh_boosters()

func _build_board() -> void:
	for c in _board_grid.get_children():
		c.queue_free()
	_tiles.clear()
	for i in ROWS * COLS:
		var t := _Tile.new()
		t.letter = _rand_letter()
		t.idx = i
		t.tile_pressed.connect(_on_tile_pressed)
		_board_grid.add_child(t)
		_tiles.append(t)
	_enforce_vowel_min()

func _rand_letter(force_vowel: bool = false) -> String:
	if force_vowel:
		return VOWELS[randi() % VOWELS.length()]
	var total := 0
	for k in LETTER_WEIGHTS: total += LETTER_WEIGHTS[k]
	var r := randi() % total
	for k in LETTER_WEIGHTS:
		r -= LETTER_WEIGHTS[k]
		if r < 0: return k
	return "E"

func _enforce_vowel_min() -> void:
	while _count_vowels() < MIN_VOWELS:
		var cons: Array = []
		for i in _tiles.size():
			if VOWELS.find((_tiles[i] as _Tile).letter) == -1:
				cons.append(i)
		if cons.is_empty(): return
		(_tiles[cons[randi() % cons.size()]] as _Tile).letter = _rand_letter(true)

func _count_vowels() -> int:
	var c := 0
	for t in _tiles:
		if VOWELS.find((t as _Tile).letter) != -1: c += 1
	return c

# ─────────── input ───────────

func _on_tile_pressed(tile: Control) -> void:
	if _busy or not _player_turn: return
	if tile.selected_order >= 0:
		var idx: int = tile.selected_order
		while _chain.size() > idx:
			var popped: Control = _chain.pop_back()
			popped.selected_order = -1
	else:
		tile.selected_order = _chain.size()
		_chain.append(tile)
	_refresh_word()

func _on_clear() -> void:
	for t in _chain:
		(t as Control).selected_order = -1
	_chain.clear()
	_refresh_word()

func _refresh_word() -> void:
	var w := _chain_word()
	_word_lbl.text = w if not w.is_empty() else "—"
	_submit_btn.disabled = w.length() < MIN_LEN
	if w.length() >= MIN_LEN:
		var dmg: int = w.length() * DMG_PER_LETTER
		var topic_match := Topics.has(_topic, w.to_lower())
		if topic_match: dmg = int(dmg * TOPIC_MULT)
		_dmg_lbl.text = "+%d dmg%s" % [dmg, "  ×2 TOPIC" if topic_match else ""]
	else:
		_dmg_lbl.text = ""

func _chain_word() -> String:
	var s := ""
	for t in _chain: s += (t as Control).letter
	return s

# ─────────── submit / damage / refill ───────────

func _on_submit() -> void:
	if _busy or not _player_turn: return
	var word_up := _chain_word()
	var word := word_up.to_lower()
	if word.length() < MIN_LEN: return
	if _used_words.has(word):
		_log("Already used: %s" % word_up); return
	if not Words.is_valid(word):
		_log("Not a word: %s" % word_up); return
	_used_words[word] = true
	var topic_match := Topics.has(_topic, word)
	var dmg: int = word.length() * DMG_PER_LETTER
	if topic_match: dmg = int(dmg * TOPIC_MULT)
	_enemy_hp_val = max(0, _enemy_hp_val - dmg)
	GameState.add_xp("word_fight", word.length() * (20 if topic_match else 10))
	_log("You: %s → %d dmg%s" % [word_up, dmg, "  ×2!" if topic_match else ""])
	# Rainbow streak
	if word.length() >= 5:
		_streak_5plus += 1
		if _streak_5plus >= RAINBOW_STREAK and _rainbows < RAINBOW_MAX:
			_rainbows += 1
			_streak_5plus = 0
			_log("🌈 Rainbow earned (%d/%d)" % [_rainbows, RAINBOW_MAX])
	else:
		_streak_5plus = 0
	_consume_chain()
	_refresh_hud()
	_refresh_boosters()
	if _enemy_hp_val <= 0:
		_finish_battle(true); return
	# Enemy turn
	_player_turn = false
	_busy = true
	await get_tree().create_timer(0.6).timeout
	_enemy_turn()

func _consume_chain() -> void:
	for t in _chain:
		(t as Control).letter = _rand_letter()
		(t as Control).selected_order = -1
	_chain.clear()
	_enforce_vowel_min()
	_refresh_word()

# ─────────── enemy ───────────

func _enemy_turn() -> void:
	var skill: float = float(ENEMIES[_enemy_idx % ENEMIES.size()].skill)
	var letters := ""
	for t in _tiles: letters += (t as Control).letter.to_lower()
	var candidates: Array[String] = Words.words_from_letters(letters, MIN_LEN, false)
	var fresh: Array[String] = []
	for w in candidates:
		if not _used_words.has(w): fresh.append(w)
	if fresh.is_empty():
		_log("Enemy passed.")
		_player_turn = true; _busy = false
		return
	fresh.sort_custom(func(a, b): return a.length() > b.length())
	var cap: int = clampi(int(round(lerp(3.0, float(fresh[0].length()), skill))), 3, 7)
	var pool: Array[String] = fresh.filter(func(w): return w.length() <= cap)
	if pool.is_empty(): pool = fresh
	var word: String = pool[randi() % mini(pool.size(), maxi(1, int(round(lerp(8.0, 2.0, skill)))))]
	_used_words[word] = true
	var topic_match := Topics.has(_topic, word)
	var dmg: int = word.length() * DMG_PER_LETTER
	if topic_match: dmg = int(dmg * TOPIC_MULT)
	# Resolve path via leftmost-first.
	var path: Array = _resolve_path(word)
	for i in path:
		(_tiles[i] as Control).selected_order = path.find(i)
		await get_tree().create_timer(0.12).timeout
	_player_hp_val = max(0, _player_hp_val - dmg)
	_log("%s: %s → %d dmg%s" % [ENEMIES[_enemy_idx % ENEMIES.size()].name, word.to_upper(), dmg, "  ×2!" if topic_match else ""])
	# Consume enemy-used tiles
	for i in path:
		(_tiles[i] as Control).letter = _rand_letter()
		(_tiles[i] as Control).selected_order = -1
	_enforce_vowel_min()
	_refresh_hud()
	if _player_hp_val <= 0:
		_finish_battle(false); return
	_player_turn = true
	_busy = false

func _resolve_path(word: String) -> Array:
	var used := {}
	var path: Array = []
	for ch in word.to_upper():
		var f := -1
		for i in _tiles.size():
			if used.has(i): continue
			if (_tiles[i] as Control).letter == ch: f = i; break
		if f == -1: return []
		used[f] = true
		path.append(f)
	return path

# ─────────── HUD ───────────

func _refresh_hud() -> void:
	_player_hp_lbl.text = "You: %d/%d" % [_player_hp_val, PLAYER_HP]
	_player_hp_canvas.value = _player_hp_val
	_enemy_hp_canvas.value = _enemy_hp_val
	_enemy_hp_lbl.text = "%d/%d" % [_enemy_hp_val, _enemy_max]

func _refresh_boosters() -> void:
	# Remove existing slots after the "Boosters:" label.
	while _booster_row.get_child_count() > 4:
		_booster_row.get_child(_booster_row.get_child_count() - 1).queue_free()
	for i in RAINBOW_MAX:
		var slot := Control.new()
		slot.custom_minimum_size = Vector2(28, 28)
		if i < _rainbows:
			var rb := WF._TileCanvas.new("★", false, true, false, 28)
			slot.add_child(rb)
		else:
			var p := PanelContainer.new()
			var sb := StyleBoxFlat.new()
			sb.bg_color = Color("#eee"); sb.set_border_width_all(1); sb.border_color = WF.BORDER_LITE
			sb.set_corner_radius_all(8)
			p.add_theme_stylebox_override("panel", sb)
			p.size = Vector2(28, 28)
			slot.add_child(p)
		_booster_row.add_child(slot)
	# Streak dots
	for c in _streak_dots_holder.get_children():
		c.queue_free()
	_streak_dots_holder.add_child(WF.streak_dots(_streak_5plus, RAINBOW_STREAK))

func _log(line: String) -> void:
	if _log_box.get_child_count() > 4:
		_log_box.get_child(0).queue_free()
	_log_box.add_child(WF.make_label(line, 13, WF.MUTED))

func _finish_battle(won: bool) -> void:
	_busy = true
	_player_turn = false
	var nav: Node = Engine.get_main_loop().get_root().get_node_or_null("Navigator")
	await get_tree().create_timer(0.9).timeout
	if won:
		_enemy_idx += 1
		GameState.set_meta("wf_last_enemy", ENEMIES[(_enemy_idx - 1) % ENEMIES.size()].name)
		if nav != null: nav.replace("wf_victory")
	else:
		if nav != null: nav.replace("wf_defeat")

# ─────────── tile widget ───────────

class _Tile extends Button:
	signal tile_pressed(tile)
	const SZ := 48.0
	var letter: String = "A" :
		set(v): letter = v.to_upper(); queue_redraw()
	var selected_order: int = -1 :
		set(v): selected_order = v; queue_redraw()
	var idx: int = 0
	func _ready() -> void:
		custom_minimum_size = Vector2(SZ, SZ)
		size = Vector2(SZ, SZ)
		focus_mode = Control.FOCUS_NONE
		text = ""
		# Transparent stylebox — we draw our own background in _draw().
		var empty := StyleBoxEmpty.new()
		add_theme_stylebox_override("normal", empty)
		add_theme_stylebox_override("hover", empty)
		add_theme_stylebox_override("pressed", empty)
		add_theme_stylebox_override("focus", empty)
		pressed.connect(func(): tile_pressed.emit(self))
	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, size)
		var sel := selected_order >= 0
		var bg := WF.ACCENT_BG if sel else WF.PAPER
		var border := WF.ACCENT if sel else WF.BORDER
		var w: float = 3.0 if sel else 2.0
		draw_rect(rect, bg, true)
		draw_rect(rect, border, false, w)
		var f := WF.font_bold()
		var fs := 22
		var ts := f.get_string_size(letter, HORIZONTAL_ALIGNMENT_CENTER, -1, fs)
		draw_string(f, size * 0.5 - ts * 0.5 + Vector2(0, fs * 0.36),
			letter, HORIZONTAL_ALIGNMENT_CENTER, -1, fs, WF.ACCENT if sel else WF.TEXT)
		if sel:
			var num := str(selected_order + 1)
			draw_circle(Vector2(size.x - 10, 10), 8, WF.ACCENT)
			var ns := f.get_string_size(num, HORIZONTAL_ALIGNMENT_CENTER, -1, 11)
			draw_string(f, Vector2(size.x - 10, 10) - ns * 0.5 + Vector2(0, 4),
				num, HORIZONTAL_ALIGNMENT_CENTER, -1, 11, Color.WHITE)
