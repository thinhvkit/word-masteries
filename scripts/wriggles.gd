class_name Wriggles
extends Control
## Mascot — cheerful bookworm in a graduation cap.
## Draws the same shapes as the Screens.jsx <Wriggles /> SVG (130×110 viewBox),
## scaled to whatever size we're given.

@export var draw_size: float = 150.0 :
	set(v):
		draw_size = v
		custom_minimum_size = Vector2(v, v * 0.85)
		queue_redraw()

func _ready() -> void:
	custom_minimum_size = Vector2(draw_size, draw_size * 0.85)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	# Source viewBox is 130×110. Scale uniformly.
	var s := draw_size / 130.0
	# Body segments
	draw_circle(Vector2(22, 82) * s, 19 * s, Color("#7DD638"))
	draw_circle(Vector2(48, 78) * s, 17 * s, Color("#6BCB27"))
	draw_circle(Vector2(72, 80) * s, 16 * s, Color("#7DD638"))
	# Segment arcs (subtle dividers)
	_arc(Vector2(41, 72) * s, 7 * s, 0.25 * PI, 0.75 * PI, Color("#5BB520"), 2.0 * s)
	_arc(Vector2(65, 73) * s, 7 * s, 0.25 * PI, 0.75 * PI, Color("#5BB520"), 2.0 * s)
	# Head
	draw_circle(Vector2(96, 70) * s, 24 * s, Color("#58CC02"))
	# Graduation cap
	_rounded_rect(Rect2(Vector2(77, 42) * s, Vector2(38, 9) * s), Color("#2C2C2C"), 4 * s)
	_rounded_rect(Rect2(Vector2(87, 32) * s, Vector2(18, 12) * s), Color("#2C2C2C"), 3 * s)
	# Tassel
	draw_line(Vector2(115, 47) * s, Vector2(121, 58) * s, Color("#FFC800"), 2.5 * s, true)
	draw_circle(Vector2(121, 61) * s, 3.5 * s, Color("#FFC800"))
	# Eyes (whites + pupils + highlights)
	_circle_outline(Vector2(87, 69) * s, 9 * s, Color.WHITE, Color("#2C2C2C"), 2.5 * s)
	_circle_outline(Vector2(105, 69) * s, 9 * s, Color.WHITE, Color("#2C2C2C"), 2.5 * s)
	draw_circle(Vector2(87, 69) * s, 4 * s, Color("#2C2C2C"))
	draw_circle(Vector2(105, 69) * s, 4 * s, Color("#2C2C2C"))
	draw_circle(Vector2(88.5, 67.5) * s, 1.2 * s, Color.WHITE)
	draw_circle(Vector2(106.5, 67.5) * s, 1.2 * s, Color.WHITE)
	# Smile
	_arc(Vector2(96, 80) * s, 12 * s, PI * 0.15, PI * 0.85, Color("#2C2C2C"), 2.5 * s)
	# Feet
	draw_circle(Vector2(17, 100) * s, 7 * s, Color("#5BB520"))
	draw_circle(Vector2(38, 100) * s, 7 * s, Color("#5BB520"))
	draw_circle(Vector2(62, 99) * s, 7 * s, Color("#5BB520"))

func _arc(center: Vector2, radius: float, start_angle: float, end_angle: float, col: Color, w: float) -> void:
	draw_arc(center, radius, start_angle, end_angle, 24, col, w, true)

func _rounded_rect(rect: Rect2, col: Color, radius: float) -> void:
	var r: float = minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
	draw_rect(Rect2(rect.position + Vector2(r, 0), Vector2(rect.size.x - 2*r, rect.size.y)), col)
	draw_rect(Rect2(rect.position + Vector2(0, r), Vector2(rect.size.x, rect.size.y - 2*r)), col)
	draw_circle(rect.position + Vector2(r, r), r, col)
	draw_circle(rect.position + Vector2(rect.size.x - r, r), r, col)
	draw_circle(rect.position + Vector2(r, rect.size.y - r), r, col)
	draw_circle(rect.position + Vector2(rect.size.x - r, rect.size.y - r), r, col)

func _circle_outline(center: Vector2, radius: float, fill: Color, stroke: Color, w: float) -> void:
	draw_circle(center, radius, fill)
	draw_arc(center, radius, 0, TAU, 48, stroke, w, true)
