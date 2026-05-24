extends Control
## Difficulty mode selection — cozy warm design with big emoji icons.

const TEXT := Color("#1C1917")
const TEXT_SEC := Color("#78716C")
const SURFACE := Color("#ffffff")
const BORDER := Color("#E7E5E4")

const INT_COLOR := Color("#22C55E")
const INT_BORDER := Color("#86EFAC")
const INT_BG := Color("#DCFCE7")
const INT_DARK := Color("#16A34A")
const INT_GLOW := Color(0.13, 0.77, 0.37, 0.5)

const ADV_COLOR := Color("#F97316")
const ADV_BORDER := Color("#FDBA74")
const ADV_BG := Color("#FFEDD5")
const ADV_DARK := Color("#EA580C")
const ADV_GLOW := Color(0.98, 0.45, 0.09, 0.5)

@onready var greet: Label = $V/Greet
@onready var sub: Label = $V/Sub
@onready var cards_row: HBoxContainer = $V/Cards
@onready var tip: PanelContainer = $V/Tip

var _int_card: Button
var _adv_card: Button
var _int_refs: Dictionary = {}
var _adv_refs: Dictionary = {}

func _ready() -> void:
	# Warm gradient backdrop.
	var bg := _GradientBG.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	move_child(bg, 0)

	# Confetti dots.
	var dots_data := [
		{"x": 0.06, "y": 0.06, "c": Color("#FB7185"), "s": 16},
		{"x": 0.82, "y": 0.12, "c": Color("#4ADE80"), "s": 13},
		{"x": 0.50, "y": 0.04, "c": Color("#A78BFA"), "s": 11},
		{"x": 0.94, "y": 0.40, "c": Color("#FB923C"), "s": 14},
		{"x": 0.04, "y": 0.48, "c": Color("#22D3EE"), "s": 10},
		{"x": 0.90, "y": 0.85, "c": Color("#60A5FA"), "s": 12},
		{"x": 0.08, "y": 0.78, "c": Color("#FBBF24"), "s": 13},
		{"x": 0.50, "y": 0.92, "c": Color("#F472B6"), "s": 10},
		{"x": 0.35, "y": 0.06, "c": Color("#34D399"), "s": 9},
	]
	for d: Dictionary in dots_data:
		var dot := _ConfettiDot.new()
		dot.dot_color = d.c as Color
		dot.dot_size = float(d.s)
		dot.rel_x = float(d.x)
		dot.rel_y = float(d.y)
		add_child(dot)
		move_child(dot, 1)

	# VBox vertical centering — push content to center.
	var v := $V as VBoxContainer
	v.alignment = BoxContainer.ALIGNMENT_CENTER

	cards_row.size_flags_vertical = Control.SIZE_FILL

	var who := GameState.player_name if not GameState.player_name.is_empty() else "there"
	greet.text = "Hi, %s!" % who
	greet.add_theme_font_size_override("font_size", 36)
	greet.add_theme_color_override("font_color", TEXT)
	greet.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prepend_icon_to_label(greet, "res://assets/icons/wave.svg", Color.WHITE, 30)
	sub.text = "Choose your difficulty"
	sub.add_theme_font_size_override("font_size", 16)
	sub.add_theme_color_override("font_color", TEXT_SEC)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	cards_row.add_theme_constant_override("separation", 14)
	_int_card = _make_card("Intermediate", "Building confidence", "1.0",
		INT_COLOR, INT_DARK, INT_BORDER, INT_BG, INT_GLOW,
		"leaf", GameState.Mode.INTERMEDIATE, _int_refs)
	_adv_card = _make_card("Advanced", "For word masters", "2.0",
		ADV_COLOR, ADV_DARK, ADV_BORDER, ADV_BG, ADV_GLOW,
		"fire", GameState.Mode.ADVANCED, _adv_refs)
	cards_row.add_child(_int_card)
	cards_row.add_child(_adv_card)

	_style_tip()

func _make_card(title_text: String, tagline: String, mult: String,
		color: Color, dark: Color, border: Color, bg_color: Color,
		glow: Color, icon_name: String, mode_val: int, refs: Dictionary) -> Button:
	var btn := Button.new()
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
	btn.text = ""
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(0, 220)
	btn.pressed.connect(func():
		_select_card(btn, refs, color, glow, mode_val))

	var idle := StyleBoxFlat.new()
	idle.bg_color = bg_color.lerp(Color.WHITE, 0.55)
	idle.set_corner_radius_all(22)
	idle.set_border_width_all(2)
	idle.border_color = border
	idle.shadow_color = Color(color.r, color.g, color.b, 0.15)
	idle.shadow_size = 12
	idle.shadow_offset = Vector2i(0, 4)

	var pressed_sb := idle.duplicate() as StyleBoxFlat
	pressed_sb.bg_color = bg_color
	pressed_sb.shadow_size = 6

	btn.add_theme_stylebox_override("normal", idle)
	btn.add_theme_stylebox_override("hover", idle)
	btn.add_theme_stylebox_override("pressed", pressed_sb)
	btn.add_theme_stylebox_override("focus", idle)
	btn.add_theme_stylebox_override("disabled", idle)

	var content := VBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 16
	content.offset_top = 24
	content.offset_right = -16
	content.offset_bottom = -20
	content.add_theme_constant_override("separation", 6)
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	btn.add_child(content)

	# Top spacer to push icon toward center-ish.
	var top_sp := Control.new()
	top_sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	top_sp.custom_minimum_size = Vector2(0, 4)
	content.add_child(top_sp)

	# Icon with glow backdrop.
	var icon_path := "res://assets/icons/%s.svg" % icon_name
	if ResourceLoader.exists(icon_path):
		var icon_host := CenterContainer.new()
		icon_host.custom_minimum_size = Vector2(80, 80)
		icon_host.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		icon_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var glow_circle := _GlowCircle.new()
		glow_circle.glow_color = Color(color.r, color.g, color.b, 0.2)
		glow_circle.set_anchors_preset(Control.PRESET_FULL_RECT)
		glow_circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_host.add_child(glow_circle)
		var tex := TextureRect.new()
		tex.texture = load(icon_path)
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.custom_minimum_size = Vector2(72, 72)
		tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_host.add_child(tex)
		content.add_child(icon_host)
		refs["icon"] = tex

	# Title.
	var title := Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", dark)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(title)
	refs["title"] = title

	# Tagline.
	var tag := Label.new()
	tag.text = tagline
	tag.add_theme_font_size_override("font_size", 13)
	tag.add_theme_color_override("font_color", Color(dark.r, dark.g, dark.b, 0.7))
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(tag)
	refs["tagline"] = tag

	# Bottom spacer.
	var bot_sp := Control.new()
	bot_sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bot_sp.custom_minimum_size = Vector2(0, 4)
	content.add_child(bot_sp)

	# Multiplier pill.
	var chip := PanelContainer.new()
	var chip_sb := StyleBoxFlat.new()
	chip_sb.bg_color = bg_color
	chip_sb.set_corner_radius_all(100)
	chip_sb.set_border_width_all(1)
	chip_sb.border_color = border
	chip_sb.content_margin_left = 20
	chip_sb.content_margin_right = 20
	chip_sb.content_margin_top = 8
	chip_sb.content_margin_bottom = 8
	chip.add_theme_stylebox_override("panel", chip_sb)
	chip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var chip_lbl := Label.new()
	chip_lbl.text = "x%s multiplier" % mult
	chip_lbl.add_theme_color_override("font_color", dark)
	chip_lbl.add_theme_font_size_override("font_size", 15)
	chip_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chip.add_child(chip_lbl)
	content.add_child(chip)

	refs["chip_sb"] = chip_sb
	refs["chip_lbl"] = chip_lbl
	refs["idle_sb"] = idle
	refs["color"] = color
	refs["dark"] = dark
	refs["border"] = border
	refs["bg_color"] = bg_color
	refs["glow"] = glow

	return btn

func _select_card(btn: Button, refs: Dictionary, color: Color, glow: Color, mode_val: int) -> void:
	var sb := (refs["idle_sb"] as StyleBoxFlat).duplicate() as StyleBoxFlat
	sb.bg_color = refs["bg_color"] as Color
	sb.border_color = refs["border"] as Color
	sb.set_border_width_all(2)
	sb.shadow_color = glow
	sb.shadow_size = 16
	sb.shadow_offset = Vector2i(0, 4)
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb)
	btn.add_theme_stylebox_override("pressed", sb)
	btn.add_theme_stylebox_override("disabled", sb)

	(refs["title"] as Label).add_theme_color_override("font_color", color)

	var chip_sb := refs["chip_sb"] as StyleBoxFlat
	chip_sb.bg_color = refs["bg_color"] as Color
	chip_sb.border_color = refs["border"] as Color
	var chip_lbl := refs["chip_lbl"] as Label
	chip_lbl.add_theme_color_override("font_color", refs["dark"] as Color)

	btn.pivot_offset = btn.size * 0.5
	var tw := btn.create_tween()
	tw.tween_property(btn, "scale", Vector2(1.04, 1.04), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	_int_card.disabled = true
	_adv_card.disabled = true

	GameState.set_mode(mode_val)
	await get_tree().create_timer(0.7).timeout
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _style_tip() -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#FEFCE8")
	sb.set_corner_radius_all(16)
	sb.set_border_width_all(1)
	sb.border_color = Color("#FDE68A")
	sb.shadow_color = Color(0, 0, 0, 0.04)
	sb.shadow_size = 2
	sb.shadow_offset = Vector2i(0, 1)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 14
	sb.content_margin_bottom = 14
	tip.add_theme_stylebox_override("panel", sb)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	tip.add_child(row)
	var bulb_path := "res://assets/icons/bulb.svg"
	if ResourceLoader.exists(bulb_path):
		var bulb := TextureRect.new()
		bulb.texture = load(bulb_path)
		bulb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		bulb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bulb.custom_minimum_size = Vector2(22, 22)
		bulb.modulate = Color.WHITE
		bulb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		bulb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(bulb)
	var t := Label.new()
	t.text = "Not sure? Start with Intermediate — you can switch anytime in Settings."
	t.add_theme_font_size_override("font_size", 13)
	t.add_theme_color_override("font_color", Color("#92400E"))
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(t)

func _prepend_icon_to_label(lbl: Label, icon_path: String, tint: Color, size_px: int) -> void:
	if not ResourceLoader.exists(icon_path):
		return
	var parent := lbl.get_parent() as Control
	if parent == null:
		return
	var idx := lbl.get_index()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	parent.add_child(row)
	parent.move_child(row, idx)
	lbl.reparent(row, false)
	var icon := TextureRect.new()
	icon.texture = load(icon_path)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.custom_minimum_size = Vector2(size_px, size_px)
	icon.modulate = tint
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)

class _GradientBG extends Control:
	func _draw() -> void:
		var c1 := Color("#FFF9EC")
		var c2 := Color("#FEF3C7")
		var c3 := Color("#F0FAF0")
		var h := size.y
		if h <= 0:
			return
		var bands := 32
		for i in bands:
			var t0 := float(i) / float(bands)
			var t1 := float(i + 1) / float(bands)
			var mid := (t0 + t1) * 0.5
			var c: Color
			if mid < 0.45:
				c = c1.lerp(c2, mid / 0.45)
			else:
				c = c2.lerp(c3, (mid - 0.45) / 0.55)
			draw_rect(Rect2(0, h * t0, size.x, h * (t1 - t0) + 1), c)

class _GlowCircle extends Control:
	var glow_color := Color(0.2, 0.8, 0.4, 0.2)
	func _draw() -> void:
		var center := size * 0.5
		var r := minf(size.x, size.y) * 0.5
		for i in 8:
			var t := float(i) / 7.0
			var cr := r * (1.0 - t * 0.6)
			var a := glow_color.a * (1.0 - t * 0.8)
			draw_circle(center, cr, Color(glow_color.r, glow_color.g, glow_color.b, a))

class _ConfettiDot extends Control:
	var dot_color := Color.WHITE
	var dot_size := 10.0
	var rel_x := 0.0
	var rel_y := 0.0
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_anchors_preset(Control.PRESET_FULL_RECT)
	func _draw() -> void:
		var pos := Vector2(size.x * rel_x, size.y * rel_y)
		draw_circle(pos, dot_size * 0.5, Color(dot_color.r, dot_color.g, dot_color.b, 0.6))
