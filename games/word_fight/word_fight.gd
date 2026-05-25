extends Control
## Word Fight — landscape duel on a 4×4 gem board. Alternating turns; dictionary
## words deal damage. 2.5D combatants flank the board on a battle stage.

const Tile := preload("res://games/word_fight/tile_node.gd")
const Topics := preload("res://games/word_fight/topics.gd")
const Fx := preload("res://games/word_fight/fx.gd")
const Worlds := preload("res://games/word_fight/worlds.gd")
const Items := preload("res://games/word_fight/items.gd")

const ROWS := 4
const COLS := 4
const MIN_WORD_LEN := 3
const MIN_VOWELS := 5
const RAINBOW_STREAK_REQUIRED := 3   # 3× consecutive 5+ letter words → rainbow
const RAINBOW_MAX := 3                # max stored rainbow charges
const DMG_LEN_MULT := 8               # base damage = word_length² × this (quadratic scaling)
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

# --- gem / hazard tuning ---
const GEM_SPAWN_CHANCE := 0.15
const FIRE_BONUS := 40                # bonus damage per Fire gem used
const DIAMOND_BONUS := 150            # bonus damage per Diamond gem used
const HEAL_PER_GEM := 350             # HP restored per Healing gem used
const POISON_STACKS_PER_GEM := 3      # poison stacks added per Poison gem used
const POISON_DMG_PER_STACK := 26      # enemy DoT per stack, start of its turn
const FIRE_FUSE_START := 3            # turns a Fire gem lasts before burning away
const FIRE_BURN_DMG := 180            # self damage when a Fire gem burns away
const BURN_FUSE_START := 3            # turns a Burning hazard lasts
const BURN_HAZARD_DMG := 160          # self damage when a Burning tile scorches
const LOCK_TURNS_START := 2           # turns a Locked tile stays frozen
const POISONED_TILE_DMG := 90         # self damage per Poisoned tile used in a word
const LEECH_DMG := 150                # HP drained per turn while leeched
const LEECH_TURNS := 3                # duration of the Leech ability
const MAX_STONE := 3                  # cap on Stone tiles to avoid soft-locks

func _enemy_avatar_path() -> String:
	return "res://assets/avatars/%s.svg" % str(_enemy.get("avatar", "octopus"))

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
var player_status_label: Label
var enemy_status_label: Label
var submit_btn: Button
var clear_btn: Button
var rainbow_btn: Button
var back_btn: Button
var streak_dots_row: HBoxContainer
var board_bg: Control                  # wooden backdrop behind the 4×4 grid
var board_wrap: Control
var arena_bg: Control                  # full-screen 2.5D arena backdrop
var player_avatar                      # Fx.Combatant — 2.5D player character
var enemy_avatar                       # Fx.Combatant — 2.5D enemy character
var submit_glow: Panel
var rainbow_sweep: ColorRect
var enemy_action_chip: PanelContainer
var enemy_action_label: Label
var enemy_word_toast: PanelContainer
var enemy_word_toast_label: Label

const RAINBOW_LABEL := "Auto"

var _tiles: Array = []                 # row-major Array of Tile (size 25), nullable
var _selected: Array = []              # ordered Array of Tile in player's current chain
var _player_max_hp: int = 1000         # set from Lex level + items in _start_battle
var _player_hp: int = 1000
var _enemy_hp: int = 1000
var _enemy_max_hp: int = 1000
var _enemy_idx: int = 0
var _world_idx: int = 0
var _enemy: Dictionary = {}            # current enemy data from WFWorlds
var _topic: String = "food"
var _player_streak_5plus: int = 0
var _player_word_streak: int = 0
var _rainbows: int = 0
var _is_player_turn: bool = true
var _busy: bool = false                # animations/AI
var _rainbow_auto_busy: bool = false

# Combatant status effects.
var _enemy_frozen: bool = false        # skips its next turn (Ice gem)
var _enemy_poison: int = 0             # poison stacks — DoT at the start of its turn
var _leech_turns: int = 0              # Leech ability — drains the player each turn

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
	_world_idx = int(session.get("world_idx", 0))
	_enemy_idx = int(session.get("enemy_idx", 0))
	_enemy = Worlds.enemy(_world_idx, _enemy_idx)
	var seeded_topic: String = String(session.get("topic", ""))
	if not seeded_topic.is_empty():
		_topic = seeded_topic
	_build_ui()
	back_btn.pressed.connect(func():
		Audio.play("click")
		Fx.set_portrait()
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	submit_btn.pressed.connect(_submit_player_word)
	clear_btn.pressed.connect(func():
		Audio.play("click")
		_clear_chain())
	rainbow_btn.pressed.connect(_use_rainbow)
	Audio.start_music()
	Fx.set_landscape()
	_start_battle(_enemy_idx)

# ---------------- UI construction (wf_game_a layout) ----------------

func _build_ui() -> void:
	# Full-screen 2.5D battle-arena backdrop.
	arena_bg = Fx.ArenaBG.new()
	arena_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	arena_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	arena_bg.set_world(_world_idx)
	add_child(arena_bg)
	# Compact header for landscape.
	var hdr_panel := PanelContainer.new()
	hdr_panel.anchor_right = 1.0
	hdr_panel.offset_bottom = 44
	var hdr_sb := StyleBoxFlat.new()
	hdr_sb.bg_color = Color(0.06, 0.04, 0.10, 0.85)
	hdr_sb.shadow_color = Color(0, 0, 0, 0.4)
	hdr_sb.shadow_size = 4
	hdr_sb.shadow_offset = Vector2i(0, 2)
	hdr_sb.content_margin_left = 12
	hdr_sb.content_margin_right = 12
	hdr_sb.content_margin_top = 6
	hdr_sb.content_margin_bottom = 6
	hdr_panel.add_theme_stylebox_override("panel", hdr_sb)
	add_child(hdr_panel)
	var _hdr_row := HBoxContainer.new()
	_hdr_row.add_theme_constant_override("separation", 12)
	hdr_panel.add_child(_hdr_row)
	back_btn = Button.new()
	back_btn.text = ""
	back_btn.focus_mode = Control.FOCUS_NONE
	var arrow_tex_path := "res://assets/icons/arrow_left.svg"
	if ResourceLoader.exists(arrow_tex_path):
		back_btn.icon = load(arrow_tex_path)
		back_btn.expand_icon = false
		back_btn.modulate = Color("#c0b4a6")
	else:
		back_btn.text = "<"
		back_btn.add_theme_font_size_override("font_size", 22)
	back_btn.add_theme_color_override("font_color", Color("#c0b4a6"))
	var empty_sb := StyleBoxEmpty.new()
	back_btn.add_theme_stylebox_override("normal", empty_sb)
	back_btn.add_theme_stylebox_override("hover", empty_sb)
	back_btn.add_theme_stylebox_override("pressed", empty_sb)
	back_btn.add_theme_stylebox_override("focus", empty_sb)
	back_btn.custom_minimum_size = Vector2(36, 36)
	_hdr_row.add_child(back_btn)
	var title_lbl := Label.new()
	title_lbl.text = "Word Fight"
	title_lbl.add_theme_font_size_override("font_size", 16)
	title_lbl.add_theme_color_override("font_color", Color("#e0d4c6"))
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hdr_row.add_child(title_lbl)
	enemy_action_chip = PanelContainer.new()
	var ea_sb := StyleBoxFlat.new()
	ea_sb.bg_color = Color(0.8, 0.2, 0.3, 0.35)
	ea_sb.set_corner_radius_all(99)
	ea_sb.content_margin_left = 12
	ea_sb.content_margin_right = 12
	ea_sb.content_margin_top = 4
	ea_sb.content_margin_bottom = 4
	enemy_action_chip.add_theme_stylebox_override("panel", ea_sb)
	enemy_action_label = Label.new()
	enemy_action_label.text = ""
	enemy_action_label.add_theme_color_override("font_color", Color("#ff8a9a"))
	enemy_action_label.add_theme_font_size_override("font_size", 14)
	enemy_action_chip.add_child(enemy_action_label)
	enemy_action_chip.visible = false
	_hdr_row.add_child(enemy_action_chip)
	var topic_chip := Chrome.chip("%s ×2" % _topic.capitalize(), Color(0.9, 0.75, 0.3, 0.25), Color("#ffd060"))
	_hdr_row.add_child(topic_chip)
	# topic_label kept (hidden) so _start_battle can write to it harmlessly.
	topic_label = Label.new()
	topic_label.visible = false
	add_child(topic_label)

	# Root: combat row (expands) above the action bar.
	var root := VBoxContainer.new()
	root.anchor_right = 1.0
	root.anchor_bottom = 1.0
	root.offset_left = 6
	root.offset_top = 48
	root.offset_right = -6
	root.offset_bottom = -4
	root.add_theme_constant_override("separation", 4)
	add_child(root)

	# Combat row: player column | center board | enemy column.
	var combat := HBoxContainer.new()
	combat.size_flags_vertical = Control.SIZE_EXPAND_FILL
	combat.add_theme_constant_override("separation", 4)
	combat.add_child(_combatant_column(true))
	combat.add_child(_center_column())
	combat.add_child(_combatant_column(false))
	root.add_child(combat)

	root.add_child(_actions_bar())

	# Big centered word toast for enemy attacks (hidden by default).
	enemy_word_toast = PanelContainer.new()
	var ewt_sb := StyleBoxFlat.new()
	ewt_sb.bg_color = Color(0.1, 0.07, 0.18, 0.85)
	ewt_sb.set_corner_radius_all(20)
	ewt_sb.shadow_color = Color(0, 0, 0, 0.4)
	ewt_sb.shadow_size = 12
	ewt_sb.content_margin_left = 28
	ewt_sb.content_margin_right = 28
	ewt_sb.content_margin_top = 12
	ewt_sb.content_margin_bottom = 12
	enemy_word_toast.add_theme_stylebox_override("panel", ewt_sb)
	enemy_word_toast_label = Label.new()
	enemy_word_toast_label.text = ""
	enemy_word_toast_label.add_theme_font_size_override("font_size", 28)
	enemy_word_toast_label.add_theme_color_override("font_color", Color.WHITE)
	enemy_word_toast_label.add_theme_color_override("font_outline_color", Color(1.0, 0.3, 0.4, 0.6))
	enemy_word_toast_label.add_theme_constant_override("outline_size", 4)
	enemy_word_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemy_word_toast.add_child(enemy_word_toast_label)
	enemy_word_toast.visible = false
	enemy_word_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	enemy_word_toast.z_index = 100
	add_child(enemy_word_toast)

	# Rainbow full-screen iridescent sweep overlay (hidden by default).
	rainbow_sweep = ColorRect.new()
	rainbow_sweep.set_anchors_preset(Control.PRESET_FULL_RECT)
	rainbow_sweep.color = Color(1, 1, 1, 0)
	rainbow_sweep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rainbow_sweep.z_index = 80
	add_child(rainbow_sweep)

# ---- landscape layout helpers ----

## One side of the duel: a 2.5D combatant above an HP bar + status line.
## The player column also carries the rainbow streak dots.
func _combatant_column(is_player: bool) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_stretch_ratio = 0.55
	col.add_theme_constant_override("separation", 1)
	var accent: Color = SAGE if is_player else HP_PINK
	var accent_dark: Color = SAGE_DARK if is_player else HP_PINK_DARK

	var combatant := Fx.Combatant.new()
	combatant.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	combatant.size_flags_vertical = Control.SIZE_EXPAND_FILL
	combatant.custom_minimum_size = Vector2(0, 64)
	var svg: String = ("res://assets/avatars/%s.svg" % GameState.player_avatar) if is_player else _enemy_avatar_path()
	combatant.setup(svg, 1.0 if is_player else -1.0, accent)
	col.add_child(combatant)

	var name_lbl := Label.new()
	name_lbl.text = (GameState.player_name if GameState.player_name != "" else "You") if is_player else String(_enemy.get("name", "Enemy"))
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.clip_text = true
	name_lbl.add_theme_font_size_override("font_size", 13)
	name_lbl.add_theme_color_override("font_color", accent_dark)
	col.add_child(name_lbl)

	var bar := _hp_bar(accent)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var value_lbl := Label.new()
	value_lbl.text = "1000"
	value_lbl.add_theme_font_size_override("font_size", 13)
	value_lbl.add_theme_color_override("font_color", Color("#c0b4a6"))
	value_lbl.custom_minimum_size = Vector2(36, 0)
	value_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var hp_row := HBoxContainer.new()
	hp_row.add_theme_constant_override("separation", 6)
	hp_row.add_child(bar)
	hp_row.add_child(value_lbl)
	col.add_child(hp_row)

	var status := _make_status_label(
		Color("#c0392b") if is_player else Color("#1f9fff"), HORIZONTAL_ALIGNMENT_CENTER)
	col.add_child(status)

	if is_player:
		player_avatar = combatant
		player_hp_bar = bar
		player_hp_label = value_lbl
		player_status_label = status
		var dots_holder := CenterContainer.new()
		streak_dots_row = UI.streak_dots(0, RAINBOW_STREAK_REQUIRED, 8)
		dots_holder.add_child(streak_dots_row)
		col.add_child(dots_holder)
	else:
		enemy_avatar = combatant
		enemy_hp_bar = bar
		enemy_hp_label = value_lbl
		enemy_status_label = status
		enemy_name_label = name_lbl
	return col

## Center column: status line, the word pill, and the 4×4 gem board.
func _center_column() -> VBoxContainer:
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 3)

	status_label = Label.new()
	status_label.text = ""
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.clip_text = true
	status_label.add_theme_color_override("font_color", Color("#8a7e72"))
	status_label.add_theme_font_size_override("font_size", 13)
	col.add_child(status_label)

	col.add_child(_word_pill())

	# Board panel — wooden backdrop; the grid is scaled to fit inside it.
	var board_panel := Control.new()
	board_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board_panel.custom_minimum_size = Vector2(200, 120)
	board_bg = Fx.BoardBG.new()
	board_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	board_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board_bg.set_world(_world_idx)
	board_panel.add_child(board_bg)
	grid = GridContainer.new()
	grid.columns = COLS
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	board_panel.add_child(grid)
	board_wrap = board_panel
	board_panel.resized.connect(_fit_board)
	col.add_child(board_panel)
	return col

## The pink "Your word / damage" pill shown above the board.
func _word_pill() -> PanelContainer:
	var word_pill := PanelContainer.new()
	var wp_sb := StyleBoxFlat.new()
	wp_sb.bg_color = PINK_PILL_BG
	wp_sb.set_corner_radius_all(18)
	wp_sb.set_border_width_all(2)
	wp_sb.border_color = PINK_PILL_BORDER
	wp_sb.content_margin_left = 12
	wp_sb.content_margin_right = 12
	wp_sb.content_margin_top = 2
	wp_sb.content_margin_bottom = 2
	wp_sb.shadow_color = Color(1.0, 0.4, 0.7, 0.2)
	wp_sb.shadow_size = 5
	wp_sb.shadow_offset = Vector2i(0, 2)
	word_pill.add_theme_stylebox_override("panel", wp_sb)
	var word_col := VBoxContainer.new()
	word_col.add_theme_constant_override("separation", 0)
	current_word_label = Label.new()
	current_word_label.text = "—"
	current_word_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	current_word_label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	current_word_label.add_theme_color_override("font_color", HP_PINK_DARK)
	current_word_label.add_theme_font_size_override("font_size", 18)
	word_col.add_child(current_word_label)
	dmg_preview_label = Label.new()
	dmg_preview_label.text = ""
	dmg_preview_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dmg_preview_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dmg_preview_label.add_theme_color_override("font_color", SAGE_DARK)
	dmg_preview_label.add_theme_font_size_override("font_size", 12)
	word_col.add_child(dmg_preview_label)
	word_pill.add_child(word_col)
	return word_pill

## Bottom action bar: rainbow charge button + Attack (epic dungeon style).
func _actions_bar() -> HBoxContainer:
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)

	rainbow_btn = Button.new()
	rainbow_btn.text = "%s (0)" % RAINBOW_LABEL
	rainbow_btn.icon = RAINBOW_ICON
	rainbow_btn.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	rainbow_btn.expand_icon = false
	rainbow_btn.add_theme_constant_override("icon_max_width", 20)
	rainbow_btn.add_theme_constant_override("h_separation", 6)
	rainbow_btn.focus_mode = Control.FOCUS_NONE
	rainbow_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rainbow_btn.add_theme_font_size_override("font_size", 16)
	rainbow_btn.add_theme_color_override("font_color", Color("#e0d4c6"))
	rainbow_btn.add_theme_color_override("font_hover_color", Color("#f0e8da"))
	rainbow_btn.add_theme_color_override("font_pressed_color", Color("#c0b4a6"))
	rainbow_btn.add_theme_color_override("font_disabled_color", Color("#706460"))
	var rb_sb := StyleBoxFlat.new()
	rb_sb.bg_color = Color("#2a2030")
	rb_sb.set_corner_radius_all(14)
	rb_sb.set_border_width_all(2)
	rb_sb.border_color = Color("#5a4a6a")
	rb_sb.shadow_color = Color(0, 0, 0, 0.3)
	rb_sb.shadow_size = 4
	rb_sb.shadow_offset = Vector2i(0, 2)
	rb_sb.content_margin_left = 14
	rb_sb.content_margin_right = 14
	rb_sb.content_margin_top = 8
	rb_sb.content_margin_bottom = 8
	var rb_press := rb_sb.duplicate() as StyleBoxFlat
	rb_press.bg_color = Color("#1a1220")
	rb_press.shadow_size = 1
	var rb_dis := rb_sb.duplicate() as StyleBoxFlat
	rb_dis.bg_color = Color("#1a1620")
	rb_dis.border_color = Color("#3a3040")
	rainbow_btn.add_theme_stylebox_override("normal", rb_sb)
	rainbow_btn.add_theme_stylebox_override("hover", rb_sb)
	rainbow_btn.add_theme_stylebox_override("pressed", rb_press)
	rainbow_btn.add_theme_stylebox_override("disabled", rb_dis)
	rainbow_btn.add_theme_stylebox_override("focus", rb_sb)
	actions.add_child(rainbow_btn)

	var submit_wrap := Control.new()
	submit_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	submit_wrap.size_flags_stretch_ratio = 2.0
	submit_wrap.custom_minimum_size = Vector2(0, 48)
	submit_glow = Panel.new()
	submit_glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	submit_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var glow_sb := StyleBoxFlat.new()
	glow_sb.bg_color = Color(1, 0.3, 0.4, 0.0)
	glow_sb.set_corner_radius_all(16)
	glow_sb.shadow_color = Color(1.0, 0.3, 0.4, 0.0)
	glow_sb.shadow_size = 20
	submit_glow.add_theme_stylebox_override("panel", glow_sb)
	submit_wrap.add_child(submit_glow)
	submit_btn = _attack_button("Attack")
	submit_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	submit_wrap.add_child(submit_btn)
	actions.add_child(submit_wrap)

	clear_btn = Button.new()
	clear_btn.visible = false
	actions.add_child(clear_btn)
	return actions

func _attack_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 48)
	b.alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.add_theme_font_size_override("font_size", 17)
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_color_override("font_hover_color", Color("#ffe0e4"))
	b.add_theme_color_override("font_pressed_color", Color("#ffc0c8"))
	b.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.4))
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#a0283a")
	sb.set_corner_radius_all(14)
	sb.set_border_width_all(2)
	sb.border_color = Color("#d04a5a")
	sb.shadow_color = Color(0.6, 0.1, 0.15, 0.4)
	sb.shadow_size = 6
	sb.shadow_offset = Vector2i(0, 3)
	sb.content_margin_left = 20
	sb.content_margin_right = 20
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	var press := sb.duplicate() as StyleBoxFlat
	press.bg_color = Color("#801e2e")
	press.shadow_size = 2
	press.shadow_offset = Vector2i(0, 1)
	var disabled := sb.duplicate() as StyleBoxFlat
	disabled.bg_color = Color("#4a1a22")
	disabled.border_color = Color("#6a2a34")
	disabled.shadow_size = 2
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sb)
	b.add_theme_stylebox_override("pressed", press)
	b.add_theme_stylebox_override("focus", sb)
	b.add_theme_stylebox_override("disabled", disabled)
	return b

# ---- HP row helpers ----
func _hp_bar(fill: Color, _mirrored: bool = false) -> ProgressBar:
	# _mirrored is reserved for future right-to-left fill; current implementation
	# keeps both bars draining LTR — the duel feel comes from avatar mirroring.
	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = 100
	bar.value = 100
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 16)
	var bg := StyleBoxFlat.new()
	bg.bg_color = HP_BG
	bg.set_corner_radius_all(99)
	var fg := StyleBoxFlat.new()
	fg.bg_color = fill
	fg.set_corner_radius_all(99)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fg)
	return bar

# Small per-combatant status line (Frozen / Poison / Leeched).
func _make_status_label(color: Color, align: int) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", 14)
	l.add_theme_color_override("font_color", color)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.horizontal_alignment = align
	l.visible = false
	return l

# ---------------- battle setup ----------------

func _start_battle(idx: int) -> void:
	_enemy_idx = idx
	_enemy = Worlds.enemy(_world_idx, _enemy_idx)
	_enemy_max_hp = int(_enemy.hp)
	_enemy_hp = _enemy_max_hp
	_player_max_hp = GameState.lex_max_hp() + int(Items.sum_effect("max_hp_bonus"))
	_player_hp = _player_max_hp
	# Honor the topic seeded by intro; otherwise (e.g. game launched standalone) roll one.
	var seeded: String = String(GameState.wf_session.get("topic", ""))
	_topic = seeded if not seeded.is_empty() else Worlds.random_topic(_world_idx)
	GameState.wf_session["topic"] = _topic
	_player_streak_5plus = 0
	_player_word_streak = 0
	_rainbow_auto_busy = false
	_enemy_frozen = false
	_enemy_poison = 0
	_leech_turns = 0
	_rainbows = clampi(int(Items.sum_effect("start_rainbow")), 0, RAINBOW_MAX)
	_damage_dealt = 0
	_words_used = 0
	_longest_word = ""
	_topic_matches = 0
	_rainbows_used = 0
	_score_earned = 0
	_clear_chain()
	enemy_name_label.text = _enemy.name
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
	_fit_board.call_deferred()

## Scales + centers the letter grid so the whole board fits the panel on any
## screen size. Re-run whenever the board panel is resized.
func _fit_board() -> void:
	if grid == null or board_wrap == null:
		return
	var gs := grid.get_combined_minimum_size()
	if gs.x <= 0.0 or gs.y <= 0.0:
		return
	var avail: Vector2 = board_wrap.size - Vector2(8, 8)
	var s: float = clampf(minf(avail.x / gs.x, avail.y / gs.y), 0.1, 1.5)
	grid.pivot_offset = Vector2.ZERO
	grid.scale = Vector2(s, s)
	grid.position = ((board_wrap.size - gs * s) * 0.5).round()

func _spawn_tile_at(idx: int, letter: String, rainbow: bool = false) -> void:
	var t: Tile = Tile.new()
	t.letter = letter
	t.rainbow = rainbow
	t.tile_pressed.connect(_on_tile_pressed)
	t.tile_selected_fx.connect(_on_tile_selected_fx)
	grid.add_child(t)
	grid.move_child(t, idx)
	_tiles[idx] = t
	_roll_and_apply_gem(t)

## Resets a tile's special state, then maybe rolls a fresh gem onto it.
func _roll_and_apply_gem(t: Tile) -> void:
	t.reset_special()
	var chance := GEM_SPAWN_CHANCE + Items.sum_effect("gem_rate_bonus")
	if randf() < chance:
		t.gem = _weighted_gem()
		if t.gem == Tile.Gem.FIRE:
			t.fire_fuse = FIRE_FUSE_START

## Weighted random pick of a non-NORMAL gem type.
func _weighted_gem() -> int:
	var weights := [
		[Tile.Gem.FIRE, 22], [Tile.Gem.HEALING, 20], [Tile.Gem.POISON, 18],
		[Tile.Gem.ICE, 16], [Tile.Gem.GOLD, 16], [Tile.Gem.DIAMOND, 8],
	]
	var total := 0
	for w in weights:
		total += int(w[1])
	var r := randi() % total
	for w in weights:
		r -= int(w[1])
		if r < 0:
			return int(w[0])
	return Tile.Gem.FIRE

func _on_tile_selected_fx(tile: Tile, color: Color) -> void:
	if board_wrap == null: return
	var pos := tile.global_position + tile.size * 0.5 - board_wrap.global_position
	Fx.sparkle_burst(board_wrap, pos, color, 7)

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
	if tile.is_blocked():
		var why := "That tile is locked!" if tile.hazard == Tile.Hazard.LOCKED else "That tile is solid stone!"
		_flash_status(why, Color(0.6, 0.45, 0.25))
		Audio.play("invalid")
		return
	if tile.selected_order >= 0:
		# Tapping a selected tile: pop chain back to (and including) this tile.
		var idx := tile.selected_order
		while _selected.size() > idx:
			var popped: Tile = _selected.pop_back()
			popped.selected_order = -1
		Audio.play("deselect")
	else:
		tile.selected_order = _selected.size()
		_selected.append(tile)
		# Pitch climbs with chain length; gem tiles get a sparkle on top.
		Audio.play("select", 0.04, lerpf(0.85, 1.45, clampf(_selected.size() / 9.0, 0.0, 1.0)))
		if tile.gem != Tile.Gem.NORMAL:
			Audio.play("gem", 0.05)
	_refresh_current_word()

func _clear_chain() -> void:
	for t: Tile in _selected:
		t.selected_order = -1
	_selected.clear()
	_refresh_current_word()

## Usable text width inside the word pill — drives word-label font shrinking.
func _word_box_width() -> float:
	return maxf(get_viewport_rect().size.x - 80.0, 120.0)

func _refresh_current_word() -> void:
	var w := _chain_word()
	Fx.fit_label_font(current_word_label, w if not w.is_empty() else "—", 24, _word_box_width())
	submit_btn.disabled = w.length() < MIN_WORD_LEN
	# Live damage preview — gem-aware.
	if w.length() >= MIN_WORD_LEN:
		var dmg := _calc_damage(_selected, w)
		var topic_match := Topics.has(_topic, w.to_lower())
		var note := ""
		if topic_match:
			note += "  ×2!"
		var poisoned := 0
		for t: Tile in _selected:
			if t.hazard == Tile.Hazard.POISONED:
				poisoned += 1
		if poisoned > 0 and not Items.has_effect("poison_immune"):
			note += "  (-%d hp)" % (poisoned * POISONED_TILE_DMG)
		dmg_preview_label.text = "+%d dmg%s" % [dmg, note]
	else:
		dmg_preview_label.text = ""
	_update_submit_glow(w.length())

## Final damage for a word given its tiles — folds in gems, topic, gold, rainbow
## and equipped-item multipliers. Used by both the live preview and submit.
func _calc_damage(tiles: Array, word: String) -> int:
	var fire := 0
	var gold := 0
	var diamond := 0
	for t in tiles:
		match (t as Tile).gem:
			Tile.Gem.FIRE: fire += 1
			Tile.Gem.GOLD: gold += 1
			Tile.Gem.DIAMOND: diamond += 1
	var d := float(_word_damage(word.length()))
	d += float(fire) * FIRE_BONUS * Items.mult_effect("fire_bonus_mult")
	d += float(diamond) * DIAMOND_BONUS
	if Topics.has(_topic, word.to_lower()):
		d *= TOPIC_MULTIPLIER
	if gold > 0:
		d *= (1.0 + float(gold))
	d *= Items.mult_effect("dmg_mult")
	return int(round(d))

func _chain_word() -> String:
	var s := ""
	for t: Tile in _selected:
		s += t.letter
	return s

## Base damage for a word — scales quadratically with length (length² × DMG_LEN_MULT).
func _word_damage(word_len: int) -> int:
	return word_len * word_len * DMG_LEN_MULT

# ---------------- submit ----------------

func _submit_player_word() -> void:
	if _busy or not _is_player_turn:
		return
	var word_up := _chain_word()
	if word_up.length() < MIN_WORD_LEN:
		return
	var word := word_up.to_lower()
	if not Words.is_valid(word):
		_flash_invalid("Not a word: %s" % word_up); return

	var topic_match := Topics.has(_topic, word)
	var fire_count := 0
	var ice_count := 0
	var poison_count := 0
	var heal_count := 0
	var poisoned_hazard := 0
	for t: Tile in _selected:
		match t.gem:
			Tile.Gem.FIRE: fire_count += 1
			Tile.Gem.ICE: ice_count += 1
			Tile.Gem.POISON: poison_count += 1
			Tile.Gem.HEALING: heal_count += 1
		if t.hazard == Tile.Hazard.POISONED:
			poisoned_hazard += 1
	var dmg := _calc_damage(_selected, word)

	var xp_base := word.length() * 10 + (STREAK_BONUS * _player_word_streak)
	if topic_match:
		xp_base = int(xp_base * 2)
	var xp_awarded := GameState.add_xp("word_fight", xp_base)
	_score_earned += xp_awarded

	_enemy_hp = maxi(0, _enemy_hp - dmg)
	_player_word_streak += 1

	# --- gem side effects ---
	if ice_count > 0:
		_enemy_frozen = true
	if poison_count > 0:
		_enemy_poison += poison_count * POISON_STACKS_PER_GEM
	if heal_count > 0:
		var healed := mini(heal_count * HEAL_PER_GEM, _player_max_hp - _player_hp)
		_player_hp += healed
		if healed > 0 and player_avatar != null and is_inside_tree():
			Audio.play("heal")
			Fx.heal_popup(self, _avatar_center(player_avatar) + Vector2(20, -10), healed)
	# Poisoned hazard tiles bite back when used in a word.
	if poisoned_hazard > 0 and not Items.has_effect("poison_immune"):
		var self_dmg := _damage_player(poisoned_hazard * POISONED_TILE_DMG)
		if player_avatar != null and is_inside_tree():
			Fx.damage_popup(self, _avatar_center(player_avatar) + Vector2(20, -10), self_dmg, false, Color("#7ad14f"))

	# Stats for victory/defeat screens.
	_damage_dealt += dmg
	_words_used += 1
	if word.length() > _longest_word.length():
		_longest_word = word_up
	if topic_match:
		_topic_matches += 1

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
	if ice_count > 0: tag += "  FROZEN!"
	if poison_count > 0: tag += "  POISON!"
	_flash_hit("%s for %d dmg%s" % [word_up, dmg, tag])

	# ----- HIT FX -----
	var big_hit := dmg >= 350
	Audio.play("big_hit" if big_hit else "hit", 0.08)
	if enemy_avatar != null and player_avatar != null and is_inside_tree():
		player_avatar.attack()                        # player swings toward the enemy
		# Confetti from the selected tiles, trailing the word energy toward the enemy.
		if board_wrap != null:
			var froms: Array = []
			var cols: Array = []
			for t: Tile in _selected:
				froms.append(t.global_position + t.size * 0.5 - global_position)
				cols.append(Fx.gem_accent(t.gem) if t.gem != Tile.Gem.NORMAL else Fx.SELECT_BOTTOM)
			Fx.confetti_to(self, froms, _avatar_center(enemy_avatar), cols)
		# Word-energy bolt flies from the player; the hit reaction lands on impact.
		var dcolor := Fx.damage_color_for(dmg)
		var on_hit := func() -> void:
			if not is_inside_tree() or enemy_avatar == null: return
			var ec := _avatar_center(enemy_avatar)
			Fx.impact_burst(self, ec, dcolor, big_hit)
			Fx.damage_popup(self, ec + Vector2(20, -10), dmg, big_hit, dcolor)
			enemy_avatar.take_hit(big_hit)
			if big_hit:
				Fx.slash(self, ec, Color.WHITE)
				Fx.shake(self, 5.0, 0.28)
		Fx.strike_bolt(self, _avatar_center(player_avatar) + Vector2(16, -4),
			_avatar_center(enemy_avatar), Color("#7fd9ff"), on_hit)
	# Topic banner.
	if topic_match:
		Fx.banner(self, "×2 TOPIC!", Color("#ffc844"), Color("#7a4a00"))
	if ice_count > 0:
		Fx.banner(self, "ENEMY FROZEN!", Color("#4db4ff"), Color.WHITE)
	elif poison_count > 0:
		Fx.banner(self, "POISONED!", Color("#3da94f"), Color.WHITE)
	# Rainbow earn fireworks (just earned this submit?).
	if word.length() >= 5 and _player_streak_5plus == 0 and _rainbows > 0:
		Fx.fireworks(self, Vector2(size.x * 0.5, size.y * 0.4))

	_consume_selected_and_refill(true)
	_refresh_hud()

	if _enemy_hp <= 0:
		_on_enemy_defeated()
		return
	if _player_hp <= 0:
		_defeat()
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
		_roll_and_apply_gem(t)
		t.selected_order = -1
		t.scale = Vector2(1, 1)
		t.modulate.a = 1.0
		t.play_drop_in()
	_selected.clear()
	_enforce_vowel_minimum()
	_refresh_current_word()

# ---------------- enemy AI ----------------

func _enemy_turn() -> void:
	var skill: float = float(_enemy.skill)
	# Poison damage-over-time ticks at the start of the enemy's turn.
	if _enemy_poison > 0:
		var pd := _enemy_poison * POISON_DMG_PER_STACK
		_enemy_hp = maxi(0, _enemy_hp - pd)
		_enemy_poison -= 1
		_set_status("%s suffers %d poison damage!" % [_enemy.get("name", "Enemy"), pd])
		if enemy_avatar != null and is_inside_tree():
			Fx.damage_popup(self, _avatar_center(enemy_avatar) + Vector2(20, -10), pd, false, Color("#7ad14f"))
		_refresh_hud()
		await get_tree().create_timer(0.7).timeout
		if _enemy_hp <= 0:
			_on_enemy_defeated()
			return
	# Frozen — the enemy loses its whole turn.
	if _enemy_frozen:
		_enemy_frozen = false
		_set_status("%s is frozen solid — turn skipped!" % _enemy.get("name", "Enemy"))
		Fx.banner(self, "ENEMY FROZEN!", Color("#4db4ff"), Color.WHITE)
		_refresh_hud()
		await get_tree().create_timer(1.0).timeout
		_end_enemy_turn()
		return
	# Maybe sabotage the board before attacking.
	await _maybe_enemy_ability(skill)
	_set_status("Enemy is thinking…")
	var pick: Dictionary = await _enemy_pick_word_async(skill)
	if pick.is_empty():
		_set_status("Enemy passed.")
		await get_tree().create_timer(0.6).timeout
		_end_enemy_turn()
		return
	var path: Array = pick.path
	var word: String = pick.word
	_show_word_toast("")
	for i in path.size():
		var t: Tile = _tiles[path[i]]
		t.selected_order = i
		var partial := word.substr(0, i + 1).to_upper()
		_show_enemy_action(partial + "_")
		_show_word_toast(partial)
		Fx.shake(self, 2.0, 0.12)
		Audio.play("select", 0.03, lerpf(0.7, 1.3, clampf(float(i) / float(path.size()), 0.0, 1.0)))
		await get_tree().create_timer(0.32).timeout
	_show_enemy_action(word.to_upper())
	_show_word_toast(word.to_upper())
	await get_tree().create_timer(0.7).timeout
	var topic_match := Topics.has(_topic, word)
	var raw_dmg: int = _word_damage(word.length())
	if topic_match:
		raw_dmg = int(raw_dmg * TOPIC_MULTIPLIER)
	var dmg := _damage_player(raw_dmg)
	var action_text := "%s → %d dmg" % [word.to_upper(), dmg]
	if topic_match:
		action_text += "  ×2!"
	_show_enemy_action(action_text)
	_show_word_toast("%s\n-%d" % [word.to_upper(), dmg])
	# ----- ENEMY HIT FX on the player -----
	var e_big := dmg >= 350
	if player_avatar != null and enemy_avatar != null and is_inside_tree():
		enemy_avatar.attack()                         # enemy swings toward the player
		var dcolor := Fx.damage_color_for(dmg)
		var on_hit := func() -> void:
			if not is_inside_tree() or player_avatar == null: return
			var pc := _avatar_center(player_avatar)
			Audio.play("enemy_hit", 0.07)
			Fx.impact_burst(self, pc, dcolor, e_big)
			Fx.damage_popup(self, pc + Vector2(20, -10), dmg, e_big, dcolor)
			player_avatar.take_hit(e_big)
			if e_big:
				Fx.slash(self, pc, Color("#ff5a6e"))
				Fx.shake(self, 5.0, 0.28)
		Fx.strike_bolt(self, _avatar_center(enemy_avatar) + Vector2(-16, -4),
			_avatar_center(player_avatar), Color("#c5402f"), on_hit)
	# Hold on the hit reaction before the tiles dissolve.
	await get_tree().create_timer(0.7).timeout
	_hide_word_toast()
	# Consume + refill those tiles.
	_selected.clear()
	for i in path:
		_selected.append(_tiles[i])
	_consume_selected_and_refill(false)
	_refresh_hud()
	if _player_hp <= 0:
		_defeat()
		return
	_end_enemy_turn()

func _end_enemy_turn() -> void:
	_busy = false
	_is_player_turn = true
	_dim_board(false)
	_hide_enemy_action()
	_tick_player_turn_start()
	if _player_hp <= 0:
		_defeat()
		return
	_set_status("Your turn — form a word!")
	_refresh_hud()

## Plays the defeat sting and routes to the defeat screen.
func _defeat() -> void:
	_set_status("You were defeated!")
	Audio.stop_music()
	Audio.play("defeat")
	_busy = true
	_is_player_turn = false
	_dim_board(false)
	await get_tree().create_timer(0.8).timeout
	_publish_session(false)
	get_tree().change_scene_to_file("res://games/word_fight/defeat.tscn")

## Body anchor of a 2.5D combatant in this Control's local space — FX aim here.
func _avatar_center(node) -> Vector2:
	var anchor: Vector2 = node.call("body_global")
	return anchor - global_position

## Applies damage to the player through armor mitigation. Returns the amount dealt.
func _damage_player(raw: int) -> int:
	var final := maxi(0, int(round(float(raw) * Items.mult_effect("dmg_taken_mult"))))
	_player_hp = maxi(0, _player_hp - final)
	return final

# ---------------- enemy abilities ----------------

## Rolls whether the enemy sabotages the board, then runs one of its abilities.
func _maybe_enemy_ability(skill: float) -> void:
	var abilities: Array = _enemy.get("abilities", [])
	if abilities.is_empty():
		return
	if randf() > (0.3 + skill * 0.3):
		return
	await _run_enemy_ability(String(abilities[randi() % abilities.size()]))

func _run_enemy_ability(ability: String) -> void:
	var ename: String = _enemy.get("name", "Enemy")
	Audio.play("hazard")
	match ability:
		"scramble":
			_set_status("%s scrambles your letters!" % ename)
			Fx.banner(self, "SCRAMBLE!", Color("#b06cff"), Color.WHITE)
			_scramble_board()
		"burn":
			var n := _apply_hazard_to_random(Tile.Hazard.BURNING, 3)
			_set_status("%s sets %d tiles ablaze!" % [ename, n])
			Fx.banner(self, "BURN!", Color("#ff5a3c"), Color.WHITE)
		"lock":
			var n := _apply_hazard_to_random(Tile.Hazard.LOCKED, 2)
			_set_status("%s freezes %d tiles!" % [ename, n])
			Fx.banner(self, "LOCK!", Color("#4db4ff"), Color.WHITE)
		"stone":
			var n := _apply_hazard_to_random(Tile.Hazard.STONE, 1)
			_set_status("%s turns a tile to stone!" % ename if n > 0 else "%s tried to cast Stone." % ename)
			Fx.banner(self, "STONE!", Color("#8a8a90"), Color.WHITE)
		"poison":
			var n := _apply_hazard_to_random(Tile.Hazard.POISONED, 3)
			_set_status("%s poisons %d tiles!" % [ename, n])
			Fx.banner(self, "POISON TILES!", Color("#3da94f"), Color.WHITE)
		"leech":
			_leech_turns = LEECH_TURNS
			_set_status("%s casts Leech — your HP will drain!" % ename)
			Fx.banner(self, "LEECH!", Color("#c0392b"), Color.WHITE)
	_refresh_hud()
	await get_tree().create_timer(1.1).timeout

## Shuffles the letters of every selectable tile.
func _scramble_board() -> void:
	var movable: Array = []
	var letters: Array = []
	for t: Tile in _tiles:
		if t != null and not t.is_blocked():
			movable.append(t)
			letters.append(t.letter)
	letters.shuffle()
	for i in movable.size():
		var t: Tile = movable[i]
		t.letter = String(letters[i])
		t.play_pop_in(0.0)
	_clear_chain()
	_enforce_vowel_minimum()

## Applies a hazard to up to `count` random hazard-free tiles. Returns how many.
func _apply_hazard_to_random(hazard_type: int, count: int) -> int:
	var candidates: Array = []
	for t: Tile in _tiles:
		if t != null and t.hazard == Tile.Hazard.NONE:
			candidates.append(t)
	candidates.shuffle()
	var applied := 0
	for t: Tile in candidates:
		if applied >= count:
			break
		if hazard_type == Tile.Hazard.STONE and _count_hazard(Tile.Hazard.STONE) >= MAX_STONE:
			break
		t.hazard = hazard_type
		if hazard_type == Tile.Hazard.BURNING:
			t.burn_fuse = BURN_FUSE_START
		elif hazard_type == Tile.Hazard.LOCKED:
			t.lock_turns = LOCK_TURNS_START
		t.play_pop_in(0.0)
		applied += 1
	return applied

func _count_hazard(hazard_type: int) -> int:
	var c := 0
	for t: Tile in _tiles:
		if t != null and t.hazard == hazard_type:
			c += 1
	return c

## Start-of-player-turn upkeep: regen, leech drain, fire/burn/lock countdowns.
func _tick_player_turn_start() -> void:
	var p_pos := Vector2.ZERO
	if player_avatar != null and is_inside_tree():
		p_pos = _avatar_center(player_avatar) + Vector2(20, -10)
	# Healing-pendant regen.
	var regen := int(Items.sum_effect("heal_per_turn"))
	if regen > 0 and _player_hp < _player_max_hp:
		var healed := mini(regen, _player_max_hp - _player_hp)
		_player_hp += healed
		if healed > 0:
			Fx.heal_popup(self, p_pos, healed)
	# Leech drain.
	if _leech_turns > 0:
		_leech_turns -= 1
		var taken := _damage_player(LEECH_DMG)
		_enemy_hp = mini(_enemy_max_hp, _enemy_hp + taken)
		Fx.damage_popup(self, p_pos, taken, false, Color("#c0392b"))
	# Tile timers: fire fuses, burning fuses, lock countdowns.
	for t: Tile in _tiles:
		if t == null:
			continue
		if t.gem == Tile.Gem.FIRE:
			t.fire_fuse -= 1
			if t.fire_fuse <= 0:
				var burned := _damage_player(FIRE_BURN_DMG)
				_tile_scorch_fx(t, burned)
				t.reset_special()
				t.letter = _rand_letter()
				t.play_pop_in(0.0)
		elif t.hazard == Tile.Hazard.BURNING:
			t.burn_fuse -= 1
			if t.burn_fuse <= 0:
				var scorch := _damage_player(BURN_HAZARD_DMG)
				_tile_scorch_fx(t, scorch)
				t.hazard = Tile.Hazard.NONE
				t.burn_fuse = 0
		elif t.hazard == Tile.Hazard.LOCKED:
			t.lock_turns -= 1
			if t.lock_turns <= 0:
				t.hazard = Tile.Hazard.NONE
				t.lock_turns = 0
	_enforce_vowel_minimum()

func _tile_scorch_fx(t: Tile, dmg: int) -> void:
	if not is_inside_tree():
		return
	if board_wrap != null:
		Fx.sparkle_burst(board_wrap, t.global_position + t.size * 0.5 - board_wrap.global_position,
			Color("#ff6a1f"), 8)
	Fx.damage_popup(self, t.global_position + t.size * 0.5 - global_position, dmg, false, Color("#ff7a1f"))

func _enemy_pick_word_async(skill: float) -> Dictionary:
	# Build letter pool from board. Enemy may use any tile but each tile only once
	# per word (same constraint as player chaining without revisits).
	var letters := ""
	for t: Tile in _tiles:
		if t != null and not t.is_blocked():
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
	if candidates.is_empty():
		return {}
	candidates.sort_custom(func(a, b): return a.length() > b.length())
	var fresh := candidates
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
			if t != null and not t.is_blocked() and t.letter == ch:
				found = i
				break
		if found == -1:
			return []
		used[found] = true
		path.append(found)
	return path

# ---------------- HUD / status ----------------

func _show_enemy_action(text: String) -> void:
	if enemy_action_label != null:
		enemy_action_label.text = text
	if enemy_action_chip != null:
		enemy_action_chip.visible = true

func _hide_enemy_action() -> void:
	if enemy_action_chip != null:
		enemy_action_chip.visible = false

func _show_word_toast(text: String) -> void:
	if enemy_word_toast == null:
		return
	enemy_word_toast_label.text = text
	enemy_word_toast.visible = true
	enemy_word_toast.modulate.a = 1.0
	enemy_word_toast.scale = Vector2(1.0, 1.0)
	await get_tree().process_frame
	var sz := enemy_word_toast.size
	var p := size
	enemy_word_toast.pivot_offset = sz * 0.5
	enemy_word_toast.position = Vector2((p.x - sz.x) * 0.5, p.y * 0.35 - sz.y * 0.5)
	var tw := enemy_word_toast.create_tween()
	tw.tween_property(enemy_word_toast, "scale", Vector2(1.06, 1.06), 0.06).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(enemy_word_toast, "scale", Vector2(1.0, 1.0), 0.08)

func _hide_word_toast() -> void:
	if enemy_word_toast == null:
		return
	var tw := create_tween()
	tw.tween_property(enemy_word_toast, "modulate:a", 0.0, 0.3)
	tw.tween_callback(func(): enemy_word_toast.visible = false)

func _refresh_hud() -> void:
	player_hp_label.text = "%d" % _player_hp
	enemy_hp_label.text = "%d" % _enemy_hp
	player_hp_bar.max_value = _player_max_hp
	enemy_hp_bar.max_value = _enemy_max_hp
	_animate_hp_bar(player_hp_bar, _player_hp)
	_animate_hp_bar(enemy_hp_bar, _enemy_hp)
	_tint_hp_bar(player_hp_bar, float(_player_hp) / float(maxi(_player_max_hp, 1)))
	_tint_hp_bar(enemy_hp_bar, float(_enemy_hp) / float(maxi(_enemy_max_hp, 1)))
	_pulse_hp_if_low(player_hp_bar, float(_player_hp) / float(maxi(_player_max_hp, 1)))
	rainbow_btn.disabled = _rainbows <= 0 or not _is_player_turn or _busy or _rainbow_auto_busy
	rainbow_btn.text = "%s (%d)" % [RAINBOW_LABEL, _rainbows]
	_refresh_streak_dots()
	# Active-turn glow on whoever is acting.
	if player_avatar != null:
		player_avatar.set_active(_is_player_turn and not _busy)
	if enemy_avatar != null:
		enemy_avatar.set_active(not _is_player_turn and _busy)
	_refresh_status_labels()

## Updates the per-combatant Frozen / Poison / Leeched status lines.
func _refresh_status_labels() -> void:
	if enemy_status_label != null:
		var e := ""
		if _enemy_frozen:
			e = "Frozen"
		if _enemy_poison > 0:
			e += ("  •  " if e != "" else "") + "Poison x%d" % _enemy_poison
		enemy_status_label.text = e
		enemy_status_label.visible = e != ""
	if player_status_label != null:
		var p := ""
		if _leech_turns > 0:
			p = "Leeched x%d" % _leech_turns
		player_status_label.text = p
		player_status_label.visible = p != ""

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
	Audio.play("invalid")
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
	if _rainbows <= 0 or _rainbow_auto_busy: return
	_rainbows -= 1
	_rainbows_used += 1
	_rainbow_auto_busy = true
	Audio.play("rainbow")
	if rainbow_sweep != null:
		rainbow_sweep.color = Color(1, 0.4, 0.95, 0.0)
		var tw := create_tween()
		tw.tween_property(rainbow_sweep, "color:a", 0.35, 0.18)
		tw.tween_property(rainbow_sweep, "color:a", 0.0, 0.6)
	_flash_status("Rainbow auto-correct!", Color(0.9, 0.55, 0.95))
	_refresh_hud()
	var pick := await _rainbow_pick_best_word()
	if pick.is_empty():
		_flash_invalid("No word found!")
		_rainbows += 1
		_rainbows_used -= 1
		_rainbow_auto_busy = false
		_refresh_hud()
		return
	_clear_chain()
	var path: Array = pick.path
	var word: String = pick.word
	for i in path.size():
		var t: Tile = _tiles[path[i]]
		t.selected_order = i
		_selected.append(t)
		for tx: Tile in _tiles:
			if tx != null:
				tx.rainbow = true
		Audio.play("select", 0.04, lerpf(0.85, 1.45, clampf(float(_selected.size()) / 9.0, 0.0, 1.0)))
		_refresh_current_word()
		await get_tree().create_timer(0.1).timeout
	for tx: Tile in _tiles:
		if tx != null:
			tx.rainbow = false
	_refresh_current_word()
	await get_tree().create_timer(0.25).timeout
	_rainbow_auto_busy = false
	_submit_player_word()

func _rainbow_pick_best_word() -> Dictionary:
	var letters := ""
	for t: Tile in _tiles:
		if t != null and not t.is_blocked():
			letters += t.letter.to_lower()
	var holder: Array = [null]
	var task_id := WorkerThreadPool.add_task(func() -> void:
		holder[0] = Words.words_from_letters(letters, MIN_WORD_LEN, false, 7)
	)
	while not WorkerThreadPool.is_task_completed(task_id):
		await get_tree().process_frame
	WorkerThreadPool.wait_for_task_completion(task_id)
	var candidates: Array[String] = holder[0]
	if candidates.is_empty():
		return {}
	var fresh := candidates
	fresh.sort_custom(func(a: String, b: String) -> bool:
		var da := _word_damage(a.length())
		var db := _word_damage(b.length())
		if Topics.has(_topic, a): da = int(da * TOPIC_MULTIPLIER)
		if Topics.has(_topic, b): db = int(db * TOPIC_MULTIPLIER)
		return da > db
	)
	var word: String = fresh[0]
	var path := _resolve_path_for_word(word)
	if path.is_empty():
		return {}
	return {"word": word, "path": path}

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
	GameState.wf_session["world_idx"] = _world_idx
	GameState.wf_session["enemy_idx"] = _enemy_idx
	GameState.wf_session["enemy_name"] = _enemy.get("name", "")
	GameState.wf_session["enemy_max_hp"] = int(_enemy.get("hp", _enemy_max_hp))
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
	_set_status("Defeated %s!" % _enemy.get("name", "the enemy"))
	var bonus := GameState.add_xp("word_fight", 100)
	_score_earned += bonus
	_busy = true
	Audio.stop_music()
	Audio.play("victory")

	# --- Phase 1: Enemy dissolve + big shake ---
	Fx.shake(self, 8.0, 0.4)
	if enemy_avatar != null:
		var ea := enemy_avatar as Control
		# Flash white then fade out.
		var tw_e := ea.create_tween()
		tw_e.tween_property(ea, "modulate", Color(3, 3, 3, 1), 0.15)
		tw_e.tween_property(ea, "modulate", Color(1, 1, 1, 0), 0.5)
		tw_e.set_parallel(false)
		# Dissolve sparkles from enemy position.
		var ec := ea.global_position + ea.size * 0.5 - global_position
		Fx.sparkle_burst(self, ec, Color("#ffd027"), 20)
		Fx.sparkle_burst(self, ec + Vector2(-20, 10), Color("#ff3aa8"), 12)
		Fx.sparkle_burst(self, ec + Vector2(20, -10), Color("#3aa8ff"), 12)

	# --- Phase 2: Screen flash ---
	var flash := ColorRect.new()
	flash.color = Color(1, 1, 1, 0)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.z_index = 300
	add_child(flash)
	var tw_f := flash.create_tween()
	tw_f.tween_property(flash, "color:a", 0.6, 0.12)
	tw_f.tween_property(flash, "color:a", 0.0, 0.4)
	tw_f.tween_callback(flash.queue_free)

	await get_tree().create_timer(0.35).timeout

	# --- Phase 3: Multi-wave fireworks ---
	var cx := size.x * 0.5
	var cy := size.y * 0.4
	Fx.fireworks(self, Vector2(cx, cy))
	Fx.fireworks(self, Vector2(cx - 80, cy + 40))
	Fx.fireworks(self, Vector2(cx + 80, cy - 20))

	# --- Phase 4: Victory banner ---
	Fx.banner(self, "VICTORY!", Color("#ffd027"), Color("#7a4a00"))

	# Player celebration bounce.
	if player_avatar != null:
		var pa := player_avatar as Control
		var tw_p := pa.create_tween().set_loops(3)
		tw_p.tween_property(pa, "position:y", pa.position.y - 12, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw_p.tween_property(pa, "position:y", pa.position.y, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	await get_tree().create_timer(0.5).timeout

	# --- Phase 5: Second fireworks wave ---
	Fx.fireworks(self, Vector2(cx + 50, cy + 30))
	Fx.fireworks(self, Vector2(cx - 60, cy - 30))

	await get_tree().create_timer(1.0).timeout

	_publish_session(true)
	get_tree().change_scene_to_file("res://games/word_fight/victory.tscn")

## Smoothly tween an HP bar's value + tint instead of snapping.
func _animate_hp_bar(bar: ProgressBar, target: int) -> void:
	if bar == null: return
	var tw := bar.create_tween()
	tw.tween_property(bar, "value", float(target), 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
