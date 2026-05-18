class_name WFTile
extends Button
## Word Fight tile — cozy palette.
## Idle: white surface, warm hairline border, soft brown shadow, brown letter.
## Selected: pink fill + white letter + small scale-up + order chip.
## Rainbow: gold outline ring.
## Dim: ghosted during enemy turn.

signal tile_pressed(tile: WFTile)

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
		queue_redraw()

var rainbow: bool = false :
	set(v):
		rainbow = v
		queue_redraw()

var dim: bool = false :
	set(v):
		dim = v
		modulate.a = 0.55 if dim else 1.0

func _ready() -> void:
	custom_minimum_size = Vector2(SIZE, SIZE)
	size = Vector2(SIZE, SIZE)
	pivot_offset = size * 0.5
	flat = true
	text = ""
	focus_mode = Control.FOCUS_NONE
	# Hide the Button's built-in chrome — _draw() renders everything.
	var empty := StyleBoxEmpty.new()
	add_theme_stylebox_override("normal", empty)
	add_theme_stylebox_override("hover", empty)
	add_theme_stylebox_override("pressed", empty)
	add_theme_stylebox_override("focus", empty)
	add_theme_stylebox_override("disabled", empty)
	pressed.connect(func(): tile_pressed.emit(self))

func _animate_select(now: bool) -> void:
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector2.ONE * (1.04 if now else 1.0), 0.12)

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	var sel := selected_order >= 0
	var fill := Palette.PINK if sel else Palette.SURFACE
	var text_col := Color.WHITE if sel else Palette.TEXT

	# Soft shadow
	_round_rect(Rect2(Vector2(0, 3), size), Color(0.35, 0.28, 0.24, 0.18), RADIUS)
	# Fill
	_round_rect(rect, fill, RADIUS)
	# Border
	if sel:
		_round_rect_outline(rect, Palette.PINK_DARK, RADIUS, 2.0)
	else:
		_round_rect_outline(rect, Palette.HAIRLINE, RADIUS, 2.0)

	# Rainbow ring (gold-tinted to fit the cozy palette)
	if rainbow:
		var colors := [
			Palette.GOLD, Palette.MUSHROOM, Palette.PINK,
			Palette.SAGE, Color("#7cc5e8"), Color("#b88adf"),
		]
		for i in colors.size():
			var inset := 2.0 + i * 1.2
			_round_rect_outline(rect.grow(-inset), colors[i], maxf(RADIUS - inset, 2), 1.4)

	# Letter
	var f := ThemeDB.fallback_font
	var fs := 26
	var ts := f.get_string_size(letter, HORIZONTAL_ALIGNMENT_CENTER, -1, fs)
	draw_string(f, size * 0.5 - ts * 0.5 + Vector2(0, fs * 0.36),
		letter, HORIZONTAL_ALIGNMENT_CENTER, -1, fs, text_col)

	# Order chip — small badge in top-right corner with a pink ring.
	if sel:
		var chip_pos := Vector2(size.x - 9, 9)
		draw_circle(chip_pos, 7, Palette.PINK_DARK)
		draw_circle(chip_pos, 6, Color.WHITE)
		var num := str(selected_order + 1)
		var chip_fs := 10
		var ns := f.get_string_size(num, HORIZONTAL_ALIGNMENT_CENTER, -1, chip_fs)
		draw_string(f, chip_pos - ns * 0.5 + Vector2(0, chip_fs * 0.35),
			num, HORIZONTAL_ALIGNMENT_CENTER, -1, chip_fs, Palette.PINK_DARK)

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
