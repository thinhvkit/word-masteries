class_name WMLetter
extends Control
## Word Match letter — candy-style glossy circle.
## Idle: bright candy gradient, glossy sheen, thick colored outline.
## Selected: deeper saturated candy, white glyph, scale 1.12, glow ring.

const Fx := preload("res://games/word_fight/fx.gd")
const LETTER_FONT: Font = preload("res://assets/fonts/LilitaOne-Regular.ttf")

signal letter_selected_fx(letter: WMLetter, color: Color)

const SIZE := 87.0
enum TileKind { REGULAR, FIRE, GOLD, DIAMOND, POISON, WILD }

const _CANDY_TIERS := [
	# Vowels — cherry red
	{"top": Color("#FF6B8A"), "bot": Color("#D4345A"), "outline": Color("#FF9DB5"), "ink": Color.WHITE},
	# Common — ocean blue
	{"top": Color("#5BC0FF"), "bot": Color("#1A7FD4"), "outline": Color("#8DD6FF"), "ink": Color.WHITE},
	# Uncommon — grape purple
	{"top": Color("#B07AFF"), "bot": Color("#7030D4"), "outline": Color("#D0ACFF"), "ink": Color.WHITE},
	# Rare — lime green
	{"top": Color("#7AE86A"), "bot": Color("#30A830"), "outline": Color("#A8F49E"), "ink": Color.WHITE},
]

const _CANDY_SELECT := {
	"top": Color("#FFD740"), "bot": Color("#FFB300"), "outline": Color("#FFE57F"), "ink": Color.WHITE,
}

const _SPECIAL_CANDY := {
	TileKind.FIRE: {"top": Color("#ff9a3d"), "bot": Color("#d84a14"), "outline": Color("#ffd06a"), "ink": Color.WHITE, "mark": "F"},
	TileKind.GOLD: {"top": Color("#ffe66d"), "bot": Color("#d19a08"), "outline": Color("#fff4a8"), "ink": Color("#513800"), "mark": "G"},
	TileKind.DIAMOND: {"top": Color("#a7f8ff"), "bot": Color("#20b8d8"), "outline": Color("#e0ffff"), "ink": Color("#06375e"), "mark": "D"},
	TileKind.POISON: {"top": Color("#5cb85c"), "bot": Color("#1f5f2a"), "outline": Color("#a8f49e"), "ink": Color.WHITE, "mark": "P"},
	TileKind.WILD: {"top": Color("#ff7ad1"), "bot": Color("#3aa8ff"), "outline": Color("#ffd027"), "ink": Color.WHITE, "mark": "W"},
}

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
			var candy := _candy_for_letter()
			letter_selected_fx.emit(self, candy.outline)

var tile_kind: int = TileKind.REGULAR :
	set(v):
		tile_kind = v
		queue_redraw()

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
	var target_scale := Vector2.ONE * (1.12 if selected else 1.0)
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", target_scale, 0.16)

func _candy_for_letter() -> Dictionary:
	if tile_kind != TileKind.REGULAR and _SPECIAL_CANDY.has(tile_kind):
		return _SPECIAL_CANDY[tile_kind]
	var tier := Fx.tier_for_letter(letter)
	return _CANDY_TIERS[clampi(tier, 0, _CANDY_TIERS.size() - 1)]

func _draw() -> void:
	var center := size * 0.5
	var r := SIZE * 0.5 - 2.0
	var candy: Dictionary
	var ink: Color
	if selected:
		candy = _CANDY_SELECT
		ink = _CANDY_SELECT.ink
	else:
		candy = _candy_for_letter()
		ink = candy.ink

	# Drop shadow (colored).
	draw_circle(center + Vector2(0, 5), r, Color(candy.bot.r, candy.bot.g, candy.bot.b, 0.35))

	# Main gradient fill.
	_draw_gradient_circle(center, r, candy.top, candy.bot)

	# Glossy candy sheen — big highlight arc near the top.
	draw_arc(center + Vector2(0, -4), r - 10, PI * 1.1, PI * 1.9, 40, Color(1, 1, 1, 0.7), 8.0, true)
	# Secondary smaller sheen for extra gloss.
	draw_arc(center + Vector2(0, -2), r - 16, PI * 1.2, PI * 1.8, 32, Color(1, 1, 1, 0.35), 5.0, true)

	# Highlight dot (candy reflection).
	draw_circle(center + Vector2(-r * 0.28, -r * 0.32), r * 0.12, Color(1, 1, 1, 0.55))
	draw_circle(center + Vector2(-r * 0.18, -r * 0.42), r * 0.06, Color(1, 1, 1, 0.7))

	# Thick colored outline.
	if selected:
		draw_arc(center, r, 0, TAU, 64, candy.outline, 4.0, true)
		# Outer glow ring.
		draw_arc(center, r + 4, 0, TAU, 64, Color(candy.outline.r, candy.outline.g, candy.outline.b, 0.45), 3.0, true)
		draw_arc(center, r + 8, 0, TAU, 64, Color(candy.outline.r, candy.outline.g, candy.outline.b, 0.15), 2.5, true)
	else:
		draw_arc(center, r, 0, TAU, 64, candy.outline, 3.0, true)
		# Subtle outer glow.
		draw_arc(center, r + 3, 0, TAU, 64, Color(candy.outline.r, candy.outline.g, candy.outline.b, 0.18), 2.0, true)

	# Bottom edge shadow for 3D depth.
	draw_arc(center, r - 1, 0.15, PI - 0.15, 32, Color(0, 0, 0, 0.18), 3.0, true)

	if tile_kind != TileKind.REGULAR:
		_draw_special_mark(center, r, candy)
	_draw_letter(center, ink)

func _draw_gradient_circle(center: Vector2, r: float, top: Color, bot: Color) -> void:
	var bands := 24
	for i in bands:
		var t0: float = float(i) / float(bands)
		var t1: float = float(i + 1) / float(bands)
		var c: Color = top.lerp(bot, (t0 + t1) * 0.5)
		var y0: float = center.y - r + (2 * r) * t0
		var y1: float = center.y - r + (2 * r) * t1
		var mid: float = (y0 + y1) * 0.5 - center.y
		var hw: float = sqrt(maxf(r * r - mid * mid, 0.0))
		draw_rect(Rect2(Vector2(center.x - hw, y0), Vector2(hw * 2, y1 - y0)), c)

func _draw_letter(center: Vector2, col: Color) -> void:
	var f: Font = LETTER_FONT
	var fs := 42
	var shown := "*" if tile_kind == TileKind.WILD else ("?" if tile_kind == TileKind.POISON else letter)
	var ts := f.get_string_size(shown, HORIZONTAL_ALIGNMENT_CENTER, -1, fs)
	var ascent := f.get_ascent(fs)
	var descent := f.get_descent(fs)
	var base := Vector2(center.x - ts.x * 0.5, center.y + (ascent - descent) * 0.5)
	draw_string(f, base + Vector2(1, 2), shown, HORIZONTAL_ALIGNMENT_CENTER, -1, fs, Color(0, 0, 0, 0.4))
	draw_string(f, base, shown, HORIZONTAL_ALIGNMENT_CENTER, -1, fs, col)

func _draw_special_mark(center: Vector2, r: float, candy: Dictionary) -> void:
	var mark := str(candy.get("mark", ""))
	if mark.is_empty():
		return
	var badge_pos := center + Vector2(r * 0.42, -r * 0.42)
	draw_circle(badge_pos, 12, Color(0, 0, 0, 0.28))
	draw_circle(badge_pos, 10, Color(candy.outline.r, candy.outline.g, candy.outline.b, 0.95))
	var f: Font = LETTER_FONT
	var fs := 13
	var ts := f.get_string_size(mark, HORIZONTAL_ALIGNMENT_CENTER, -1, fs)
	var base := Vector2(badge_pos.x - ts.x * 0.5, badge_pos.y + (f.get_ascent(fs) - f.get_descent(fs)) * 0.5)
	draw_string(f, base, mark, HORIZONTAL_ALIGNMENT_CENTER, -1, fs, Color(0.12, 0.08, 0.16))
