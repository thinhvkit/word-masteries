extends RefCounted
## Shared UI builders for Word Fight intro / victory / defeat screens.
## Uses Palette autoload tokens. Programmatic — no .tscn dependency.

static func center_label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_size_override("font_size", size)
	return l

static func card(bg: Color, border: Color, radius: int = 12, pad: int = 16) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.border_width_left = 2
	sb.border_width_right = 2
	sb.border_width_top = 2
	sb.border_width_bottom = 2
	sb.corner_radius_top_left = radius
	sb.corner_radius_top_right = radius
	sb.corner_radius_bottom_left = radius
	sb.corner_radius_bottom_right = radius
	sb.content_margin_left = pad
	sb.content_margin_right = pad
	sb.content_margin_top = pad
	sb.content_margin_bottom = pad
	p.add_theme_stylebox_override("panel", sb)
	return p

static func primary_btn(text: String, bg: Color = Palette.PINK, bg_hover: Color = Palette.PINK_DARK) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 48)
	b.add_theme_font_size_override("font_size", 18)
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", Color.WHITE)
	b.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.85))
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.corner_radius_top_left = 24
	sb.corner_radius_top_right = 24
	sb.corner_radius_bottom_left = 24
	sb.corner_radius_bottom_right = 24
	sb.content_margin_left = 24
	sb.content_margin_right = 24
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	b.add_theme_stylebox_override("normal", sb)
	var sbh: StyleBoxFlat = sb.duplicate()
	sbh.bg_color = bg_hover
	b.add_theme_stylebox_override("hover", sbh)
	var sbd: StyleBoxFlat = sb.duplicate()
	sbd.bg_color = Color(bg.r, bg.g, bg.b, 0.45)
	b.add_theme_stylebox_override("disabled", sbd)
	return b

static func ghost_btn(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 44)
	b.add_theme_font_size_override("font_size", 16)
	b.add_theme_color_override("font_color", Palette.TEXT)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Palette.SURFACE
	sb.border_color = Palette.BORDER
	sb.border_width_left = 2
	sb.border_width_right = 2
	sb.border_width_top = 2
	sb.border_width_bottom = 2
	sb.corner_radius_top_left = 22
	sb.corner_radius_top_right = 22
	sb.corner_radius_bottom_left = 22
	sb.corner_radius_bottom_right = 22
	sb.content_margin_left = 24
	sb.content_margin_right = 24
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	b.add_theme_stylebox_override("normal", sb)
	var sbh: StyleBoxFlat = sb.duplicate()
	sbh.bg_color = Palette.BG_SOFT
	b.add_theme_stylebox_override("hover", sbh)
	var sbd: StyleBoxFlat = sb.duplicate()
	sbd.bg_color = Palette.BG_SOFT
	b.add_theme_stylebox_override("disabled", sbd)
	b.add_theme_color_override("font_disabled_color", Palette.TEXT_SECONDARY)
	return b

static func stat_box(label_text: String, value_text: String, accent: Color) -> Control:
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 2)
	box.add_child(center_label(value_text, 28, accent))
	box.add_child(center_label(label_text, 12, Palette.TEXT_SECONDARY))
	return box

static func kv_row(label_text: String, value_text: String, highlight: bool = false) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var l := Label.new()
	l.text = label_text
	l.add_theme_color_override("font_color", Palette.TEXT_SECONDARY)
	l.add_theme_font_size_override("font_size", 14)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	var v := Label.new()
	v.text = value_text
	v.add_theme_color_override("font_color", Palette.GOLD_DARK if highlight else Palette.TEXT)
	v.add_theme_font_size_override("font_size", 14)
	row.add_child(v)
	return row

static func bg_layer(parent: Control, color: Color) -> void:
	var bg := ColorRect.new()
	bg.color = color
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(bg)

static func pill(text: String, bg: Color, fg: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", fg)
	l.add_theme_font_size_override("font_size", 13)
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.corner_radius_top_left = 10
	sb.corner_radius_top_right = 10
	sb.corner_radius_bottom_left = 10
	sb.corner_radius_bottom_right = 10
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	l.add_theme_stylebox_override("normal", sb)
	return l

static func avatar(color: Color, size_px: int = 40) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	var r := size_px / 2
	sb.corner_radius_top_left = r
	sb.corner_radius_top_right = r
	sb.corner_radius_bottom_left = r
	sb.corner_radius_bottom_right = r
	p.add_theme_stylebox_override("panel", sb)
	p.custom_minimum_size = Vector2(size_px, size_px)
	return p

static func hp_bar(color: Color, track: Color = Color("#e8e0d8"), height: int = 14) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, height)
	bar.max_value = 100
	bar.value = 100
	var bg_sb := StyleBoxFlat.new()
	bg_sb.bg_color = track
	bg_sb.corner_radius_top_left = height / 2
	bg_sb.corner_radius_top_right = height / 2
	bg_sb.corner_radius_bottom_left = height / 2
	bg_sb.corner_radius_bottom_right = height / 2
	bar.add_theme_stylebox_override("background", bg_sb)
	var fg_sb := StyleBoxFlat.new()
	fg_sb.bg_color = color
	fg_sb.corner_radius_top_left = height / 2
	fg_sb.corner_radius_top_right = height / 2
	fg_sb.corner_radius_bottom_left = height / 2
	fg_sb.corner_radius_bottom_right = height / 2
	bar.add_theme_stylebox_override("fill", fg_sb)
	return bar

static func chip(text: String, fg: Color, bg: Color, border: Color = Color(0, 0, 0, 0)) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", fg)
	l.add_theme_font_size_override("font_size", 12)
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	if border.a > 0:
		sb.border_color = border
		sb.border_width_left = 1
		sb.border_width_right = 1
		sb.border_width_top = 1
		sb.border_width_bottom = 1
	sb.corner_radius_top_left = 10
	sb.corner_radius_top_right = 10
	sb.corner_radius_bottom_left = 10
	sb.corner_radius_bottom_right = 10
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 3
	sb.content_margin_bottom = 3
	l.add_theme_stylebox_override("normal", sb)
	return l

static func streak_dots(filled: int, total: int = 4, size_px: int = 8) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	for i in total:
		var dot := PanelContainer.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Palette.GOLD if i < filled else Palette.HAIRLINE
		var r := size_px / 2
		sb.corner_radius_top_left = r
		sb.corner_radius_top_right = r
		sb.corner_radius_bottom_left = r
		sb.corner_radius_bottom_right = r
		dot.add_theme_stylebox_override("panel", sb)
		dot.custom_minimum_size = Vector2(size_px, size_px)
		row.add_child(dot)
	return row

static func action_btn(text: String, primary: bool = false, disabled: bool = false) -> Button:
	if primary:
		var b := primary_btn(text)
		b.disabled = disabled
		return b
	var b := ghost_btn(text)
	b.disabled = disabled
	return b

static func flow_pills(words: Array, bg: Color, fg: Color) -> HFlowContainer:
	var f := HFlowContainer.new()
	f.add_theme_constant_override("h_separation", 6)
	f.add_theme_constant_override("v_separation", 6)
	for w in words:
		f.add_child(pill(str(w), bg, fg))
	return f
