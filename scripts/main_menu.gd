extends Control

const GAMES := [
	{"id":"word_fight","name":"Word Fight","desc":"Turn-based battle on a 5×5 board","icon":"⚔","tag":"Battle","scene":"res://games/word_fight/intro.tscn"},
	{"id":"word_match","name":"Word Match","desc":"Drag across circle letters — 2 minutes","icon":"◉","tag":"Drag","scene":"res://games/word_match/word_match.tscn"},
	{"id":"word_found","name":"Word Found","desc":"Tap letters into rows, wave by wave","icon":"≡","tag":"Waves","scene":"res://games/word_found/word_found.tscn"},
	{"id":"story_tell","name":"Story Tell","desc":"Fill blanks — AI scores your grammar","icon":"✎","tag":"AI","scene":"res://games/story_tell/story_tell.tscn"},
	{"id":"word_type","name":"Word Type","desc":"Find every form of the given word","icon":"Aa","tag":"Grammar","scene":"res://games/word_type/word_type.tscn"},
	{"id":"describe_picture","name":"Describe Picture","desc":"Complete sentence starters from an image","icon":"▭","tag":"Visual","scene":"res://games/describe_picture/describe_picture.tscn"},
	{"id":"listen_dictate","name":"Listen & Dictate","desc":"Hear the word — type it correctly","icon":"♬","tag":"Audio","scene":"res://games/listen_dictate/listen_dictate.tscn"},
]

const BG := Color("#faf5ed")
const TEXT := Color("#5a4840")
const TEXT_SEC := Color("#9a8a7e")
const SURFACE := Color("#ffffff")
const BORDER := Color("#e8e0d8")
const GOLD_TINT := Color("#fff1c4")
const GOLD_DEEP := Color("#b48218")
const MODE_CHIP_BG := Color("#ece4d8")
const AVATAR_EMOJI := "🦊"

@onready var list: VBoxContainer = $V/Scroll/List
@onready var greet: Label = $V/Header/Greet
@onready var xp_pill: PanelContainer = $V/Header/XP
@onready var xp_label: Label = $V/Header/XP/Label
@onready var change_mode_btn: Button = $V/ChangeModeBtn
@onready var mode_badge: Control = $V/ModeBadge
@onready var title_lbl: Label = $V/Title

func _ready() -> void:
	# Cream backdrop matching welcome / mode_select.
	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	move_child(bg, 0)

	var who := GameState.player_name if not GameState.player_name.is_empty() else "there"
	greet.text = "Hi, %s %s" % [who, AVATAR_EMOJI]
	greet.add_theme_color_override("font_color", TEXT)
	greet.add_theme_font_size_override("font_size", 22)
	_style_xp_pill()
	_refresh_xp()

	# Replace the old mode badge + bottom button with a centered pill row
	# (mode chip + Change button) like the design.
	mode_badge.visible = false
	title_lbl.visible = false
	change_mode_btn.visible = false
	_insert_mode_row()

	GameState.score_added.connect(func(_g, _a): _refresh_xp())
	for g in GAMES:
		list.add_child(_build_row(g))

func _insert_mode_row() -> void:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)

	row.add_child(_chip(GameState.mode_name(), MODE_CHIP_BG, TEXT, false))
	var change_btn := _chip("Change ↗", SURFACE, TEXT, true)
	change_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/mode_select.tscn"))
	row.add_child(change_btn)

	var v := $V as VBoxContainer
	v.add_child(row)
	# Place right after the header (index 0).
	v.move_child(row, 1)

func _chip(text: String, bg: Color, fg: Color, clickable: bool) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 13)
	b.add_theme_color_override("font_color", fg)
	b.add_theme_color_override("font_hover_color", fg)
	b.add_theme_color_override("font_pressed_color", fg)
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(99)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	if clickable:
		sb.set_border_width_all(1)
		sb.border_color = BORDER
		sb.shadow_color = Color(0, 0, 0, 0.06)
		sb.shadow_size = 3
		sb.shadow_offset = Vector2i(0, 1)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sb)
	b.add_theme_stylebox_override("pressed", sb)
	b.add_theme_stylebox_override("focus", sb)
	b.add_theme_stylebox_override("disabled", sb)
	if not clickable:
		b.disabled = true
	return b

func _style_xp_pill() -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = GOLD_TINT
	sb.set_corner_radius_all(99)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	sb.shadow_color = Color(0, 0, 0, 0.08)
	sb.shadow_size = 2
	sb.shadow_offset = Vector2i(0, 1)
	xp_pill.add_theme_stylebox_override("panel", sb)
	xp_label.add_theme_color_override("font_color", GOLD_DEEP)
	xp_label.add_theme_font_size_override("font_size", 13)

func _refresh_xp() -> void:
	xp_label.text = "★ %d XP" % GameState.total_xp

# ---------------- row card ----------------

func _build_row(g: Dictionary) -> Control:
	var color: Color = Palette.game_color(g.id)
	var dark := color.darkened(0.18)
	var light := color.lightened(0.78)

	# Outer button (full row clickable). Uses StyleBoxFlat for the white card.
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, 84)
	btn.focus_mode = Control.FOCUS_NONE
	btn.toggle_mode = false
	btn.pressed.connect(func():
		if g.id == "word_fight":
			GameState.wf_session["enemy_idx"] = 0
		_open(g.scene)
	)
	# Hide button text; we draw the row contents ourselves.
	btn.text = ""
	var sb := StyleBoxFlat.new()
	sb.bg_color = SURFACE
	sb.set_corner_radius_all(20)
	sb.set_border_width_all(1)
	sb.border_color = BORDER
	sb.shadow_color = Color(0, 0, 0, 0.10)
	sb.shadow_size = 4
	sb.shadow_offset = Vector2i(0, 2)
	var sb_hover := sb.duplicate() as StyleBoxFlat
	sb_hover.shadow_color = Color(0, 0, 0, 0.14)
	sb_hover.shadow_size = 6
	sb_hover.shadow_offset = Vector2i(0, 3)
	var sb_press := sb.duplicate() as StyleBoxFlat
	sb_press.shadow_size = 2
	sb_press.shadow_offset = Vector2i(0, 1)
	sb_press.content_margin_top = 2
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb_hover)
	btn.add_theme_stylebox_override("pressed", sb_press)
	btn.add_theme_stylebox_override("focus", sb)

	# Row content via an HBox positioned absolutely over the button.
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 14)
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 14
	row.offset_right = -14
	row.offset_top = 0
	row.offset_bottom = 0
	btn.add_child(row)

	# Icon block
	var icon := _icon_block(g.icon, color, dark)
	row.add_child(icon)

	# Text column
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	col.add_theme_constant_override("separation", 2)
	row.add_child(col)
	var name_lbl := Label.new()
	name_lbl.text = g.name
	name_lbl.add_theme_font_size_override("font_size", 16)
	name_lbl.add_theme_color_override("font_color", TEXT)
	col.add_child(name_lbl)
	var desc := Label.new()
	desc.text = g.desc
	desc.add_theme_font_size_override("font_size", 12)
	desc.add_theme_color_override("font_color", TEXT_SEC)
	col.add_child(desc)

	# Tag pill
	var tag := _tag_pill(g.tag, light, dark)
	tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(tag)

	return btn

func _icon_block(glyph: String, color: Color, dark: Color) -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(52, 55)  # +3px to allow shadow
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := PanelContainer.new()
	bg.set_anchors_preset(Control.PRESET_TOP_LEFT)
	bg.size = Vector2(52, 52)
	bg.position = Vector2(0, 3)
	# Shadow layer
	var shadow_sb := StyleBoxFlat.new()
	shadow_sb.bg_color = dark
	shadow_sb.corner_radius_top_left = 15
	shadow_sb.corner_radius_top_right = 15
	shadow_sb.corner_radius_bottom_left = 15
	shadow_sb.corner_radius_bottom_right = 15
	bg.add_theme_stylebox_override("panel", shadow_sb)
	holder.add_child(bg)
	var top := PanelContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_LEFT)
	top.size = Vector2(52, 52)
	top.position = Vector2.ZERO
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.corner_radius_top_left = 15
	sb.corner_radius_top_right = 15
	sb.corner_radius_bottom_left = 15
	sb.corner_radius_bottom_right = 15
	top.add_theme_stylebox_override("panel", sb)
	holder.add_child(top)
	var glyph_lbl := Label.new()
	glyph_lbl.text = glyph
	glyph_lbl.add_theme_font_size_override("font_size", 22)
	glyph_lbl.add_theme_color_override("font_color", Color.WHITE)
	glyph_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	glyph_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	glyph_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	top.add_child(glyph_lbl)
	return holder

func _tag_pill(text: String, light: Color, dark: Color) -> Control:
	var pill := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = light
	sb.corner_radius_top_left = 99
	sb.corner_radius_top_right = 99
	sb.corner_radius_bottom_left = 99
	sb.corner_radius_bottom_right = 99
	sb.content_margin_left = 9
	sb.content_margin_right = 9
	sb.content_margin_top = 3
	sb.content_margin_bottom = 3
	pill.add_theme_stylebox_override("panel", sb)
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_color_override("font_color", dark)
	lbl.add_theme_font_size_override("font_size", 10)
	pill.add_child(lbl)
	return pill

func _open(scene_path: String) -> void:
	if not ResourceLoader.exists(scene_path):
		push_warning("Scene missing: " + scene_path)
		return
	get_tree().change_scene_to_file(scene_path)
