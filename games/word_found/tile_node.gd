class_name WFoundTile
extends Control
## Word Found letter tile. Three states:
## - available: white surface, brown ink, soft drop shadow
## - moved:     pink fill, white ink (currently in Row 2, can be returned)
## - used:      cream-soft fill, faded ink, no shadow (consumed by a submit)

signal pressed(tile: WFoundTile)

enum State { AVAILABLE, MOVED, USED }

const SIZE := 50.0
const RADIUS := 11.0

@export var letter: String = "A" :
	set(v):
		letter = v.to_upper()
		queue_redraw()

var state: int = State.AVAILABLE :
	set(v):
		state = v
		queue_redraw()

func _ready() -> void:
	custom_minimum_size = Vector2(SIZE, SIZE)
	size = Vector2(SIZE, SIZE)
	pivot_offset = size * 0.5
	mouse_filter = Control.MOUSE_FILTER_STOP

func _gui_input(event: InputEvent) -> void:
	if state == State.USED:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pressed.emit(self)
	elif event is InputEventScreenTouch and event.pressed:
		pressed.emit(self)

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	var fill := Palette.SURFACE
	var ink := Palette.TEXT
	var draw_shadow := true
	match state:
		State.MOVED:
			fill = Palette.PINK
			ink = Color.WHITE
		State.USED:
			fill = Palette.BG_SOFT
			ink = Color(Palette.TEXT.r, Palette.TEXT.g, Palette.TEXT.b, 0.35)
			draw_shadow = false

	if draw_shadow:
		_round_rect(Rect2(Vector2(0, 2), size), Color(0.35, 0.28, 0.24, 0.16), RADIUS)
	_round_rect(rect, fill, RADIUS)
	if state == State.AVAILABLE:
		_round_rect_outline(rect, Palette.HAIRLINE, RADIUS, 2.0)

	var f := ThemeDB.fallback_font
	var fs := 24
	var ts := f.get_string_size(letter, HORIZONTAL_ALIGNMENT_CENTER, -1, fs)
	draw_string(f, size * 0.5 - ts * 0.5 + Vector2(0, fs * 0.36),
		letter, HORIZONTAL_ALIGNMENT_CENTER, -1, fs, ink)

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
