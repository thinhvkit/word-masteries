@tool
class_name MasteriesButton
extends Button
## Cozy chunky button (Forest-Match style): rounded, soft drop shadow.
## On press the button "settles" — shadow shrinks and content shifts down 2px.

@export var color: Color = Color("#ff8faa") :
	set(v):
		color = v
		_rebuild_styles()

@export var corner_radius: int = 14 :
	set(v):
		corner_radius = v
		_rebuild_styles()

func _ready() -> void:
	custom_minimum_size.y = 52
	add_theme_font_size_override("font_size", 17)
	add_theme_color_override("font_color", Color.WHITE)
	add_theme_color_override("font_hover_color", Color.WHITE)
	add_theme_color_override("font_pressed_color", Color.WHITE)
	add_theme_color_override("font_focus_color", Color.WHITE)
	_rebuild_styles()

func _rebuild_styles() -> void:
	if not is_inside_tree() and not Engine.is_editor_hint():
		return
	add_theme_stylebox_override("normal", Palette.chunky_button_stylebox(color, corner_radius))
	add_theme_stylebox_override("hover", Palette.chunky_button_hover(color, corner_radius))
	add_theme_stylebox_override("pressed", Palette.chunky_button_pressed(color, corner_radius))
	var focus := Palette.chunky_button_stylebox(color, corner_radius)
	focus.border_color = Palette.GOLD
	focus.set_border_width_all(2)
	add_theme_stylebox_override("focus", focus)
	var disabled := Palette.chunky_button_stylebox(Palette.HAIRLINE, corner_radius)
	add_theme_stylebox_override("disabled", disabled)
