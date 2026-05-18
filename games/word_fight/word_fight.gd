extends Control
## Word Fight — 5×5 shared board, alternating turns, dictionary words deal damage.
## Implements GDD §2 (Core Board, Rainbow Booster, scoring).

const Tile := preload("res://games/word_fight/tile_node.gd")
const Topics := preload("res://games/word_fight/topics.gd")

const ROWS := 5
const COLS := 5
const MIN_WORD_LEN := 3
const MIN_VOWELS := 4
const RAINBOW_STREAK_REQUIRED := 4   # 4× consecutive 5+ letter words → rainbow
const RAINBOW_MAX := 3
const DMG_PER_LETTER := 10
const TOPIC_MULTIPLIER := 2.0
const STREAK_BONUS := 5               # +5 per consecutive valid word (xp side)

# Scrabble-style letter weights (rounded). Used for tile generation.
const LETTER_WEIGHTS := {
	"E": 12, "A": 9, "I": 9, "O": 8, "N": 6, "R": 6, "T": 6, "L": 4,
	"S": 4, "U": 4, "D": 4, "G": 3, "B": 2, "C": 2, "M": 2, "P": 2,
	"F": 2, "H": 2, "V": 2, "W": 2, "Y": 2, "K": 1, "J": 1, "X": 1,
	"Q": 1, "Z": 1,
}
const VOWELS := "AEIOU"

# --- enemies ---
const ENEMIES := [
	{"name": "Wriggles Jr.", "hp": 80,  "skill": 0.4},
	{"name": "Spelluga",     "hp": 120, "skill": 0.6},
	{"name": "Verbosaur",    "hp": 160, "skill": 0.8},
	{"name": "Lexigon",      "hp": 220, "skill": 1.0},
]

const UI := preload("res://scripts/results_ui.gd")

# UI refs (assigned in _build_ui).
var grid: GridContainer
var current_word_label: Label
var dmg_preview_label: Label
var topic_label: Label
var player_hp_label: Label
var enemy_hp_label: Label
var enemy_name_label: Label
var player_hp_bar: ProgressBar
var enemy_hp_bar: ProgressBar
var status_label: Label
var submit_btn: Button
var clear_btn: Button
var rainbow_btn: Button
var back_btn: Button
var streak_dots_row: HBoxContainer

const RAINBOW_DAMAGE_MULT := 2

const PLAYER_MAX_HP := 200

var _tiles: Array = []                 # row-major Array of Tile (size 25), nullable
var _selected: Array = []              # ordered Array of Tile in player's current chain
var _player_hp: int = PLAYER_MAX_HP
var _enemy_hp: int = 100
var _enemy_max_hp: int = 100
var _enemy_idx: int = 0
var _topic: String = "food"
var _player_streak_5plus: int = 0
var _player_word_streak: int = 0
var _rainbows: int = 0
var _used_words: Dictionary = {}       # word(lower) -> true, per-enemy
var _is_player_turn: bool = true
var _busy: bool = false                # animations/AI
var _rainbow_pending: bool = false     # next submitted word gets RAINBOW_DAMAGE_MULT

# Per-battle stats (read by victory/defeat screens via GameState.wf_session).
var _damage_dealt: int = 0
var _words_used: int = 0
var _longest_word: String = ""
var _topic_matches: int = 0
var _rainbows_used: int = 0
var _score_earned: int = 0

func _ready() -> void:
	_build_ui()
	back_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	submit_btn.pressed.connect(_submit_player_word)
	clear_btn.pressed.connect(_clear_chain)
	rainbow_btn.pressed.connect(_use_rainbow)
	# Honor intro screen's enemy selection if present.
	var session: Dictionary = GameState.wf_session
	_enemy_idx = int(session.get("enemy_idx", 0))
	_start_battle(_enemy_idx)

# ---------------- UI construction (wf_game_a layout) ----------------

func _build_ui() -> void:
	UI.bg_layer(self, Palette.BG)

	# Header strip: BackBtn + title + topic chip.
	back_btn = Button.new()
	back_btn.text = "← Back"
	back_btn.position = Vector2(12, 12)
	back_btn.size = Vector2(80, 32)
	add_child(back_btn)

	var title := Label.new()
	title.text = "Word Fight"
	title.add_theme_color_override("font_color", Palette.TEXT)
	title.add_theme_font_size_override("font_size", 18)
	title.position = Vector2(104, 16)
	add_child(title)

	topic_label = UI.chip("Topic: —", Palette.GOLD_DARK, Color("#fff1c4"), Palette.GOLD_DARK)
	topic_label.anchor_left = 1.0
	topic_label.anchor_right = 1.0
	topic_label.offset_left = -180
	topic_label.offset_top = 16
	topic_label.offset_right = -12
	topic_label.offset_bottom = 40
	topic_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(topic_label)

	# Body VBox.
	var body := VBoxContainer.new()
	body.anchor_right = 1.0
	body.anchor_bottom = 1.0
	body.offset_left = 12
	body.offset_top = 56
	body.offset_right = -12
	body.offset_bottom = -12
	body.add_theme_constant_override("separation", 10)
	add_child(body)

	# Player HP row.
	var p_row := HBoxContainer.new()
	p_row.add_theme_constant_override("separation", 10)
	p_row.add_child(UI.avatar(Palette.SAGE, 36))
	var p_box := VBoxContainer.new()
	p_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p_box.add_theme_constant_override("separation", 2)
	player_hp_label = Label.new()
	player_hp_label.text = "You: 200"
	player_hp_label.add_theme_color_override("font_color", Palette.TEXT)
	player_hp_label.add_theme_font_size_override("font_size", 13)
	p_box.add_child(player_hp_label)
	player_hp_bar = UI.hp_bar(Palette.SAGE, Palette.HAIRLINE, 12)
	p_box.add_child(player_hp_bar)
	p_row.add_child(p_box)
	body.add_child(p_row)

	# Enemy HP row.
	var e_row := HBoxContainer.new()
	e_row.add_theme_constant_override("separation", 10)
	var e_box := VBoxContainer.new()
	e_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	e_box.add_theme_constant_override("separation", 2)
	enemy_name_label = Label.new()
	enemy_name_label.text = "Enemy"
	enemy_name_label.add_theme_color_override("font_color", Palette.TERRACOTTA)
	enemy_name_label.add_theme_font_size_override("font_size", 13)
	enemy_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	e_box.add_child(enemy_name_label)
	var e_inner := HBoxContainer.new()
	e_inner.add_theme_constant_override("separation", 8)
	enemy_hp_bar = UI.hp_bar(Palette.TERRACOTTA, Palette.HAIRLINE, 12)
	enemy_hp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	e_inner.add_child(enemy_hp_bar)
	enemy_hp_label = Label.new()
	enemy_hp_label.text = "0"
	enemy_hp_label.add_theme_color_override("font_color", Palette.TEXT)
	enemy_hp_label.add_theme_font_size_override("font_size", 14)
	enemy_hp_label.custom_minimum_size = Vector2(36, 0)
	enemy_hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	e_inner.add_child(enemy_hp_label)
	e_box.add_child(e_inner)
	e_row.add_child(e_box)
	e_row.add_child(UI.avatar(Palette.TERRACOTTA, 36))
	body.add_child(e_row)

	# Current word card (pink accent).
	var word_card := UI.card(Color("#fde6ec"), Palette.PINK_DARK, 10, 12)
	var word_row := HBoxContainer.new()
	word_row.alignment = BoxContainer.ALIGNMENT_CENTER
	word_row.add_theme_constant_override("separation", 8)
	var prefix := Label.new()
	prefix.text = "Your word:"
	prefix.add_theme_color_override("font_color", Palette.TEXT_SECONDARY)
	prefix.add_theme_font_size_override("font_size", 13)
	word_row.add_child(prefix)
	current_word_label = Label.new()
	current_word_label.text = "—"
	current_word_label.add_theme_color_override("font_color", Palette.PINK_DARK)
	current_word_label.add_theme_font_size_override("font_size", 22)
	word_row.add_child(current_word_label)
	dmg_preview_label = Label.new()
	dmg_preview_label.text = ""
	dmg_preview_label.add_theme_color_override("font_color", Palette.SAGE_DARK)
	dmg_preview_label.add_theme_font_size_override("font_size", 13)
	word_row.add_child(dmg_preview_label)
	word_card.add_child(word_row)
	body.add_child(word_card)

	# Board card.
	var board_card := UI.card(Palette.SURFACE, Palette.BORDER, 12, 12)
	var board_wrap := CenterContainer.new()
	grid = GridContainer.new()
	grid.columns = COLS
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	board_wrap.add_child(grid)
	board_card.add_child(board_wrap)
	body.add_child(board_card)

	# Boosters row: streak dots + spacer + rainbow button.
	var boosters := HBoxContainer.new()
	boosters.add_theme_constant_override("separation", 8)
	streak_dots_row = UI.streak_dots(0, RAINBOW_STREAK_REQUIRED, 9)
	boosters.add_child(streak_dots_row)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	boosters.add_child(spacer)
	var boost_lbl := Label.new()
	boost_lbl.text = "Boosters:"
	boost_lbl.add_theme_color_override("font_color", Palette.TEXT_SECONDARY)
	boost_lbl.add_theme_font_size_override("font_size", 13)
	boosters.add_child(boost_lbl)
	rainbow_btn = UI.action_btn("Use 🌈 (0)", false, true)
	rainbow_btn.custom_minimum_size = Vector2(110, 36)
	boosters.add_child(rainbow_btn)
	body.add_child(boosters)

	# Actions row.
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	clear_btn = UI.action_btn("Clear", false, false)
	clear_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(clear_btn)
	submit_btn = UI.action_btn("Submit Word", true, true)
	submit_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(submit_btn)
	body.add_child(actions)

	# Status label.
	status_label = Label.new()
	status_label.text = ""
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_color_override("font_color", Palette.TEXT_SECONDARY)
	status_label.add_theme_font_size_override("font_size", 13)
	body.add_child(status_label)

# ---------------- battle setup ----------------

func _start_battle(idx: int) -> void:
	_enemy_idx = idx
	var e: Dictionary = ENEMIES[idx % ENEMIES.size()]
	_enemy_max_hp = int(e.hp)
	_enemy_hp = _enemy_max_hp
	_topic = Topics.random_topic()
	_used_words.clear()
	_player_streak_5plus = 0
	_player_word_streak = 0
	_rainbow_pending = false
	_damage_dealt = 0
	_words_used = 0
	_longest_word = ""
	_topic_matches = 0
	_rainbows_used = 0
	_score_earned = 0
	_clear_chain()
	enemy_name_label.text = e.name
	topic_label.text = "Topic: %s  (×2 dmg)" % _topic.capitalize()
	_build_board()
	_refresh_hud()
	_set_status("Your turn — form a word!")
	_is_player_turn = true

func _build_board() -> void:
	for c in grid.get_children():
		c.queue_free()
	_tiles.clear()
	for i in ROWS * COLS:
		_tiles.append(null)
	for i in ROWS * COLS:
		_spawn_tile_at(i, _rand_letter())
	_enforce_vowel_minimum()

func _spawn_tile_at(idx: int, letter: String, rainbow: bool = false) -> void:
	var t: Tile = Tile.new()
	t.letter = letter
	t.rainbow = rainbow
	t.tile_pressed.connect(_on_tile_pressed)
	grid.add_child(t)
	# Place at correct index (grid preserves child order = visual position).
	# Move into position by reordering children based on idx.
	grid.move_child(t, idx)
	_tiles[idx] = t

func _rand_letter(force_vowel: bool = false) -> String:
	if force_vowel:
		var v := VOWELS
		return v[randi() % v.length()]
	var total := 0
	for k in LETTER_WEIGHTS:
		total += LETTER_WEIGHTS[k]
	var r := randi() % total
	for k in LETTER_WEIGHTS:
		r -= LETTER_WEIGHTS[k]
		if r < 0:
			return k
	return "E"

func _count_board_vowels() -> int:
	var c := 0
	for t: Tile in _tiles:
		if t != null and VOWELS.find(t.letter) != -1:
			c += 1
	return c

func _enforce_vowel_minimum() -> void:
	while _count_board_vowels() < MIN_VOWELS:
		# Replace a random consonant with a vowel.
		var consonants: Array = []
		for i in _tiles.size():
			var t: Tile = _tiles[i]
			if t != null and VOWELS.find(t.letter) == -1:
				consonants.append(i)
		if consonants.is_empty():
			return
		var idx: int = consonants[randi() % consonants.size()]
		(_tiles[idx] as Tile).letter = _rand_letter(true)

# ---------------- player input ----------------

func _on_tile_pressed(tile: Tile) -> void:
	if _busy or not _is_player_turn:
		return
	if tile.selected_order >= 0:
		# Tapping a selected tile: pop chain back to (and including) this tile.
		var idx := tile.selected_order
		while _selected.size() > idx:
			var popped: Tile = _selected.pop_back()
			popped.selected_order = -1
	else:
		tile.selected_order = _selected.size()
		_selected.append(tile)
	_refresh_current_word()

func _clear_chain() -> void:
	for t: Tile in _selected:
		t.selected_order = -1
	_selected.clear()
	_refresh_current_word()

func _refresh_current_word() -> void:
	var w := _chain_word()
	current_word_label.text = w if not w.is_empty() else "—"
	submit_btn.disabled = w.length() < MIN_WORD_LEN
	# Live damage preview.
	if w.length() >= MIN_WORD_LEN:
		var dmg := w.length() * DMG_PER_LETTER
		var topic_match := Topics.has(_topic, w.to_lower())
		if topic_match:
			dmg = int(dmg * TOPIC_MULTIPLIER)
		if _rainbow_pending:
			dmg *= RAINBOW_DAMAGE_MULT
		dmg_preview_label.text = "+%d dmg%s" % [dmg, "  ×2!" if topic_match else ""]
	else:
		dmg_preview_label.text = ""

func _chain_word() -> String:
	var s := ""
	for t: Tile in _selected:
		s += t.letter
	return s

# ---------------- submit ----------------

func _submit_player_word() -> void:
	if _busy or not _is_player_turn:
		return
	var word_up := _chain_word()
	if word_up.length() < MIN_WORD_LEN:
		return
	var word := word_up.to_lower()
	if _used_words.has(word):
		_flash_invalid("Already used: %s" % word_up); return
	if not Words.is_valid(word):
		_flash_invalid("Not a word: %s" % word_up); return
	_used_words[word] = true

	var topic_match := Topics.has(_topic, word)
	var dmg := word.length() * DMG_PER_LETTER
	if topic_match:
		dmg = int(dmg * TOPIC_MULTIPLIER)
	var rainbow_used := _rainbow_pending
	if rainbow_used:
		dmg *= RAINBOW_DAMAGE_MULT
		_rainbow_pending = false

	var xp_base := word.length() * 10 + (STREAK_BONUS * _player_word_streak)
	if topic_match:
		xp_base = int(xp_base * 2)
	var xp_awarded := GameState.add_xp("word_fight", xp_base)
	_score_earned += xp_awarded

	_enemy_hp = maxi(0, _enemy_hp - dmg)
	_player_word_streak += 1

	# Stats for victory/defeat screens.
	_damage_dealt += dmg
	_words_used += 1
	if word.length() > _longest_word.length():
		_longest_word = word_up
	if topic_match:
		_topic_matches += 1
	if rainbow_used:
		_rainbows_used += 1

	# Rainbow streak: 5+ letter words consecutively.
	if word.length() >= 5:
		_player_streak_5plus += 1
		if _player_streak_5plus >= RAINBOW_STREAK_REQUIRED and _rainbows < RAINBOW_MAX:
			_rainbows += 1
			_player_streak_5plus = 0
			_set_status("Rainbow earned! (%d/%d)" % [_rainbows, RAINBOW_MAX])
	else:
		_player_streak_5plus = 0

	var tag := ""
	if topic_match: tag += "  ×2 TOPIC!"
	if rainbow_used: tag += "  🌈 ×%d!" % RAINBOW_DAMAGE_MULT
	_flash_hit("%s for %d dmg%s" % [word_up, dmg, tag])
	_consume_selected_and_refill(true)
	_refresh_hud()

	if _enemy_hp <= 0:
		_on_enemy_defeated()
		return
	_is_player_turn = false
	_busy = true
	_dim_board(true)
	_refresh_hud()
	await get_tree().create_timer(0.6).timeout
	_enemy_turn()

func _consume_selected_and_refill(player_triggered: bool) -> void:
	# Replace each used tile in place with a fresh letter (simulates "1 new tile falls").
	# (GDD says 1 new tile per turn — we refill all consumed slots so the board
	# never collapses; this is the prototype simplification noted in the GDD risks.)
	for t: Tile in _selected:
		t.letter = _rand_letter()
		t.selected_order = -1
	_selected.clear()
	# Enforce vowel guarantee after every refill.
	_enforce_vowel_minimum()
	_refresh_current_word()

# ---------------- enemy AI ----------------

func _enemy_turn() -> void:
	var skill: float = float(ENEMIES[_enemy_idx % ENEMIES.size()].skill)
	_set_status("Enemy is thinking…")
	var pick: Dictionary = await _enemy_pick_word_async(skill)
	if pick.is_empty():
		_set_status("Enemy passed.")
		await get_tree().create_timer(0.6).timeout
		_end_enemy_turn()
		return
	# Animate selection: mark tiles briefly.
	var path: Array = pick.path
	for i in path.size():
		var t: Tile = _tiles[path[i]]
		t.selected_order = i
		await get_tree().create_timer(0.12).timeout
	var word: String = pick.word
	var topic_match := Topics.has(_topic, word)
	var dmg: int = word.length() * DMG_PER_LETTER
	if topic_match:
		dmg = int(dmg * TOPIC_MULTIPLIER)
	_player_hp = maxi(0, _player_hp - dmg)
	_used_words[word] = true
	_set_status("Enemy played %s for %d dmg%s" % [word.to_upper(), dmg, "  ×2 TOPIC!" if topic_match else ""])
	# Consume + refill those tiles.
	_selected.clear()
	for i in path:
		_selected.append(_tiles[i])
	_consume_selected_and_refill(false)
	_refresh_hud()
	if _player_hp <= 0:
		_set_status("You were defeated!")
		_busy = true
		_is_player_turn = false
		_dim_board(false)
		await get_tree().create_timer(0.8).timeout
		_publish_session(false)
		get_tree().change_scene_to_file("res://games/word_fight/defeat.tscn")
		return
	_end_enemy_turn()

func _end_enemy_turn() -> void:
	_busy = false
	_is_player_turn = true
	_dim_board(false)
	_set_status(status_label.text + "  ·  Your turn.")
	_refresh_hud()

func _enemy_pick_word_async(skill: float) -> Dictionary:
	# Build letter pool from board. Enemy may use any tile but each tile only once
	# per word (same constraint as player chaining without revisits).
	var letters := ""
	for t: Tile in _tiles:
		if t != null:
			letters += t.letter.to_lower()
	# Run the dictionary scan on a worker thread so the main thread keeps rendering.
	# Words.words_from_letters only reads immutable post-load data, so it's thread-safe.
	var holder: Array = [null]
	var task_id := WorkerThreadPool.add_task(func() -> void:
		holder[0] = Words.words_from_letters(letters, MIN_WORD_LEN, false, 7)
	)
	while not WorkerThreadPool.is_task_completed(task_id):
		await get_tree().process_frame
	WorkerThreadPool.wait_for_task_completion(task_id)
	var candidates: Array[String] = holder[0]
	# Filter unused and verify a tile-index path actually exists (it does because
	# words_from_letters checks letter multiplicity).
	var fresh: Array[String] = []
	for w in candidates:
		if not _used_words.has(w):
			fresh.append(w)
	if fresh.is_empty():
		return {}
	fresh.sort_custom(func(a, b): return a.length() > b.length())
	# Skill-based pick: high skill picks near the top, low skill picks shorter words.
	var max_len: int = fresh[0].length()
	# Cap enemy max length so it doesn't always one-shot.
	var cap: int = clampi(int(round(lerp(3.0, float(max_len), skill))), 3, 7)
	var pool: Array[String] = []
	for w in fresh:
		if w.length() <= cap:
			pool.append(w)
	if pool.is_empty():
		pool = fresh
	# Prefer topic matches sometimes.
	var prefer_topic := randf() < skill
	if prefer_topic:
		var tm: Array[String] = pool.filter(func(w): return Topics.has(_topic, w))
		if not tm.is_empty():
			pool = tm
	var word: String = pool[randi() % mini(pool.size(), maxi(1, int(round(lerp(8.0, 2.0, skill)))))]
	var path := _resolve_path_for_word(word)
	if path.is_empty():
		return {}
	return {"word": word, "path": path}

func _resolve_path_for_word(word: String) -> Array:
	# Returns an Array[int] of tile indices forming `word`, picking the leftmost
	# available match per letter. Returns [] if impossible.
	var used := {}
	var path := []
	for ch in word.to_upper():
		var found := -1
		for i in _tiles.size():
			if used.has(i):
				continue
			var t: Tile = _tiles[i]
			if t != null and t.letter == ch:
				found = i
				break
		if found == -1:
			return []
		used[found] = true
		path.append(found)
	return path

# ---------------- HUD / status ----------------

func _refresh_hud() -> void:
	player_hp_label.text = "You: %d" % _player_hp
	enemy_hp_label.text = "%d" % _enemy_hp
	player_hp_bar.max_value = PLAYER_MAX_HP
	player_hp_bar.value = _player_hp
	enemy_hp_bar.max_value = _enemy_max_hp
	enemy_hp_bar.value = _enemy_hp
	rainbow_btn.disabled = _rainbows <= 0 or not _is_player_turn or _busy
	rainbow_btn.text = "🌈 Armed" if _rainbow_pending else "Use 🌈 (%d)" % _rainbows
	_refresh_streak_dots()

func _refresh_streak_dots() -> void:
	if streak_dots_row == null:
		return
	var children := streak_dots_row.get_children()
	for i in children.size():
		var dot := children[i] as PanelContainer
		var sb := dot.get_theme_stylebox("panel") as StyleBoxFlat
		var fresh: StyleBoxFlat = sb.duplicate()
		fresh.bg_color = Palette.GOLD if i < _player_streak_5plus else Palette.HAIRLINE
		dot.add_theme_stylebox_override("panel", fresh)

const _STATUS_BASE_COLOR := Color(0.173, 0.173, 0.173, 1)

func _set_status(s: String) -> void:
	status_label.text = s
	status_label.add_theme_color_override("font_color", _STATUS_BASE_COLOR)

func _flash_status(s: String, color: Color) -> void:
	status_label.text = s
	status_label.add_theme_color_override("font_color", color)
	var tw := create_tween()
	tw.tween_property(status_label, "theme_override_colors/font_color", _STATUS_BASE_COLOR, 0.9)

func _flash_invalid(s: String) -> void:
	_flash_status(s, Color(0.85, 0.15, 0.15))
	# Big, unmissable feedback in the Current Word label.
	var prev_text := current_word_label.text
	current_word_label.text = "✗ " + s
	current_word_label.add_theme_color_override("font_color", Color(0.85, 0.15, 0.15))
	current_word_label.modulate = Color(1, 1, 1)
	# Shake horizontally.
	var shake := create_tween()
	for i in 6:
		shake.tween_property(current_word_label, "position:x",
			current_word_label.position.x + (6 if i % 2 == 0 else -6), 0.04)
	shake.tween_property(current_word_label, "position:x", current_word_label.position.x, 0.04)
	# Restore after 1s.
	get_tree().create_timer(1.0).timeout.connect(func():
		current_word_label.text = _chain_word() if not _selected.is_empty() else "—"
		current_word_label.add_theme_color_override("font_color", Color(1, 0.42, 0.207))
	)

func _flash_hit(s: String) -> void:
	_flash_status(s, Color(0.15, 0.6, 0.25))
	current_word_label.add_theme_color_override("font_color", Color(0.15, 0.6, 0.25))
	get_tree().create_timer(0.5).timeout.connect(func():
		current_word_label.add_theme_color_override("font_color", Color(1, 0.42, 0.207))
	)

func _use_rainbow() -> void:
	if _busy or not _is_player_turn: return
	if _rainbows <= 0 or _rainbow_pending: return
	_rainbows -= 1
	_rainbow_pending = true
	_flash_status("Rainbow armed — next word deals ×%d damage" % RAINBOW_DAMAGE_MULT, Color(0.9, 0.55, 0.95))
	_refresh_hud()

func _dim_board(dim_on: bool) -> void:
	for t: Tile in _tiles:
		if t != null:
			t.dim = dim_on

func _publish_session(player_won: bool) -> void:
	var e: Dictionary = ENEMIES[_enemy_idx % ENEMIES.size()]
	GameState.wf_session["enemy_idx"] = _enemy_idx
	GameState.wf_session["enemy_name"] = e.name
	GameState.wf_session["enemy_max_hp"] = int(e.hp)
	GameState.wf_session["enemy_hp_left"] = _enemy_hp
	GameState.wf_session["player_hp_left"] = _player_hp
	GameState.wf_session["topic"] = _topic
	GameState.wf_session["damage_dealt"] = _damage_dealt
	GameState.wf_session["words_used"] = _words_used
	GameState.wf_session["longest_word"] = _longest_word
	GameState.wf_session["topic_matches"] = _topic_matches
	GameState.wf_session["rainbows_used"] = _rainbows_used
	GameState.wf_session["score_earned"] = _score_earned
	GameState.wf_session["player_won"] = player_won

func _on_enemy_defeated() -> void:
	_set_status("Defeated %s!" % ENEMIES[_enemy_idx % ENEMIES.size()].name)
	var bonus := GameState.add_xp("word_fight", 100)
	_score_earned += bonus
	_busy = true
	await get_tree().create_timer(0.8).timeout
	_publish_session(true)
	get_tree().change_scene_to_file("res://games/word_fight/victory.tscn")
