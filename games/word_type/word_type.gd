extends Control
## Word Type — show a base word, type up to 4 forms (derivations, inflections),
## score 20 XP per recognized form.

const Chrome := preload("res://scripts/screen_chrome.gd")

const GOLD := Color("#ffc844")
const GOLD_LIGHT := Color("#fff1c4")
const GOLD_DARK := Color("#b48218")
const PINK_DARK := Color("#c95e74")
const SAGE_LIGHT := Color("#dff1e0")
const SAGE_DARK := Color("#4a7d4a")
const TERRA := Color("#c95e3e")
const TERRA_LIGHT := Color("#fbeaea")
const PURPLE := Color("#7a4caf")

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

func _ready() -> void:
	_data = DATA[randi() % DATA.size()]
	Chrome.bg_layer(self)
	var back := Chrome.header(self, "Word Type", "word_type", GOLD_LIGHT, GOLD_DARK)
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

	# Word card.
	var card := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Chrome.SURFACE
	sb.set_corner_radius_all(16)
	sb.set_border_width_all(1)
	sb.border_color = Chrome.BORDER
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 16
	sb.content_margin_bottom = 16
	card.add_theme_stylebox_override("panel", sb)
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 6)
	card.add_child(col)
	var prompt := Label.new()
	prompt.text = "Transform this word"
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 13)
	prompt.add_theme_color_override("font_color", Chrome.TEXT_SEC)
	col.add_child(prompt)
	var word := Label.new()
	word.text = _data.word
	word.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	word.add_theme_font_size_override("font_size", 32)
	word.add_theme_color_override("font_color", Chrome.TEXT)
	col.add_child(word)
	var pos_holder := CenterContainer.new()
	pos_holder.add_child(Chrome.chip(_data.pos, GOLD_LIGHT, GOLD_DARK))
	col.add_child(pos_holder)
	_body.add_child(card)

	# Hint.
	var hint := Label.new()
	hint.text = "This word has %d forms — fill in what you know!" % _data.forms.size()
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", PURPLE)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.add_child(hint)

	# Inputs (4 slots).
	for i in SLOTS:
		var le := LineEdit.new()
		le.placeholder_text = "Type a word form…"
		le.add_theme_font_size_override("font_size", 16)
		le.add_theme_color_override("font_color", Chrome.TEXT)
		var box := StyleBoxFlat.new()
		box.bg_color = Chrome.SURFACE
		box.set_corner_radius_all(12)
		box.set_border_width_all(1)
		box.border_color = Chrome.BORDER
		box.content_margin_left = 12
		box.content_margin_right = 12
		box.content_margin_top = 10
		box.content_margin_bottom = 10
		le.add_theme_stylebox_override("normal", box)
		le.add_theme_stylebox_override("focus", box)
		_inputs.append(le)
		_body.add_child(le)

	var note := Label.new()
	note.text = "You don't need to fill all boxes — partial credit given!"
	note.add_theme_font_size_override("font_size", 12)
	note.add_theme_color_override("font_color", Chrome.TEXT_SEC)
	_body.add_child(note)

	var submit := Chrome.pill_button("Submit", GOLD, Chrome.TEXT)
	submit.disabled = true
	submit.pressed.connect(_submit)
	_body.add_child(submit)
	for input in _inputs:
		input.text_changed.connect(func(_t):
			submit.disabled = _all_blank())

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
	GameState.add_xp("word_type", correct * 20)
	_build_results(typed_set, correct)

func _build_results(typed_set: Dictionary, correct: int) -> void:
	_clear_body()

	var head := Label.new()
	head.text = "Results"
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_theme_font_size_override("font_size", 24)
	head.add_theme_color_override("font_color", Chrome.TEXT)
	_body.add_child(head)

	var sub := Label.new()
	sub.text = "%s — %s" % [_data.word, _data.pos]
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 14)
	sub.add_theme_color_override("font_color", Chrome.TEXT_SEC)
	_body.add_child(sub)

	var stat := Label.new()
	stat.text = "Forms found: %d / %d  •  +%d XP" % [correct, _data.forms.size(), correct * 20]
	stat.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stat.add_theme_font_size_override("font_size", 16)
	stat.add_theme_color_override("font_color", PINK_DARK)
	_body.add_child(stat)

	var card := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Chrome.SURFACE
	sb.set_corner_radius_all(16)
	sb.set_border_width_all(1)
	sb.border_color = Chrome.BORDER
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	card.add_theme_stylebox_override("panel", sb)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	card.add_child(box)
	var card_head := Label.new()
	card_head.text = "All Word Forms"
	card_head.add_theme_font_size_override("font_size", 14)
	card_head.add_theme_color_override("font_color", Chrome.TEXT)
	box.add_child(card_head)
	for i in _data.forms.size():
		box.add_child(_form_row(_data.forms[i], _data.types[i], _data.examples[i], typed_set.has(_data.forms[i])))
	_body.add_child(card)

	var next := Chrome.pill_button("Next Word →", GOLD, Chrome.TEXT)
	next.pressed.connect(func():
		_data = DATA[randi() % DATA.size()]
		_build_form())
	_body.add_child(next)
	var back := Chrome.pill_button("Back to Menu", Chrome.SURFACE, Chrome.TEXT)
	back.pressed.connect(_back)
	_body.add_child(back)

func _form_row(form: String, pos: String, example: String, found: bool) -> Control:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 2)
	var top := HBoxContainer.new()
	var word_lbl := Label.new()
	word_lbl.text = "%s  (%s)" % [form, pos]
	word_lbl.add_theme_font_size_override("font_size", 14)
	word_lbl.add_theme_color_override("font_color", Chrome.TEXT)
	word_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(word_lbl)
	var chip_bg: Color = SAGE_LIGHT if found else TERRA_LIGHT
	var chip_fg: Color = SAGE_DARK if found else TERRA
	top.add_child(Chrome.chip("✓ Found" if found else "Missed", chip_bg, chip_fg))
	row.add_child(top)
	var ex := Label.new()
	ex.text = example
	ex.add_theme_font_size_override("font_size", 12)
	ex.add_theme_color_override("font_color", Chrome.TEXT_SEC)
	ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(ex)
	return row

func _clear_body() -> void:
	for c in _body.get_children():
		c.queue_free()

func _back() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
