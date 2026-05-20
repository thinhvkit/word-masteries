extends RefCounted
## Shared screen chrome — cream bg + white top header band (back, title, tag chip).
## Used by game screens to keep the look consistent with the prototype.

const BG := Color("#faf5ed")
const SURFACE := Color("#ffffff")
const BORDER := Color("#ece4d8")
const TEXT := Color("#5a4840")
const TEXT_SEC := Color("#9a8a7e")

const HEADER_H := 72

## Adds a full-rect cream backdrop as the first child of `parent`.
static func bg_layer(parent: Control) -> ColorRect:
	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(bg)
	parent.move_child(bg, 0)
	return bg

## Builds a header band at the top of `parent`. Returns the back Button so the
## caller can wire up navigation. `tag_text`/`tag_color` add a chip on the right.
static func header(parent: Control, title: String, tag_text: String = "", tag_bg: Color = Color(0,0,0,0), tag_fg: Color = TEXT) -> Button:
	var panel := PanelContainer.new()
	panel.anchor_left = 0.0
	panel.anchor_right = 1.0
	panel.offset_top = 0
	panel.offset_bottom = HEADER_H
	var sb := StyleBoxFlat.new()
	sb.bg_color = SURFACE
	sb.shadow_color = Color(0, 0, 0, 0.05)
	sb.shadow_size = 3
	sb.shadow_offset = Vector2i(0, 1)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 18
	sb.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", sb)
	parent.add_child(panel)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	panel.add_child(row)

	var back := Button.new()
	back.text = ""
	back.focus_mode = Control.FOCUS_NONE
	var arrow_tex_path := "res://assets/icons/arrow_left.svg"
	if ResourceLoader.exists(arrow_tex_path):
		back.icon = load(arrow_tex_path)
		back.expand_icon = false
		back.modulate = TEXT      # tint the white-stroke SVG to header text color
	else:
		back.text = "<"           # fallback only if icon is missing
		back.add_theme_font_size_override("font_size", 22)
	back.add_theme_color_override("font_color", TEXT)
	back.add_theme_color_override("font_hover_color", TEXT)
	back.add_theme_color_override("font_pressed_color", TEXT)
	var empty := StyleBoxEmpty.new()
	back.add_theme_stylebox_override("normal", empty)
	back.add_theme_stylebox_override("hover", empty)
	back.add_theme_stylebox_override("pressed", empty)
	back.add_theme_stylebox_override("focus", empty)
	back.custom_minimum_size = Vector2(32, 32)
	row.add_child(back)

	var title_lbl := Label.new()
	title_lbl.text = title
	title_lbl.add_theme_font_size_override("font_size", 20)
	title_lbl.add_theme_color_override("font_color", TEXT)
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title_lbl)

	if tag_text != "":
		row.add_child(chip(tag_text, tag_bg, tag_fg))

	return back

static func chip(text: String, bg: Color, fg: Color) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(99)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 5
	sb.content_margin_bottom = 5
	p.add_theme_stylebox_override("panel", sb)
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_color_override("font_color", fg)
	lbl.add_theme_font_size_override("font_size", 13)
	p.add_child(lbl)
	return p

static func pill_button(text: String, fill: Color, fg: Color = Color.WHITE, icon_path: String = "", icon_alignment: int = HORIZONTAL_ALIGNMENT_RIGHT) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 52)
	b.alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.add_theme_font_size_override("font_size", 17)
	b.add_theme_color_override("font_color", fg)
	b.add_theme_color_override("font_hover_color", fg)
	# Optional inline icon (e.g. arrow_right on a "Next" pill, play on a play button).
	if icon_path != "" and ResourceLoader.exists(icon_path):
		b.icon = load(icon_path)
		b.icon_alignment = icon_alignment
		b.expand_icon = false
		b.add_theme_constant_override("icon_max_width", 22)
		b.add_theme_constant_override("h_separation", 8)
	b.add_theme_color_override("font_pressed_color", fg)
	b.add_theme_color_override("font_disabled_color", Color(fg.r, fg.g, fg.b, 0.6))
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.set_corner_radius_all(28)
	sb.shadow_color = Color(0, 0, 0, 0.12)
	sb.shadow_size = 4
	sb.shadow_offset = Vector2i(0, 2)
	sb.content_margin_left = 24
	sb.content_margin_right = 24
	sb.content_margin_top = 14
	sb.content_margin_bottom = 14
	var press := sb.duplicate() as StyleBoxFlat
	press.bg_color = fill.darkened(0.05)
	press.shadow_size = 1
	press.shadow_offset = Vector2i(0, 0)
	press.content_margin_top = 16
	press.content_margin_bottom = 12
	var disabled := sb.duplicate() as StyleBoxFlat
	# Desaturated, lighter fill so disabled stays on-style instead of falling
	# back to the theme's gray default.
	disabled.bg_color = Color(fill.r, fill.g, fill.b, 0.55).lerp(Color("#ece4d8"), 0.4)
	disabled.shadow_size = 2
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sb)
	b.add_theme_stylebox_override("pressed", press)
	b.add_theme_stylebox_override("focus", sb)
	b.add_theme_stylebox_override("disabled", disabled)
	return b
