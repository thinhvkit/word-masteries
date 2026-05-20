class_name WMLetter
extends Control
## Word Match letter — vibrant circle matching Word Fight's tile style.
## Idle: gradient fill by letter tier, top sheen, drop shadow, bold ink glyph.
## Selected: hot-pink/magenta gradient, white glyph, scale 1.08, glow ring.
## Animations: pop-in, sparkle burst on select (via signal).

const Fx := preload("res://games/word_fight/fx.gd")
const LETTER_FONT: Font = preload("res://assets/fonts/LilitaOne-Regular.ttf")

signal letter_selected_fx(letter: WMLetter, color: Color)

const SIZE := 84.0

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
		if selected:
			var grad := Fx.gradient_for_letter(letter)
			letter_selected_fx.emit(self, grad[1])

func _ready() -> void:
	custom_minimum_size = Vector2(SIZE, SIZE)
	size = Vector2(SIZE, SIZE)
	pivot_offset = size * 0.5
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func contains_point(global_pos: Vector2) -> bool:
	var center := global_position + size * 0.5
	return global_pos.distance_to(center) <= SIZE * 0.5

func play_pop_in(delay: float = 0.0) -> void:
	scale = Vector2(0.2, 0.2)
	modulate.a = 0.0
	var tw := create_tween()
	if delay > 0.0:
		tw.tween_interval(delay)
	tw.set_parallel(true)
	tw.tween_property(self, "scale", Vector2(1.0, 1.0), 0.36).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 1.0, 0.24)

func _animate_select() -> void:
	var target_scale := Vector2.ONE * (1.1 if selected else 1.0)
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", target_scale, 0.16)

func _draw() -> void:
	var center := size * 0.5
	var r := SIZE * 0.5 - 2.0
	# Soft drop shadow.
	draw_circle(center + Vector2(0, 4), r, Color(0.15, 0.10, 0.25, 0.22))

	var top: Color
	var bot: Color
	var ink: Color
	if selected:
		top = Fx.SELECT_TOP
		bot = Fx.SELECT_BOTTOM
		ink = Fx.SELECT_INK
	else:
		var g := Fx.gradient_for_letter(letter)
		top = g[0]; bot = g[1]; ink = g[2]

	_draw_gradient_circle(center, r, top, bot)

	# Sheen — top arc highlight.
	draw_arc(center + Vector2(0, -2), r - 6, PI * 1.15, PI * 1.85, 40, Color(1, 1, 1, 0.55), 6.0)

	# Outline.
	if selected:
		draw_arc(center, r - 1, 0, TAU, 64, Color("#7a0e4a"), 3.0, true)
		# Glow ring just outside.
		draw_arc(center, r + 3, 0, TAU, 64, Color(1.0, 0.5, 0.85, 0.6), 2.0, true)
	else:
		draw_arc(center, r - 1, 0, TAU, 64, Color(0, 0, 0, 0.2), 2.0, true)

	_draw_letter(center, ink)

func _draw_gradient_circle(center: Vector2, r: float, top: Color, bot: Color) -> void:
	# Approximate a vertical gradient inside a circle using horizontal chords.
	var bands := 22
	for i in bands:
		var t0: float = float(i) / float(bands)
		var t1: float = float(i + 1) / float(bands)
		var c: Color = top.lerp(bot, (t0 + t1) * 0.5)
		var y0: float = center.y - r + (2 * r) * t0
		var y1: float = center.y - r + (2 * r) * t1
		# Chord half-width at midpoint of this band.
		var mid: float = (y0 + y1) * 0.5 - center.y
		var hw: float = sqrt(maxf(r * r - mid * mid, 0.0))
		draw_rect(Rect2(Vector2(center.x - hw, y0), Vector2(hw * 2, y1 - y0)), c)

func _draw_letter(center: Vector2, col: Color) -> void:
	var f: Font = LETTER_FONT
	var fs := 42
	var ts := f.get_string_size(letter, HORIZONTAL_ALIGNMENT_CENTER, -1, fs)
	var ascent := f.get_ascent(fs)
	var descent := f.get_descent(fs)
	var base := Vector2(center.x - ts.x * 0.5, center.y + (ascent - descent) * 0.5)
	# Drop shadow for readability against the gradient.
	draw_string(f, base + Vector2(1, 1), letter, HORIZONTAL_ALIGNMENT_CENTER, -1, fs, Color(0, 0, 0, 0.35))
	draw_string(f, base, letter, HORIZONTAL_ALIGNMENT_CENTER, -1, fs, col)
