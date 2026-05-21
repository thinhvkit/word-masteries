extends Control
## Describe Picture — show a placeholder scene + sentence stems for the player
## to complete. Score by length of each answer.

const Chrome := preload("res://scripts/screen_chrome.gd")
const Fx := preload("res://games/word_fight/fx.gd")

const TEAL := Color("#5fb7a3")
const TEAL_LIGHT := Color("#dff3ee")
const TEAL_DARK := Color("#2f7060")
const PINK_DARK := Color("#c95e74")
const SAGE_LIGHT := Color("#dff1e0")
const SAGE_DARK := Color("#4a7d4a")
const GOLD_LIGHT := Color("#fff4e0")
const GOLD_DARK := Color("#b48218")

const VIBRANT_GOLD := Color("#ffd027")
const VIBRANT_GOLD_DARK := Color("#7a4a00")
const VIBRANT_MAGENTA := Color("#ff3aa8")
const VIBRANT_MAGENTA_DARK := Color("#7a0e4a")
const VIBRANT_TEAL := Color("#3ad6a8")
const VIBRANT_TEAL_DARK := Color("#0a6650")
const DARK_CARD := Color("#1a1240")
const DARK_CARD_BORDER := Color("#3a2a78")

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
var _inputs: Array = []  # Control wrappers, each with meta("line_edit")
var _body: VBoxContainer

func _ready() -> void:
	_scene_data = SCENES[randi() % SCENES.size()]
	var bg := Fx.BoardBG.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
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

	# Picture placeholder — dark vibrant card with gold "scene" label.
	var img_card := PanelContainer.new()
	img_card.custom_minimum_size = Vector2(0, 140)
	var img_sb := StyleBoxFlat.new()
	img_sb.bg_color = Color(DARK_CARD.r, DARK_CARD.g, DARK_CARD.b, 0.82)
	img_sb.set_corner_radius_all(18)
	img_sb.set_border_width_all(2)
	img_sb.border_color = DARK_CARD_BORDER
	img_sb.shadow_color = Color(0, 0, 0, 0.25)
	img_sb.shadow_size = 6
	img_sb.shadow_offset = Vector2i(0, 3)
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
		palette_icon.modulate = VIBRANT_GOLD
		palette_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		palette_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		img_row.add_child(palette_icon)
	var img_lbl := Label.new()
	img_lbl.text = _scene_data.label
	img_lbl.add_theme_font_size_override("font_size", 18)
	img_lbl.add_theme_color_override("font_color", Color.WHITE)
	img_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.45))
	img_lbl.add_theme_constant_override("outline_size", 3)
	img_row.add_child(img_lbl)
	_body.add_child(img_card)

	var heading := Label.new()
	heading.text = "Complete each sentence:"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 16)
	heading.add_theme_color_override("font_color", VIBRANT_GOLD)
	_body.add_child(heading)

	for i in _scene_data.stems.size():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var stem := Label.new()
		stem.text = "%s…" % _scene_data.stems[i]
		stem.custom_minimum_size = Vector2(100, 0)
		stem.add_theme_font_size_override("font_size", 15)
		stem.add_theme_color_override("font_color", Color.WHITE)
		stem.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.45))
		stem.add_theme_constant_override("outline_size", 3)
		stem.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(stem)
		var input_ctrl := _glow_input("…")
		input_ctrl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_inputs.append(input_ctrl)
		row.add_child(input_ctrl)
		_body.add_child(row)

	var hint := Label.new()
	hint.text = "Longer, natural sentences score higher"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
	_body.add_child(hint)

	# Submit pill wrapped in a magenta glow ring.
	var submit_wrap := Control.new()
	submit_wrap.custom_minimum_size = Vector2(0, 56)
	var submit_glow := Panel.new()
	submit_glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	submit_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var glow_sb := StyleBoxFlat.new()
	glow_sb.bg_color = Color(0, 0, 0, 0)
	glow_sb.set_corner_radius_all(32)
	glow_sb.shadow_color = Color(1.0, 0.4, 0.7, 0.0)
	glow_sb.shadow_size = 0
	submit_glow.add_theme_stylebox_override("panel", glow_sb)
	submit_wrap.add_child(submit_glow)
	var submit := Chrome.pill_button("Submit All", VIBRANT_MAGENTA, Color.WHITE)
	submit.set_anchors_preset(Control.PRESET_FULL_RECT)
	submit.disabled = true
	submit.pressed.connect(_submit)
	submit_wrap.add_child(submit)
	_body.add_child(submit_wrap)
	for input_ctrl in _inputs:
		var le := _line_edit_for(input_ctrl)
		if le != null:
			le.text_changed.connect(func(_t): _refresh_submit(submit, submit_glow))
	_refresh_submit(submit, submit_glow)

func _all_blank() -> bool:
	for input_ctrl in _inputs:
		var le := _line_edit_for(input_ctrl)
		if le != null and not le.text.strip_edges().is_empty():
			return false
	return true

func _line_edit_for(holder: Variant) -> LineEdit:
	if holder is LineEdit:
		return holder
	if holder is Control and (holder as Control).has_meta("line_edit"):
		return (holder as Control).get_meta("line_edit") as LineEdit
	return null

func _refresh_submit(btn: Button, glow_panel: Panel) -> void:
	var all_filled := not _all_blank()
	btn.disabled = not all_filled
	var sb := glow_panel.get_theme_stylebox("panel") as StyleBoxFlat
	if sb != null:
		var fresh: StyleBoxFlat = sb.duplicate()
		fresh.shadow_color = Color(1.0, 0.4, 0.7, 0.55 if all_filled else 0.0)
		fresh.shadow_size = 20 if all_filled else 0
		glow_panel.add_theme_stylebox_override("panel", fresh)

func _glow_input(placeholder: String) -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(0, 44)
	var glow := Panel.new()
	glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var glow_sb := StyleBoxFlat.new()
	glow_sb.bg_color = Color(0, 0, 0, 0)
	glow_sb.set_corner_radius_all(12)
	glow_sb.shadow_color = Color(1.0, 0.4, 0.7, 0.0)
	glow_sb.shadow_size = 0
	glow.add_theme_stylebox_override("panel", glow_sb)
	holder.add_child(glow)
	var card := PanelContainer.new()
	card.set_anchors_preset(Control.PRESET_FULL_RECT)
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color.WHITE
	sb.set_corner_radius_all(12)
	sb.set_border_width_all(2)
	sb.border_color = Color("#e0d8c8")
	sb.shadow_color = Color(0, 0, 0, 0.18)
	sb.shadow_size = 3
	card.add_theme_stylebox_override("panel", sb)
	holder.add_child(card)
	var le := LineEdit.new()
	le.placeholder_text = placeholder
	le.add_theme_font_size_override("font_size", 15)
	le.add_theme_color_override("font_color", VIBRANT_MAGENTA_DARK)
	le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	le.size_flags_vertical = Control.SIZE_EXPAND_FILL
	le.focus_mode = Control.FOCUS_ALL
	le.mouse_filter = Control.MOUSE_FILTER_STOP
	var le_box := StyleBoxFlat.new()
	le_box.bg_color = Color(0, 0, 0, 0)
	le_box.content_margin_left = 10
	le_box.content_margin_right = 10
	le_box.content_margin_top = 10
	le_box.content_margin_bottom = 10
	le.add_theme_stylebox_override("normal", le_box)
	le.add_theme_stylebox_override("focus", le_box)
	le.add_theme_stylebox_override("read_only", le_box)
	card.add_child(le)
	le.focus_entered.connect(func():
		var gsb := glow.get_theme_stylebox("panel") as StyleBoxFlat
		if gsb == null: return
		var fresh: StyleBoxFlat = gsb.duplicate()
		fresh.shadow_color = Color(1.0, 0.4, 0.7, 0.5)
		fresh.shadow_size = 10
		glow.add_theme_stylebox_override("panel", fresh))
	le.focus_exited.connect(func():
		var gsb := glow.get_theme_stylebox("panel") as StyleBoxFlat
		if gsb == null: return
		var fresh: StyleBoxFlat = gsb.duplicate()
		fresh.shadow_color = Color(1.0, 0.4, 0.7, 0.0)
		fresh.shadow_size = 0
		glow.add_theme_stylebox_override("panel", fresh))
	card.gui_input.connect(func(event: InputEvent):
		if (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed):
			le.grab_focus())
	holder.set_meta("line_edit", le)
	return holder

func _submit() -> void:
	var scores := []
	var total := 0
	for i in _inputs.size():
		var le := _line_edit_for(_inputs[i])
		var text := le.text.strip_edges() if le != null else ""
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
	head.text = "SCORED!"
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_theme_font_size_override("font_size", 30)
	head.add_theme_color_override("font_color", VIBRANT_GOLD)
	head.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.55))
	head.add_theme_constant_override("outline_size", 5)
	_body.add_child(head)

	var max_total: int = scores.size() * 25
	var stat := Label.new()
	stat.text = "%d / %d" % [total, max_total]
	stat.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stat.add_theme_font_size_override("font_size", 22)
	stat.add_theme_color_override("font_color", Color.WHITE)
	stat.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.45))
	stat.add_theme_constant_override("outline_size", 3)
	_body.add_child(stat)

	for i in scores.size():
		_body.add_child(_score_card(i, scores[i]))

	# Reveal FX.
	await get_tree().process_frame
	Fx.score_popup(self, Vector2(size.x * 0.5 - 24, 120), "+%d XP" % total, true, VIBRANT_GOLD)
	var froms: Array = []
	var cols: Array = [VIBRANT_GOLD, VIBRANT_MAGENTA, VIBRANT_TEAL, Color("#3aa8ff")]
	for i in scores.size():
		froms.append(Vector2(size.x * (0.2 + 0.18 * i), 200))
	Fx.confetti_to(self, froms, Vector2(size.x * 0.5, 100), cols)
	if max_total > 0 and float(total) / float(max_total) >= 0.7:
		Fx.banner(self, "GREAT JOB!", VIBRANT_GOLD, VIBRANT_GOLD_DARK)
		Fx.fireworks(self, Vector2(size.x * 0.5, size.y * 0.35))

	var next := Chrome.pill_button("Next Picture", VIBRANT_MAGENTA, Color.WHITE, "res://assets/icons/arrow_right.svg")
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
	sb.bg_color = Color(DARK_CARD.r, DARK_CARD.g, DARK_CARD.b, 0.82)
	sb.set_corner_radius_all(14)
	sb.set_border_width_all(2)
	sb.border_color = DARK_CARD_BORDER
	sb.shadow_color = Color(0, 0, 0, 0.22)
	sb.shadow_size = 4
	sb.shadow_offset = Vector2i(0, 2)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	card.add_theme_stylebox_override("panel", sb)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	card.add_child(box)
	var top := HBoxContainer.new()
	var stem := Label.new()
	stem.text = "%s…" % _scene_data.stems[i]
	stem.add_theme_font_size_override("font_size", 14)
	stem.add_theme_color_override("font_color", VIBRANT_GOLD)
	stem.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(stem)
	var chip_bg: Color = VIBRANT_TEAL if s.ok else VIBRANT_MAGENTA
	var chip_fg: Color = VIBRANT_TEAL_DARK if s.ok else Color.WHITE
	top.add_child(Chrome.chip("%d/%d" % [s.score, s.max], chip_bg, chip_fg))
	box.add_child(top)
	var you := Label.new()
	you.text = 'You: "%s"' % s.yours
	you.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	you.add_theme_font_size_override("font_size", 13)
	you.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
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
		rb.modulate = VIBRANT_GOLD
		rb.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		rb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rec_row.add_child(rb)
	var rec := Label.new()
	rec.text = s.rec
	rec.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rec.add_theme_font_size_override("font_size", 12)
	rec.add_theme_color_override("font_color", VIBRANT_GOLD)
	rec.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rec_row.add_child(rec)
	return card

func _clear_body() -> void:
	for c in _body.get_children():
		c.queue_free()

func _back() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
