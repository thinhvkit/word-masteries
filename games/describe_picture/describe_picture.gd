extends Control
## Describe Picture — show a placeholder scene + sentence stems for the player
## to complete. Score by length of each answer.

const Chrome := preload("res://scripts/screen_chrome.gd")

const TEAL := Color("#5fb7a3")
const TEAL_LIGHT := Color("#dff3ee")
const TEAL_DARK := Color("#2f7060")
const PINK_DARK := Color("#c95e74")
const SAGE_LIGHT := Color("#dff1e0")
const SAGE_DARK := Color("#4a7d4a")
const GOLD_LIGHT := Color("#fff4e0")
const GOLD_DARK := Color("#b48218")

const SCENES := [
	{
		"label": "Girl in park with dog",
		"stems": ["She is", "She has", "She wears", "It seems like"],
		"samples": [
			"sitting on a park bench reading a book",
			"long brown hair tied in a ponytail",
			"a red dress with white polka dots",
			"she is enjoying a peaceful afternoon",
		],
	},
	{
		"label": "Boy cooking in kitchen",
		"stems": ["He is", "He has", "He wears", "The kitchen looks"],
		"samples": [
			"stirring a pot on the stove",
			"short curly hair and a big smile",
			"a white apron over a blue shirt",
			"warm and cozy with lots of spices",
		],
	},
]

var _scene_data: Dictionary
var _inputs: Array[LineEdit] = []
var _body: VBoxContainer

func _ready() -> void:
	_scene_data = SCENES[randi() % SCENES.size()]
	Chrome.bg_layer(self)
	var back := Chrome.header(self, "Describe Picture", "describe_picture", TEAL_LIGHT, TEAL_DARK)
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
	_body.add_theme_constant_override("separation", 12)
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_body)
	_build_form()

func _build_form() -> void:
	_clear_body()
	_inputs.clear()

	# Picture placeholder.
	var img_card := PanelContainer.new()
	img_card.custom_minimum_size = Vector2(0, 140)
	var img_sb := StyleBoxFlat.new()
	img_sb.bg_color = TEAL_LIGHT
	img_sb.set_corner_radius_all(14)
	img_sb.set_border_width_all(2)
	img_sb.border_color = TEAL
	img_card.add_theme_stylebox_override("panel", img_sb)
	# Centered row: palette icon + scene label.
	var img_row := HBoxContainer.new()
	img_row.alignment = BoxContainer.ALIGNMENT_CENTER
	img_row.add_theme_constant_override("separation", 8)
	img_row.set_anchors_preset(Control.PRESET_CENTER)
	img_card.add_child(img_row)
	var palette_path := "res://assets/icons/palette.svg"
	if ResourceLoader.exists(palette_path):
		var palette_icon := TextureRect.new()
		palette_icon.texture = load(palette_path)
		palette_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		palette_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		palette_icon.custom_minimum_size = Vector2(22, 22)
		palette_icon.modulate = TEAL_DARK
		palette_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		palette_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		img_row.add_child(palette_icon)
	var img_lbl := Label.new()
	img_lbl.text = _scene_data.label
	img_lbl.add_theme_font_size_override("font_size", 14)
	img_lbl.add_theme_color_override("font_color", TEAL_DARK)
	img_row.add_child(img_lbl)
	_body.add_child(img_card)

	var heading := Label.new()
	heading.text = "Complete each sentence:"
	heading.add_theme_font_size_override("font_size", 15)
	heading.add_theme_color_override("font_color", Chrome.TEXT)
	_body.add_child(heading)

	for i in _scene_data.stems.size():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var stem := Label.new()
		stem.text = "%s…" % _scene_data.stems[i]
		stem.custom_minimum_size = Vector2(95, 0)
		stem.add_theme_font_size_override("font_size", 14)
		stem.add_theme_color_override("font_color", Chrome.TEXT)
		stem.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(stem)
		var le := LineEdit.new()
		le.placeholder_text = "…"
		le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		le.add_theme_font_size_override("font_size", 14)
		le.add_theme_color_override("font_color", Chrome.TEXT)
		var input_sb := StyleBoxFlat.new()
		input_sb.bg_color = Chrome.SURFACE
		input_sb.set_corner_radius_all(10)
		input_sb.set_border_width_all(1)
		input_sb.border_color = Chrome.BORDER
		input_sb.content_margin_left = 10
		input_sb.content_margin_right = 10
		input_sb.content_margin_top = 8
		input_sb.content_margin_bottom = 8
		le.add_theme_stylebox_override("normal", input_sb)
		le.add_theme_stylebox_override("focus", input_sb)
		_inputs.append(le)
		row.add_child(le)
		_body.add_child(row)

	var hint := Label.new()
	hint.text = "Longer, natural sentences score higher"
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Chrome.TEXT_SEC)
	_body.add_child(hint)

	var submit := Chrome.pill_button("Submit All", TEAL)
	submit.disabled = true
	submit.pressed.connect(_submit)
	_body.add_child(submit)
	for input in _inputs:
		input.text_changed.connect(func(_t): submit.disabled = _all_blank())

func _all_blank() -> bool:
	for input in _inputs:
		if not input.text.strip_edges().is_empty():
			return false
	return true

func _submit() -> void:
	var scores := []
	var total := 0
	for i in _inputs.size():
		var text := _inputs[i].text.strip_edges()
		var n: int = text.length()
		var pts: int = mini(25, int(round(n * 2 + (5 if n > 12 else 0))))
		var ok: bool = pts >= 15
		scores.append({"yours": text, "score": pts, "max": 25, "ok": ok, "rec": _scene_data.samples[i]})
		total += pts
	GameState.add_xp("describe_picture", total)
	_build_results(scores, total)

func _build_results(scores: Array, total: int) -> void:
	_clear_body()

	var head := Label.new()
	head.text = "Scored!"
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_theme_font_size_override("font_size", 24)
	head.add_theme_color_override("font_color", Chrome.TEXT)
	_body.add_child(head)

	var stat := Label.new()
	stat.text = "Total: %d / %d" % [total, scores.size() * 25]
	stat.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stat.add_theme_font_size_override("font_size", 18)
	stat.add_theme_color_override("font_color", PINK_DARK)
	_body.add_child(stat)

	for i in scores.size():
		_body.add_child(_score_card(i, scores[i]))

	var next := Chrome.pill_button("Next Picture →", TEAL)
	next.pressed.connect(func():
		_scene_data = SCENES[randi() % SCENES.size()]
		_build_form())
	_body.add_child(next)
	var back := Chrome.pill_button("Back to Menu", Chrome.SURFACE, Chrome.TEXT)
	back.pressed.connect(_back)
	_body.add_child(back)

func _score_card(i: int, s: Dictionary) -> Control:
	var card := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Chrome.SURFACE
	sb.set_corner_radius_all(12)
	sb.set_border_width_all(1)
	sb.border_color = Chrome.BORDER
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	card.add_theme_stylebox_override("panel", sb)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	card.add_child(box)
	var top := HBoxContainer.new()
	var stem := Label.new()
	stem.text = "%s…" % _scene_data.stems[i]
	stem.add_theme_font_size_override("font_size", 14)
	stem.add_theme_color_override("font_color", Chrome.TEXT)
	stem.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(stem)
	var chip_bg: Color = SAGE_LIGHT if s.ok else GOLD_LIGHT
	var chip_fg: Color = SAGE_DARK if s.ok else GOLD_DARK
	top.add_child(Chrome.chip("%d/%d" % [s.score, s.max], chip_bg, chip_fg))
	box.add_child(top)
	var you := Label.new()
	you.text = 'You: "%s"' % s.yours
	you.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	you.add_theme_font_size_override("font_size", 13)
	you.add_theme_color_override("font_color", Chrome.TEXT)
	box.add_child(you)
	var rec_row := HBoxContainer.new()
	rec_row.add_theme_constant_override("separation", 6)
	box.add_child(rec_row)
	var rec_bulb := "res://assets/icons/bulb.svg"
	if ResourceLoader.exists(rec_bulb):
		var rb := TextureRect.new()
		rb.texture = load(rec_bulb)
		rb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rb.custom_minimum_size = Vector2(16, 16)
		rb.modulate = TEAL_DARK
		rb.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		rb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rec_row.add_child(rb)
	var rec := Label.new()
	rec.text = s.rec
	rec.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rec.add_theme_font_size_override("font_size", 12)
	rec.add_theme_color_override("font_color", TEAL_DARK)
	rec.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rec_row.add_child(rec)
	return card

func _clear_body() -> void:
	for c in _body.get_children():
		c.queue_free()

func _back() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
