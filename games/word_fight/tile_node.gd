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

const SIZE := 64.0
const RADIUS := 12.0

## Beneficial special tiles. Order is referenced by Fx.gem_gradient/gem_accent.
enum Gem { NORMAL, FIRE, ICE, GOLD, POISON, DIAMOND, HEALING }
## Enemy-inflicted tile states. Order is referenced by Fx.hazard_overlay.
enum Hazard { NONE, BURNING, LOCKED, STONE, POISONED }

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
				var spark := Fx.gem_accent(gem) if gem != Gem.NORMAL else Fx.SELECT_BOTTOM
				tile_selected_fx.emit(self, spark)
		queue_redraw()

var rainbow: bool = false :
	set(v):
		rainbow = v
		_update_process()
		queue_redraw()

var dim: bool = false :
	set(v):
		dim = v
		var tw := create_tween()
		tw.tween_property(self, "modulate:a", 0.55 if dim else 1.0, 0.2)

## Beneficial gem type (see Gem enum).
var gem: int = Gem.NORMAL :
	set(v):
		gem = v
		_update_process()
		queue_redraw()

## Enemy hazard state (see Hazard enum).
var hazard: int = Hazard.NONE :
	set(v):
		hazard = v
		_update_process()
		queue_redraw()

var fire_fuse: int = 0 :       # FIRE gem — turns until it burns away
	set(v):
		fire_fuse = v
		queue_redraw()
var burn_fuse: int = 0 :       # BURNING hazard — turns until it scorches you
	set(v):
		burn_fuse = v
		queue_redraw()
var lock_turns: int = 0 :      # LOCKED hazard — turns until it thaws
	set(v):
		lock_turns = v
		queue_redraw()

var _rainbow_phase: float = 0.0
var _idle_phase: float = 0.0
var _haz_phase: float = 0.0

## True when the tile cannot be selected into a word.
func is_blocked() -> bool:
	return hazard == Hazard.LOCKED or hazard == Hazard.STONE

## Clears any gem + hazard state back to a plain tile.
func reset_special() -> void:
	gem = Gem.NORMAL
	hazard = Hazard.NONE
	fire_fuse = 0
	burn_fuse = 0
	lock_turns = 0

func _update_process() -> void:
	set_process(rainbow or hazard == Hazard.BURNING or gem != Gem.NORMAL)

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
	var redraw := false
	if rainbow:
		_rainbow_phase += delta * 1.6
		redraw = true
	if hazard == Hazard.BURNING or gem != Gem.NORMAL:
		_haz_phase += delta * 5.0
		redraw = true
	if redraw:
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
	var s := size.x
	var cut := s * 0.27
	var sel := selected_order >= 0
	var is_gem := gem != Gem.NORMAL
	var is_stone := hazard == Hazard.STONE
	var outer := _octagon(Vector2.ZERO, s, cut)

	# Drop shadow — octagon offset down.
	draw_colored_polygon(_octagon(Vector2(0, 5), s, cut), Color(0.12, 0.08, 0.22, 0.30))

	# --- fill colors: select overrides gem overrides letter tier ---
	var top: Color
	var bot: Color
	var ink: Color
	if sel:
		top = Fx.SELECT_TOP; bot = Fx.SELECT_BOTTOM; ink = Fx.SELECT_INK
	elif is_gem:
		var gg := Fx.gem_gradient(gem)
		top = gg[0]; bot = gg[1]; ink = gg[2]
	else:
		var lg := Fx.gradient_for_letter(letter)
		top = lg[0]; bot = lg[1]; ink = lg[2]

	# Outer bevel body.
	draw_colored_polygon(outer, bot.darkened(0.34))

	# Faceted bevel rim — 8 trapezoids lit by a top-left light source.
	var bw := s * 0.135
	var inner := _octagon(Vector2(bw, bw), s - bw * 2.0, cut - bw)
	var light := Vector2(0.55, 0.83)
	for i in 8:
		var o0: Vector2 = outer[i]
		var o1: Vector2 = outer[(i + 1) % 8]
		var i1: Vector2 = inner[(i + 1) % 8]
		var i0: Vector2 = inner[i]
		var edge := o1 - o0
		var nrm := Vector2(edge.y, -edge.x).normalized()
		var f: float = 0.5 + 0.5 * nrm.dot(-light)
		var facet := top.lerp(bot.darkened(0.2), 1.0 - f).lerp(Color.WHITE, f * 0.2)
		draw_colored_polygon(PackedVector2Array([o0, o1, i1, i0]), facet)

	# Inner table face — vertical gradient.
	_fill_octagon_gradient(Vector2(bw, bw), s - bw * 2.0, cut - bw, top, bot)

	# Sheen — soft white highlight across the upper table.
	draw_colored_polygon(PackedVector2Array([
		Vector2(bw + 3, bw + 3), Vector2(s - bw - 3, bw + 3),
		Vector2(s - bw - 9, s * 0.46), Vector2(bw + 9, s * 0.46)]),
		Color(1, 1, 1, 0.20))

	# --- enemy hazard tint over the fill ---
	if hazard != Hazard.NONE:
		draw_colored_polygon(outer, Fx.hazard_overlay(hazard))

	# --- border / glow ---
	if sel:
		_draw_poly_outline(outer, Color("#7a0e4a"), 2.6)
		_draw_poly_outline(_octagon(Vector2(-2.5, -2.5), s + 5.0, cut),
			Color(1.0, 0.5, 0.85, 0.6), 2.2)
	elif is_stone:
		_draw_poly_outline(outer, Color("#2b2b30"), 2.6)
	elif hazard == Hazard.LOCKED:
		_draw_poly_outline(outer, Color("#3a5e88"), 2.6)
	elif is_gem:
		_draw_poly_outline(outer, Fx.gem_accent(gem), 2.6)
	else:
		_draw_poly_outline(outer, Color(0, 0, 0, 0.22), 1.6)

	# Rainbow ring (animated hue rotation around the outline).
	if rainbow:
		for i in 6:
			var inset: float = 1.0 + i * 1.3
			var hue: float = fmod((float(i) / 6.0) + _rainbow_phase * 0.15, 1.0)
			_draw_poly_outline(_octagon(Vector2(inset, inset), s - inset * 2.0, cut - inset),
				Color.from_hsv(hue, 0.85, 1.0, 0.9), 1.6)

	# --- letter (hidden under stone) ---
	if not is_stone:
		var f: Font = TILE_FONT
		var fs := int(s * 0.5)
		var ts := f.get_string_size(letter, HORIZONTAL_ALIGNMENT_CENTER, -1, fs)
		var ascent := f.get_ascent(fs)
		var descent := f.get_descent(fs)
		var y := (size.y + ascent - descent) * 0.5
		var letter_ink := Color(ink, 0.5) if hazard == Hazard.LOCKED else ink
		# Drop shadow on the glyph for readability.
		draw_string(f, Vector2(size.x * 0.5 - ts.x * 0.5 + 1, y + 1),
			letter, HORIZONTAL_ALIGNMENT_CENTER, -1, fs, Color(0, 0, 0, 0.35))
		draw_string(f, Vector2(size.x * 0.5 - ts.x * 0.5, y),
			letter, HORIZONTAL_ALIGNMENT_CENTER, -1, fs, letter_ink)

	# --- hazard decorations ---
	match hazard:
		Hazard.STONE:    _draw_cracks()
		Hazard.LOCKED:   _draw_lock()
		Hazard.BURNING:  _draw_embers()
		Hazard.POISONED: _draw_blotches()

	# --- gem type emblem + idle effect ---
	if is_gem and not sel and not is_stone:
		_draw_gem_decor()

	# --- top-left timer badge ---
	if gem == Gem.FIRE and fire_fuse > 0:
		_draw_badge(str(fire_fuse), Color("#ff5a1f"))
	elif hazard == Hazard.BURNING and burn_fuse > 0:
		_draw_badge(str(burn_fuse), Color("#ff3c1a"))
	elif hazard == Hazard.LOCKED and lock_turns > 0:
		_draw_badge(str(lock_turns), Color("#3a6ea8"))

	# Order chip — top-right with bright magenta ring.
	if sel:
		var fchip: Font = TILE_FONT
		var chip_pos := Vector2(size.x - 10, 10)
		draw_circle(chip_pos, 9, Color("#7a0e4a"))
		draw_circle(chip_pos, 7, Color.WHITE)
		var num := str(selected_order + 1)
		var chip_fs := 11
		var ns := fchip.get_string_size(num, HORIZONTAL_ALIGNMENT_CENTER, -1, chip_fs)
		var n_ascent := fchip.get_ascent(chip_fs)
		var n_descent := fchip.get_descent(chip_fs)
		draw_string(fchip, Vector2(chip_pos.x - ns.x * 0.5, chip_pos.y + (n_ascent - n_descent) * 0.5),
			num, HORIZONTAL_ALIGNMENT_CENTER, -1, chip_fs, Color("#7a0e4a"))

# --------- hazard / badge decorations ---------
func _draw_badge(text: String, color: Color) -> void:
	var c := Vector2(11, 11)
	draw_circle(c, 9, Color(0, 0, 0, 0.55))
	draw_circle(c, 7.5, color)
	var f: Font = TILE_FONT
	var fs := 12
	var ts := f.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, fs)
	draw_string(f, Vector2(c.x - ts.x * 0.5, c.y + (f.get_ascent(fs) - f.get_descent(fs)) * 0.5),
		text, HORIZONTAL_ALIGNMENT_CENTER, -1, fs, Color.WHITE)

func _draw_cracks() -> void:
	var dark := Color(0.16, 0.16, 0.19, 0.85)
	draw_polyline(PackedVector2Array([
		Vector2(14, 8), Vector2(22, 22), Vector2(18, 34), Vector2(28, 47)]), dark, 2.2, true)
	draw_polyline(PackedVector2Array([
		Vector2(41, 9), Vector2(34, 24), Vector2(45, 39)]), dark, 2.0, true)
	draw_circle(Vector2(38, 18), 2.0, Color(1, 1, 1, 0.22))
	draw_circle(Vector2(21, 41), 1.6, Color(1, 1, 1, 0.18))

func _draw_lock() -> void:
	var ox := size.x - 14.0
	var oy := size.y - 15.0
	draw_arc(Vector2(ox, oy), 4.0, PI, TAU, 14, Color("#cdddf0"), 2.6)
	var body := Rect2(ox - 6.5, oy, 13.0, 9.5)
	_round_rect(body, Color("#e8f1fb"), 3.0)
	_round_rect_outline(body, Color("#5b7da5"), 3.0, 1.2)
	draw_circle(Vector2(ox, oy + 4.7), 1.7, Color("#5b7da5"))

func _draw_embers() -> void:
	var base_y := size.y - 5.0
	for i in 4:
		var ex: float = 10.0 + i * 12.0
		var h: float = 9.0 + sin(_haz_phase + i * 1.7) * 3.0
		var col := Color("#ffd23c") if i % 2 == 0 else Color("#ff6a1f")
		draw_colored_polygon(PackedVector2Array([
			Vector2(ex - 4, base_y), Vector2(ex + 4, base_y), Vector2(ex, base_y - h)]), col)
	draw_line(Vector2(6, base_y + 1), Vector2(size.x - 6, base_y + 1), Color(1, 0.4, 0.1, 0.6), 3.0)

func _draw_blotches() -> void:
	var spots := [
		[Vector2(16, 18), 6.5], [Vector2(40, 27), 8.0],
		[Vector2(24, 41), 5.0], [Vector2(43, 44), 4.0]]
	for s in spots:
		var p: Vector2 = s[0]
		var r: float = s[1]
		draw_circle(p, r, Color(0.11, 0.33, 0.07, 0.6))
		draw_circle(p - Vector2(r * 0.3, r * 0.3), r * 0.35, Color(0.62, 0.96, 0.42, 0.55))

# --------- gem type emblems + idle effects ---------
## Per-gem-type emblem + idle animation, mirroring the hazard decorations.
func _draw_gem_decor() -> void:
	match gem:
		Gem.FIRE:    _draw_gem_fire()
		Gem.ICE:     _draw_gem_ice()
		Gem.GOLD:    _draw_gem_gold()
		Gem.POISON:  _draw_gem_poison()
		Gem.DIAMOND: _draw_gem_diamond()
		Gem.HEALING: _draw_gem_healing()

## Bottom-left corner — a free spot (fuse badge is top-left, order chip top-right).
func _emblem_center() -> Vector2:
	return Vector2(13.0, size.y - 13.0)

func _offset_poly(pts: PackedVector2Array, off: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts:
		out.append(p + off)
	return out

## Filled convex emblem polygon with a soft dark drop-shadow.
func _emblem_poly(pts: PackedVector2Array) -> void:
	draw_colored_polygon(_offset_poly(pts, Vector2(1, 1.3)), Color(0, 0, 0, 0.32))
	draw_colored_polygon(pts, Color(1, 1, 1, 0.95))

## A small cross-shaped glint.
func _draw_spark(c: Vector2, r: float, col: Color) -> void:
	draw_line(c - Vector2(r, 0), c + Vector2(r, 0), col, 1.6)
	draw_line(c - Vector2(0, r), c + Vector2(0, r), col, 1.6)

func _draw_gem_fire() -> void:
	# Idle: embers drifting upward.
	for i in 3:
		var prog: float = fmod(_haz_phase * 0.32 + i * 0.37, 1.0)
		var ex: float = 19.0 + i * 11.0 + sin(_haz_phase * 1.3 + i) * 2.5
		var ey: float = size.y - 7.0 - prog * 32.0
		draw_circle(Vector2(ex, ey), maxf(2.4 - prog * 1.6, 0.3),
			Color(1.0, 0.78, 0.25, (1.0 - prog) * 0.85))
	# Emblem: a flickering flame.
	var c := _emblem_center()
	var flick: float = sin(_haz_phase * 1.7) * 1.6
	_emblem_poly(PackedVector2Array([
		c + Vector2(-4.5, 7), c + Vector2(4.5, 7), c + Vector2(flick, -9)]))
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(-2.4, 6), c + Vector2(2.4, 6), c + Vector2(flick * 0.6, -3.2)]),
		Color(1.0, 0.6, 0.18, 0.95))

func _draw_gem_ice() -> void:
	# Idle: twinkling frost glints.
	var glints := [Vector2(36, 14), Vector2(45, 27), Vector2(27, 11), Vector2(43, 40)]
	for i in glints.size():
		var tw: float = 0.5 + 0.5 * sin(_haz_phase * 1.7 + i * 1.9)
		_draw_spark(glints[i], 1.0 + tw * 2.4, Color(1, 1, 1, 0.2 + tw * 0.6))
	# Emblem: a 6-spoke snowflake.
	var c := _emblem_center()
	for k in 3:
		var d := Vector2(cos(PI / 3.0 * k), sin(PI / 3.0 * k)) * 6.5
		draw_line(c - d + Vector2(1, 1.3), c + d + Vector2(1, 1.3), Color(0, 0, 0, 0.3), 2.2)
	for k in 3:
		var d2 := Vector2(cos(PI / 3.0 * k), sin(PI / 3.0 * k)) * 6.5
		draw_line(c - d2, c + d2, Color(1, 1, 1, 0.95), 1.9)

func _draw_gem_gold() -> void:
	# Idle: a glint travelling diagonally across the tile.
	var s: float = fmod(_haz_phase * 0.22, 1.0)
	var gp := Vector2(9, 9).lerp(Vector2(size.x - 9, size.y - 9), s)
	_draw_spark(gp, 4.0 + sin(s * PI) * 4.0, Color(1, 1, 1, sin(s * PI) * 0.85))
	# Emblem: a 4-point sparkle star (two crossed diamonds).
	var c := _emblem_center()
	var r := 7.0
	_emblem_poly(PackedVector2Array([
		c + Vector2(0, -r), c + Vector2(r * 0.34, 0),
		c + Vector2(0, r), c + Vector2(-r * 0.34, 0)]))
	_emblem_poly(PackedVector2Array([
		c + Vector2(-r, 0), c + Vector2(0, -r * 0.34),
		c + Vector2(r, 0), c + Vector2(0, r * 0.34)]))

func _draw_gem_poison() -> void:
	# Idle: bubbles rising from the bottom.
	for i in 3:
		var prog: float = fmod(_haz_phase * 0.24 + i * 0.4, 1.0)
		var bx: float = 23.0 + i * 10.0 + sin(_haz_phase + i * 2.0) * 2.0
		var by: float = size.y - 6.0 - prog * 34.0
		draw_arc(Vector2(bx, by), 1.6 + i * 0.7, 0, TAU, 12,
			Color(0.85, 1.0, 0.7, (1.0 - prog) * 0.7), 1.3)
	# Emblem: a droplet (round base + pointed top).
	var c := _emblem_center()
	var tri := PackedVector2Array([
		c + Vector2(-3.4, 0.6), c + Vector2(3.4, 0.6), c + Vector2(0, -8.4)])
	draw_circle(c + Vector2(1, 2.6), 4.4, Color(0, 0, 0, 0.3))
	draw_colored_polygon(_offset_poly(tri, Vector2(1, 1.3)), Color(0, 0, 0, 0.3))
	draw_circle(c + Vector2(0, 1.3), 4.4, Color(1, 1, 1, 0.95))
	draw_colored_polygon(tri, Color(1, 1, 1, 0.95))

func _draw_gem_diamond() -> void:
	# Idle: shimmer ring + sparkle twinkles.
	var rect := Rect2(Vector2.ZERO, size)
	var sh: float = 0.5 + 0.5 * sin(_haz_phase)
	_round_rect_outline(rect.grow(-3), Color(1, 1, 1, 0.3 + 0.45 * sh), RADIUS - 3, 1.6)
	var spots := [Vector2(40, 15), Vector2(17, 20), Vector2(44, 39)]
	for i in spots.size():
		var tw: float = maxf(0.0, sin(_haz_phase * 1.5 + i * 2.1))
		_draw_spark(spots[i], 1.6 + tw * 4.0, Color(1, 1, 1, tw * 0.9))
	# Emblem: a cut gem.
	var c := _emblem_center()
	_emblem_poly(PackedVector2Array([
		c + Vector2(0, -7), c + Vector2(6, -1), c + Vector2(0, 8), c + Vector2(-6, -1)]))
	draw_line(c + Vector2(-6, -1), c + Vector2(6, -1), Color(0.16, 0.45, 0.52, 0.7), 1.0)

func _draw_gem_healing() -> void:
	# Idle: a gently pulsing halo ring.
	var rect := Rect2(Vector2.ZERO, size)
	var p: float = 0.5 + 0.5 * sin(_haz_phase * 0.7)
	_round_rect_outline(rect.grow(-2.0 - p * 3.0),
		Color(1, 1, 1, 0.12 + 0.3 * p), maxf(RADIUS - 2, 2), 2.0)
	# Emblem: a heart.
	var c := _emblem_center()
	_draw_heart(c + Vector2(1, 1.3), Color(0, 0, 0, 0.3))
	_draw_heart(c, Color(1, 1, 1, 0.95))

func _draw_heart(c: Vector2, col: Color) -> void:
	draw_circle(c + Vector2(-3, -2), 3.5, col)
	draw_circle(c + Vector2(3, -2), 3.5, col)
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(-6, -0.8), c + Vector2(6, -0.8), c + Vector2(0, 8)]), col)

# --------- drawing helpers ---------
func _round_rect(rect: Rect2, color: Color, radius: float) -> void:
	var r: float = minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
	draw_rect(Rect2(rect.position + Vector2(r, 0), Vector2(rect.size.x - 2*r, rect.size.y)), color)
	draw_rect(Rect2(rect.position + Vector2(0, r), Vector2(rect.size.x, rect.size.y - 2*r)), color)
	draw_circle(rect.position + Vector2(r, r), r, color)
	draw_circle(rect.position + Vector2(rect.size.x - r, r), r, color)
	draw_circle(rect.position + Vector2(r, rect.size.y - r), r, color)
	draw_circle(rect.position + Vector2(rect.size.x - r, rect.size.y - r), r, color)

# --------- octagon gem helpers ---------
## Eight corner points of a beveled-square (octagon) gem outline.
func _octagon(o: Vector2, s: float, cut: float) -> PackedVector2Array:
	var c: float = clampf(cut, 0.0, s * 0.5)
	return PackedVector2Array([
		o + Vector2(c, 0), o + Vector2(s - c, 0),
		o + Vector2(s, c), o + Vector2(s, s - c),
		o + Vector2(s - c, s), o + Vector2(c, s),
		o + Vector2(0, s - c), o + Vector2(0, c)])

## Closed outline stroke through an octagon's points.
func _draw_poly_outline(pts: PackedVector2Array, color: Color, width: float) -> void:
	var n := pts.size()
	for i in n:
		draw_line(pts[i], pts[(i + 1) % n], color, width, true)

## Vertical gradient fill clipped to an octagon, drawn as horizontal bands.
func _fill_octagon_gradient(o: Vector2, s: float, cut: float, top: Color, bot: Color) -> void:
	var bands := 14
	for b in bands:
		var t0: float = float(b) / float(bands)
		var t1: float = float(b + 1) / float(bands)
		var y0: float = s * t0
		var y1: float = s * t1
		var col := top.lerp(bot, (t0 + t1) * 0.5)
		var inset: float = maxf(maxf(cut - y0, cut - (s - y1)), 0.0)
		inset = minf(inset, s * 0.5)
		draw_rect(Rect2(o + Vector2(inset, y0), Vector2(s - inset * 2.0, y1 - y0)), col)

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
