class_name WMLetter
extends Control
## Word Match letter — cozy palette.
## Idle: white circle with warm-grey hairline + soft brown shadow + brown ink letter.
## Selected: pink fill, white letter, scale 1.08.

const SIZE := 64.0

@export var letter: String = "A" :
	set(v):
		letter = v.to_upper()
		queue_redraw()

var selected: bool = false :
	set(v):
		if selected == v: return
		selected = v
		_animate_select()
		queue_redraw()

func _ready() -> void:
	custom_minimum_size = Vector2(SIZE, SIZE)
	size = Vector2(SIZE, SIZE)
	pivot_offset = size * 0.5
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func contains_point(global_pos: Vector2) -> bool:
	var center := global_position + size * 0.5
	return global_pos.distance_to(center) <= SIZE * 0.5

func _animate_select() -> void:
	var target_scale := Vector2.ONE * (1.08 if selected else 1.0)
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", target_scale, 0.16)

func _draw() -> void:
	var center := size * 0.5
	var r := SIZE * 0.5 - 2
	# Soft drop shadow (warm)
	draw_circle(center + Vector2(0, 3), r, Color(0.35, 0.28, 0.24, 0.18))
	if selected:
		draw_circle(center, r, Palette.PINK)
		draw_arc(center, r - 1, 0, TAU, 64, Palette.PINK_DARK, 2.0, true)
		_draw_letter(center, Color.WHITE)
	else:
		draw_circle(center, r, Palette.SURFACE)
		draw_arc(center, r - 1, 0, TAU, 64, Palette.HAIRLINE, 2.0, true)
		_draw_letter(center, Palette.TEXT)

func _draw_letter(center: Vector2, col: Color) -> void:
	var f := ThemeDB.fallback_font
	var fs := 28
	var ts := f.get_string_size(letter, HORIZONTAL_ALIGNMENT_CENTER, -1, fs)
	var ascent := f.get_ascent(fs)
	var descent := f.get_descent(fs)
	draw_string(f, Vector2(center.x - ts.x * 0.5, center.y + (ascent - descent) * 0.5),
		letter, HORIZONTAL_ALIGNMENT_CENTER, -1, fs, col)
