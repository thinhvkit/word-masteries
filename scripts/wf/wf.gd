class_name WF
extends RefCounted
## Wireframe widget kit — Godot translation of wireframe-core.jsx.
## All factories return ready-to-add Control nodes styled in the sketchy
## handwritten aesthetic: paper-white bg, 2px black borders, Caveat font.

const _Chrome := preload("res://scripts/screen_chrome.gd")

# ---- color palette ----
const BG          := Color("#FAF9F6")
const PAPER       := Color("#FFFFFF")
const BORDER      := Color("#333333")
const BORDER_LITE := Color("#CCCCCC")
const TEXT        := Color("#2D2D2D")
const MUTED       := Color("#999999")
const ACCENT      := Color("#5B8DEF")
const ACCENT_BG   := Color("#EDF2FF")
const SUCCESS     := Color("#5CB85C")
const SUCCESS_BG  := Color("#E9F7E9")
const DANGER      := Color("#E05555")
const DANGER_BG   := Color("#FDE8E8")
const WARN        := Color("#F5A623")
const WARN_BG     := Color("#FFF4E0")
const PURPLE      := Color("#9B59B6")
const PURPLE_BG   := Color("#F4ECF7")
# dark mode
const DARK_BG     := Color("#1A1A2E")
const DARK_PAPER  := Color("#16213E")
const DARK_CELL   := Color("#1A1A3E")
const DARK_BORDER := Color("#445566")
const DARK_TEXT   := Color("#EEEEEE")

# ---- font helpers ----
static func font_regular() -> FontFile:
	return load("res://assets/fonts/Caveat-Regular.ttf")
static func font_bold() -> FontFile:
	return load("res://assets/fonts/Caveat-Bold.ttf")

# Apply Caveat font + color + size to any Label-like Control.
static func style_label(lbl: Label, size: int = 18, color: Color = TEXT, bold: bool = false) -> Label:
	lbl.add_theme_font_override("font", font_bold() if bold else font_regular())
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", color)
	return lbl

static func make_label(text: String, size: int = 18, color: Color = TEXT, bold: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	style_label(l, size, color, bold)
	return l

# ---- styleboxes ----
static func sketch_box(bg: Color = PAPER, border: Color = BORDER, w: int = 2, radius: int = 12) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_border_width_all(w)
	s.border_color = border
	s.set_corner_radius_all(radius)
	s.content_margin_left = 12
	s.content_margin_right = 12
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s

static func dashed_box(bg: Color = PAPER, border: Color = BORDER, radius: int = 12) -> StyleBoxFlat:
	# StyleBoxFlat doesn't support dashed borders; we render a normal border
	# and rely on the dashed-look only inside specific Dashy widgets where it matters.
	return sketch_box(bg, border, 2, radius)

# ---- root phone wrapper ----
# A phone artboard: 340×720 with white background, status bar, optional header,
# scrollable content, optional bottom nav. Use add_content(c) to push children.
class Phone extends Control:
	var dark: bool = false
	var inner: VBoxContainer
	var content_box: VBoxContainer
	var header_holder: Control
	var nav_holder: Control
	func _init(dark_mode: bool = false) -> void:
		dark = dark_mode
		# Default minimum keeps the design-canvas grid laying out cleanly;
		# when used as a real screen the parent sets full-rect anchors and we
		# fill the viewport instead.
		custom_minimum_size = Vector2(340, 720)
		size_flags_horizontal = Control.SIZE_EXPAND_FILL
		size_flags_vertical = Control.SIZE_EXPAND_FILL
		set_anchors_preset(Control.PRESET_FULL_RECT)
		var bg := PanelContainer.new()
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		var sb := StyleBoxFlat.new()
		sb.bg_color = WF.DARK_BG if dark else WF.BG
		sb.set_corner_radius_all(0)
		bg.add_theme_stylebox_override("panel", sb)
		add_child(bg)
		inner = VBoxContainer.new()
		inner.add_theme_constant_override("separation", 0)
		inner.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(inner)
		inner.add_child(WF.status_bar(dark))
		header_holder = Control.new()
		header_holder.custom_minimum_size = Vector2(0, 0)
		header_holder.visible = false
		inner.add_child(header_holder)
		var scroll := _Chrome.scroll_container()
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		inner.add_child(scroll)
		content_box = VBoxContainer.new()
		content_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		content_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
		content_box.add_theme_constant_override("separation", 0)
		scroll.add_child(content_box)
		nav_holder = Control.new()
		nav_holder.visible = false
		inner.add_child(nav_holder)
	func set_header(h: Control) -> void:
		if header_holder.get_child_count() > 0:
			header_holder.get_child(0).queue_free()
		header_holder.add_child(h)
		header_holder.custom_minimum_size = Vector2(0, 44)
		header_holder.visible = true
	func set_bottom_nav(n: Control) -> void:
		if nav_holder.get_child_count() > 0:
			nav_holder.get_child(0).queue_free()
		nav_holder.add_child(n)
		nav_holder.custom_minimum_size = Vector2(0, 60)
		nav_holder.visible = true
	func add_content(c: Control) -> void:
		content_box.add_child(c)
	func padded_body(padding := Vector4(16, 16, 16, 16), separation: int = 12) -> VBoxContainer:
		# Helper: adds a VBoxContainer with padding and returns it for filling.
		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", int(padding.x))
		margin.add_theme_constant_override("margin_top", int(padding.y))
		margin.add_theme_constant_override("margin_right", int(padding.z))
		margin.add_theme_constant_override("margin_bottom", int(padding.w))
		margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
		add_content(margin)
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", separation)
		margin.add_child(box)
		return box

# ---- status bar ----
static func status_bar(dark: bool = false) -> Control:
	var bar := HBoxContainer.new()
	bar.custom_minimum_size = Vector2(0, 26)
	var col := DARK_TEXT if dark else BORDER
	var time := Label.new()
	time.text = "9:41"
	time.add_theme_font_size_override("font_size", 13)
	time.add_theme_color_override("font_color", col)
	bar.add_theme_constant_override("separation", 0)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var dots := Label.new()
	dots.text = "▮▮▮  ◯  ▭▭"
	dots.add_theme_font_size_override("font_size", 12)
	dots.add_theme_color_override("font_color", col)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	margin.add_child(bar)
	bar.add_child(time)
	bar.add_child(spacer)
	bar.add_child(dots)
	return margin

# ---- app header ----
static func app_head(title: String, back: bool = false, badge: String = "", right_glyph: String = "", dark: bool = false) -> Control:
	var wrap := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = DARK_PAPER if dark else PAPER
	sb.border_width_bottom = 1
	sb.border_color = DARK_BORDER if dark else BORDER_LITE
	wrap.add_theme_stylebox_override("panel", sb)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	wrap.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	margin.add_child(row)
	if back:
		var arrow := Button.new()
		arrow.flat = true
		arrow.focus_mode = Control.FOCUS_NONE
		var arrow_path := "res://assets/icons/arrow_left.svg"
		if ResourceLoader.exists(arrow_path):
			arrow.icon = load(arrow_path)
			arrow.expand_icon = false
			arrow.modulate = DARK_TEXT if dark else TEXT
		else:
			arrow.text = "<"
			arrow.add_theme_font_override("font", font_bold())
			arrow.add_theme_font_size_override("font_size", 24)
			arrow.add_theme_color_override("font_color", DARK_TEXT if dark else TEXT)
			arrow.add_theme_color_override("font_hover_color", DARK_TEXT if dark else TEXT)
			arrow.add_theme_color_override("font_pressed_color", MUTED)
		arrow.custom_minimum_size = Vector2(32, 32)
		arrow.set_meta("nav", "$back")
		row.add_child(arrow)
	var title_lbl := make_label(title, 22, DARK_TEXT if dark else TEXT, true)
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title_lbl)
	if not badge.is_empty():
		row.add_child(pill(badge, Color.WHITE, ACCENT))
	if not right_glyph.is_empty():
		row.add_child(make_label(right_glyph, 20, DARK_TEXT if dark else TEXT))
	return wrap

# ---- bottom nav ----
static func bottom_nav(items: Array, active: int = 0) -> Control:
	var wrap := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = PAPER
	sb.border_width_top = 1
	sb.border_color = BORDER_LITE
	wrap.add_theme_stylebox_override("panel", sb)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 0)
	wrap.add_child(row)
	for i in items.size():
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		col.add_theme_constant_override("separation", 2)
		col.modulate.a = 1.0 if i == active else 0.45
		var dot := PanelContainer.new()
		var dot_sb := StyleBoxFlat.new()
		dot_sb.bg_color = ACCENT_BG if i == active else Color(0,0,0,0)
		dot_sb.set_border_width_all(2)
		dot_sb.border_color = BORDER
		dot_sb.set_corner_radius_all(12)
		dot.add_theme_stylebox_override("panel", dot_sb)
		dot.custom_minimum_size = Vector2(24, 24)
		dot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		col.add_child(dot)
		col.add_child(make_label(items[i], 13, TEXT))
		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_top", 6)
		margin.add_theme_constant_override("margin_bottom", 10)
		margin.add_child(col)
		margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(margin)
	return wrap

# ---- button ----
static func wf_btn(label_text: String, primary: bool = false, outline: bool = false, small: bool = false, disabled: bool = false, full: bool = true) -> Button:
	var btn := Button.new()
	btn.text = label_text
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(0 if full else 80, 44 if small else 52)
	btn.add_theme_font_override("font", font_bold())
	btn.add_theme_font_size_override("font_size", 18 if small else 22)
	if primary:
		btn.add_theme_color_override("font_color", Color.WHITE)
		btn.add_theme_color_override("font_hover_color", Color.WHITE)
		btn.add_theme_color_override("font_pressed_color", Color.WHITE)
		_apply_btn_sb(btn, ACCENT, ACCENT, 2)
	elif outline:
		btn.add_theme_color_override("font_color", TEXT)
		_apply_btn_sb(btn, Color(1,1,1,0), BORDER, 2)
	else:
		btn.add_theme_color_override("font_color", TEXT)
		_apply_btn_sb(btn, PAPER, BORDER, 2)
	if disabled:
		btn.modulate.a = 0.5
		btn.disabled = true
	return btn

static func _apply_btn_sb(btn: Button, bg: Color, border: Color, w: int) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_border_width_all(w)
	sb.border_color = border
	sb.set_corner_radius_all(12)
	sb.content_margin_left = 20
	sb.content_margin_right = 20
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	var pressed := sb.duplicate() as StyleBoxFlat
	pressed.bg_color = bg.darkened(0.05) if bg.a > 0 else Color(0,0,0,0.04)
	pressed.content_margin_top = 8
	pressed.content_margin_bottom = 4
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("focus", sb)
	btn.add_theme_stylebox_override("disabled", sb)

# ---- input ----
static func wf_input(placeholder: String, value: String = "", multiline: bool = false, min_height: int = 44) -> Control:
	var wrap := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = PAPER
	sb.set_border_width_all(2)
	sb.border_color = BORDER_LITE
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	wrap.add_theme_stylebox_override("panel", sb)
	wrap.custom_minimum_size = Vector2(0, min_height if not multiline else min_height + 28)
	var lbl := Label.new()
	if value.is_empty():
		lbl.text = placeholder
		lbl.add_theme_color_override("font_color", MUTED)
	else:
		lbl.text = value
		lbl.add_theme_color_override("font_color", TEXT)
	lbl.add_theme_font_override("font", font_regular())
	lbl.add_theme_font_size_override("font_size", 20)
	if multiline:
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	wrap.add_child(lbl)
	return wrap

# ---- letter tile (board / circle / row tile) ----
static func tile(letter: String, selected: bool = false, rainbow: bool = false, used: bool = false, size_px: int = 44) -> Control:
	var wrap := Control.new()
	wrap.custom_minimum_size = Vector2(size_px, size_px)
	wrap.size = Vector2(size_px, size_px)
	wrap.set_meta("letter", letter)
	var canvas := _TileCanvas.new(letter, selected, rainbow, used, size_px)
	wrap.add_child(canvas)
	return wrap

class _TileCanvas extends Control:
	var letter: String
	var selected: bool
	var rainbow: bool
	var used: bool
	var size_px: int
	func _init(l: String, sel: bool, rb: bool, u: bool, sz: int) -> void:
		letter = l
		selected = sel
		rainbow = rb
		used = u
		size_px = sz
		custom_minimum_size = Vector2(sz, sz)
		size = Vector2(sz, sz)
	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, size)
		var bg := WF.PAPER
		var border := WF.BORDER
		var text_col := WF.TEXT
		if used:
			bg = Color("#e8e8e6")
			border = WF.BORDER_LITE
			text_col = WF.MUTED
		elif rainbow:
			text_col = Color.WHITE
		elif selected:
			bg = WF.ACCENT_BG
		if rainbow:
			_draw_rainbow(rect, 8)
		else:
			_round_rect(rect, bg, 8)
		_round_rect_outline(rect, border, 8, 2.0)
		if selected:
			# halo glow
			_round_rect_outline(rect.grow(2), WF.ACCENT, 10, 2.0)
		var f := WF.font_bold()
		var fs := int(size_px * 0.45)
		var ts := f.get_string_size(letter, HORIZONTAL_ALIGNMENT_CENTER, -1, fs)
		draw_string(f, size * 0.5 - ts * 0.5 + Vector2(0, fs * 0.38),
			letter.to_upper(), HORIZONTAL_ALIGNMENT_CENTER, -1, fs, text_col)
	func _draw_rainbow(rect: Rect2, radius: float) -> void:
		# Crude 5-band rainbow: vertical strips
		var colors := [
			Color("#FF6B6B"), Color("#FFD93D"), Color("#6BCB77"),
			Color("#4D96FF"), Color("#9B59B6"),
		]
		var strip := rect.size.x / colors.size()
		for i in colors.size():
			draw_rect(Rect2(rect.position + Vector2(i * strip, 0), Vector2(strip + 1, rect.size.y)), colors[i])
		# crude rounded corners by masking with paper-colored arcs at each corner
		# (skip — rainbow tiles are visually distinct enough)
	func _round_rect(rect: Rect2, color: Color, radius: float) -> void:
		var r: float = minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
		draw_rect(Rect2(rect.position + Vector2(r, 0), Vector2(rect.size.x - 2*r, rect.size.y)), color)
		draw_rect(Rect2(rect.position + Vector2(0, r), Vector2(rect.size.x, rect.size.y - 2*r)), color)
		draw_circle(rect.position + Vector2(r, r), r, color)
		draw_circle(rect.position + Vector2(rect.size.x - r, r), r, color)
		draw_circle(rect.position + Vector2(r, rect.size.y - r), r, color)
		draw_circle(rect.position + Vector2(rect.size.x - r, rect.size.y - r), r, color)
	func _round_rect_outline(rect: Rect2, color: Color, radius: float, width: float) -> void:
		var r: float = minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
		draw_line(rect.position + Vector2(r, 0), rect.position + Vector2(rect.size.x - r, 0), color, width)
		draw_line(rect.position + Vector2(r, rect.size.y), rect.position + Vector2(rect.size.x - r, rect.size.y), color, width)
		draw_line(rect.position + Vector2(0, r), rect.position + Vector2(0, rect.size.y - r), color, width)
		draw_line(rect.position + Vector2(rect.size.x, r), rect.position + Vector2(rect.size.x, rect.size.y - r), color, width)
		draw_arc(rect.position + Vector2(r, r), r, PI, PI * 1.5, 16, color, width)
		draw_arc(rect.position + Vector2(rect.size.x - r, r), r, -PI * 0.5, 0, 16, color, width)
		draw_arc(rect.position + Vector2(r, rect.size.y - r), r, PI * 0.5, PI, 16, color, width)
		draw_arc(rect.position + Vector2(rect.size.x - r, rect.size.y - r), r, 0, PI * 0.5, 16, color, width)

# ---- HP / progress bar ----
static func hp_bar(value: float, maxv: float, color: Color = ACCENT, label_text: String = "", show_num: bool = false, height: int = 14) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	if not label_text.is_empty() or show_num:
		var top := HBoxContainer.new()
		top.add_theme_constant_override("separation", 0)
		var t := make_label(label_text, 14, TEXT)
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top.add_child(t)
		if show_num:
			top.add_child(make_label("%d/%d" % [int(value), int(maxv)], 14, TEXT))
		box.add_child(top)
	var bar := Control.new()
	bar.custom_minimum_size = Vector2(0, height)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var pct: float = clampf(value / maxv, 0.0, 1.0)
	bar.add_child(_HPBarCanvas.new(pct, color, height))
	box.add_child(bar)
	return box

class _HPBarCanvas extends Control:
	var pct: float
	var color: Color
	var height_px: int
	func _init(p: float, c: Color, h: int) -> void:
		pct = p; color = c; height_px = h
		set_anchors_preset(Control.PRESET_FULL_RECT)
	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, size)
		var r := height_px * 0.5
		# track
		draw_rect(rect, Color(WF.BORDER_LITE.r, WF.BORDER_LITE.g, WF.BORDER_LITE.b, 0.4))
		# outline
		_outline(rect, WF.BORDER_LITE, 1.0)
		# fill
		var fill_rect := Rect2(Vector2.ZERO, Vector2(size.x * pct, size.y))
		draw_rect(fill_rect, color)
	func _outline(rect: Rect2, c: Color, w: float) -> void:
		draw_rect(rect, c, false, w)

# ---- timer badge ----
static func timer_badge(time: String, warning: bool = false) -> Control:
	var wrap := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = DANGER_BG if warning else ACCENT_BG
	sb.set_border_width_all(1)
	sb.border_color = DANGER if warning else ACCENT
	sb.set_corner_radius_all(20)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	wrap.add_theme_stylebox_override("panel", sb)
	var lbl := make_label("⏱ " + time, 20, DANGER if warning else ACCENT, true)
	wrap.add_child(lbl)
	return wrap

# ---- score box ----
static func score_box(label_text: String, value: String, sub: String = "", color: Color = ACCENT) -> Control:
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 0)
	var l := make_label(label_text, 16, MUTED)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(l)
	var v := make_label(value, 36, color, true)
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(v)
	if not sub.is_empty():
		var s := make_label(sub, 14, MUTED)
		s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(s)
	return col

# ---- image placeholder (striped) ----
static func img_holder(label_text: String, h: int = 120, dark: bool = false) -> Control:
	var wrap := Control.new()
	wrap.custom_minimum_size = Vector2(0, h)
	wrap.add_child(_StripedCanvas.new(dark))
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	wrap.add_child(center)
	var chip := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#222") if dark else PAPER
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	chip.add_theme_stylebox_override("panel", sb)
	var lbl := make_label(label_text, 14, MUTED)
	chip.add_child(lbl)
	center.add_child(chip)
	return wrap

class _StripedCanvas extends Control:
	var dark: bool
	func _init(d: bool) -> void:
		dark = d
		set_anchors_preset(Control.PRESET_FULL_RECT)
	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, size)
		var c1 := Color("#e8e8e6")
		var c2 := Color("#f2f2f0")
		if dark:
			c1 = Color("#333")
			c2 = Color("#2a2a2a")
		# Approximate the 45° striped pattern with diagonal lines.
		draw_rect(rect, c2)
		var step := 16.0
		for offset in range(-int(size.y), int(size.x + size.y), int(step)):
			draw_line(Vector2(offset, 0), Vector2(offset + size.y, size.y), c1, 8)
		_round_rect_outline(rect, WF.BORDER_LITE if not dark else Color("#555"), 12, 2.0)
	func _round_rect_outline(rect: Rect2, color: Color, radius: float, width: float) -> void:
		var r: float = minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
		draw_line(rect.position + Vector2(r, 0), rect.position + Vector2(rect.size.x - r, 0), color, width)
		draw_line(rect.position + Vector2(r, rect.size.y), rect.position + Vector2(rect.size.x - r, rect.size.y), color, width)
		draw_line(rect.position + Vector2(0, r), rect.position + Vector2(0, rect.size.y - r), color, width)
		draw_line(rect.position + Vector2(rect.size.x, r), rect.position + Vector2(rect.size.x, rect.size.y - r), color, width)

# ---- note (yellow left-bar italic) ----
static func note(text: String, color: Color = WARN) -> Control:
	var wrap := MarginContainer.new()
	wrap.add_theme_constant_override("margin_left", 8)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	wrap.add_child(row)
	var bar := ColorRect.new()
	bar.color = color
	bar.custom_minimum_size = Vector2(3, 0)
	bar.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_child(bar)
	var lbl := make_label(text, 15, color)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(lbl)
	return wrap

# ---- pill / badge ----
static func pill(text: String, fg: Color = ACCENT, bg: Color = ACCENT_BG) -> Control:
	var wrap := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(20)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	wrap.add_theme_stylebox_override("panel", sb)
	wrap.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	wrap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var lbl := make_label(text, 14, fg, true)
	wrap.add_child(lbl)
	return wrap

# ---- divider with optional label ----
static func divr(label_text: String = "") -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var l := ColorRect.new()
	l.color = BORDER_LITE
	l.custom_minimum_size = Vector2(0, 1)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	if not label_text.is_empty():
		var lbl := make_label(label_text, 13, MUTED)
		row.add_child(lbl)
	var r := ColorRect.new()
	r.color = BORDER_LITE
	r.custom_minimum_size = Vector2(0, 1)
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(r)
	return row

# ---- audio ctrl ----
static func audio_ctrl(playing: bool = false) -> Control:
	var wrap := PanelContainer.new()
	wrap.add_theme_stylebox_override("panel", sketch_box(PAPER, BORDER_LITE, 2, 16))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	wrap.add_child(row)
	var play := Panel.new()
	play.custom_minimum_size = Vector2(44, 44)
	var psb := StyleBoxFlat.new()
	psb.bg_color = ACCENT
	psb.set_corner_radius_all(22)
	play.add_theme_stylebox_override("panel", psb)
	var glyph := make_label("⏸" if playing else "▶", 22, Color.WHITE, true)
	glyph.set_anchors_preset(Control.PRESET_FULL_RECT)
	glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	play.add_child(glyph)
	row.add_child(play)
	var bar_holder := Control.new()
	bar_holder.custom_minimum_size = Vector2(0, 8)
	bar_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar_holder.add_child(_HPBarCanvas.new(0.6 if playing else 0.0, ACCENT, 6))
	row.add_child(bar_holder)
	row.add_child(make_label("Replay", 14, MUTED))
	return wrap

# ---- wave tag ----
static func wave_tag(num: int) -> Control:
	return pill("Wave %d" % num, PURPLE, PURPLE_BG)

# ---- avatar (circular) ----
static func avatar(label_text: String = "", size_px: int = 48, enemy: bool = false, color: Color = Color(0,0,0,0)) -> Control:
	var col_v := VBoxContainer.new()
	col_v.alignment = BoxContainer.ALIGNMENT_CENTER
	col_v.add_theme_constant_override("separation", 2)
	var c := color if color.a > 0 else (DANGER if enemy else ACCENT)
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(size_px, size_px)
	holder.add_child(_AvatarCanvas.new(size_px, c, enemy))
	holder.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col_v.add_child(holder)
	if not label_text.is_empty():
		col_v.add_child(make_label(label_text, 13, TEXT, true))
	return col_v

class _AvatarCanvas extends Control:
	var size_px: int
	var color: Color
	var enemy: bool
	func _init(sz: int, c: Color, e: bool) -> void:
		size_px = sz; color = c; enemy = e
		custom_minimum_size = Vector2(sz, sz)
	func _draw() -> void:
		var center := size * 0.5
		var r: float = size_px * 0.5 - 2
		draw_circle(center, r, WF.DANGER_BG if enemy else WF.ACCENT_BG)
		draw_arc(center, r, 0, TAU, 64, color, 2.5, true)
		var f := WF.font_bold()
		var fs := int(size_px * 0.45)
		var emoji := "👾" if enemy else "🧑"
		var ts := f.get_string_size(emoji, HORIZONTAL_ALIGNMENT_CENTER, -1, fs)
		draw_string(f, center - ts * 0.5 + Vector2(0, fs * 0.36),
			emoji, HORIZONTAL_ALIGNMENT_CENTER, -1, fs, WF.TEXT)

# ---- streak dots ----
static func streak_dots(count: int, max_count: int = 4) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	for i in max_count:
		var dot := Panel.new()
		dot.custom_minimum_size = Vector2(10, 10)
		var sb := StyleBoxFlat.new()
		sb.bg_color = SUCCESS if i < count else Color("#dddddd")
		sb.set_corner_radius_all(5)
		sb.set_border_width_all(1)
		sb.border_color = SUCCESS if i < count else BORDER_LITE
		dot.add_theme_stylebox_override("panel", sb)
		row.add_child(dot)
	row.add_child(make_label("streak", 12, MUTED))
	return row

# ---- screen label (small ALL CAPS caption above artboards) ----
static func screen_label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 13)
	l.add_theme_color_override("font_color", MUTED)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l

# ---- card panel (paper, light border, rounded) ----
static func card(bg: Color = PAPER, border: Color = BORDER_LITE, padding: int = 12, radius: int = 14, border_w: int = 2) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = padding
	sb.content_margin_right = padding
	sb.content_margin_top = padding
	sb.content_margin_bottom = padding
	p.add_theme_stylebox_override("panel", sb)
	return p

# ---- rainbow logo block (used on splash) ----
static func rainbow_block(letter: String, sz: int = 100, radius: int = 24) -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(sz, sz)
	holder.add_child(_RainbowBlock.new(sz, letter, radius))
	return holder

class _RainbowBlock extends Control:
	var sz: int
	var letter: String
	var radius: int
	func _init(s: int, l: String, r: int) -> void:
		sz = s; letter = l; radius = r
		custom_minimum_size = Vector2(s, s)
	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, Vector2(sz, sz))
		var colors := [
			Color("#FF6B6B"), Color("#FFD93D"), Color("#6BCB77"),
			Color("#4D96FF"), Color("#9B59B6"),
		]
		# Diagonal gradient bands.
		var step := sz / float(colors.size())
		for i in colors.size():
			draw_rect(Rect2(Vector2(0, i * step), Vector2(sz, step + 1)), colors[i])
		# 2px border
		draw_rect(rect, WF.BORDER, false, 3.0)
		var f := WF.font_bold()
		var fs := int(sz * 0.5)
		var ts := f.get_string_size(letter, HORIZONTAL_ALIGNMENT_CENTER, -1, fs)
		draw_string(f, Vector2(sz, sz) * 0.5 - ts * 0.5 + Vector2(0, fs * 0.36),
			letter, HORIZONTAL_ALIGNMENT_CENTER, -1, fs, Color.WHITE)
