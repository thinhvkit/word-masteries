class_name WFoundTile
extends Button
## Word Found letter — candy-style glossy circle matching Word Match.
## - AVAILABLE: bright candy gradient circle per letter tier.
## - MOVED:     golden selected candy, selection order badge.

const TILE_FONT: Font = preload("res://assets/fonts/Baloo2-ExtraBold.ttf")

signal tile_pressed(tile: WFoundTile)
signal tile_picked_fx(tile: WFoundTile, color: Color)

enum State { AVAILABLE, MOVED }

const SIZE := 87.0

const _CANDY_VOWEL := {"top": Color("#FF6B8A"), "bot": Color("#D4345A"), "outline": Color("#FFB0C2"), "ink": Color.WHITE}
const _CANDY_CONSONANT := {"top": Color("#5BC0FF"), "bot": Color("#1A7FD4"), "outline": Color("#A6E0FF"), "ink": Color.WHITE}

const _CANDY_MOVED := {
	"top": Color("#FFD740"), "bot": Color("#FFB300"), "outline": Color("#FFE57F"), "ink": Color.WHITE,
}

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
	flat = true
	focus_mode = Control.FOCUS_NONE

func _pressed() -> void:
	tile_pressed.emit(self)

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
		tw.tween_property(self, "scale", Vector2(1.08, 1.08), 0.14)
		var candy := _candy_for_letter()
		tile_picked_fx.emit(self, candy.outline)
	elif now == State.AVAILABLE:
		selection_index = -1
		var tw := create_tween()
		tw.tween_property(self, "scale", Vector2(1.0, 1.0), 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _candy_for_letter() -> Dictionary:
	return _CANDY_VOWEL if _is_vowel(letter) else _CANDY_CONSONANT

func _is_vowel(ch: String) -> bool:
	return "AEIOU".find(ch) != -1

func _draw() -> void:
	var center := size * 0.5
	var r := SIZE * 0.5 - 2.0
	var candy: Dictionary
	if state == State.MOVED:
		candy = _CANDY_MOVED
	else:
		candy = _candy_for_letter()

	# Drop shadow (colored).
	draw_circle(center + Vector2(0, 4), r, Color(candy.bot.r, candy.bot.g, candy.bot.b, 0.35))

	# Main gradient fill.
	_draw_gradient_circle(center, r, candy.top, candy.bot)

	# Glossy candy sheen.
	draw_arc(center + Vector2(0, -3), r - 8, PI * 1.1, PI * 1.9, 32, Color(1, 1, 1, 0.6), 6.0, true)
	draw_arc(center + Vector2(0, -1), r - 13, PI * 1.2, PI * 1.8, 24, Color(1, 1, 1, 0.3), 4.0, true)

	# Highlight dots (candy reflection).
	draw_circle(center + Vector2(-r * 0.28, -r * 0.32), r * 0.10, Color(1, 1, 1, 0.5))
	draw_circle(center + Vector2(-r * 0.18, -r * 0.42), r * 0.05, Color(1, 1, 1, 0.65))

	# Colored outline.
	if state == State.MOVED:
		draw_arc(center, r, 0, TAU, 48, candy.outline, 3.5, true)
		draw_arc(center, r + 4, 0, TAU, 48, Color(candy.outline.r, candy.outline.g, candy.outline.b, 0.4), 2.5, true)
		draw_arc(center, r + 7, 0, TAU, 48, Color(candy.outline.r, candy.outline.g, candy.outline.b, 0.12), 2.0, true)
	else:
		draw_arc(center, r, 0, TAU, 48, candy.outline, 2.5, true)
		draw_arc(center, r + 3, 0, TAU, 48, Color(candy.outline.r, candy.outline.g, candy.outline.b, 0.15), 1.5, true)

	# Bottom edge shadow.
	draw_arc(center, r - 1, 0.15, PI - 0.15, 24, Color(0, 0, 0, 0.16), 2.5, true)

	# Letter glyph.
	var f: Font = TILE_FONT
	var fs := 50
	var ts := f.get_string_size(letter, HORIZONTAL_ALIGNMENT_CENTER, -1, fs)
	var ascent := f.get_ascent(fs)
	var descent := f.get_descent(fs)
	var base := Vector2(center.x - ts.x * 0.5, center.y + (ascent - descent) * 0.5 + 1.0)
	draw_string(f, base + Vector2(0, 4), letter, HORIZONTAL_ALIGNMENT_CENTER, -1, fs, Color(0, 0, 0, 0.52))
	draw_string(f, base + Vector2(1, 2), letter, HORIZONTAL_ALIGNMENT_CENTER, -1, fs, Color(0, 0, 0, 0.28))
	for o in [Vector2(-0.8, 0), Vector2(0.8, 0), Vector2(0, -0.6), Vector2(0, 0.6)]:
		draw_string(f, base + o, letter, HORIZONTAL_ALIGNMENT_CENTER, -1, fs, candy.ink)
	draw_string(f, base, letter, HORIZONTAL_ALIGNMENT_CENTER, -1, fs, candy.ink)
	_draw_letter_cues(center, letter, candy.ink)

	# Selection order badge (top-right).
	if state == State.MOVED and selection_index >= 0:
		var badge_r := 8.0
		var badge_pos := Vector2(size.x - badge_r - 2, badge_r + 2)
		draw_circle(badge_pos, badge_r + 1, Color(0, 0, 0, 0.3))
		draw_circle(badge_pos, badge_r, Color("#ff3aa8"))
		var num_str := str(selection_index + 1)
		var nfs := 10
		var nts := f.get_string_size(num_str, HORIZONTAL_ALIGNMENT_CENTER, -1, nfs)
		draw_string(f, badge_pos + Vector2(-nts.x * 0.5, f.get_ascent(nfs) * 0.5 - 1), num_str, HORIZONTAL_ALIGNMENT_CENTER, -1, nfs, Color.WHITE)

func _draw_letter_cues(center: Vector2, shown: String, col: Color) -> void:
	if shown == "I":
		var cue_shadow := Color(0, 0, 0, 0.22)
		draw_line(center + Vector2(-11, -18), center + Vector2(11, -18), cue_shadow, 5.0, true)
		draw_line(center + Vector2(-11, 18), center + Vector2(11, 18), cue_shadow, 5.0, true)
		draw_line(center + Vector2(-10, -19), center + Vector2(10, -19), col, 3.0, true)
		draw_line(center + Vector2(-10, 17), center + Vector2(10, 17), col, 3.0, true)
	elif shown == "D":
		draw_line(center + Vector2(-12, -19), center + Vector2(-12, 19), Color(0, 0, 0, 0.20), 3.0, true)

func _draw_gradient_circle(center: Vector2, r: float, top: Color, bot: Color) -> void:
	var bands := 20
	for i in bands:
		var t0: float = float(i) / float(bands)
		var t1: float = float(i + 1) / float(bands)
		var c: Color = top.lerp(bot, (t0 + t1) * 0.5)
		var y0: float = center.y - r + (2 * r) * t0
		var y1: float = center.y - r + (2 * r) * t1
		var mid: float = (y0 + y1) * 0.5 - center.y
		var hw: float = sqrt(maxf(r * r - mid * mid, 0.0))
		draw_rect(Rect2(Vector2(center.x - hw, y0), Vector2(hw * 2, y1 - y0)), c)
