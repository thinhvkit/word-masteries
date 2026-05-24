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

const SIZE := 50.0
const RADIUS := 10.0

const GREEN_AVAIL_TOP := Color("#5ec46e")
const GREEN_AVAIL_BOT := Color("#2e8a3e")
const GREEN_AVAIL_BORDER := Color("#90e8a0")

const GREEN_MOVED_TOP := Color("#2a5028")
const GREEN_MOVED_BOT := Color("#1a3818")
const GREEN_MOVED_BORDER := Color("#4a7a40")

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

	# Drop shadow (colored).
	_round_rect(Rect2(Vector2(0, 4), size), Color(bot.r * 0.3, bot.g * 0.3, bot.b * 0.3, 0.6), RADIUS)
	# Gradient fill.
	_round_rect_gradient(rect, top, bot, RADIUS)
	# Glossy sheen — arc highlights instead of rects to avoid corner artifacts.
	var cx := size.x * 0.5
	draw_arc(Vector2(cx, 6), size.x * 0.38, PI * 1.05, PI * 1.95, 24, Color(1, 1, 1, 0.25), 5.0, true)
	draw_arc(Vector2(cx, 8), size.x * 0.28, PI * 1.15, PI * 1.85, 20, Color(1, 1, 1, 0.12), 3.0, true)
	# Bottom 3D edge.
	draw_arc(Vector2(cx, size.y - 2), size.x * 0.35, 0.1, PI - 0.1, 20, Color(0, 0, 0, 0.18), 2.0, true)
	# Highlight dot.
	draw_circle(Vector2(RADIUS + 2, RADIUS), 2.5, Color(1, 1, 1, 0.35))

	# Border.
	_round_rect_outline(rect, border_col, RADIUS, 2.5)
	if state == State.AVAILABLE:
		_round_rect_outline(rect.grow(1), Color(border_col.r, border_col.g, border_col.b, 0.2), RADIUS + 1, 1.0)
	elif state == State.MOVED:
		_round_rect_outline(rect.grow(2), Color(GREEN_MOVED_BORDER.r, GREEN_MOVED_BORDER.g, GREEN_MOVED_BORDER.b, 0.4), RADIUS + 2, 1.5)

	# Letter glyph.
	var f: Font = TILE_FONT
	var fs := 26
	var ts := f.get_string_size(letter, HORIZONTAL_ALIGNMENT_CENTER, -1, fs)
	var ascent := f.get_ascent(fs)
	var descent := f.get_descent(fs)
	var base := Vector2(size.x * 0.5 - ts.x * 0.5, (size.y + ascent - descent) * 0.5)
	draw_string(f, base + Vector2(1, 2), letter, HORIZONTAL_ALIGNMENT_CENTER, -1, fs, Color(0, 0, 0, 0.5))
	draw_string(f, base + Vector2(0, -1), letter, HORIZONTAL_ALIGNMENT_CENTER, -1, fs, Color(1, 1, 1, 0.95))

	# Selection order badge (top-right).
	if state == State.MOVED and selection_index >= 0:
		var badge_r := 8.0
		var badge_pos := Vector2(size.x - badge_r - 3, badge_r + 3)
		draw_circle(badge_pos, badge_r + 1, Color(0, 0, 0, 0.3))
		draw_circle(badge_pos, badge_r, Color("#ffd027"))
		var num_str := str(selection_index + 1)
		var nfs := 10
		var nts := f.get_string_size(num_str, HORIZONTAL_ALIGNMENT_CENTER, -1, nfs)
		draw_string(f, badge_pos + Vector2(-nts.x * 0.5, f.get_ascent(nfs) * 0.5 - 1), num_str, HORIZONTAL_ALIGNMENT_CENTER, -1, nfs, Color("#5a3a00"))

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
	var bands := 20
	var r: float = minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
	for i in bands:
		var t0: float = float(i) / float(bands)
		var t1: float = float(i + 1) / float(bands)
		var c := top.lerp(bot, (t0 + t1) * 0.5)
		var y0 := rect.position.y + rect.size.y * t0
		var y1 := rect.position.y + rect.size.y * t1
		var inset_top: float = 0.0
		var inset_bot: float = 0.0
		if y0 < rect.position.y + r:
			inset_top = r - (y0 - rect.position.y)
		if y1 > rect.position.y + rect.size.y - r:
			inset_bot = r - ((rect.position.y + rect.size.y) - y1)
		var inset: float = maxf(clampf(inset_top, 0.0, r), clampf(inset_bot, 0.0, r))
		var chord: float = 0.0
		if inset > 0:
			chord = r - sqrt(maxf(r * r - (r - inset) * (r - inset), 0.0))
		draw_rect(Rect2(Vector2(rect.position.x + chord, y0),
			Vector2(rect.size.x - chord * 2, y1 - y0)), c)
	var t_top: float = r / rect.size.y
	var t_bot: float = (rect.size.y - r) / rect.size.y
	var c_top := top.lerp(bot, t_top)
	var c_bot := top.lerp(bot, t_bot)
	draw_circle(rect.position + Vector2(r, r), r, c_top)
	draw_circle(rect.position + Vector2(rect.size.x - r, r), r, c_top)
	draw_circle(rect.position + Vector2(r, rect.size.y - r), r, c_bot)
	draw_circle(rect.position + Vector2(rect.size.x - r, rect.size.y - r), r, c_bot)

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
