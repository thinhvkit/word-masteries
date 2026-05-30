extends Control

const Fx := preload("res://games/word_fight/fx.gd")

const DRAG_THRESHOLD := 14.0

const GAMES := [
	{"id":"word_fight","name":"Word Fight","desc":"Battle through worlds on a 4x4 word board","tag":"Battle","scene":"res://games/word_fight/world_map.tscn"},
	{"id":"word_match","name":"Word Match","desc":"Two-minute drag chase with combos and targets","tag":"Speed","scene":"res://games/word_match/word_match.tscn"},
	{"id":"word_found","name":"Word Found","desc":"Build target words from a shared letter bank","tag":"Puzzle","scene":"res://games/word_found/word_found.tscn"},
	{"id":"story_tell","name":"Story Tell","desc":"Fill blanks — AI scores your grammar","tag":"AI","scene":"res://games/story_tell/story_tell.tscn"},
	{"id":"word_type","name":"Word Type","desc":"Find every form of the given word","tag":"Grammar","scene":"res://games/word_type/word_type.tscn"},
	{"id":"describe_picture","name":"Describe Picture","desc":"Complete sentence starters from an image","tag":"Visual","scene":"res://games/describe_picture/describe_picture.tscn"},
	{"id":"listen_dictate","name":"Listen & Dictate","desc":"Hear the word — type it correctly","tag":"Audio","scene":"res://games/listen_dictate/listen_dictate.tscn"},
]

# Bright arcade palette.
const BG_TOP := Color("#f5fbff")
const BG_BOT := Color("#fff4f8")
const CARD_BG := Color("#ffffff")
const CARD_BORDER := Color("#e3ecf7")
const CARD_SHADOW := Color(0.16, 0.22, 0.35, 0.14)
const TEXT_WARM := Color("#243044")
const TEXT_SEC := Color("#6b7890")
const TEXT_FAINT := Color("#8d99ad")
const ACCENT_GOLD := Color("#f2aa00")
const ACCENT_GOLD_LIGHT := Color("#fff3c7")
const ACCENT_GREEN := Color("#21b86b")
const ACCENT_ROSE := Color("#ff4f9a")
const ACCENT_SKY := Color("#28a8ff")

@onready var list: VBoxContainer = $V/Scroll/List
@onready var _scroll: ScrollContainer = $V/Scroll
@onready var greet: Label = $V/Header/Greet
@onready var xp_pill: PanelContainer = $V/Header/XP
@onready var xp_label: Label = $V/Header/XP/Label
@onready var title_lbl: Label = $V/Title

func _ready() -> void:
	var bg_panel := Panel.new()
	bg_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg_sb := StyleBoxFlat.new()
	bg_sb.bg_color = BG_TOP
	bg_panel.add_theme_stylebox_override("panel", bg_sb)
	add_child(bg_panel)
	move_child(bg_panel, 0)
	var tint := Panel.new()
	tint.set_anchors_preset(Control.PRESET_FULL_RECT)
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tint_sb := StyleBoxFlat.new()
	tint_sb.bg_color = Color(BG_BOT.r, BG_BOT.g, BG_BOT.b, 0.0)
	tint.add_theme_stylebox_override("panel", tint_sb)
	add_child(tint)
	move_child(tint, 1)

	var sc_bar: VScrollBar = $V/Scroll.get_v_scroll_bar()
	for s_name in ["scroll", "scroll_highlight", "scroll_pressed", "grabber", "grabber_highlight", "grabber_pressed"]:
		sc_bar.add_theme_stylebox_override(s_name, StyleBoxEmpty.new())

	var who := GameState.player_name if not GameState.player_name.is_empty() else "there"
	greet.text = "Hi, %s" % who
	greet.add_theme_color_override("font_color", TEXT_WARM)
	greet.add_theme_font_size_override("font_size", 24)
	_insert_avatar_chip()
	_insert_sound_toggle()
	_style_xp_pill()
	_refresh_xp()

	title_lbl.text = "Choose a Game"
	title_lbl.visible = true
	title_lbl.add_theme_font_size_override("font_size", 22)
	title_lbl.add_theme_color_override("font_color", TEXT_WARM)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	list.add_theme_constant_override("separation", 12)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	GameState.score_added.connect(func(_g, _a): _refresh_xp())
	var visible_games := GAMES.filter(func(g): return g.id in ["word_fight", "word_match", "word_found"])
	for i in visible_games.size():
		var card := _build_row(visible_games[i])
		list.add_child(card)
		card.modulate.a = 0.0
		card.scale = Vector2(0.92, 0.92)
		card.pivot_offset = Vector2(160, 46)
		var tw := card.create_tween()
		tw.tween_interval(i * 0.06)
		tw.set_parallel(true)
		tw.tween_property(card, "modulate:a", 1.0, 0.25)
		tw.tween_property(card, "scale", Vector2(1, 1), 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenDrag:
		_scroll.scroll_vertical -= int(event.relative.y)
		get_viewport().set_input_as_handled()

func _insert_avatar_chip() -> void:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(48, 48)
	holder.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var bg_p := Panel.new()
	bg_p.set_anchors_preset(Control.PRESET_FULL_RECT)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color.WHITE
	sb.set_corner_radius_all(24)
	sb.set_border_width_all(2)
	sb.border_color = ACCENT_SKY
	sb.shadow_color = Color(ACCENT_SKY.r, ACCENT_SKY.g, ACCENT_SKY.b, 0.18)
	sb.shadow_size = 4
	sb.shadow_offset = Vector2i(0, 2)
	bg_p.add_theme_stylebox_override("panel", sb)
	holder.add_child(bg_p)
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

func _insert_sound_toggle() -> void:
	var btn := Button.new()
	btn.text = "ON" if GameState.sound_on else "OFF"
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(48, 48)
	btn.add_theme_font_size_override("font_size", 13)
	var on := GameState.sound_on
	var fg := Color.WHITE if on else TEXT_SEC
	btn.add_theme_color_override("font_color", fg)
	btn.add_theme_color_override("font_hover_color", fg)
	btn.add_theme_color_override("font_pressed_color", fg)
	var sb := StyleBoxFlat.new()
	sb.bg_color = ACCENT_GREEN if on else Color("#e8edf5")
	sb.set_corner_radius_all(99)
	sb.set_border_width_all(2)
	sb.border_color = ACCENT_GREEN.darkened(0.12) if on else CARD_BORDER
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	sb.shadow_color = CARD_SHADOW
	sb.shadow_size = 3
	sb.shadow_offset = Vector2i(0, 1)
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb)
	btn.add_theme_stylebox_override("pressed", sb)
	btn.add_theme_stylebox_override("focus", sb)
	btn.pressed.connect(func():
		GameState.toggle_sound()
		var is_on := GameState.sound_on
		btn.text = "ON" if is_on else "OFF"
		var new_fg := Color.WHITE if is_on else TEXT_SEC
		btn.add_theme_color_override("font_color", new_fg)
		btn.add_theme_color_override("font_hover_color", new_fg)
		btn.add_theme_color_override("font_pressed_color", new_fg)
		var new_sb := sb.duplicate() as StyleBoxFlat
		new_sb.bg_color = ACCENT_GREEN if is_on else Color("#e8edf5")
		new_sb.border_color = ACCENT_GREEN.darkened(0.12) if is_on else CARD_BORDER
		btn.add_theme_stylebox_override("normal", new_sb)
		btn.add_theme_stylebox_override("hover", new_sb)
		btn.add_theme_stylebox_override("pressed", new_sb)
		btn.add_theme_stylebox_override("focus", new_sb))
	var hdr := $V/Header as HBoxContainer
	hdr.add_child(btn)

func _chip(text: String, bg: Color, fg: Color, clickable: bool) -> Button:
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
	sb.shadow_color = Color(bg.r * 0.5, bg.g * 0.5, bg.b * 0.5, 0.2)
	sb.shadow_size = 3
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
	sb.bg_color = ACCENT_GOLD_LIGHT
	sb.set_corner_radius_all(99)
	sb.set_border_width_all(2)
	sb.border_color = ACCENT_GOLD
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	sb.shadow_color = Color(ACCENT_GOLD.r, ACCENT_GOLD.g, ACCENT_GOLD.b, 0.15)
	sb.shadow_size = 4
	sb.shadow_offset = Vector2i(0, 2)
	xp_pill.add_theme_stylebox_override("panel", sb)
	xp_label.add_theme_color_override("font_color", ACCENT_GOLD.darkened(0.15))
	xp_label.add_theme_font_size_override("font_size", 15)
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
		icon.modulate = ACCENT_GOLD
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(icon)
	xp_label.reparent(row, false)

func _refresh_xp() -> void:
	xp_label.text = "%d XP" % GameState.total_xp

# ---------------- row card ----------------

func _build_row(g: Dictionary) -> Control:
	var color: Color = Palette.game_color(g.id)
	var color_dark := Palette.game_color_dark(g.id)

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, 116)
	btn.focus_mode = Control.FOCUS_NONE
	btn.toggle_mode = false
	btn.mouse_filter = Control.MOUSE_FILTER_PASS
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.text = ""
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(color.r, color.g, color.b, 0.14)
	sb.set_corner_radius_all(16)
	sb.set_border_width_all(2)
	sb.border_color = Color(color.r, color.g, color.b, 0.34)
	sb.shadow_color = CARD_SHADOW
	sb.shadow_size = 8
	sb.shadow_offset = Vector2i(0, 3)
	sb.content_margin_left = 0
	sb.content_margin_right = 0
	var sb_hover := sb.duplicate() as StyleBoxFlat
	sb_hover.bg_color = Color(color.r, color.g, color.b, 0.20)
	sb_hover.border_color = Color(color.r, color.g, color.b, 0.78)
	sb_hover.shadow_color = Color(color.r, color.g, color.b, 0.22)
	sb_hover.shadow_size = 10
	var sb_press := sb.duplicate() as StyleBoxFlat
	sb_press.bg_color = Color(color.r, color.g, color.b, 0.24)
	sb_press.shadow_size = 3
	sb_press.shadow_offset = Vector2i(0, 1)
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb_hover)
	btn.add_theme_stylebox_override("pressed", sb_press)
	btn.add_theme_stylebox_override("focus", sb)

	var accent := ColorRect.new()
	accent.color = color
	accent.anchor_top = 0.0
	accent.anchor_bottom = 1.0
	accent.offset_left = 0
	accent.offset_top = 0
	accent.offset_right = 8
	accent.offset_bottom = 0
	accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(accent)

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 14)
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 20
	row.offset_right = -14
	row.offset_top = 12
	row.offset_bottom = -12
	btn.add_child(row)

	var icon := _icon_block(g.id, color)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon)

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	col.add_theme_constant_override("separation", 6)
	row.add_child(col)
	var name_lbl := Label.new()
	name_lbl.text = g.name
	name_lbl.add_theme_font_size_override("font_size", 21)
	name_lbl.add_theme_color_override("font_color", TEXT_WARM)
	name_lbl.clip_text = true
	col.add_child(name_lbl)
	var desc := Label.new()
	desc.text = g.desc
	desc.add_theme_font_size_override("font_size", 14)
	desc.add_theme_color_override("font_color", TEXT_SEC)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(0, 36)
	col.add_child(desc)

	var progress := Label.new()
	progress.text = _game_progress_text(g.id)
	progress.add_theme_font_size_override("font_size", 12)
	progress.add_theme_color_override("font_color", TEXT_FAINT)
	progress.clip_text = true
	col.add_child(progress)

	var action_col := VBoxContainer.new()
	action_col.custom_minimum_size = Vector2(76, 0)
	action_col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	action_col.alignment = BoxContainer.ALIGNMENT_CENTER
	action_col.add_theme_constant_override("separation", 8)
	row.add_child(action_col)

	var tag := _tag_pill(g.tag, color)
	tag.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	action_col.add_child(tag)
	action_col.add_child(_play_pill(color, color_dark))

	var touch_start := Vector2.ZERO
	var touch_active := false
	btn.gui_input.connect(func(event: InputEvent):
		if event is InputEventScreenTouch:
			if event.pressed:
				touch_start = event.position
				touch_active = true
			else:
				if touch_active and touch_start.distance_to(event.position) < DRAG_THRESHOLD:
					if g.id == "word_fight":
						GameState.wf_session["enemy_idx"] = 0
					_open(g.scene)
				touch_active = false
		elif event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				if g.id == "word_fight":
					GameState.wf_session["enemy_idx"] = 0
				_open(g.scene))

	return btn

func _game_progress_text(game_id: String) -> String:
	var xp := int(GameState.per_game_xp.get(game_id, 0))
	if xp <= 0:
		return "NEW"
	return "%d XP earned" % xp

func _icon_block(game_id: String, color: Color) -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(64, 72)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := PanelContainer.new()
	bg.set_anchors_preset(Control.PRESET_TOP_LEFT)
	bg.size = Vector2(64, 64)
	bg.position = Vector2(0, 5)
	var shadow_sb := StyleBoxFlat.new()
	shadow_sb.bg_color = color.darkened(0.15)
	shadow_sb.set_corner_radius_all(18)
	bg.add_theme_stylebox_override("panel", shadow_sb)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(bg)
	var top := PanelContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_LEFT)
	top.size = Vector2(64, 64)
	top.position = Vector2.ZERO
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(18)
	sb.set_border_width_all(2)
	sb.border_color = Color(1, 1, 1, 0.3)
	top.add_theme_stylebox_override("panel", sb)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(top)
	var tex_path := "res://assets/games/%s.svg" % game_id
	if ResourceLoader.exists(tex_path):
		var icon := TextureRect.new()
		icon.texture = load(tex_path)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.set_anchors_preset(Control.PRESET_FULL_RECT)
		icon.offset_left = 8
		icon.offset_top = 8
		icon.offset_right = -8
		icon.offset_bottom = -8
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		top.add_child(icon)
	return holder

func _tag_pill(text: String, accent: Color) -> Control:
	var pill := PanelContainer.new()
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(accent.r, accent.g, accent.b, 0.18)
	sb.set_corner_radius_all(99)
	sb.set_border_width_all(1)
	sb.border_color = Color(accent.r, accent.g, accent.b, 0.36)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	pill.add_theme_stylebox_override("panel", sb)
	var lbl := Label.new()
	lbl.text = text.to_upper()
	lbl.add_theme_color_override("font_color", accent.darkened(0.22))
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pill.add_child(lbl)
	return pill

func _play_pill(accent: Color, accent_dark: Color) -> Control:
	var pill := PanelContainer.new()
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill.custom_minimum_size = Vector2(64, 34)
	var sb := StyleBoxFlat.new()
	sb.bg_color = accent
	sb.set_corner_radius_all(99)
	sb.set_border_width_all(2)
	sb.border_color = accent_dark
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	sb.shadow_color = Color(accent.r, accent.g, accent.b, 0.24)
	sb.shadow_size = 4
	sb.shadow_offset = Vector2i(0, 2)
	pill.add_theme_stylebox_override("panel", sb)
	var lbl := Label.new()
	lbl.text = "PLAY"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	pill.add_child(lbl)
	return pill

func _open(scene_path: String) -> void:
	if not ResourceLoader.exists(scene_path):
		push_warning("Scene missing: " + scene_path)
		return
	get_tree().change_scene_to_file(scene_path)
