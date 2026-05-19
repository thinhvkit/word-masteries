extends Control
## Welcome / splash screen — matches Masteries Prototype screen 1.

const BG := Color("#faf5ed")
const TEXT := Color("#5a4840")
const TEXT_SEC := Color("#9a8a7e")
const SURFACE := Color("#ffffff")
const BORDER := Color("#ece4d8")
const PRIMARY := Color("#ff8faa")
const PRIMARY_DARK := Color("#e86888")

const DOT_COLORS := [
	"#6dd68a", "#ffc844", "#ff8844", "#7cc5e8",
	"#b88adf", "#6fc8b8", "#ff8faa",
]

const ICON_TEX := preload("res://assets/welcome_icon.svg")

func _ready() -> void:
	_build()

func _build() -> void:
	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Centered column with a fixed max width so it reads on tablet too.
	var col := VBoxContainer.new()
	col.anchor_left = 0.5
	col.anchor_right = 0.5
	col.anchor_top = 0.0
	col.anchor_bottom = 1.0
	col.offset_left = -170
	col.offset_right = 170
	col.offset_top = 0
	col.offset_bottom = 0
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 0)
	add_child(col)

	# Icon: gradient-rounded-square with white M (asset matches the design).
	var icon := TextureRect.new()
	icon.texture = ICON_TEX
	icon.custom_minimum_size = Vector2(140, 140)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(icon)

	col.add_child(_spacer(20))

	var title := Label.new()
	title.text = "Masteries"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", TEXT)
	col.add_child(title)

	col.add_child(_spacer(8))

	var tagline := Label.new()
	tagline.text = "Level up your words."
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tagline.add_theme_font_size_override("font_size", 16)
	tagline.add_theme_color_override("font_color", TEXT_SEC)
	col.add_child(tagline)

	col.add_child(_spacer(14))

	col.add_child(_build_dots())

	col.add_child(_spacer(56))

	# Primary CTA — pink pill.
	var cta := Button.new()
	cta.text = "Get Started"
	cta.custom_minimum_size = Vector2(0, 56)
	cta.focus_mode = Control.FOCUS_NONE
	cta.add_theme_font_size_override("font_size", 17)
	cta.add_theme_color_override("font_color", Color.WHITE)
	cta.add_theme_color_override("font_hover_color", Color.WHITE)
	cta.add_theme_color_override("font_pressed_color", Color.WHITE)
	_apply_pill(cta, PRIMARY, PRIMARY_DARK)
	cta.pressed.connect(_on_get_started)
	col.add_child(cta)

	col.add_child(_spacer(14))

	# Secondary — log-in card.
	var login_card := Button.new()
	login_card.custom_minimum_size = Vector2(0, 76)
	login_card.focus_mode = Control.FOCUS_NONE
	_apply_card(login_card)
	login_card.pressed.connect(_on_login)
	col.add_child(login_card)

	# Two-line label stacked inside the card.
	var label_box := VBoxContainer.new()
	label_box.anchor_left = 0.0
	label_box.anchor_right = 1.0
	label_box.anchor_top = 0.0
	label_box.anchor_bottom = 1.0
	label_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label_box.alignment = BoxContainer.ALIGNMENT_CENTER
	label_box.add_theme_constant_override("separation", 2)
	login_card.add_child(label_box)

	var prompt := Label.new()
	prompt.text = "Already have an account?"
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 14)
	prompt.add_theme_color_override("font_color", TEXT_SEC)
	label_box.add_child(prompt)

	var login_lbl := Label.new()
	login_lbl.text = "Log in"
	login_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	login_lbl.add_theme_font_size_override("font_size", 17)
	login_lbl.add_theme_color_override("font_color", TEXT)
	label_box.add_child(login_lbl)

func _build_dots() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	for hex in DOT_COLORS:
		row.add_child(_Dot.new_with(Color(hex)))
	return row

func _spacer(h: int) -> Control:
	var s := Control.new()
	s.custom_minimum_size = Vector2(0, h)
	return s

func _apply_pill(btn: Button, fill: Color, shadow_color: Color) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.set_corner_radius_all(28)
	sb.shadow_color = Color(shadow_color.r, shadow_color.g, shadow_color.b, 0.35)
	sb.shadow_size = 6
	sb.shadow_offset = Vector2i(0, 3)
	sb.content_margin_left = 24
	sb.content_margin_right = 24
	sb.content_margin_top = 14
	sb.content_margin_bottom = 14
	var press := sb.duplicate() as StyleBoxFlat
	press.bg_color = fill.darkened(0.05)
	press.shadow_size = 2
	press.shadow_offset = Vector2i(0, 1)
	press.content_margin_top = 16
	press.content_margin_bottom = 12
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb)
	btn.add_theme_stylebox_override("pressed", press)
	btn.add_theme_stylebox_override("focus", sb)

func _apply_card(btn: Button) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = SURFACE
	sb.set_corner_radius_all(20)
	sb.set_border_width_all(1)
	sb.border_color = BORDER
	sb.shadow_color = Color(0, 0, 0, 0.06)
	sb.shadow_size = 8
	sb.shadow_offset = Vector2i(0, 2)
	var press := sb.duplicate() as StyleBoxFlat
	press.bg_color = Color("#f7f0e6")
	press.shadow_size = 2
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb)
	btn.add_theme_stylebox_override("pressed", press)
	btn.add_theme_stylebox_override("focus", sb)

func _on_get_started() -> void:
	get_tree().change_scene_to_file("res://scenes/login.tscn")

func _on_login() -> void:
	# No auth yet — for now route the same place.
	get_tree().change_scene_to_file("res://scenes/login.tscn")

class _Dot extends Control:
	var color: Color = Color.WHITE
	static func new_with(c: Color) -> _Dot:
		var d := _Dot.new()
		d.color = c
		return d
	func _ready() -> void:
		custom_minimum_size = Vector2(10, 10)
	func _draw() -> void:
		draw_circle(size * 0.5, 5, color)
