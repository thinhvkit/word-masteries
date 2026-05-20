extends Control
## Difficulty mode selection (Masteries kit screen 3).
## Two side-by-side cards (Intermediate green, Advanced coral) + a tip card.

const TEXT := Color("#5a4840")
const TEXT_SEC := Color("#9a8a7e")
const SURFACE := Color("#ffffff")
const BORDER := Color("#e8e0d8")
# Intermediate: sage (cozy success green).
const GREEN := Color("#6dd68a")
const GREEN_DARK := Color("#4fb86b")
const GREEN_LIGHT := Color("#e0f4d8")
# Advanced: mushroom (warm orange).
const CORAL := Color("#ff8844")
const CORAL_DARK := Color("#d96624")
const CORAL_LIGHT := Color("#ffe2cf")

const INTERMEDIATE := {
	"title": "Intermediate",
	"sub": "For learners building confidence",
	"bullets": [
		"3-4 letter word targets",
		"Shorter, simpler prompts",
		"Beginner-friendly vocabulary",
	],
	"mult": "1.0",
}

const ADVANCED := {
	"title": "Advanced",
	"sub": "For confident English users",
	"bullets": [
		"5-6 letter word targets",
		"Complex grammar & forms",
		"Harder vocabulary + scoring",
	],
	"mult": "2.0",
}

const BG := Color("#faf5ed")

@onready var greet: Label = $V/Greet
@onready var sub: Label = $V/Sub
@onready var cards_row: HBoxContainer = $V/Cards
@onready var tip: PanelContainer = $V/Tip

func _ready() -> void:
	# Cream backdrop to match the welcome screen.
	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	move_child(bg, 0)

	# Don't let the card row eat the remaining vertical space — keep cards compact.
	cards_row.size_flags_vertical = Control.SIZE_FILL

	var who := GameState.player_name if not GameState.player_name.is_empty() else "there"
	greet.text = "Hi, %s!" % who
	greet.add_theme_font_size_override("font_size", 28)
	greet.add_theme_color_override("font_color", TEXT)
	_prepend_icon_to_label(greet, "res://assets/icons/wave.svg", TEXT, 22)
	sub.text = "Choose your difficulty. This applies to all games."
	sub.add_theme_font_size_override("font_size", 15)
	sub.add_theme_color_override("font_color", TEXT_SEC)
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	cards_row.add_theme_constant_override("separation", 14)
	cards_row.add_child(_make_card(INTERMEDIATE, GREEN, GREEN_DARK, GREEN_LIGHT, GameState.Mode.INTERMEDIATE))
	cards_row.add_child(_make_card(ADVANCED, CORAL, CORAL_DARK, CORAL_LIGHT, GameState.Mode.ADVANCED))

	_style_tip()

func _make_card(data: Dictionary, color: Color, dark: Color, light: Color, mode_val: int) -> Control:
	var btn := Button.new()
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
	btn.text = ""
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(0, 260)
	btn.pressed.connect(func():
		GameState.set_mode(mode_val)
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))

	var idle := StyleBoxFlat.new()
	idle.bg_color = SURFACE
	idle.set_corner_radius_all(22)
	idle.set_border_width_all(2)
	idle.border_color = BORDER
	idle.shadow_color = Color(0, 0, 0, 0.10)
	idle.shadow_size = 6
	idle.shadow_offset = Vector2i(0, 3)

	var active := idle.duplicate() as StyleBoxFlat
	active.bg_color = color
	active.border_color = dark
	active.shadow_color = Color(0, 0, 0, 0.18)
	active.shadow_size = 10
	active.shadow_offset = Vector2i(0, 4)

	btn.add_theme_stylebox_override("normal", idle)
	btn.add_theme_stylebox_override("hover", active)
	btn.add_theme_stylebox_override("pressed", active)
	btn.add_theme_stylebox_override("focus", idle)

	var content := VBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 18
	content.offset_top = 22
	content.offset_right = -18
	content.offset_bottom = -18
	content.add_theme_constant_override("separation", 8)
	btn.add_child(content)

	var title := Label.new()
	title.text = data.title
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", TEXT)
	content.add_child(title)

	var sub_lbl := Label.new()
	sub_lbl.text = data.sub
	sub_lbl.add_theme_font_size_override("font_size", 12)
	sub_lbl.add_theme_color_override("font_color", TEXT_SEC)
	sub_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(sub_lbl)

	var bullets_box := VBoxContainer.new()
	bullets_box.add_theme_constant_override("separation", 6)
	content.add_child(bullets_box)
	var bullet_labels: Array[Label] = []
	for line: String in data.bullets:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var dot := _Dot.new()
		dot.color = color
		row.add_child(dot)
		var lbl := Label.new()
		lbl.text = line
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.add_theme_color_override("font_color", TEXT)
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(lbl)
		bullets_box.add_child(row)
		bullet_labels.append(lbl)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(spacer)

	var chip := PanelContainer.new()
	var chip_sb := StyleBoxFlat.new()
	chip_sb.bg_color = light
	chip_sb.corner_radius_top_left = 12
	chip_sb.corner_radius_top_right = 12
	chip_sb.corner_radius_bottom_left = 12
	chip_sb.corner_radius_bottom_right = 12
	chip_sb.content_margin_top = 6
	chip_sb.content_margin_bottom = 6
	chip.add_theme_stylebox_override("panel", chip_sb)
	var chip_lbl := Label.new()
	chip_lbl.text = "× %s multiplier" % data.mult
	chip_lbl.add_theme_color_override("font_color", dark)
	chip_lbl.add_theme_font_size_override("font_size", 16)
	chip_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chip.add_child(chip_lbl)
	content.add_child(chip)

	btn.mouse_entered.connect(func(): _set_card_active(title, sub_lbl, bullet_labels, chip_sb, chip_lbl, true, light, dark))
	btn.mouse_exited.connect(func(): _set_card_active(title, sub_lbl, bullet_labels, chip_sb, chip_lbl, false, light, dark))

	return btn

func _set_card_active(title: Label, sub_lbl: Label, bullets: Array[Label], chip_sb: StyleBoxFlat, chip_lbl: Label, active: bool, light: Color, dark: Color) -> void:
	if active:
		title.add_theme_color_override("font_color", Color.WHITE)
		sub_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
		for b in bullets:
			b.add_theme_color_override("font_color", Color(1, 1, 1, 0.92))
		chip_sb.bg_color = Color(1, 1, 1, 0.22)
		chip_lbl.add_theme_color_override("font_color", Color.WHITE)
	else:
		title.add_theme_color_override("font_color", TEXT)
		sub_lbl.add_theme_color_override("font_color", TEXT_SEC)
		for b in bullets:
			b.add_theme_color_override("font_color", TEXT)
		chip_sb.bg_color = light
		chip_lbl.add_theme_color_override("font_color", dark)

func _style_tip() -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#fff1c4")  # gold-tint card
	sb.set_corner_radius_all(16)
	sb.set_border_width_all(1)
	sb.border_color = Color("#f0d890")
	sb.shadow_color = Color(0, 0, 0, 0.08)
	sb.shadow_size = 3
	sb.shadow_offset = Vector2i(0, 1)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
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
		bulb.modulate = TEXT
		bulb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		bulb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(bulb)
	var t := Label.new()
	t.text = "Not sure? Start with Intermediate — you can switch anytime in Settings."
	t.add_theme_font_size_override("font_size", 13)
	t.add_theme_color_override("font_color", TEXT_SEC)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(t)

func _prepend_icon_to_label(lbl: Label, icon_path: String, tint: Color, size_px: int) -> void:
	# Reparent the label into a centered HBox alongside a tinted SVG icon.
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

class _Dot extends Control:
	var color: Color = Color.WHITE :
		set(v):
			color = v
			queue_redraw()
	func _ready() -> void:
		custom_minimum_size = Vector2(6, 6)
		size = Vector2(6, 6)
	func _draw() -> void:
		draw_circle(size * 0.5, 3, color)
