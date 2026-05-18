extends Control
## Splash + Username combined (Masteries kit screens 1+2).

const AVATARS := ["🦊","🦋","🐸","🦁","🦜","🐙","🐬","🐼"]
const DOT_COLORS := [
	"#6dd68a", "#ffc844", "#ff8844", "#7cc5e8",
	"#b88adf", "#6fc8b8", "#ff8faa",
]
const TEXT := Color("#5a4840")
const TEXT_SEC := Color("#9a8a7e")
const SURFACE := Color("#ffffff")
const BORDER := Color("#e8e0d8")
# Primary accent — pink instead of Duolingo green.
const PRIMARY := Color("#ff8faa")
const PRIMARY_DARK := Color("#e86888")
# Legacy names so the rest of the file (avatars + button factories) compiles unchanged.
const GREEN := PRIMARY
const GREEN_DARK := PRIMARY_DARK

@onready var mascot_holder: Control = $V/Top/Mascot
@onready var title_lbl: Label = $V/Top/Title
@onready var tagline_lbl: Label = $V/Top/Tagline
@onready var dots_row: HBoxContainer = $V/Top/Dots
@onready var avatars_grid: GridContainer = $V/Avatars
@onready var name_field: PanelContainer = $V/NameField
@onready var name_edit: LineEdit = $V/NameField/Edit
@onready var continue_btn: Button = $V/Continue

var _avatar_idx: int = 0
var _name_sb: StyleBoxFlat
var _avatar_btns: Array[Control] = []

func _ready() -> void:
	_build_mascot()
	_style_title()
	_build_dots()
	_build_avatars()
	_style_name_field()
	_style_continue()
	if not GameState.player_name.is_empty():
		name_edit.text = GameState.player_name
		_refresh_name()
	name_edit.text_changed.connect(func(_t): _refresh_name())
	name_edit.text_submitted.connect(func(_t): _try_continue())
	continue_btn.pressed.connect(_try_continue)

func _build_mascot() -> void:
	var MascotScript := preload("res://scripts/wriggles.gd")
	var m := MascotScript.new()
	m.draw_size = 130.0
	mascot_holder.add_child(m)
	mascot_holder.custom_minimum_size = Vector2(0, 130 * 0.85 + 4)
	# Center horizontally inside its row.
	m.set_anchors_preset(Control.PRESET_CENTER_TOP)
	m.position = Vector2(-65, 0)

func _style_title() -> void:
	title_lbl.text = "Masteries"
	title_lbl.add_theme_font_size_override("font_size", 48)
	title_lbl.add_theme_color_override("font_color", TEXT)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tagline_lbl.text = "Level up your words."
	tagline_lbl.add_theme_font_size_override("font_size", 16)
	tagline_lbl.add_theme_color_override("font_color", TEXT_SEC)
	tagline_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _build_dots() -> void:
	dots_row.alignment = BoxContainer.ALIGNMENT_CENTER
	dots_row.add_theme_constant_override("separation", 8)
	for hex in DOT_COLORS:
		var d := _Dot.new()
		d.color = Color(hex)
		dots_row.add_child(d)

func _build_avatars() -> void:
	avatars_grid.columns = 4
	avatars_grid.add_theme_constant_override("h_separation", 10)
	avatars_grid.add_theme_constant_override("v_separation", 10)
	for i in AVATARS.size():
		var btn := _make_avatar(AVATARS[i], i)
		avatars_grid.add_child(btn)
		_avatar_btns.append(btn)
	_refresh_avatars()

func _make_avatar(emoji: String, idx: int) -> Control:
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 64)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.text = emoji
	b.add_theme_font_size_override("font_size", 28)
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(func():
		_avatar_idx = idx
		_refresh_avatars())
	return b

func _refresh_avatars() -> void:
	for i in _avatar_btns.size():
		var b := _avatar_btns[i] as Button
		var active := i == _avatar_idx
		var sb := StyleBoxFlat.new()
		sb.bg_color = PRIMARY if active else SURFACE
		sb.set_corner_radius_all(18)
		sb.set_border_width_all(2)
		sb.border_color = PRIMARY_DARK if active else BORDER
		sb.shadow_color = Color(0, 0, 0, 0.15 if active else 0.08)
		sb.shadow_size = 4 if active else 3
		sb.shadow_offset = Vector2i(0, 2 if active else 1)
		var press := sb.duplicate() as StyleBoxFlat
		press.shadow_size = 1
		press.shadow_offset = Vector2i(0, 0)
		press.content_margin_top = 2
		b.add_theme_stylebox_override("normal", sb)
		b.add_theme_stylebox_override("hover", sb)
		b.add_theme_stylebox_override("pressed", press)
		b.add_theme_stylebox_override("focus", sb)
		b.add_theme_color_override("font_color", Color.WHITE if active else TEXT)

func _style_name_field() -> void:
	_name_sb = StyleBoxFlat.new()
	_name_sb.bg_color = SURFACE
	_name_sb.corner_radius_top_left = 16
	_name_sb.corner_radius_top_right = 16
	_name_sb.corner_radius_bottom_left = 16
	_name_sb.corner_radius_bottom_right = 16
	_name_sb.border_width_left = 2
	_name_sb.border_width_right = 2
	_name_sb.border_width_top = 2
	_name_sb.border_width_bottom = 2
	_name_sb.border_color = BORDER
	_name_sb.content_margin_left = 16
	_name_sb.content_margin_right = 16
	_name_sb.content_margin_top = 0
	_name_sb.content_margin_bottom = 0
	name_field.add_theme_stylebox_override("panel", _name_sb)
	name_edit.placeholder_text = "Your display name"
	name_edit.add_theme_font_size_override("font_size", 16)
	name_edit.add_theme_color_override("font_color", TEXT)
	name_edit.add_theme_color_override("font_placeholder_color", TEXT_SEC)
	var transparent := StyleBoxEmpty.new()
	name_edit.add_theme_stylebox_override("normal", transparent)
	name_edit.add_theme_stylebox_override("focus", transparent)
	name_edit.add_theme_stylebox_override("read_only", transparent)

func _refresh_name() -> void:
	var has := not name_edit.text.strip_edges().is_empty()
	_name_sb.border_color = GREEN if has else BORDER
	continue_btn.disabled = not has

func _style_continue() -> void:
	continue_btn.custom_minimum_size = Vector2(0, 56)
	continue_btn.text = "Continue →"
	continue_btn.add_theme_font_size_override("font_size", 17)
	continue_btn.focus_mode = Control.FOCUS_NONE
	Palette.style_button(continue_btn, PRIMARY, Color.WHITE, 16)
	var disabled := Palette.chunky_button_stylebox(Color("#d8cdc0"), 16)
	continue_btn.add_theme_stylebox_override("disabled", disabled)
	continue_btn.add_theme_color_override("font_disabled_color", Color.WHITE)
	continue_btn.disabled = true

func _try_continue() -> void:
	var n := name_edit.text.strip_edges()
	if n.is_empty():
		return
	GameState.player_name = n
	GameState.save()
	get_tree().change_scene_to_file("res://scenes/mode_select.tscn")

class _Dot extends Control:
	var color: Color = Color.WHITE :
		set(v):
			color = v
			queue_redraw()
	func _ready() -> void:
		custom_minimum_size = Vector2(8, 8)
		size = Vector2(8, 8)
	func _draw() -> void:
		draw_circle(size * 0.5, 4, color)
