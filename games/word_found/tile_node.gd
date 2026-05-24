class_name WFoundTile
extends Control
## Word Found letter tile — forest green dungeon theme.
## - AVAILABLE: bright green gradient, white text, green border.
## - MOVED:     darker olive green, selection order number in top-right.

const Fx := preload("res://games/word_fight/fx.gd")
const TILE_FONT: Font = preload("res://assets/fonts/LilitaOne-Regular.ttf")

signal pressed(tile: WFoundTile)
signal tile_picked_fx(tile: WFoundTile, color: Color)

enum State { AVAILABLE, MOVED }

const SIZE := 58.0
const RADIUS := 14.0

const GREEN_AVAIL_TOP := Color("#4a9e5a")
const GREEN_AVAIL_BOT := Color("#357a42")
const GREEN_AVAIL_BORDER := Color("#6bc47a")

const GREEN_MOVED_TOP := Color("#3a6830")
const GREEN_MOVED_BOT := Color("#2a4e22")
const GREEN_MOVED_BORDER := Color("#5a8a4a")

@export var letter: String = "A" :
	set(v):
		letter = v.to_upper()
		queue_redraw()

var state: int = State.AVAILABLE :
	set(v):
		var prev := state
		state = v
		_handle_state_change(prev, state)
		queue_redraw()

var selection_index: int = -1 :
	set(v):
		selection_index = v
		queue_redraw()

func _ready() -> void:
	custom_minimum_size = Vector2(SIZE, SIZE)
	size = Vector2(SIZE, SIZE)
	pivot_offset = size * 0.5
	mouse_filter = Control.MOUSE_FILTER_STOP

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pressed.emit(self)
	elif event is InputEventScreenTouch and event.pressed:
		pressed.emit(self)

func play_pop_in(delay: float = 0.0) -> void:
	scale = Vector2(0.2, 0.2)
	modulate.a = 0.0
	var tw := create_tween()
	if delay > 0.0:
		tw.tween_interval(delay)
	tw.set_parallel(true)
	tw.tween_property(self, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 1.0, 0.22)

func _handle_state_change(prev: int, now: int) -> void:
	if now == State.MOVED and prev != State.MOVED:
		var tw := create_tween()
		tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(self, "scale", Vector2(1.06, 1.06), 0.14)
		tile_picked_fx.emit(self, GREEN_AVAIL_BORDER)
	elif now == State.AVAILABLE:
		selection_index = -1
		var tw := create_tween()
		tw.tween_property(self, "scale", Vector2(1.0, 1.0), 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	var top: Color
	var bot: Color
	var border_col: Color
	if state == State.MOVED:
		top = GREEN_MOVED_TOP
		bot = GREEN_MOVED_BOT
		border_col = GREEN_MOVED_BORDER
	else:
		top = GREEN_AVAIL_TOP
		bot = GREEN_AVAIL_BOT
		border_col = GREEN_AVAIL_BORDER

	# Drop shadow.
	_round_rect(Rect2(Vector2(0, 4), size), Color(0, 0, 0, 0.45), RADIUS)
	# Gradient fill.
	_round_rect_gradient(rect, top, bot, RADIUS)
	# Top sheen.
	var sheen_rect := Rect2(rect.position + Vector2(3, 3), Vector2(rect.size.x - 6, rect.size.y * 0.35))
	_round_rect(sheen_rect, Color(1, 1, 1, 0.10), RADIUS - 3)

	# Border.
	_round_rect_outline(rect, border_col, RADIUS, 2.5)
	if state == State.MOVED:
		_round_rect_outline(rect.grow(2), Color(GREEN_MOVED_BORDER.r, GREEN_MOVED_BORDER.g, GREEN_MOVED_BORDER.b, 0.3), RADIUS + 2, 1.5)

	# Letter glyph.
	var f: Font = TILE_FONT
	var fs := 26
	var ts := f.get_string_size(letter, HORIZONTAL_ALIGNMENT_CENTER, -1, fs)
	var ascent := f.get_ascent(fs)
	var descent := f.get_descent(fs)
	var base := Vector2(size.x * 0.5 - ts.x * 0.5, (size.y + ascent - descent) * 0.5)
	draw_string(f, base + Vector2(1, 2), letter, HORIZONTAL_ALIGNMENT_CENTER, -1, fs, Color(0, 0, 0, 0.4))
	draw_string(f, base, letter, HORIZONTAL_ALIGNMENT_CENTER, -1, fs, Color.WHITE)

	# Selection order number (top-right).
	if state == State.MOVED and selection_index >= 0:
		var num_str := str(selection_index + 1)
		var nfs := 11
		var num_pos := Vector2(size.x - 12, 14)
		draw_string(f, num_pos, num_str, HORIZONTAL_ALIGNMENT_CENTER, -1, nfs, Color(1, 1, 1, 0.7))

# --------- drawing helpers ---------
func _round_rect(rect: Rect2, color: Color, radius: float) -> void:
	var r: float = minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
	draw_rect(Rect2(rect.position + Vector2(r, 0), Vector2(rect.size.x - 2*r, rect.size.y)), color)
	draw_rect(Rect2(rect.position + Vector2(0, r), Vector2(rect.size.x, rect.size.y - 2*r)), color)
	draw_circle(rect.position + Vector2(r, r), r, color)
	draw_circle(rect.position + Vector2(rect.size.x - r, r), r, color)
	draw_circle(rect.position + Vector2(r, rect.size.y - r), r, color)
	draw_circle(rect.position + Vector2(rect.size.x - r, rect.size.y - r), r, color)

func _round_rect_gradient(rect: Rect2, top: Color, bot: Color, radius: float) -> void:
	var bands := 12
	var r: float = minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
	for i in bands:
		var t0: float = float(i) / float(bands)
		var t1: float = float(i + 1) / float(bands)
		var c := top.lerp(bot, (t0 + t1) * 0.5)
		var y0 := rect.position.y + rect.size.y * t0
		var y1 := rect.position.y + rect.size.y * t1
		var inset: float = 0.0
		if y0 < rect.position.y + r:
			inset = r - (y0 - rect.position.y)
		elif y1 > rect.position.y + rect.size.y - r:
			inset = r - ((rect.position.y + rect.size.y) - y1)
		inset = clampf(inset, 0.0, r)
		var chord: float = 0.0
		if inset > 0:
			chord = r - sqrt(maxf(r * r - (r - inset) * (r - inset), 0.0))
		draw_rect(Rect2(Vector2(rect.position.x + chord, y0),
			Vector2(rect.size.x - chord * 2, y1 - y0)), c)
	draw_circle(rect.position + Vector2(r, r), r, top)
	draw_circle(rect.position + Vector2(rect.size.x - r, r), r, top)
	draw_circle(rect.position + Vector2(r, rect.size.y - r), r, bot)
	draw_circle(rect.position + Vector2(rect.size.x - r, rect.size.y - r), r, bot)

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
