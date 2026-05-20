extends Control

const Fx := preload("res://games/word_fight/fx.gd")

const GAMES := [
	{"id":"word_fight","name":"Word Fight","desc":"Turn-based battle on a 5×5 board","tag":"Battle","scene":"res://games/word_fight/intro.tscn"},
	{"id":"word_match","name":"Word Match","desc":"Drag across circle letters — 2 minutes","tag":"Drag","scene":"res://games/word_match/word_match.tscn"},
	{"id":"word_found","name":"Word Found","desc":"Tap letters into rows, wave by wave","tag":"Waves","scene":"res://games/word_found/word_found.tscn"},
	{"id":"story_tell","name":"Story Tell","desc":"Fill blanks — AI scores your grammar","tag":"AI","scene":"res://games/story_tell/story_tell.tscn"},
	{"id":"word_type","name":"Word Type","desc":"Find every form of the given word","tag":"Grammar","scene":"res://games/word_type/word_type.tscn"},
	{"id":"describe_picture","name":"Describe Picture","desc":"Complete sentence starters from an image","tag":"Visual","scene":"res://games/describe_picture/describe_picture.tscn"},
	{"id":"listen_dictate","name":"Listen & Dictate","desc":"Hear the word — type it correctly","tag":"Audio","scene":"res://games/listen_dictate/listen_dictate.tscn"},
]

const BG := Color("#faf5ed")
const TEXT := Color("#5a4840")
const TEXT_SEC := Color("#9a8a7e")
const SURFACE := Color("#ffffff")
const BORDER := Color("#e8e0d8")
const GOLD_TINT := Color("#fff1c4")
const GOLD_DEEP := Color("#b48218")
const MODE_CHIP_BG := Color("#ece4d8")

# Vibrant tokens — match the in-game palette.
const VIBRANT_BLUE := Color("#3aa8ff")
const VIBRANT_BLUE_DARK := Color("#0f5e9c")
const VIBRANT_GOLD := Color("#ffd027")
const VIBRANT_GOLD_DARK := Color("#7a4a00")
const VIBRANT_MAGENTA := Color("#ff3aa8")
const VIBRANT_MAGENTA_DARK := Color("#7a0e4a")
const DARK_CARD := Color("#1a1240")
const DARK_CARD_BORDER := Color("#3a2a78")

@onready var list: VBoxContainer = $V/Scroll/List
@onready var greet: Label = $V/Header/Greet
@onready var xp_pill: PanelContainer = $V/Header/XP
@onready var xp_label: Label = $V/Header/XP/Label
@onready var change_mode_btn: Button = $V/ChangeModeBtn
@onready var mode_badge: Control = $V/ModeBadge
@onready var title_lbl: Label = $V/Title

func _ready() -> void:
	# Animated vibrant backdrop matching the in-game palette.
	var bg := _AnimatedBoardBG.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	move_child(bg, 0)

	var who := GameState.player_name if not GameState.player_name.is_empty() else "there"
	greet.text = "Hi, %s" % who
	greet.add_theme_color_override("font_color", Color.WHITE)
	greet.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.55))
	greet.add_theme_constant_override("outline_size", 4)
	greet.add_theme_font_size_override("font_size", 24)
	_insert_avatar_chip()
	_style_xp_pill()
	_refresh_xp()

	# Replace the old mode badge + bottom button with a centered pill row
	# (mode chip + Change button) like the design.
	mode_badge.visible = false
	title_lbl.visible = false
	change_mode_btn.visible = false
	_insert_mode_row()

	GameState.score_added.connect(func(_g, _a): _refresh_xp())
	for i in GAMES.size():
		var card := _build_row(GAMES[i])
		list.add_child(card)
		# Staggered pop-in.
		card.modulate.a = 0.0
		card.scale = Vector2(0.92, 0.92)
		card.pivot_offset = Vector2(160, 42)
		var tw := card.create_tween()
		tw.tween_interval(i * 0.06)
		tw.set_parallel(true)
		tw.tween_property(card, "modulate:a", 1.0, 0.25)
		tw.tween_property(card, "scale", Vector2(1, 1), 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _insert_mode_row() -> void:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)

	row.add_child(_chip(GameState.mode_name().to_upper(), VIBRANT_BLUE, Color.WHITE, false, VIBRANT_BLUE_DARK))
	var change_btn := _chip("CHANGE", VIBRANT_MAGENTA, Color.WHITE, true, VIBRANT_MAGENTA_DARK)
	change_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/mode_select.tscn"))
	row.add_child(change_btn)

	var v := $V as VBoxContainer
	v.add_child(row)
	# Place right after the header (index 0).
	v.move_child(row, 1)

func _insert_avatar_chip() -> void:
	# Round vibrant gold badge with magenta ring for the player's SVG avatar.
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(48, 48)
	holder.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var bg_panel := Panel.new()
	bg_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#ffe9d4")
	sb.set_corner_radius_all(24)
	sb.set_border_width_all(2)
	sb.border_color = VIBRANT_MAGENTA
	sb.shadow_color = Color(VIBRANT_MAGENTA.r, VIBRANT_MAGENTA.g, VIBRANT_MAGENTA.b, 0.5)
	sb.shadow_size = 6
	sb.shadow_offset = Vector2i(0, 2)
	bg_panel.add_theme_stylebox_override("panel", sb)
	holder.add_child(bg_panel)
	var icon := TextureRect.new()
	var path := "res://assets/avatars/%s.svg" % GameState.player_avatar
	if ResourceLoader.exists(path):
		icon.texture = load(path)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.offset_left = 4
	icon.offset_top = 4
	icon.offset_right = -4
	icon.offset_bottom = -4
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(icon)
	var hdr := $V/Header as HBoxContainer
	hdr.add_child(holder)
	hdr.move_child(holder, 0)

func _chip(text: String, bg: Color, fg: Color, clickable: bool, border: Color = Color(0, 0, 0, 0)) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 14)
	b.add_theme_color_override("font_color", fg)
	b.add_theme_color_override("font_hover_color", fg)
	b.add_theme_color_override("font_pressed_color", fg)
	b.add_theme_color_override("font_disabled_color", fg)
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(99)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 7
	sb.content_margin_bottom = 7
	if border.a > 0:
		sb.set_border_width_all(2)
		sb.border_color = border
	sb.shadow_color = Color(0, 0, 0, 0.22)
	sb.shadow_size = 4
	sb.shadow_offset = Vector2i(0, 2)
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
	sb.bg_color = VIBRANT_GOLD
	sb.set_corner_radius_all(99)
	sb.set_border_width_all(2)
	sb.border_color = Color("#dba830")
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	sb.shadow_color = Color(0, 0, 0, 0.25)
	sb.shadow_size = 4
	sb.shadow_offset = Vector2i(0, 2)
	xp_pill.add_theme_stylebox_override("panel", sb)
	xp_label.add_theme_color_override("font_color", VIBRANT_GOLD_DARK)
	xp_label.add_theme_font_size_override("font_size", 15)
	# Replace the original Label child with an HBox: star icon + label.
	var parent := xp_label.get_parent() as Control
	var idx := xp_label.get_index()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	parent.add_child(row)
	parent.move_child(row, idx)
	var icon_path := "res://assets/icons/star.svg"
	if ResourceLoader.exists(icon_path):
		var icon := TextureRect.new()
		icon.texture = load(icon_path)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.custom_minimum_size = Vector2(16, 16)
		icon.modulate = VIBRANT_GOLD_DARK
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(icon)
	xp_label.reparent(row, false)

func _refresh_xp() -> void:
	xp_label.text = "%d XP" % GameState.total_xp

# ---------------- row card ----------------

func _build_row(g: Dictionary) -> Control:
	var color: Color = Palette.game_color(g.id)
	var dark := color.darkened(0.28)

	# Outer button — translucent dark navy card so the animated bg shows through.
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, 92)
	btn.focus_mode = Control.FOCUS_NONE
	btn.toggle_mode = false
	btn.pressed.connect(func():
		if g.id == "word_fight":
			GameState.wf_session["enemy_idx"] = 0
		_open(g.scene)
	)
	btn.text = ""
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(DARK_CARD.r, DARK_CARD.g, DARK_CARD.b, 0.82)
	sb.set_corner_radius_all(22)
	sb.set_border_width_all(2)
	sb.border_color = DARK_CARD_BORDER
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 6
	sb.shadow_offset = Vector2i(0, 3)
	var sb_hover := sb.duplicate() as StyleBoxFlat
	sb_hover.border_color = color
	sb_hover.shadow_color = Color(color.r, color.g, color.b, 0.5)
	sb_hover.shadow_size = 12
	var sb_press := sb.duplicate() as StyleBoxFlat
	sb_press.shadow_size = 2
	sb_press.shadow_offset = Vector2i(0, 1)
	sb_press.content_margin_top = 2
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb_hover)
	btn.add_theme_stylebox_override("pressed", sb_press)
	btn.add_theme_stylebox_override("focus", sb)

	# Row content.
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 14)
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 14
	row.offset_right = -14
	row.offset_top = 0
	row.offset_bottom = 0
	btn.add_child(row)

	# Vibrant icon block — gradient fill, glow ring.
	var icon := _icon_block(g.id, color, dark)
	row.add_child(icon)

	# Text column.
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	col.add_theme_constant_override("separation", 3)
	row.add_child(col)
	var name_lbl := Label.new()
	name_lbl.text = g.name
	name_lbl.add_theme_font_size_override("font_size", 18)
	name_lbl.add_theme_color_override("font_color", Color.WHITE)
	name_lbl.clip_text = true                      # never overflow the column
	col.add_child(name_lbl)
	var desc := Label.new()
	desc.text = g.desc
	desc.add_theme_font_size_override("font_size", 13)
	desc.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART  # wrap so it can't push the tag pill off-row
	col.add_child(desc)

	# Tag pill — vibrant per-game color. Shrink so the column can't push it off.
	var tag := _tag_pill(g.tag, color, dark)
	tag.size_flags_horizontal = Control.SIZE_SHRINK_END
	tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(tag)

	return btn

func _icon_block(game_id: String, color: Color, dark: Color) -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(60, 64)  # +4px to allow shadow
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Shadow layer underneath.
	var bg := PanelContainer.new()
	bg.set_anchors_preset(Control.PRESET_TOP_LEFT)
	bg.size = Vector2(60, 60)
	bg.position = Vector2(0, 4)
	var shadow_sb := StyleBoxFlat.new()
	shadow_sb.bg_color = dark
	shadow_sb.set_corner_radius_all(17)
	bg.add_theme_stylebox_override("panel", shadow_sb)
	holder.add_child(bg)
	# Colored top layer with subtle outline glow.
	var top := PanelContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_LEFT)
	top.size = Vector2(60, 60)
	top.position = Vector2.ZERO
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(17)
	sb.set_border_width_all(2)
	sb.border_color = Color(1, 1, 1, 0.35)
	sb.shadow_color = Color(color.r, color.g, color.b, 0.5)
	sb.shadow_size = 8
	top.add_theme_stylebox_override("panel", sb)
	holder.add_child(top)
	# White glyph icon (SVG).
	var tex_path := "res://assets/games/%s.svg" % game_id
	if ResourceLoader.exists(tex_path):
		var icon := TextureRect.new()
		icon.texture = load(tex_path)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.set_anchors_preset(Control.PRESET_FULL_RECT)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		top.add_child(icon)
	return holder

func _tag_pill(text: String, accent: Color, accent_dark: Color) -> Control:
	var pill := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = accent
	sb.set_corner_radius_all(99)
	sb.set_border_width_all(2)
	sb.border_color = accent_dark
	sb.shadow_color = Color(0, 0, 0, 0.25)
	sb.shadow_size = 3
	sb.shadow_offset = Vector2i(0, 1)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	pill.add_theme_stylebox_override("panel", sb)
	var lbl := Label.new()
	lbl.text = text.to_upper()
	lbl.add_theme_color_override("font_color", Color.WHITE)
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.45))
	lbl.add_theme_constant_override("outline_size", 3)
	lbl.add_theme_font_size_override("font_size", 11)
	pill.add_child(lbl)
	return pill

func _open(scene_path: String) -> void:
	if not ResourceLoader.exists(scene_path):
		push_warning("Scene missing: " + scene_path)
		return
	get_tree().change_scene_to_file(scene_path)

# ---------------- animated vibrant backdrop ----------------
class _AnimatedBoardBG extends Control:
	var _t: float = 0.0
	func _ready() -> void:
		set_process(true)
		clip_contents = true
	func _process(delta: float) -> void:
		_t += delta * 0.25
		queue_redraw()
	func _draw() -> void:
		var palette := [
			Color("#3aa8ff"), Color("#7a55ff"), Color("#ff3aa8"),
			Color("#ff7a1f"), Color("#ffd027"), Color("#3ad6a8"),
		]
		# Dark base for contrast against the white text & vibrant cards.
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.04, 0.12, 1))
		var bands := 22
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
			col.a = 0.45
			draw_rect(Rect2(Vector2(0, h * t0), Vector2(w, h * (t1 - t0))), col)
		# Subtle vignette so the corners read darker.
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.01, 0.08, 0.0))
