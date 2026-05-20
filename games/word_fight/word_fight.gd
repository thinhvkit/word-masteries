extends Control
## Word Fight — 5×5 shared board, alternating turns, dictionary words deal damage.
## Implements GDD §2 (Core Board, Rainbow Booster, scoring).

const Tile := preload("res://games/word_fight/tile_node.gd")
const Topics := preload("res://games/word_fight/topics.gd")
const Fx := preload("res://games/word_fight/fx.gd")

const ROWS := 5
const COLS := 5
const MIN_WORD_LEN := 3
const MIN_VOWELS := 4
const RAINBOW_STREAK_REQUIRED := 3   # 3× consecutive 5+ letter words → rainbow
const RAINBOW_MAX := 3                # max stored rainbow charges
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
	{"name": "Wriggles Jr.", "hp": 110, "skill": 0.6, "avatar": "wriggles_jr"},
	{"name": "Spelluga",     "hp": 170, "skill": 0.78, "avatar": "spelluga"},
	{"name": "Verbosaur",    "hp": 230, "skill": 0.9, "avatar": "verbosaur"},
	{"name": "Lexigon",      "hp": 310, "skill": 1.0, "avatar": "lexigon"},
]

func _enemy_avatar_path(idx: int) -> String:
	var e: Dictionary = ENEMIES[idx % ENEMIES.size()]
	return "res://assets/avatars/%s.svg" % str(e.get("avatar", "octopus"))

const UI := preload("res://scripts/results_ui.gd")
const Chrome := preload("res://scripts/screen_chrome.gd")

const CORAL_LIGHT := Color("#ffdcc7")
const CORAL_DARK := Color("#c95a1f")
const SAGE := Color("#a7d99a")
const SAGE_DARK := Color("#6cb072")
const HP_PINK := Color("#e07a8c")
const HP_PINK_DARK := Color("#c95e74")
const HP_BG := Color("#f1ebe1")
const PINK_PILL_BG := Color("#fde0e7")
const PINK_PILL_BORDER := Color("#f2a6b6")
const SUBMIT_PINK := Color("#e07a8c")
const TILE_BG := Color("#ffffff")
const TILE_BORDER := Color("#ece4d8")
const RAINBOW_ICON := preload("res://assets/boosters/rainbow.svg")

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
var board_bg: Control                  # animated gradient backdrop behind the 5x5
var chain_overlay: Control             # draws connector lines between selected tiles
var board_wrap: Control
var player_avatar: Control
var enemy_avatar: Control
var submit_glow: Panel
var rainbow_sweep: ColorRect

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
	# Honor intro screen's enemy + topic selection BEFORE building UI so the header chip is right.
	var session: Dictionary = GameState.wf_session
	_enemy_idx = int(session.get("enemy_idx", 0))
	var seeded_topic: String = String(session.get("topic", ""))
	if not seeded_topic.is_empty():
		_topic = seeded_topic
	_build_ui()
	back_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	submit_btn.pressed.connect(_submit_player_word)
	clear_btn.pressed.connect(_clear_chain)
	rainbow_btn.pressed.connect(_use_rainbow)
	_start_battle(_enemy_idx)

# ---------------- UI construction (wf_game_a layout) ----------------

func _build_ui() -> void:
	Chrome.bg_layer(self)
	back_btn = Chrome.header(self, "Word Fight", "%s ×2" % _topic.capitalize(), Color("#fff1c4"), Color("#b48218"))
	# Keep `topic_label` as a Label so existing _start_battle can update its text.
	# We'll wire the in-header chip to mirror it below.
	topic_label = Label.new()
	topic_label.visible = false
	add_child(topic_label)

	# Body VBox.
	var body := VBoxContainer.new()
	body.anchor_right = 1.0
	body.anchor_bottom = 1.0
	body.offset_left = 16
	body.offset_top = Chrome.HEADER_H + 12
	body.offset_right = -16
	body.offset_bottom = -12
	body.add_theme_constant_override("separation", 14)
	add_child(body)

	# Player HP row — avatar on the LEFT, bar fills to the right (player facing right).
	player_hp_bar = _hp_bar(SAGE, false)
	player_hp_label = Label.new()
	var player_svg := "res://assets/avatars/%s.svg" % GameState.player_avatar
	var p_row := _hp_row(SAGE, player_svg, player_hp_bar, player_hp_label, false)
	player_avatar = p_row.get_child(0) as Control
	body.add_child(p_row)
	player_hp_label.text = "200"

	# Enemy HP row — MIRRORED: avatar on the RIGHT, bar fills to the left (enemy facing left).
	enemy_hp_bar = _hp_bar(HP_PINK, true)
	enemy_hp_label = Label.new()
	var enemy_svg := _enemy_avatar_path(_enemy_idx)
	var e_row := _hp_row(HP_PINK, enemy_svg, enemy_hp_bar, enemy_hp_label, true)
	# Avatar is now the LAST child when mirrored.
	enemy_avatar = e_row.get_child(e_row.get_child_count() - 1) as Control
	enemy_name_label = Label.new()
	enemy_name_label.visible = false
	add_child(enemy_name_label)
	body.add_child(e_row)
	# Kick off idle breathing animations on both avatars.
	_start_idle_bob(player_avatar)
	_start_idle_bob(enemy_avatar)
	# Mirror enemy SVG horizontally so it visually faces the player.
	_face_avatar_inward(enemy_avatar, true)
	_face_avatar_inward(player_avatar, false)

	# "Your word: —" pink pill.
	var word_pill := PanelContainer.new()
	var wp_sb := StyleBoxFlat.new()
	wp_sb.bg_color = PINK_PILL_BG
	wp_sb.set_corner_radius_all(22)
	wp_sb.set_border_width_all(2)
	wp_sb.border_color = PINK_PILL_BORDER
	wp_sb.content_margin_left = 20
	wp_sb.content_margin_right = 20
	wp_sb.content_margin_top = 16
	wp_sb.content_margin_bottom = 16
	wp_sb.shadow_color = Color(1.0, 0.4, 0.7, 0.2)
	wp_sb.shadow_size = 6
	wp_sb.shadow_offset = Vector2i(0, 2)
	word_pill.add_theme_stylebox_override("panel", wp_sb)
	var word_row := HBoxContainer.new()
	word_row.alignment = BoxContainer.ALIGNMENT_CENTER
	word_row.add_theme_constant_override("separation", 10)
	var prefix := Label.new()
	prefix.text = "Your word:"
	prefix.add_theme_color_override("font_color", Chrome.TEXT_SEC)
	prefix.add_theme_font_size_override("font_size", 15)
	word_row.add_child(prefix)
	current_word_label = Label.new()
	current_word_label.text = "—"
	current_word_label.add_theme_color_override("font_color", HP_PINK_DARK)
	current_word_label.add_theme_font_size_override("font_size", 24)
	word_row.add_child(current_word_label)
	dmg_preview_label = Label.new()
	dmg_preview_label.text = ""
	dmg_preview_label.add_theme_color_override("font_color", SAGE_DARK)
	dmg_preview_label.add_theme_font_size_override("font_size", 14)
	word_row.add_child(dmg_preview_label)
	word_pill.add_child(word_row)
	body.add_child(word_pill)

	# Board — animated gradient backdrop fills all leftover vertical space;
	# the grid stays centered inside it. Removes the dead area below the board.
	var board_panel := Control.new()
	board_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	# Minimum so the board never collapses below tile size on small screens.
	board_panel.custom_minimum_size = Vector2(COLS * 56 + (COLS - 1) * 10 + 24, ROWS * 56 + (ROWS - 1) * 10 + 24)
	board_bg = Fx.AnimatedBoardBG.new()
	board_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	board_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board_panel.add_child(board_bg)
	var grid_center := CenterContainer.new()
	grid_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	board_panel.add_child(grid_center)
	grid = GridContainer.new()
	grid.columns = COLS
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	grid_center.add_child(grid)
	chain_overlay = _ChainOverlay.new()
	chain_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	chain_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board_panel.add_child(chain_overlay)
	# board_wrap's old role (CenterContainer parent for coordinate translation)
	# is now played by board_panel itself; alias them so existing FX code works.
	board_wrap = board_panel
	body.add_child(board_panel)

	# Boosters row: 4 streak dots + "streak" label on left, rainbow chip on right.
	var boosters := HBoxContainer.new()
	boosters.add_theme_constant_override("separation", 6)
	streak_dots_row = UI.streak_dots(0, RAINBOW_STREAK_REQUIRED, 8)
	boosters.add_child(streak_dots_row)
	var streak_lbl := Label.new()
	streak_lbl.text = "streak"
	streak_lbl.add_theme_color_override("font_color", Chrome.TEXT_SEC)
	streak_lbl.add_theme_font_size_override("font_size", 15)
	boosters.add_child(streak_lbl)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	boosters.add_child(spacer)
	rainbow_btn = Button.new()
	rainbow_btn.text = "Use (0)"
	rainbow_btn.icon = RAINBOW_ICON
	rainbow_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rainbow_btn.expand_icon = false
	rainbow_btn.add_theme_constant_override("icon_max_width", 22)
	rainbow_btn.add_theme_constant_override("h_separation", 4)
	rainbow_btn.focus_mode = Control.FOCUS_NONE
	rainbow_btn.add_theme_font_size_override("font_size", 15)
	rainbow_btn.add_theme_color_override("font_color", Chrome.TEXT_SEC)
	var rb_sb := StyleBoxFlat.new()
	rb_sb.bg_color = Color("#f1ebe1")
	rb_sb.set_corner_radius_all(99)
	rb_sb.content_margin_left = 12
	rb_sb.content_margin_right = 12
	rb_sb.content_margin_top = 6
	rb_sb.content_margin_bottom = 6
	rainbow_btn.add_theme_stylebox_override("normal", rb_sb)
	rainbow_btn.add_theme_stylebox_override("hover", rb_sb)
	rainbow_btn.add_theme_stylebox_override("pressed", rb_sb)
	rainbow_btn.add_theme_stylebox_override("disabled", rb_sb)
	rainbow_btn.add_theme_stylebox_override("focus", rb_sb)
	boosters.add_child(rainbow_btn)
	body.add_child(boosters)

	# Actions row — Clear (white pill) + Submit (pink pill) wrapped in a glow panel.
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 12)
	clear_btn = Chrome.pill_button("Clear", Chrome.SURFACE, Chrome.TEXT)
	clear_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(clear_btn)
	var submit_wrap := Control.new()
	submit_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	submit_wrap.custom_minimum_size = Vector2(0, 56)
	submit_glow = Panel.new()
	submit_glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	submit_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var glow_sb := StyleBoxFlat.new()
	glow_sb.bg_color = Color(1, 0.5, 0.7, 0.0)
	glow_sb.set_corner_radius_all(32)
	glow_sb.shadow_color = Color(1.0, 0.4, 0.7, 0.0)
	glow_sb.shadow_size = 18
	submit_glow.add_theme_stylebox_override("panel", glow_sb)
	submit_wrap.add_child(submit_glow)
	submit_btn = Chrome.pill_button("Submit", SUBMIT_PINK)
	submit_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	submit_wrap.add_child(submit_btn)
	actions.add_child(submit_wrap)
	body.add_child(actions)

	# Rainbow full-screen iridescent sweep overlay (hidden by default).
	rainbow_sweep = ColorRect.new()
	rainbow_sweep.set_anchors_preset(Control.PRESET_FULL_RECT)
	rainbow_sweep.color = Color(1, 1, 1, 0)
	rainbow_sweep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rainbow_sweep.z_index = 80
	add_child(rainbow_sweep)

	# Status label.
	status_label = Label.new()
	status_label.text = ""
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_color_override("font_color", Chrome.TEXT_SEC)
	status_label.add_theme_font_size_override("font_size", 16)
	body.add_child(status_label)

# ---- HP row helpers ----
func _hp_bar(fill: Color, _mirrored: bool = false) -> ProgressBar:
	# _mirrored is reserved for future right-to-left fill; current implementation
	# keeps both bars draining LTR — the duel feel comes from avatar mirroring.
	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = 100
	bar.value = 100
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 20)
	var bg := StyleBoxFlat.new()
	bg.bg_color = HP_BG
	bg.set_corner_radius_all(99)
	var fg := StyleBoxFlat.new()
	fg.bg_color = fill
	fg.set_corner_radius_all(99)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fg)
	return bar

func _hp_row(circle: Color, svg_path: String, bar: ProgressBar, value_lbl: Label, mirrored: bool = false) -> HBoxContainer:
	# Order: [avatar][bar][value_lbl]   for player (mirrored=false)
	#        [value_lbl][bar][avatar]   for enemy  (mirrored=true)  → duel feel.
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var av := Panel.new()
	av.custom_minimum_size = Vector2(56, 56)
	av.pivot_offset = Vector2(28, 28)
	var av_sb := StyleBoxFlat.new()
	av_sb.bg_color = circle
	av_sb.set_corner_radius_all(28)
	av_sb.set_border_width_all(3)
	av_sb.border_color = Color(1, 1, 1, 0.75)
	av_sb.shadow_color = Color(circle.r, circle.g, circle.b, 0.55)
	av_sb.shadow_size = 10
	av_sb.shadow_offset = Vector2i(0, 3)
	av.add_theme_stylebox_override("panel", av_sb)
	if ResourceLoader.exists(svg_path):
		var icon := TextureRect.new()
		icon.texture = load(svg_path)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.set_anchors_preset(Control.PRESET_FULL_RECT)
		icon.offset_left = 5
		icon.offset_top = 5
		icon.offset_right = -5
		icon.offset_bottom = -5
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		av.add_child(icon)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	value_lbl.text = "0"
	value_lbl.add_theme_color_override("font_color", Chrome.TEXT)
	value_lbl.add_theme_font_size_override("font_size", 18)
	value_lbl.custom_minimum_size = Vector2(40, 0)
	value_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if mirrored:
		value_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.add_child(value_lbl)
		row.add_child(bar)
		row.add_child(av)
	else:
		value_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(av)
		row.add_child(bar)
		row.add_child(value_lbl)
	return row

# ---------------- battle setup ----------------

func _start_battle(idx: int) -> void:
	_enemy_idx = idx
	var e: Dictionary = ENEMIES[idx % ENEMIES.size()]
	_enemy_max_hp = int(e.hp)
	_enemy_hp = _enemy_max_hp
	# Honor the topic seeded by intro; otherwise (e.g. game launched standalone) roll one.
	var seeded: String = String(GameState.wf_session.get("topic", ""))
	_topic = seeded if not seeded.is_empty() else Topics.random_topic()
	GameState.wf_session["topic"] = _topic
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
	# Staggered pop-in across the board.
	for i in _tiles.size():
		var t: Tile = _tiles[i]
		if t != null:
			var row := i / COLS
			var col := i % COLS
			var d: float = (row + col) * 0.04
			t.play_pop_in(d)

func _spawn_tile_at(idx: int, letter: String, rainbow: bool = false) -> void:
	var t: Tile = Tile.new()
	t.letter = letter
	t.rainbow = rainbow
	t.tile_pressed.connect(_on_tile_pressed)
	t.tile_selected_fx.connect(_on_tile_selected_fx)
	grid.add_child(t)
	grid.move_child(t, idx)
	_tiles[idx] = t

func _on_tile_selected_fx(tile: Tile, color: Color) -> void:
	if board_wrap == null: return
	var pos := tile.global_position + tile.size * 0.5 - board_wrap.global_position
	Fx.sparkle_burst(board_wrap, pos, color, 7)
	if chain_overlay != null:
		chain_overlay.queue_redraw()

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
	if chain_overlay != null:
		(chain_overlay as _ChainOverlay).set_tiles(_selected, board_wrap)
	_update_submit_glow(w.length())

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
		for tx: Tile in _tiles:
			if tx != null:
				tx.rainbow = false

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
	if rainbow_used: tag += "  RAINBOW ×%d!" % RAINBOW_DAMAGE_MULT
	_flash_hit("%s for %d dmg%s" % [word_up, dmg, tag])

	# ----- HIT FX -----
	if enemy_avatar != null and is_inside_tree():
		var hit_pos := enemy_avatar.global_position + enemy_avatar.size * 0.5 - global_position
		Fx.damage_popup(self, hit_pos + Vector2(20, -10), dmg, dmg >= 80, Fx.damage_color_for(dmg))
		Fx.shake(enemy_avatar, 8.0, 0.35)
		_avatar_lean(enemy_avatar, true)   # enemy leans right (away from player on the left)
	# Confetti from selected tiles toward enemy avatar.
	if board_wrap != null and enemy_avatar != null:
		var froms: Array = []
		var cols: Array = []
		for t: Tile in _selected:
			froms.append(t.global_position + t.size * 0.5 - global_position)
			var g := Fx.gradient_for_letter(t.letter)
			cols.append(g[1])
		var target := enemy_avatar.global_position + enemy_avatar.size * 0.5 - global_position
		Fx.confetti_to(self, froms, target, cols)
	# Screen shake on big damage.
	if dmg >= 80:
		Fx.shake(self, 4.0, 0.25)
	# Topic banner.
	if topic_match:
		Fx.banner(self, "×2 TOPIC!", Color("#ffc844"), Color("#7a4a00"))
	# Rainbow earn fireworks (just earned this submit?).
	if word.length() >= 5 and _player_streak_5plus == 0 and _rainbows > 0:
		Fx.fireworks(self, Vector2(size.x * 0.5, size.y * 0.4))

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
	# Burst-dissolve consumed tiles, reassign letters, then drop the fresh tiles in.
	var consumed: Array = _selected.duplicate()
	for t: Tile in consumed:
		t.play_burst()
	if not consumed.is_empty():
		await get_tree().create_timer(0.18).timeout
	for t: Tile in consumed:
		t.letter = _rand_letter()
		t.selected_order = -1
		t.scale = Vector2(1, 1)
		t.modulate.a = 1.0
		t.play_drop_in()
	_selected.clear()
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
	# Animate selection one letter at a time so the player can read the word as
	# it forms. Show preview text in the status line, then pause before the hit.
	var path: Array = pick.path
	var word: String = pick.word
	for i in path.size():
		var t: Tile = _tiles[path[i]]
		t.selected_order = i
		# Live preview of the partial word the enemy is spelling.
		_set_status("Enemy: %s_" % word.substr(0, i + 1).to_upper())
		await get_tree().create_timer(0.32).timeout
	# Hold the completed word so the player can read it before the hit.
	_set_status("Enemy plays %s…" % word.to_upper())
	await get_tree().create_timer(0.7).timeout
	var topic_match := Topics.has(_topic, word)
	var dmg: int = word.length() * DMG_PER_LETTER
	if topic_match:
		dmg = int(dmg * TOPIC_MULTIPLIER)
	_player_hp = maxi(0, _player_hp - dmg)
	_used_words[word] = true
	_set_status("Enemy played %s for %d dmg%s" % [word.to_upper(), dmg, "  ×2 TOPIC!" if topic_match else ""])
	# ----- ENEMY HIT FX on the player -----
	if player_avatar != null and is_inside_tree():
		var p_pos := player_avatar.global_position + player_avatar.size * 0.5 - global_position
		Fx.damage_popup(self, p_pos + Vector2(20, -10), dmg, dmg >= 80, Fx.damage_color_for(dmg))
		Fx.shake(player_avatar, 8.0, 0.35)
		_avatar_lean(player_avatar, false)   # player leans left (away from enemy on the right)
	if dmg >= 80:
		Fx.shake(self, 4.0, 0.25)
	# Hold on the hit reaction before the tiles dissolve.
	await get_tree().create_timer(0.7).timeout
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
	_set_status(status_label.text + "  |  Your turn.")
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
	player_hp_label.text = "%d" % _player_hp
	enemy_hp_label.text = "%d" % _enemy_hp
	player_hp_bar.max_value = PLAYER_MAX_HP
	enemy_hp_bar.max_value = _enemy_max_hp
	_animate_hp_bar(player_hp_bar, _player_hp)
	_animate_hp_bar(enemy_hp_bar, _enemy_hp)
	_tint_hp_bar(player_hp_bar, float(_player_hp) / float(PLAYER_MAX_HP))
	_tint_hp_bar(enemy_hp_bar, float(_enemy_hp) / float(maxi(_enemy_max_hp, 1)))
	_pulse_hp_if_low(player_hp_bar, float(_player_hp) / float(PLAYER_MAX_HP))
	rainbow_btn.disabled = _rainbows <= 0 or not _is_player_turn or _busy
	rainbow_btn.text = "Armed" if _rainbow_pending else "Use (%d)" % _rainbows
	_refresh_streak_dots()
	# Active-turn glow on whoever is acting.
	_set_active_avatar(player_avatar, SAGE_DARK, _is_player_turn and not _busy)
	_set_active_avatar(enemy_avatar, HP_PINK_DARK, not _is_player_turn and _busy)

func _tint_hp_bar(bar: ProgressBar, ratio: float) -> void:
	var fill: Color
	if ratio > 0.6:
		fill = Color("#4fd17b")          # vibrant green
	elif ratio > 0.3:
		fill = Color("#ffc02e")          # gold
	else:
		fill = Color("#ff4f6a")          # danger red
	var sb := bar.get_theme_stylebox("fill") as StyleBoxFlat
	if sb != null:
		var fresh: StyleBoxFlat = sb.duplicate()
		fresh.bg_color = fill
		bar.add_theme_stylebox_override("fill", fresh)

func _pulse_hp_if_low(bar: ProgressBar, ratio: float) -> void:
	if ratio < 0.3 and ratio > 0.0:
		bar.modulate = Color(1, 1, 1, 1)
		var tw := bar.create_tween().set_loops(2)
		tw.tween_property(bar, "modulate", Color(1.4, 0.7, 0.7, 1), 0.25)
		tw.tween_property(bar, "modulate", Color(1, 1, 1, 1), 0.25)
	else:
		bar.modulate = Color(1, 1, 1, 1)

func _refresh_streak_dots() -> void:
	if streak_dots_row == null:
		return
	var children := streak_dots_row.get_children()
	for i in children.size():
		var dot := children[i] as PanelContainer
		if dot == null: continue
		var sb := dot.get_theme_stylebox("panel") as StyleBoxFlat
		var fresh: StyleBoxFlat = sb.duplicate()
		var active := i < _player_streak_5plus
		fresh.bg_color = Palette.GOLD if active else Palette.HAIRLINE
		dot.add_theme_stylebox_override("panel", fresh)
		# Ping pulse on the newest active dot.
		if active and i == _player_streak_5plus - 1:
			dot.pivot_offset = dot.size * 0.5
			var tw := dot.create_tween()
			tw.tween_property(dot, "scale", Vector2(1.5, 1.5), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.tween_property(dot, "scale", Vector2(1.0, 1.0), 0.18)

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
	# Red color + horizontal shake already convey invalidity; no glyph prefix.
	current_word_label.text = s
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
	# Iridescent screen sweep + tile rainbow shimmer until consumed.
	if rainbow_sweep != null:
		rainbow_sweep.color = Color(1, 0.4, 0.95, 0.0)
		var tw := create_tween()
		tw.tween_property(rainbow_sweep, "color:a", 0.35, 0.18)
		tw.tween_property(rainbow_sweep, "color:a", 0.0, 0.6)
	for t: Tile in _tiles:
		if t != null:
			t.rainbow = true
	_refresh_hud()

func _update_submit_glow(word_len: int) -> void:
	if submit_glow == null: return
	var sb := submit_glow.get_theme_stylebox("panel") as StyleBoxFlat
	if sb == null: return
	var on := word_len >= 5
	var fresh: StyleBoxFlat = sb.duplicate()
	fresh.shadow_color = Color(1.0, 0.4, 0.7, 0.55 if on else 0.0)
	fresh.shadow_size = 24 if on else 0
	submit_glow.add_theme_stylebox_override("panel", fresh)

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
	# Victory fireworks before scene change.
	Fx.fireworks(self, Vector2(size.x * 0.5, size.y * 0.45))
	await get_tree().create_timer(0.9).timeout
	_publish_session(true)
	get_tree().change_scene_to_file("res://games/word_fight/victory.tscn")

# ---------- duel-style avatar helpers ----------

## Continuous "breathing" scale loop on an avatar so it never feels static.
func _start_idle_bob(node: Control) -> void:
	if node == null: return
	node.pivot_offset = node.size * 0.5
	var tw := node.create_tween().set_loops()
	tw.tween_property(node, "scale", Vector2(1.04, 1.04), 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(node, "scale", Vector2(1.0, 1.0), 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

## Horizontally mirror the avatar SVG so the enemy faces the player.
func _face_avatar_inward(av_panel: Control, mirror: bool) -> void:
	if av_panel == null: return
	for c in av_panel.get_children():
		if c is TextureRect:
			(c as TextureRect).flip_h = mirror

## Lean an avatar away from the impact, then snap back. Subtler than full shake.
func _avatar_lean(node: Control, mirror: bool) -> void:
	if node == null: return
	var base := node.position
	var away := Vector2(-12 if not mirror else 12, 0)
	var tw := node.create_tween()
	tw.tween_property(node, "position", base + away, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(node, "position", base, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

## Highlight whose turn it is by pulsing a colored border + shadow on their avatar.
func _set_active_avatar(node: Control, accent: Color, on: bool) -> void:
	if node == null: return
	var sb := node.get_theme_stylebox("panel") as StyleBoxFlat
	if sb == null: return
	var fresh: StyleBoxFlat = sb.duplicate()
	fresh.border_color = accent if on else Color(1, 1, 1, 0.75)
	fresh.shadow_color = Color(accent.r, accent.g, accent.b, 0.85 if on else 0.55)
	fresh.shadow_size = 16 if on else 10
	node.add_theme_stylebox_override("panel", fresh)

## Smoothly tween an HP bar's value + tint instead of snapping.
func _animate_hp_bar(bar: ProgressBar, target: int) -> void:
	if bar == null: return
	var tw := bar.create_tween()
	tw.tween_property(bar, "value", float(target), 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

class _ChainOverlay extends Control:
	var _tiles_chain: Array = []
	var _wrap: Control
	var _phase: float = 0.0
	func _ready() -> void:
		set_process(true)
	func _process(delta: float) -> void:
		_phase += delta * 2.0
		if not _tiles_chain.is_empty():
			queue_redraw()
	func set_tiles(tiles: Array, wrap: Control) -> void:
		_tiles_chain = tiles
		_wrap = wrap
		queue_redraw()
	func _draw() -> void:
		if _tiles_chain.size() < 2 or _wrap == null:
			return
		var points: PackedVector2Array = PackedVector2Array()
		for t in _tiles_chain:
			var ctrl := t as Control
			if ctrl == null: continue
			points.append(ctrl.global_position + ctrl.size * 0.5 - global_position)
		# Glow underlay.
		for i in points.size() - 1:
			draw_line(points[i], points[i + 1], Color(1, 1, 1, 0.35), 10.0, true)
		# Main line — pink/magenta with subtle pulse.
		var pulse: float = 0.65 + 0.35 * (0.5 + 0.5 * sin(_phase))
		var col := Color(1.0, 0.45, 0.75, pulse)
		for i in points.size() - 1:
			draw_line(points[i], points[i + 1], col, 5.0, true)
		# Node dots at each junction.
		for p in points:
			draw_circle(p, 6, Color(1, 1, 1, 0.9))
			draw_circle(p, 4, Color("#c81f8c"))
