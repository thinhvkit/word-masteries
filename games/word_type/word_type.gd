extends Control
## Word Type — show a base word, type up to 4 forms (derivations, inflections),
## score 20 XP per recognized form. Vibrant FX redesign.

const Chrome := preload("res://scripts/screen_chrome.gd")
const Fx := preload("res://games/word_fight/fx.gd")

# Legacy cozy tokens (kept for the back-to-menu pill, etc).
const GOLD := Color("#ffc844")
const GOLD_LIGHT := Color("#fff1c4")
const GOLD_DARK := Color("#b48218")
const PINK_DARK := Color("#c95e74")
const SAGE_LIGHT := Color("#dff1e0")
const SAGE_DARK := Color("#4a7d4a")
const TERRA := Color("#c95e3e")
const TERRA_LIGHT := Color("#fbeaea")
const PURPLE := Color("#7a4caf")

# Vibrant tokens matching the rest of the app.
const VIBRANT_BLUE := Color("#3aa8ff")
const VIBRANT_BLUE_DARK := Color("#0f5e9c")
const VIBRANT_GOLD := Color("#ffd027")
const VIBRANT_GOLD_DARK := Color("#7a4a00")
const VIBRANT_MAGENTA := Color("#ff3aa8")
const VIBRANT_MAGENTA_DARK := Color("#7a0e4a")
const VIBRANT_GREEN := Color("#3ad6a8")
const VIBRANT_GREEN_DARK := Color("#0a6650")
const DARK_CARD := Color("#1a1240")
const DARK_CARD_BORDER := Color("#3a2a78")

const DATA := [
	{
		"word": "Careful",
		"pos": "adjective",
		"forms": ["carefully", "careless", "carelessly", "carefulness", "carelessness", "care"],
		"types": ["adverb", "adjective", "adverb", "noun", "noun", "noun/verb"],
		"examples": [
			'"She carefully opened the box."',
			'"That was a careless mistake."',
			'"He carelessly dropped it."',
			'"Her carefulness saved the day."',
			'"Carelessness leads to errors."',
			'"I care about the result."',
		],
	},
	{
		"word": "Create",
		"pos": "verb",
		"forms": ["creation", "creative", "creatively", "creativity", "creator", "created"],
		"types": ["noun", "adjective", "adverb", "noun", "noun", "past tense"],
		"examples": [
			'"The creation was beautiful."',
			'"She has a creative mind."',
			'"He creatively solved it."',
			'"Creativity takes courage."',
			'"The creator was inspired."',
			'"She created a masterpiece."',
		],
	},
]

const SLOTS := 4

var _data: Dictionary
var _inputs: Array[LineEdit] = []
var _body: VBoxContainer
var _submit_btn: Button
var _submit_glow: Panel

func _ready() -> void:
	_data = DATA[randi() % DATA.size()]
	Chrome.bg_layer(self)
	var back := Chrome.header(self, "Word Type", "word_type", VIBRANT_GOLD, VIBRANT_GOLD_DARK)
	back.pressed.connect(_back)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_top = Chrome.HEADER_H
	scroll.offset_left = 16
	scroll.offset_right = -16
	scroll.offset_bottom = -16
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 14)
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_body)
	_build_form()

func _build_form() -> void:
	_clear_body()
	_inputs.clear()

	# Hero word card — animated vibrant backdrop with dark overlay panel.
	var hero := Control.new()
	hero.custom_minimum_size = Vector2(0, 160)
	hero.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var hero_bg := Fx.AnimatedBoardBG.new()
	hero_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	hero_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero.add_child(hero_bg)
	# Dark inner card layered above the bg for legibility.
	var inner := PanelContainer.new()
	inner.set_anchors_preset(Control.PRESET_FULL_RECT)
	inner.offset_left = 10
	inner.offset_right = -10
	inner.offset_top = 10
	inner.offset_bottom = -10
	var inner_sb := StyleBoxFlat.new()
	inner_sb.bg_color = Color(DARK_CARD.r, DARK_CARD.g, DARK_CARD.b, 0.78)
	inner_sb.set_corner_radius_all(14)
	inner_sb.set_border_width_all(2)
	inner_sb.border_color = DARK_CARD_BORDER
	inner.add_theme_stylebox_override("panel", inner_sb)
	hero.add_child(inner)
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 6)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inner.add_child(col)
	var prompt := Label.new()
	prompt.text = "TRANSFORM THIS WORD"
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 13)
	prompt.add_theme_color_override("font_color", VIBRANT_GOLD)
	col.add_child(prompt)
	var word := Label.new()
	word.text = _data.word
	word.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	word.add_theme_font_size_override("font_size", 44)
	word.add_theme_color_override("font_color", Color.WHITE)
	word.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.55))
	word.add_theme_constant_override("outline_size", 6)
	col.add_child(word)
	var pos_holder := CenterContainer.new()
	pos_holder.add_child(_vibrant_chip(_data.pos.to_upper(), VIBRANT_GOLD, VIBRANT_GOLD_DARK, Color("#dba830")))
	col.add_child(pos_holder)
	_body.add_child(hero)

	# Hint — bold magenta.
	var hint := Label.new()
	hint.text = "This word has %d forms — fill in what you know!" % _data.forms.size()
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 15)
	hint.add_theme_color_override("font_color", VIBRANT_MAGENTA_DARK)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.add_child(hint)

	# Input slots — chunky, with magenta focus glow.
	for i in SLOTS:
		_body.add_child(_build_input_slot(i))

	var note := Label.new()
	note.text = "You don't need to fill all boxes — partial credit given!"
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.add_theme_font_size_override("font_size", 12)
	note.add_theme_color_override("font_color", Chrome.TEXT_SEC)
	_body.add_child(note)

	# Submit — vibrant magenta with glow ring activated when any input has text.
	var submit_wrap := Control.new()
	submit_wrap.custom_minimum_size = Vector2(0, 56)
	submit_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_submit_glow = Panel.new()
	_submit_glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	_submit_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var glow_sb := StyleBoxFlat.new()
	glow_sb.bg_color = Color(1, 0.5, 0.7, 0.0)
	glow_sb.set_corner_radius_all(32)
	glow_sb.shadow_color = Color(1.0, 0.4, 0.7, 0.0)
	glow_sb.shadow_size = 18
	_submit_glow.add_theme_stylebox_override("panel", glow_sb)
	submit_wrap.add_child(_submit_glow)
	_submit_btn = Chrome.pill_button("Submit", VIBRANT_MAGENTA, Color.WHITE)
	_submit_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	_submit_btn.disabled = true
	_submit_btn.pressed.connect(_submit)
	submit_wrap.add_child(_submit_btn)
	_body.add_child(submit_wrap)
	for input in _inputs:
		input.text_changed.connect(func(_t): _refresh_submit_state())

func _build_input_slot(idx: int) -> Control:
	# Wrapper is a plain Control so the static glow Panel + interactive PanelContainer can stack.
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(0, 56)
	holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	holder.mouse_filter = Control.MOUSE_FILTER_PASS

	# Static glow ring — its shadow is tweened on focus, but its OWN node never
	# gets restyled-on-focus (avoids web LineEdit defocus bug from swapping styleboxes).
	var glow := Panel.new()
	glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var glow_sb := StyleBoxFlat.new()
	glow_sb.bg_color = Color(0, 0, 0, 0)
	glow_sb.set_corner_radius_all(18)
	glow_sb.shadow_color = Color(1.0, 0.4, 0.7, 0.0)
	glow_sb.shadow_size = 0
	glow.add_theme_stylebox_override("panel", glow_sb)
	holder.add_child(glow)

	# Card panel.
	var card := PanelContainer.new()
	card.set_anchors_preset(Control.PRESET_FULL_RECT)
	# PASS so clicks on padding bubble to children (LineEdit) on web.
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	var sb := StyleBoxFlat.new()
	sb.bg_color = Chrome.SURFACE
	sb.set_corner_radius_all(16)
	sb.set_border_width_all(2)
	sb.border_color = Color("#e0d8c8")
	sb.shadow_color = Color(0, 0, 0, 0.12)
	sb.shadow_size = 4
	sb.shadow_offset = Vector2i(0, 2)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	card.add_theme_stylebox_override("panel", sb)
	holder.add_child(card)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.add_child(row)

	# Number badge with tier color.
	var tier_colors := [VIBRANT_GOLD, VIBRANT_BLUE, VIBRANT_MAGENTA, VIBRANT_GREEN]
	var badge := Panel.new()
	badge.custom_minimum_size = Vector2(32, 32)
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bsb := StyleBoxFlat.new()
	bsb.bg_color = tier_colors[idx % tier_colors.size()]
	bsb.set_corner_radius_all(16)
	badge.add_theme_stylebox_override("panel", bsb)
	var num := Label.new()
	num.text = str(idx + 1)
	num.add_theme_font_size_override("font_size", 16)
	num.add_theme_color_override("font_color", Color.WHITE)
	num.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.45))
	num.add_theme_constant_override("outline_size", 3)
	num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	num.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	num.set_anchors_preset(Control.PRESET_FULL_RECT)
	badge.add_child(num)
	row.add_child(badge)

	# Input — fills both axes so clicks anywhere in the row land on it.
	var le := LineEdit.new()
	le.placeholder_text = "Type a word form…"
	le.add_theme_font_size_override("font_size", 18)
	le.add_theme_color_override("font_color", Chrome.TEXT)
	le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	le.size_flags_vertical = Control.SIZE_EXPAND_FILL
	le.focus_mode = Control.FOCUS_ALL
	le.mouse_filter = Control.MOUSE_FILTER_STOP
	var empty := StyleBoxEmpty.new()
	le.add_theme_stylebox_override("normal", empty)
	le.add_theme_stylebox_override("focus", empty)
	le.add_theme_stylebox_override("read_only", empty)
	row.add_child(le)
	_inputs.append(le)

	# Focus visuals via the GLOW panel only (no PanelContainer restyle = no defocus on web).
	le.focus_entered.connect(func(): _set_glow(glow, true))
	le.focus_exited.connect(func(): _set_glow(glow, false))

	# If the user clicks anywhere on the card padding (not on the LineEdit itself),
	# focus the LineEdit explicitly. This handles edge-case clicks on the badge column.
	card.gui_input.connect(func(event: InputEvent):
		if (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed):
			le.grab_focus())
	return holder

func _set_glow(glow: Panel, on: bool) -> void:
	var sb := glow.get_theme_stylebox("panel") as StyleBoxFlat
	if sb == null: return
	var fresh: StyleBoxFlat = sb.duplicate()
	fresh.shadow_color = Color(1.0, 0.4, 0.7, 0.55 if on else 0.0)
	fresh.shadow_size = 14 if on else 0
	glow.add_theme_stylebox_override("panel", fresh)

func _refresh_submit_state() -> void:
	var any_filled := not _all_blank()
	_submit_btn.disabled = not any_filled
	if _submit_glow != null:
		var sb := _submit_glow.get_theme_stylebox("panel") as StyleBoxFlat
		if sb != null:
			var fresh: StyleBoxFlat = sb.duplicate()
			fresh.shadow_color = Color(1.0, 0.4, 0.7, 0.55 if any_filled else 0.0)
			fresh.shadow_size = 22 if any_filled else 0
			_submit_glow.add_theme_stylebox_override("panel", fresh)

func _all_blank() -> bool:
	for input in _inputs:
		if not input.text.strip_edges().is_empty():
			return false
	return true

func _submit() -> void:
	var typed_set := {}
	for input in _inputs:
		var t := input.text.strip_edges().to_lower()
		if not t.is_empty():
			typed_set[t] = true
	var correct := 0
	for f: String in _data.forms:
		if typed_set.has(f):
			correct += 1
	var earned: int = correct * 20
	GameState.add_xp("word_type", earned)
	_build_results(typed_set, correct, earned)

func _build_results(typed_set: Dictionary, correct: int, earned: int) -> void:
	_clear_body()

	# Hero result card with animated bg + score popup + confetti.
	var hero := Control.new()
	hero.custom_minimum_size = Vector2(0, 160)
	hero.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var hero_bg := Fx.AnimatedBoardBG.new()
	hero_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	hero_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero.add_child(hero_bg)
	var inner := PanelContainer.new()
	inner.set_anchors_preset(Control.PRESET_FULL_RECT)
	inner.offset_left = 10; inner.offset_right = -10; inner.offset_top = 10; inner.offset_bottom = -10
	var inner_sb := StyleBoxFlat.new()
	inner_sb.bg_color = Color(DARK_CARD.r, DARK_CARD.g, DARK_CARD.b, 0.82)
	inner_sb.set_corner_radius_all(14)
	inner_sb.set_border_width_all(2)
	inner_sb.border_color = DARK_CARD_BORDER
	inner.add_theme_stylebox_override("panel", inner_sb)
	hero.add_child(inner)
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 4)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inner.add_child(col)
	var head := Label.new()
	head.text = "RESULTS"
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_theme_font_size_override("font_size", 14)
	head.add_theme_color_override("font_color", VIBRANT_GOLD)
	col.add_child(head)
	var sub := Label.new()
	sub.text = "%s — %s" % [_data.word, _data.pos]
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 16)
	sub.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
	col.add_child(sub)
	var stat := Label.new()
	stat.text = "%d / %d forms  |  +%d XP" % [correct, _data.forms.size(), earned]
	stat.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stat.add_theme_font_size_override("font_size", 22)
	stat.add_theme_color_override("font_color", VIBRANT_GOLD)
	stat.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.5))
	stat.add_theme_constant_override("outline_size", 4)
	col.add_child(stat)
	_body.add_child(hero)

	# All Word Forms card (dark vibrant).
	var card := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = DARK_CARD
	sb.set_corner_radius_all(18)
	sb.set_border_width_all(2)
	sb.border_color = DARK_CARD_BORDER
	sb.shadow_color = Color(0, 0, 0, 0.25)
	sb.shadow_size = 6
	sb.shadow_offset = Vector2i(0, 3)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 14
	sb.content_margin_bottom = 14
	card.add_theme_stylebox_override("panel", sb)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	card.add_child(box)
	var card_head := Label.new()
	card_head.text = "All Word Forms"
	card_head.add_theme_font_size_override("font_size", 14)
	card_head.add_theme_color_override("font_color", VIBRANT_GOLD)
	box.add_child(card_head)
	for i in _data.forms.size():
		box.add_child(_form_row(_data.forms[i], _data.types[i], _data.examples[i], typed_set.has(_data.forms[i])))
	_body.add_child(card)

	var next := Chrome.pill_button("Next Word", VIBRANT_MAGENTA, Color.WHITE, "res://assets/icons/arrow_right.svg")
	next.pressed.connect(func():
		_data = DATA[randi() % DATA.size()]
		_build_form())
	_body.add_child(next)
	var back := Chrome.pill_button("Back to Menu", Chrome.SURFACE, Chrome.TEXT)
	back.pressed.connect(_back)
	_body.add_child(back)

	# Celebrate after layout settles.
	await get_tree().process_frame
	Fx.score_popup(self, Vector2(size.x * 0.5 - 20, 140), "+%d XP" % earned, true, VIBRANT_GOLD)
	# Build confetti origins from each input slot position (approx top of body).
	var froms: Array = []
	var cols: Array = []
	var palette := [VIBRANT_GOLD, VIBRANT_MAGENTA, VIBRANT_BLUE, VIBRANT_GREEN]
	for i in SLOTS:
		froms.append(Vector2(size.x * (0.2 + 0.2 * i), 200))
		cols.append(palette[i % palette.size()])
	Fx.confetti_to(self, froms, Vector2(size.x * 0.5, 100), cols)
	if correct >= 4:
		Fx.banner(self, "PERFECT!" if correct == _data.forms.size() else "GREAT!",
			VIBRANT_GOLD, VIBRANT_GOLD_DARK)
		Fx.fireworks(self, Vector2(size.x * 0.5, size.y * 0.35))
	elif correct == 0:
		Fx.shake(self, 4.0, 0.25)

func _form_row(form: String, pos: String, example: String, found: bool) -> Control:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 2)
	var top := HBoxContainer.new()
	var word_lbl := Label.new()
	word_lbl.text = "%s  (%s)" % [form, pos]
	word_lbl.add_theme_font_size_override("font_size", 15)
	word_lbl.add_theme_color_override("font_color", Color.WHITE)
	word_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(word_lbl)
	var chip_bg: Color = VIBRANT_GREEN if found else VIBRANT_MAGENTA
	var chip_fg: Color = VIBRANT_GREEN_DARK if found else Color.WHITE
	top.add_child(_status_chip(found, chip_bg, chip_fg))
	row.add_child(top)
	var ex := Label.new()
	ex.text = example
	ex.add_theme_font_size_override("font_size", 12)
	ex.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
	ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(ex)
	return row

func _status_chip(found: bool, bg: Color, fg: Color) -> PanelContainer:
	# Found = ✓ icon + "FOUND". Missed = ✗ icon + "MISSED".
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(99)
	sb.set_border_width_all(2)
	sb.border_color = bg.darkened(0.18)
	sb.shadow_color = Color(0, 0, 0, 0.22)
	sb.shadow_size = 4
	sb.shadow_offset = Vector2i(0, 2)
	sb.content_margin_left = 12
	sb.content_margin_right = 14
	sb.content_margin_top = 5
	sb.content_margin_bottom = 5
	p.add_theme_stylebox_override("panel", sb)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	p.add_child(row)
	var icon_path := "res://assets/icons/check.svg" if found else "res://assets/icons/xmark.svg"
	if ResourceLoader.exists(icon_path):
		var icon := TextureRect.new()
		icon.texture = load(icon_path)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.custom_minimum_size = Vector2(14, 14)
		icon.modulate = fg
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(icon)
	var lbl := Label.new()
	lbl.text = "FOUND" if found else "MISSED"
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", fg)
	row.add_child(lbl)
	return p

func _vibrant_chip(text: String, bg: Color, fg: Color, border: Color) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(99)
	sb.set_border_width_all(2)
	sb.border_color = border
	sb.shadow_color = Color(0, 0, 0, 0.22)
	sb.shadow_size = 4
	sb.shadow_offset = Vector2i(0, 2)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 5
	sb.content_margin_bottom = 5
	p.add_theme_stylebox_override("panel", sb)
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", fg)
	p.add_child(lbl)
	return p

func _clear_body() -> void:
	for c in _body.get_children():
		c.queue_free()

func _back() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
