class_name WFTile
extends Button
## Word Fight tile — vibrant board.
## Idle: gradient fill by letter tier (vowel/common/uncommon/rare), top sheen,
## soft drop shadow, bold ink letter.
## Selected: hot-pink gradient + white letter + scale-up + glow ring + order chip.
## Rainbow: animated multi-color outer ring.
## Dim: ghosted during enemy turn.
## Animations: pop-in on spawn, burst-dissolve on consume, drop-in on refill,
## sparkle particles on select (handled by Fx via signal).

const Fx := preload("res://games/word_fight/fx.gd")
const TILE_FONT: Font = preload("res://assets/fonts/LilitaOne-Regular.ttf")

signal tile_pressed(tile: WFTile)
signal tile_selected_fx(tile: WFTile, color: Color)

const SIZE := 56.0
const RADIUS := 12.0

@export var letter: String = "A" :
	set(v):
		letter = v.to_upper()
		queue_redraw()

var selected_order: int = -1 :
	set(v):
		var was := selected_order >= 0
		selected_order = v
		var now := selected_order >= 0
		if was != now:
			_animate_select(now)
			if now:
				var grad := Fx.gradient_for_letter(letter)
				tile_selected_fx.emit(self, grad[1])
		queue_redraw()

var rainbow: bool = false :
	set(v):
		rainbow = v
		set_process(v)
		queue_redraw()

var dim: bool = false :
	set(v):
		dim = v
		var tw := create_tween()
		tw.tween_property(self, "modulate:a", 0.55 if dim else 1.0, 0.2)

var _rainbow_phase: float = 0.0
var _idle_phase: float = 0.0

func _ready() -> void:
	custom_minimum_size = Vector2(SIZE, SIZE)
	size = Vector2(SIZE, SIZE)
	pivot_offset = size * 0.5
	flat = true
	text = ""
	focus_mode = Control.FOCUS_NONE
	var empty := StyleBoxEmpty.new()
	add_theme_stylebox_override("normal", empty)
	add_theme_stylebox_override("hover", empty)
	add_theme_stylebox_override("pressed", empty)
	add_theme_stylebox_override("focus", empty)
	add_theme_stylebox_override("disabled", empty)
	pressed.connect(func(): tile_pressed.emit(self))
	set_process(false)
	_idle_phase = randf() * TAU

func _process(delta: float) -> void:
	if rainbow:
		_rainbow_phase += delta * 1.6
		queue_redraw()

## Plays a pop-in (used after spawn or refill). Optional delay for stagger.
func play_pop_in(delay: float = 0.0) -> void:
	scale = Vector2(0.2, 0.2)
	modulate.a = 0.0
	var tw := create_tween()
	if delay > 0.0:
		tw.tween_interval(delay)
	tw.set_parallel(true)
	tw.tween_property(self, "scale", Vector2(1.0, 1.0), 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 1.0, 0.22)

## Plays a drop-in (new tile falling from above into its slot).
func play_drop_in() -> void:
	var dst := position
	position = dst + Vector2(0, -SIZE * 1.6)
	modulate.a = 0.0
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "position", dst, 0.32).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 1.0, 0.18)

## Plays a burst-out before the tile letter is reassigned (consumed in chain).
func play_burst() -> void:
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "scale", Vector2(1.25, 1.25), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 0.0, 0.18)

func _animate_select(now: bool) -> void:
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector2.ONE * (1.08 if now else 1.0), 0.14)

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	var sel := selected_order >= 0

	# Soft shadow.
	_round_rect(Rect2(Vector2(0, 4), size), Color(0.15, 0.10, 0.25, 0.22), RADIUS)

	var top: Color
	var bot: Color
	var ink: Color
	if sel:
		top = Fx.SELECT_TOP
		bot = Fx.SELECT_BOTTOM
		ink = Fx.SELECT_INK
	else:
		var g := Fx.gradient_for_letter(letter)
		top = g[0]; bot = g[1]; ink = g[2]

	# Vertical gradient fill (banded rows).
	_round_rect_gradient(rect, top, bot, RADIUS)

	# Top sheen — light horizontal highlight.
	var sheen_rect := Rect2(rect.position + Vector2(4, 4), Vector2(rect.size.x - 8, rect.size.y * 0.42))
	_round_rect(sheen_rect, Color(1, 1, 1, 0.22), RADIUS - 4)

	# Border.
	if sel:
		_round_rect_outline(rect, Color("#7a0e4a"), RADIUS, 2.5)
		# Glow ring just outside.
		_round_rect_outline(rect.grow(2), Color(1.0, 0.5, 0.85, 0.55), RADIUS + 2, 2.0)
	else:
		_round_rect_outline(rect, Color(0, 0, 0, 0.18), RADIUS, 1.5)

	# Rainbow ring (animated hue rotation around the outline).
	if rainbow:
		var bands := 6
		for i in bands:
			var inset: float = 2.0 + i * 1.2
			var hue: float = fmod((float(i) / float(bands)) + _rainbow_phase * 0.15, 1.0)
			var col := Color.from_hsv(hue, 0.85, 1.0, 0.9)
			_round_rect_outline(rect.grow(-inset), col, maxf(RADIUS - inset, 2), 1.6)

	# Letter — bold ink. Center using ascent/descent.
	var f: Font = TILE_FONT
	var fs := 28
	var ts := f.get_string_size(letter, HORIZONTAL_ALIGNMENT_CENTER, -1, fs)
	var ascent := f.get_ascent(fs)
	var descent := f.get_descent(fs)
	var y := (size.y + ascent - descent) * 0.5
	# Drop shadow on the glyph for readability.
	draw_string(f, Vector2(size.x * 0.5 - ts.x * 0.5 + 1, y + 1),
		letter, HORIZONTAL_ALIGNMENT_CENTER, -1, fs, Color(0, 0, 0, 0.35))
	draw_string(f, Vector2(size.x * 0.5 - ts.x * 0.5, y),
		letter, HORIZONTAL_ALIGNMENT_CENTER, -1, fs, ink)

	# Order chip — top-right with bright magenta ring.
	if sel:
		var chip_pos := Vector2(size.x - 10, 10)
		draw_circle(chip_pos, 9, Color("#7a0e4a"))
		draw_circle(chip_pos, 7, Color.WHITE)
		var num := str(selected_order + 1)
		var chip_fs := 11
		var ns := f.get_string_size(num, HORIZONTAL_ALIGNMENT_CENTER, -1, chip_fs)
		var n_ascent := f.get_ascent(chip_fs)
		var n_descent := f.get_descent(chip_fs)
		draw_string(f, Vector2(chip_pos.x - ns.x * 0.5, chip_pos.y + (n_ascent - n_descent) * 0.5),
			num, HORIZONTAL_ALIGNMENT_CENTER, -1, chip_fs, Color("#7a0e4a"))

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
	# Approximate a vertical gradient using horizontal strips with rounded mask.
	var bands := 14
	var r: float = minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
	for i in bands:
		var t0: float = float(i) / float(bands)
		var t1: float = float(i + 1) / float(bands)
		var c := top.lerp(bot, (t0 + t1) * 0.5)
		var y0 := rect.position.y + rect.size.y * t0
		var y1 := rect.position.y + rect.size.y * t1
		# Inset horizontally near top/bottom rows to fake rounded corners.
		var inset: float = 0.0
		if y0 < rect.position.y + r:
			inset = r - (y0 - rect.position.y)
		elif y1 > rect.position.y + rect.size.y - r:
			inset = r - ((rect.position.y + rect.size.y) - y1)
		inset = clampf(inset, 0.0, r)
		# Use a circle "chord" approx — shrink the strip width to match the rounded corner.
		var chord: float = 0.0
		if inset > 0:
			chord = r - sqrt(maxf(r * r - (r - inset) * (r - inset), 0.0))
		draw_rect(Rect2(Vector2(rect.position.x + chord, y0),
			Vector2(rect.size.x - chord * 2, y1 - y0)), c)
	# Re-stamp the rounded corners with the closest band color to smooth the silhouette.
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
