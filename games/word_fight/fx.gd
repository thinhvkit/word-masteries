extends RefCounted
## Word Fight FX library — wooden backdrop, particle bursts, attack bolts,
## damage popups, shake, banners, and fireworks. All entry points are static
## so the main game script can call them as `Fx.X(parent, ...)`.

const TILE_SIZE := 56.0
const TILE_RADIUS := 12.0

# ---- letter color tiers (neutral gray so gem tiles pop) --------------------
const VOWEL_TOP    := Color("#e8e4e0")
const VOWEL_BOTTOM := Color("#c8c2ba")
const VOWEL_INK    := Color("#4a4440")

const COMMON_TOP    := Color("#e8e4e0")
const COMMON_BOTTOM := Color("#c8c2ba")
const COMMON_INK    := Color("#4a4440")

const UNCOMMON_TOP    := Color("#e8e4e0")
const UNCOMMON_BOTTOM := Color("#c8c2ba")
const UNCOMMON_INK    := Color("#4a4440")

const RARE_TOP    := Color("#e8e4e0")
const RARE_BOTTOM := Color("#c8c2ba")
const RARE_INK    := Color("#4a4440")

# Selected tiles use a unified hot pink/magenta gradient.
const SELECT_TOP    := Color("#ff7ad1")
const SELECT_BOTTOM := Color("#c81f8c")
const SELECT_INK    := Color("#ffffff")

# Every normal (non-gem) tile shares this neutral gray so gem tiles pop.
const NORMAL_TILE_TOP    := Color("#e8e4e0")
const NORMAL_TILE_BOTTOM := Color("#c8c2ba")
const NORMAL_TILE_INK    := Color("#4a4440")

const VOWELS := "AEIOU"
const COMMON := "NRTLSDG"
const RARE   := "JKQXZ"

static func tier_for_letter(ch: String) -> int:
	if VOWELS.find(ch) != -1: return 0          # vowel
	if RARE.find(ch) != -1:   return 3          # rare
	if COMMON.find(ch) != -1: return 1          # common
	return 2                                     # uncommon

static func gradient_for_letter(ch: String) -> Array:
	match tier_for_letter(ch):
		0: return [VOWEL_TOP, VOWEL_BOTTOM, VOWEL_INK]
		1: return [COMMON_TOP, COMMON_BOTTOM, COMMON_INK]
		3: return [RARE_TOP, RARE_BOTTOM, RARE_INK]
		_: return [UNCOMMON_TOP, UNCOMMON_BOTTOM, UNCOMMON_INK]

# ---- damage popup ---------------------------------------------------------
static func damage_popup(parent: Control, world_pos: Vector2, amount: int, big: bool = false, color: Color = Color.WHITE) -> void:
	var lbl := Label.new()
	lbl.text = "-%d" % amount
	lbl.add_theme_font_size_override("font_size", 32 if big else 22)
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.65))
	lbl.add_theme_constant_override("outline_size", 6)
	lbl.position = world_pos
	lbl.pivot_offset = Vector2(20, 12)
	lbl.z_index = 100
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(lbl)
	var tw := parent.create_tween()
	tw.set_parallel(true)
	tw.tween_property(lbl, "position:y", world_pos.y - (60.0 if big else 44.0), 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(lbl, "scale", Vector2(1.4, 1.4) if big else Vector2(1.15, 1.15), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.chain().tween_property(lbl, "modulate:a", 0.0, 0.4)
	tw.chain().tween_callback(lbl.queue_free)

## Floating "+text" popup used for XP/score gains in non-combat contexts.
static func score_popup(parent: Control, world_pos: Vector2, text: String, big: bool = false, color: Color = Color("#ffd027")) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 30 if big else 22)
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.65))
	lbl.add_theme_constant_override("outline_size", 6)
	lbl.position = world_pos
	lbl.pivot_offset = Vector2(20, 12)
	lbl.z_index = 100
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(lbl)
	var tw := parent.create_tween()
	tw.set_parallel(true)
	tw.tween_property(lbl, "position:y", world_pos.y - (60.0 if big else 44.0), 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(lbl, "scale", Vector2(1.35, 1.35) if big else Vector2(1.15, 1.15), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.chain().tween_property(lbl, "modulate:a", 0.0, 0.4)
	tw.chain().tween_callback(lbl.queue_free)

static func damage_color_for(amount: int) -> Color:
	if amount >= 650: return Color("#ff3838")   # crimson
	if amount >= 350: return Color("#ff7a1f")   # orange
	if amount >= 150: return Color("#ffd027")   # gold
	return Color.WHITE

## Sets `label.text` and shrinks its font size (down to `min_size`) so the text
## fits `max_width` px on one line — keeps long words from overflowing the
## screen. Pair with an autowrap mode as a safety net for extreme lengths.
static func fit_label_font(label: Label, text: String, base_size: int, max_width: float, min_size: int = 13) -> void:
	if label == null:
		return
	label.text = text
	label.add_theme_font_size_override("font_size", base_size)
	if text.is_empty() or max_width <= 0.0:
		return
	var font := label.get_theme_font("font")
	if font == null:
		return
	var w: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, base_size).x
	if w <= max_width:
		return
	var scaled: int = int(floor(float(base_size) * max_width / w))
	label.add_theme_font_size_override("font_size", maxi(scaled, min_size))

# ---- gem tiles ------------------------------------------------------------
# Indices match WFTile.Gem: 0 NORMAL,1 FIRE,2 ICE,3 GOLD,4 POISON,5 DIAMOND,6 HEALING.

## [top, bottom, ink] gradient for a gem fill. NORMAL returns [] (use letter tier).
static func gem_gradient(gem_type: int) -> Array:
	match gem_type:
		1: return [Color("#ff9a6b"), Color("#ff5a3c"), Color("#5e1500")]   # fire
		2: return [Color("#cbecff"), Color("#4db4ff"), Color("#06375e")]   # ice
		3: return [Color("#ffe488"), Color("#ffc01f"), Color("#6e4a00")]   # gold
		4: return [Color("#9fe88f"), Color("#3da94f"), Color("#123e12")]   # poison
		5: return [Color("#bdf6f6"), Color("#2fd6d6"), Color("#064a4a")]   # diamond
		6: return [Color("#e3c8ff"), Color("#a259f0"), Color("#2e0a55")]   # healing
		_: return []

## Bright accent (ring / glow / pip) for a gem.
static func gem_accent(gem_type: int) -> Color:
	match gem_type:
		1: return Color("#ff3c1a")
		2: return Color("#1f9fff")
		3: return Color("#ffb300")
		4: return Color("#2fc04c")
		5: return Color("#18e6e6")
		6: return Color("#b86bff")
		_: return Color.WHITE

## Translucent tint drawn over a tile carrying an enemy hazard.
## Indices match WFTile.Hazard: 0 NONE,1 BURNING,2 LOCKED,3 STONE,4 POISONED.
static func hazard_overlay(hazard_type: int) -> Color:
	match hazard_type:
		1: return Color(1.0, 0.35, 0.05, 0.42)    # burning
		2: return Color(0.55, 0.72, 0.95, 0.5)    # locked / frozen
		3: return Color(0.42, 0.42, 0.46, 0.92)   # stone (near-opaque)
		4: return Color(0.30, 0.52, 0.16, 0.55)   # poisoned
		_: return Color(0, 0, 0, 0)

## Floating green "+N" popup for healing.
static func heal_popup(parent: Control, world_pos: Vector2, amount: int) -> void:
	var lbl := Label.new()
	lbl.text = "+%d" % amount
	lbl.add_theme_font_size_override("font_size", 26)
	lbl.add_theme_color_override("font_color", Color("#54e07a"))
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.65))
	lbl.add_theme_constant_override("outline_size", 6)
	lbl.position = world_pos
	lbl.pivot_offset = Vector2(20, 12)
	lbl.z_index = 100
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(lbl)
	var tw := parent.create_tween()
	tw.set_parallel(true)
	tw.tween_property(lbl, "position:y", world_pos.y - 52.0, 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(lbl, "scale", Vector2(1.25, 1.25), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.chain().tween_property(lbl, "modulate:a", 0.0, 0.4)
	tw.chain().tween_callback(lbl.queue_free)

# ---- shake ----------------------------------------------------------------
static func shake(node: Control, intensity: float = 6.0, duration: float = 0.35) -> void:
	if node == null: return
	var base := node.position
	var tw := node.create_tween()
	var steps := int(round(duration / 0.04))
	for i in steps:
		var t: float = 1.0 - float(i) / float(steps)
		var off := Vector2(randf_range(-1, 1), randf_range(-1, 1)) * intensity * t
		tw.tween_property(node, "position", base + off, 0.04)
	tw.tween_property(node, "position", base, 0.04)

# ---- sparkle burst at a tile ---------------------------------------------
static func sparkle_burst(parent: Control, world_pos: Vector2, color: Color, count: int = 8) -> void:
	for i in count:
		var dot := _SparkleDot.new(color)
		dot.position = world_pos
		dot.z_index = 50
		parent.add_child(dot)
		var ang := randf() * TAU
		var dist := randf_range(18, 38)
		var target := world_pos + Vector2(cos(ang), sin(ang)) * dist
		var tw := parent.create_tween()
		tw.set_parallel(true)
		tw.tween_property(dot, "position", target, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(dot, "scale", Vector2(0.2, 0.2), 0.45)
		tw.tween_property(dot, "modulate:a", 0.0, 0.45)
		tw.chain().tween_callback(dot.queue_free)

class _SparkleDot extends Control:
	var col: Color
	func _init(c: Color) -> void:
		col = c
		size = Vector2(8, 8)
		pivot_offset = Vector2(4, 4)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		draw_circle(Vector2(4, 4), 4, col)
		draw_circle(Vector2(4, 4), 2, Color.WHITE)

# ---- confetti from tiles toward enemy ------------------------------------
static func confetti_to(parent: Control, from_positions: Array, target: Vector2, colors: Array) -> void:
	for i in from_positions.size():
		var start: Vector2 = from_positions[i]
		var col: Color = colors[i % colors.size()]
		for k in 3:
			var c := _ConfettiChip.new(col)
			c.position = start + Vector2(randf_range(-6, 6), randf_range(-6, 6))
			c.z_index = 60
			parent.add_child(c)
			var ctrl := start.lerp(target, 0.5) + Vector2(randf_range(-40, 40), -randf_range(20, 80))
			var dur := randf_range(0.45, 0.7)
			var tw := parent.create_tween()
			tw.set_parallel(true)
			var advance := func(t: float) -> void:
				if not is_instance_valid(c): return
				var a := start.lerp(ctrl, t)
				var b := ctrl.lerp(target, t)
				c.position = a.lerp(b, t)
				c.rotation = t * 6.0
			tw.tween_method(advance, 0.0, 1.0, dur).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
			tw.tween_property(c, "modulate:a", 0.0, dur).set_delay(dur * 0.55)
			tw.chain().tween_callback(Callable(c, "queue_free"))

class _ConfettiChip extends Control:
	var col: Color
	func _init(c: Color) -> void:
		col = c
		size = Vector2(8, 4)
		pivot_offset = Vector2(4, 2)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), col)

# ---- Word Match tier bursts / stamps --------------------------------------
static func word_burst(parent: Control, center: Vector2, count: int, colors: Array,
		radius: float = 90.0, include_stars: bool = false, include_confetti: bool = false) -> void:
	if parent == null:
		return
	if colors.is_empty():
		colors = [Color.WHITE]
	for i in count:
		var col: Color = colors[i % colors.size()]
		var p := _WordBurstParticle.new(col, include_stars and i % 4 == 0, include_confetti and i % 3 == 0)
		p.position = center
		p.z_index = 180
		parent.add_child(p)
		var ang := randf() * TAU
		var dist := randf_range(radius * 0.35, radius)
		var target := center + Vector2(cos(ang), sin(ang)) * dist
		var dur := randf_range(0.36, 0.52)
		var tw := parent.create_tween()
		tw.set_parallel(true)
		tw.tween_property(p, "position", target, dur).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(p, "scale", Vector2(0.25, 0.25), dur)
		tw.tween_property(p, "rotation", randf_range(-PI, PI), dur)
		tw.tween_property(p, "modulate:a", 0.0, dur).set_delay(dur * 0.35)
		tw.chain().tween_callback(p.queue_free)

static func board_rim_flash(parent: Control, target: Control, color: Color, pulses: int = 3) -> void:
	if parent == null or target == null:
		return
	var rim := _RimFlash.new(color, pulses)
	rim.position = target.global_position - parent.global_position
	rim.size = target.size
	rim.z_index = 170
	parent.add_child(rim)
	var tw := parent.create_tween()
	var advance := func(v: float) -> void:
		if is_instance_valid(rim):
			rim.progress = v
			rim.queue_redraw()
	tw.tween_method(advance, 0.0, 1.0, 0.48)
	tw.tween_callback(rim.queue_free)

static func stamp(parent: Control, center: Vector2, text: String = "X", color: Color = Color("#ff3838")) -> void:
	if parent == null:
		return
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 34)
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.55))
	lbl.add_theme_constant_override("outline_size", 5)
	lbl.position = center - Vector2(18, 24)
	lbl.rotation = -0.18
	lbl.scale = Vector2(0.3, 0.3)
	lbl.modulate.a = 0.0
	lbl.z_index = 220
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(lbl)
	var tw := parent.create_tween()
	tw.set_parallel(true)
	tw.tween_property(lbl, "modulate:a", 1.0, 0.08)
	tw.tween_property(lbl, "scale", Vector2(1.15, 1.15), 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.chain().tween_interval(0.28)
	tw.chain().tween_property(lbl, "modulate:a", 0.0, 0.18)
	tw.chain().tween_callback(lbl.queue_free)

class _WordBurstParticle extends Control:
	var col: Color
	var star := false
	var confetti := false
	func _init(c: Color, is_star: bool, is_confetti: bool) -> void:
		col = c
		star = is_star
		confetti = is_confetti
		size = Vector2(10, 10)
		pivot_offset = size * 0.5
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		if confetti:
			draw_rect(Rect2(Vector2(1, 3), Vector2(8, 4)), col)
		elif star:
			draw_line(Vector2(5, 0), Vector2(5, 10), col, 2.2, true)
			draw_line(Vector2(0, 5), Vector2(10, 5), col, 2.2, true)
			draw_line(Vector2(2, 2), Vector2(8, 8), Color.WHITE, 1.2, true)
			draw_line(Vector2(8, 2), Vector2(2, 8), Color.WHITE, 1.2, true)
		else:
			draw_circle(Vector2(5, 5), 4.0, col)
			draw_circle(Vector2(5, 5), 1.8, Color.WHITE)

class _RimFlash extends Control:
	var col: Color
	var pulses: int
	var progress := 0.0
	func _init(c: Color, p: int) -> void:
		col = c
		pulses = maxi(1, p)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		var phase := sin(progress * float(pulses) * PI)
		var a := clampf(phase, 0.0, 1.0) * (1.0 - progress * 0.25)
		var r := minf(28.0, minf(size.x, size.y) * 0.5)
		for k in 4:
			var inset := float(k) * 4.0
			var rect := Rect2(Vector2(inset, inset), size - Vector2(inset * 2.0, inset * 2.0))
			_round_outline(rect, Color(col.r, col.g, col.b, a * (0.9 - k * 0.16)), r, 5.0 - k * 0.6)
	func _round_outline(rect: Rect2, color: Color, r: float, width: float) -> void:
		var rr: float = minf(r, minf(rect.size.x, rect.size.y) * 0.5)
		var p := rect.position
		var sz := rect.size
		draw_line(p + Vector2(rr, 0), p + Vector2(sz.x - rr, 0), color, width, true)
		draw_line(p + Vector2(rr, sz.y), p + Vector2(sz.x - rr, sz.y), color, width, true)
		draw_line(p + Vector2(0, rr), p + Vector2(0, sz.y - rr), color, width, true)
		draw_line(p + Vector2(sz.x, rr), p + Vector2(sz.x, sz.y - rr), color, width, true)
		draw_arc(p + Vector2(rr, rr), rr, PI, PI * 1.5, 16, color, width, true)
		draw_arc(p + Vector2(sz.x - rr, rr), rr, -PI * 0.5, 0, 16, color, width, true)
		draw_arc(p + Vector2(rr, sz.y - rr), rr, PI * 0.5, PI, 16, color, width, true)
		draw_arc(p + Vector2(sz.x - rr, sz.y - rr), rr, 0, PI * 0.5, 16, color, width, true)

# ---- fireworks (rainbow earned) ------------------------------------------
static func fireworks(parent: Control, center: Vector2) -> void:
	var palette := [
		Color("#ff3aa8"), Color("#ffd027"), Color("#3aa8ff"),
		Color("#7a55ff"), Color("#3ad6a8"), Color("#ff7a1f"),
	]
	for burst in 3:
		var delay := burst * 0.18
		var origin := center + Vector2(randf_range(-60, 60), randf_range(-40, 40))
		for j in 18:
			var col: Color = palette[(burst * 5 + j) % palette.size()]
			var dot := _SparkleDot.new(col)
			dot.position = origin
			dot.z_index = 200
			dot.modulate.a = 0.0
			parent.add_child(dot)
			var ang := TAU * float(j) / 18.0
			var dist := randf_range(50, 120)
			var target := origin + Vector2(cos(ang), sin(ang)) * dist
			var tw := parent.create_tween()
			tw.tween_interval(delay)
			tw.set_parallel(true)
			tw.tween_property(dot, "modulate:a", 1.0, 0.08)
			tw.tween_property(dot, "position", target, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.tween_property(dot, "scale", Vector2(0.3, 0.3), 0.7)
			tw.chain().tween_property(dot, "modulate:a", 0.0, 0.2)
			tw.chain().tween_callback(dot.queue_free)

# ---- topic-match golden banner -------------------------------------------
static func banner(parent: Control, text: String, bg: Color, fg: Color = Color.WHITE) -> void:
	var b := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(99)
	sb.shadow_color = Color(0, 0, 0, 0.25)
	sb.shadow_size = 8
	sb.content_margin_left = 20
	sb.content_margin_right = 20
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	b.add_theme_stylebox_override("panel", sb)
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_color_override("font_color", fg)
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.4))
	lbl.add_theme_constant_override("outline_size", 4)
	b.add_child(lbl)
	b.modulate.a = 0.0
	b.scale = Vector2(0.6, 0.6)
	b.z_index = 250
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(b)
	# Center horizontally near the top of the screen.
	await parent.get_tree().process_frame
	var sz := b.size
	var p := parent.size
	b.position = Vector2((p.x - sz.x) * 0.5, p.y * 0.22)
	b.pivot_offset = sz * 0.5
	var tw := parent.create_tween()
	tw.set_parallel(true)
	tw.tween_property(b, "modulate:a", 1.0, 0.15)
	tw.tween_property(b, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.chain().tween_interval(0.9)
	tw.chain().tween_property(b, "modulate:a", 0.0, 0.3)
	tw.chain().tween_callback(b.queue_free)

# ---- attack: projectile bolt, impact burst, slash, hit flash --------------
## A glowing comet that flies from `from_pos` to `to_pos`, leaving a muzzle
## spark behind and calling `on_impact` the instant it lands.
static func strike_bolt(parent: Control, from_pos: Vector2, to_pos: Vector2, color: Color, on_impact: Callable = Callable()) -> void:
	if parent == null: return
	sparkle_burst(parent, from_pos, color, 5)            # muzzle flash
	var bolt := _StrikeBolt.new(color)
	bolt.position = from_pos
	bolt.rotation = (to_pos - from_pos).angle()
	bolt.z_index = 120
	parent.add_child(bolt)
	var dur: float = clampf(from_pos.distance_to(to_pos) / 1500.0, 0.16, 0.36)
	var finish := func() -> void:
		if on_impact.is_valid():
			on_impact.call()
		if is_instance_valid(bolt):
			bolt.queue_free()
	var tw := parent.create_tween()
	tw.tween_property(bolt, "position", to_pos, dur).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	tw.tween_callback(finish)

class _StrikeBolt extends Control:
	var col: Color
	func _init(c: Color) -> void:
		col = c
		size = Vector2(2, 2)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		# Tapering tail trailing behind the head (head at origin, tail toward -x).
		for i in 7:
			var f: float = float(i) / 6.0
			draw_circle(Vector2(-f * 34.0, 0), lerp(10.0, 1.0, f),
				Color(col.r, col.g, col.b, (1.0 - f) * 0.55))
		draw_circle(Vector2.ZERO, 10.0, Color(col.r, col.g, col.b, 0.85))
		draw_circle(Vector2.ZERO, 6.0, Color(1, 1, 1, 0.95))

## Expanding shockwave ring + white core flash + radial spark debris.
static func impact_burst(parent: Control, world_pos: Vector2, color: Color, big: bool = false) -> void:
	if parent == null: return
	var ring := _ImpactRing.new(color, big)
	ring.position = world_pos
	ring.z_index = 110
	parent.add_child(ring)
	var step := func(v: float) -> void:
		if is_instance_valid(ring):
			ring.progress = v
			ring.queue_redraw()
	var tw := parent.create_tween()
	tw.tween_method(step, 0.0, 1.0, 0.42 if big else 0.32).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_callback(ring.queue_free)
	sparkle_burst(parent, world_pos, color, 11 if big else 7)

class _ImpactRing extends Control:
	var col: Color
	var big: bool
	var progress: float = 0.0
	func _init(c: Color, b: bool) -> void:
		col = c
		big = b
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		var max_r: float = 70.0 if big else 46.0
		var r: float = lerp(8.0, max_r, progress)
		var a: float = 1.0 - progress
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 44,
			Color(col.r, col.g, col.b, a * 0.9), lerp(8.0, 1.0, progress), true)
		if progress < 0.45:
			var fa: float = 1.0 - progress / 0.45
			draw_circle(Vector2.ZERO, lerp(6.0, 26.0, progress), Color(1, 1, 1, fa * 0.75))

## Two bright diagonal slash streaks — punctuates a heavy hit.
static func slash(parent: Control, world_pos: Vector2, color: Color) -> void:
	if parent == null: return
	var mark := _SlashMark.new(color)
	mark.position = world_pos
	mark.z_index = 130
	parent.add_child(mark)
	var step := func(v: float) -> void:
		if is_instance_valid(mark):
			mark.progress = v
			mark.queue_redraw()
	var tw := parent.create_tween()
	tw.tween_method(step, 0.0, 1.0, 0.34).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_callback(mark.queue_free)

class _SlashMark extends Control:
	var col: Color
	var ang: float
	var progress: float = 0.0
	func _init(c: Color) -> void:
		col = c
		ang = -0.7 + randf_range(-0.25, 0.25)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		var dir := Vector2(cos(ang), sin(ang))
		var nrm := Vector2(-dir.y, dir.x)
		var grow: float = clampf(progress * 2.2, 0.0, 1.0)
		var a: float = clampf((1.0 - progress) * 1.5, 0.0, 1.0)
		var half: float = 42.0 * grow
		for k in 2:
			var off := nrm * (float(k) * 16.0 - 8.0)
			var p0 := off - dir * half
			var p1 := off + dir * half
			draw_line(p0, p1, Color(col.r, col.g, col.b, a), lerp(8.0, 2.0, progress), true)
			draw_line(p0, p1, Color(1, 1, 1, a * 0.85), lerp(3.5, 1.0, progress), true)

## Brief overbright flash on a node — a combatant reacting to a hit.
static func hit_flash(node: CanvasItem, tint: Color = Color(1.9, 1.25, 1.25)) -> void:
	if node == null: return
	var tw := node.create_tween()
	tw.tween_property(node, "modulate", tint, 0.06)
	tw.tween_property(node, "modulate", Color(1, 1, 1, 1), 0.24)

static func set_landscape() -> void:
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_LANDSCAPE)
	if OS.has_feature("web"):
		JavaScriptBridge.eval("try{screen.orientation.lock('landscape')}catch(e){}")
	elif not OS.has_feature("mobile"):
		var ws := DisplayServer.window_get_size()
		if ws.x < ws.y:
			DisplayServer.window_set_size(Vector2i(ws.y, ws.x))

static func set_portrait() -> void:
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
	if OS.has_feature("web"):
		JavaScriptBridge.eval("try{screen.orientation.unlock()}catch(e){}")
	elif not OS.has_feature("mobile"):
		var ws := DisplayServer.window_get_size()
		if ws.x > ws.y:
			DisplayServer.window_set_size(Vector2i(ws.y, ws.x))

# ---------- shared mono backdrop ----------
## Clean gradient panel with subtle glow, thin border.
## `Fx.BoardBG.new()` then add_child.
class BoardBG extends Control:
	var radius: float = 0.0

	var glow_color := Color(1, 1, 1, 0.08)
	var bg_top := Color("#2e2e2e")
	var bg_bot := Color("#1a1a1a")
	var border_color := Color(1, 1, 1, 0.12)

	const _THEMES := [
		{"glow": Color(1, 1, 1, 0.08), "top": Color("#2e2e2e"), "bot": Color("#1a1a1a"), "border": Color(1, 1, 1, 0.12)},
		{"glow": Color(0.95, 0.88, 0.72, 0.10), "top": Color("#332e28"), "bot": Color("#1e1a14"), "border": Color(0.85, 0.75, 0.55, 0.14)},
		{"glow": Color(0.95, 0.65, 0.35, 0.10), "top": Color("#352a22"), "bot": Color("#201410"), "border": Color(0.90, 0.60, 0.30, 0.14)},
		{"glow": Color(0.85, 0.55, 0.60, 0.10), "top": Color("#322428"), "bot": Color("#1e1216"), "border": Color(0.80, 0.50, 0.55, 0.14)},
	]

	func set_world(world_idx: int) -> void:
		var t: Dictionary = _THEMES[clampi(world_idx, 0, _THEMES.size() - 1)]
		glow_color = t.glow
		bg_top = t.top
		bg_bot = t.bot
		border_color = t.border
		queue_redraw()

	func _ready() -> void:
		clip_contents = true

	func _draw() -> void:
		var r: float = minf(radius, minf(size.x, size.y) * 0.5)
		# Gradient fill via horizontal bands + corner circles.
		var bands := 24
		for i in bands:
			var t0: float = float(i) / float(bands)
			var t1: float = float(i + 1) / float(bands)
			var c: Color = bg_top.lerp(bg_bot, (t0 + t1) * 0.5)
			var y0: float = t0 * size.y
			var y1: float = t1 * size.y
			var chord0: float = _corner_chord_at_y(y0, r, size.y)
			var chord1: float = _corner_chord_at_y(y1, r, size.y)
			var chord: float = maxf(chord0, chord1)
			if chord < size.x * 0.5:
				draw_rect(Rect2(Vector2(chord, y0), Vector2(size.x - chord * 2, y1 - y0)), c)
		# Corner circles with gradient-matched colors.
		var rr: float = r
		if rr > 0.5:
			var c_top: Color = bg_top.lerp(bg_bot, rr / size.y * 0.5)
			var c_bot: Color = bg_top.lerp(bg_bot, 1.0 - rr / size.y * 0.5)
			draw_circle(Vector2(rr, rr), rr, c_top)
			draw_circle(Vector2(size.x - rr, rr), rr, c_top)
			draw_circle(Vector2(rr, size.y - rr), rr, c_bot)
			draw_circle(Vector2(size.x - rr, size.y - rr), rr, c_bot)
		# Subtle center glow.
		var cx: float = size.x * 0.5
		var cy: float = size.y * 0.5
		var gc := Color(glow_color.r, glow_color.g, glow_color.b)
		draw_circle(Vector2(cx, cy), minf(size.x, size.y) * 0.38, Color(gc.r, gc.g, gc.b, glow_color.a * 0.5))
		draw_circle(Vector2(cx, cy), minf(size.x, size.y) * 0.20, Color(gc.r, gc.g, gc.b, glow_color.a * 0.3))
		# Inner highlight.
		_round_rect_outline(Rect2(Vector2(1, 1), size - Vector2(2, 2)), Color(1, 1, 1, 0.04), r - 1, 1.0)
		# Thin border.
		_round_rect_outline(Rect2(Vector2.ZERO, size), border_color, r, 1.5)

	func _corner_chord_at_y(y: float, r: float, h: float) -> float:
		var d: float = -1.0
		if y < r:
			d = r - y
		elif y > h - r:
			d = r - (h - y)
		if d < 0.0:
			return 0.0
		return r - sqrt(maxf(r * r - d * d, 0.0))

	func _round_rect(rect: Rect2, color: Color, r: float) -> void:
		var rr: float = minf(r, minf(rect.size.x, rect.size.y) * 0.5)
		draw_rect(Rect2(rect.position + Vector2(rr, 0), Vector2(rect.size.x - 2 * rr, rect.size.y)), color)
		draw_rect(Rect2(rect.position + Vector2(0, rr), Vector2(rect.size.x, rect.size.y - 2 * rr)), color)
		draw_circle(rect.position + Vector2(rr, rr), rr, color)
		draw_circle(rect.position + Vector2(rect.size.x - rr, rr), rr, color)
		draw_circle(rect.position + Vector2(rr, rect.size.y - rr), rr, color)
		draw_circle(rect.position + Vector2(rect.size.x - rr, rect.size.y - rr), rr, color)

	func _round_rect_outline(rect: Rect2, color: Color, r: float, width: float) -> void:
		var rr: float = minf(r, minf(rect.size.x, rect.size.y) * 0.5)
		var p := rect.position
		var sz := rect.size
		draw_line(p + Vector2(rr, 0), p + Vector2(sz.x - rr, 0), color, width)
		draw_line(p + Vector2(rr, sz.y), p + Vector2(sz.x - rr, sz.y), color, width)
		draw_line(p + Vector2(0, rr), p + Vector2(0, sz.y - rr), color, width)
		draw_line(p + Vector2(sz.x, rr), p + Vector2(sz.x, sz.y - rr), color, width)
		draw_arc(p + Vector2(rr, rr), rr, PI, PI * 1.5, 16, color, width)
		draw_arc(p + Vector2(sz.x - rr, rr), rr, -PI * 0.5, 0, 16, color, width)
		draw_arc(p + Vector2(rr, sz.y - rr), rr, PI * 0.5, PI, 16, color, width)
		draw_arc(p + Vector2(sz.x - rr, sz.y - rr), rr, 0, PI * 0.5, 16, color, width)

# ---------- 2.5D battle arena backdrop ----------
## Full-screen landscape backdrop: graded sky, a glowing horizon, and a
## perspective floor plane that grounds the two combatants in a 2.5D stage.
class ArenaBG extends Control:
	const THEMES := [
		{"sky_top": Color("#0f1a12"), "sky_bot": Color("#3a7a3f"), "floor_top": Color("#1f3a22"), "floor_bot": Color("#080e08"), "glow": Color(0.4, 0.9, 0.5, 0.14), "line": Color(0.5, 1, 0.6, 0.06)},
		{"sky_top": Color("#12122a"), "sky_bot": Color("#c4943a"), "floor_top": Color("#5a5a7a"), "floor_bot": Color("#0e0e1a"), "glow": Color(1.0, 0.9, 0.6, 0.2), "line": Color(1, 0.95, 0.8, 0.07)},
		{"sky_top": Color("#1a0e04"), "sky_bot": Color("#c46a1a"), "floor_top": Color("#6a3a18"), "floor_bot": Color("#0e0604"), "glow": Color(1.0, 0.7, 0.3, 0.18), "line": Color(1, 0.8, 0.5, 0.06)},
		{"sky_top": Color("#0e0408"), "sky_bot": Color("#5a1020"), "floor_top": Color("#2a0e16"), "floor_bot": Color("#060204"), "glow": Color(0.9, 0.2, 0.3, 0.16), "line": Color(0.9, 0.3, 0.4, 0.06)},
	]

	var sky_top := Color("#2c1f5e")
	var sky_bot := Color("#e09a6a")
	var floor_top := Color("#7a4f9c")
	var floor_bot := Color("#1d1230")
	var glow_color := Color(1, 0.86, 0.62, 0.18)
	var line_color := Color(1, 1, 1, 0.07)

	func set_world(world_idx: int) -> void:
		var t: Dictionary = THEMES[clampi(world_idx, 0, THEMES.size() - 1)]
		sky_top = t.sky_top
		sky_bot = t.sky_bot
		floor_top = t.floor_top
		floor_bot = t.floor_bot
		glow_color = t.glow
		line_color = t.line
		queue_redraw()

	func _draw() -> void:
		var w := size.x
		var h := size.y
		var horizon: float = h * 0.5
		var bands := 22
		for i in bands:
			var y0: float = horizon * float(i) / bands
			var y1: float = horizon * float(i + 1) / bands
			draw_rect(Rect2(0, y0, w, y1 - y0), sky_top.lerp(sky_bot, float(i) / bands))
		draw_circle(Vector2(w * 0.5, horizon), h * 0.26, glow_color)
		draw_circle(Vector2(w * 0.5, horizon), h * 0.15, Color(glow_color.r, glow_color.g, glow_color.b, glow_color.a * 1.6))
		var fb := 18
		for i in fb:
			var y0: float = horizon + (h - horizon) * float(i) / fb
			var y1: float = horizon + (h - horizon) * float(i + 1) / fb
			draw_rect(Rect2(0, y0, w, y1 - y0), floor_top.lerp(floor_bot, float(i) / fb))
		var vp := Vector2(w * 0.5, horizon)
		for k in 13:
			var fx: float = w * (float(k) / 12.0 - 0.5) * 2.4 + w * 0.5
			draw_line(Vector2(fx, h), vp, line_color, 1.5, true)
		for k in range(1, 7):
			var t: float = float(k) / 6.0
			var yy: float = horizon + (h - horizon) * t * t
			draw_line(Vector2(0, yy), Vector2(w, yy), Color(line_color.r, line_color.g, line_color.b, line_color.a * 0.85), 1.5, true)
		for i in 8:
			var a: float = (1.0 - float(i) / 8.0) * 0.18
			draw_rect(Rect2(0, i * 4, w, 4), Color(0, 0, 0, a))
			draw_rect(Rect2(0, h - (i + 1) * 5, w, 5), Color(0, 0, 0, a))

# ---------- 2.5D combatant ----------
## A character standing on a lit 2.5D stage disc: graded platform, contact
## shadow, idle breathing, and attack / hit reactions. Owns its own sprite.
class Combatant extends Control:
	var facing := 1.0                       # +1 faces right, -1 faces left
	var accent := Color("#a7d99a")
	var active := false

	var _sprite: TextureRect
	var _sprite_base := Vector2.ZERO
	var _anim_offset := Vector2.ZERO        # tweened by attack/hit reactions
	var _t := 0.0                           # idle clock
	var _flash := 0.0                       # 0..1 hit overbright
	var _hurt := 0.0                        # 0..1 recoil lean
	var _glow := 0.0                        # active-turn pulse phase

	## Builds the sprite. `svg_path` may be missing (draws stage only).
	func setup(svg_path: String, face: float, accent_color: Color) -> void:
		facing = face
		accent = accent_color
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		clip_contents = false
		if ResourceLoader.exists(svg_path):
			_sprite = TextureRect.new()
			_sprite.texture = load(svg_path)
			_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			_sprite.flip_h = facing < 0.0
			_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(_sprite)
		resized.connect(_layout)
		_t = randf() * TAU
		set_process(true)
		_layout()

	func _layout() -> void:
		if _sprite == null:
			return
		var sw: float = size.x * 0.86
		var sh: float = size.y * 0.66
		_sprite.size = Vector2(sw, sh)
		_sprite_base = Vector2((size.x - sw) * 0.5, size.y * 0.06)
		_sprite.pivot_offset = Vector2(sw * 0.5, sh)

	func _process(delta: float) -> void:
		_t += delta
		if _flash > 0.0: _flash = maxf(0.0, _flash - delta * 4.0)
		if _hurt > 0.0: _hurt = maxf(0.0, _hurt - delta * 3.0)
		if active: _glow += delta * 3.2
		if _sprite != null:
			var bob: float = sin(_t * 1.9) * 3.0
			_sprite.position = _sprite_base + Vector2(0, bob) + _anim_offset
			var breathe: float = 1.0 + sin(_t * 1.9) * 0.025
			_sprite.scale = Vector2(breathe, breathe)
			_sprite.rotation = -facing * _hurt * 0.20
			_sprite.modulate = Color(1, 1, 1, 1).lerp(Color(2.1, 1.35, 1.35, 1), _flash)
		queue_redraw()

	## Body anchor point in global space — FX aim here.
	func body_global() -> Vector2:
		return global_position + Vector2(size.x * 0.5, size.y * 0.42)

	## Lunges toward the opponent, then springs back — sells a swing.
	func attack() -> void:
		var tw := create_tween()
		tw.tween_property(self, "_anim_offset", Vector2(facing * 26.0, -8.0), 0.12) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(self, "_anim_offset", Vector2.ZERO, 0.28) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	## Reacts to an incoming hit — overbright flash, recoil lean, and a shake.
	func take_hit(big: bool = false) -> void:
		_flash = 1.0
		_hurt = 1.0
		var mag: float = 9.0 if big else 5.0
		var tw := create_tween()
		for i in 5:
			var s: float = 1.0 - float(i) / 5.0
			tw.tween_property(self, "_anim_offset",
				Vector2(-facing * mag * s, randf_range(-mag, mag) * s * 0.5), 0.05)
		tw.tween_property(self, "_anim_offset", Vector2.ZERO, 0.06)

	func set_active(on: bool) -> void:
		active = on
		if not on:
			_glow = 0.0

	func _ellipse(c: Vector2, rx: float, ry: float, n: int) -> PackedVector2Array:
		var pts := PackedVector2Array()
		for i in n:
			var a := TAU * float(i) / float(n)
			pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
		return pts

	func _draw() -> void:
		var cx: float = size.x * 0.5
		var cy: float = size.y * 0.78
		var rx: float = size.x * 0.44
		var ry: float = size.x * 0.15
		# Active-turn glow ring beneath the disc.
		if active:
			var g: float = 0.5 + 0.5 * sin(_glow)
			draw_colored_polygon(_ellipse(Vector2(cx, cy), rx + 7.0 + g * 5.0, ry + 4.0 + g * 3.0, 30),
				Color(accent.r, accent.g, accent.b, 0.20 + 0.20 * g))
		# Stage disc — graded for depth.
		draw_colored_polygon(_ellipse(Vector2(cx, cy + 4.0), rx, ry, 30), accent.darkened(0.5))
		draw_colored_polygon(_ellipse(Vector2(cx, cy), rx, ry, 30), accent.darkened(0.15))
		draw_colored_polygon(_ellipse(Vector2(cx, cy - 1.5), rx * 0.72, ry * 0.66, 26), accent.lightened(0.16))
		# Contact shadow — shrinks as the idle bob lifts the character.
		var bob: float = sin(_t * 1.9) * 3.0
		var ss: float = 1.0 - bob * 0.045
		draw_colored_polygon(_ellipse(Vector2(cx, cy - ry * 0.18), rx * 0.6 * ss, ry * 0.6 * ss, 24),
			Color(0, 0, 0, 0.30))
