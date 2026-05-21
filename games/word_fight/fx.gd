extends RefCounted
## Word Fight FX library — wooden backdrop, particle bursts, attack bolts,
## damage popups, shake, banners, and fireworks. All entry points are static
## so the main game script can call them as `Fx.X(parent, ...)`.

const TILE_SIZE := 56.0
const TILE_RADIUS := 12.0

# ---- letter color tiers (vibrant board, cozy frame) -----------------------
const VOWEL_TOP    := Color("#ffe27a")
const VOWEL_BOTTOM := Color("#ffb330")
const VOWEL_INK    := Color("#7a4a00")

const COMMON_TOP    := Color("#a8e7ff")
const COMMON_BOTTOM := Color("#3aa8ff")
const COMMON_INK    := Color("#093762")

const UNCOMMON_TOP    := Color("#c7b6ff")
const UNCOMMON_BOTTOM := Color("#7a55ff")
const UNCOMMON_INK    := Color("#2b1466")

const RARE_TOP    := Color("#ffb3e0")
const RARE_BOTTOM := Color("#ff3aa8")
const RARE_INK    := Color("#5e0e3a")

# Selected tiles use a unified hot pink/magenta gradient.
const SELECT_TOP    := Color("#ff7ad1")
const SELECT_BOTTOM := Color("#c81f8c")
const SELECT_INK    := Color("#ffffff")

# Every normal (non-gem) tile shares this one warm-cream gradient, so the
# saturated gem tiles are the only ones that read as special.
const NORMAL_TILE_TOP    := Color("#fff7ec")
const NORMAL_TILE_BOTTOM := Color("#ecdfca")
const NORMAL_TILE_INK    := Color("#5a4840")

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

# ---------- shared wooden backdrop ----------
## Reusable static backdrop: stacked wooden planks with grain + rounded
## corners. Each screen instantiates one via `Fx.BoardBG.new()` and
## (optionally) tunes `radius` before `add_child`.
class BoardBG extends Control:
	var radius: float = 18.0

	const _BASE := Color("#4a2f1a")
	const _GROOVE := Color("#33200f")
	const _PLANK_H := 56.0
	const _PLANK_TONES := [
		Color("#9c6b43"), Color("#8a5b38"), Color("#a87c4f"),
		Color("#915f3c"), Color("#b0855a"), Color("#82542f"),
	]

	func _ready() -> void:
		clip_contents = true

	func _draw() -> void:
		var r: float = minf(radius, minf(size.x, size.y) * 0.5)
		# Rounded dark base — shows through at the corner curves.
		_round_rect(Rect2(Vector2.ZERO, size), _BASE, r)
		# Stacked horizontal wooden planks.
		var plank_count: int = maxi(2, int(round(size.y / _PLANK_H)))
		var ph: float = size.y / float(plank_count)
		for i in plank_count:
			var y0: float = ph * i
			var y1: float = ph * (i + 1)
			var tone: Color = _PLANK_TONES[i % _PLANK_TONES.size()]
			# Soft vertical shading inside the plank (lit top → shaded bottom).
			var sub := 6
			for s in sub:
				var st0: float = y0 + (y1 - y0) * float(s) / float(sub)
				var st1: float = y0 + (y1 - y0) * float(s + 1) / float(sub)
				var f: float = float(s) / float(sub - 1)
				var shade: Color = tone.lightened(0.10).lerp(tone.darkened(0.16), f)
				var chord: float = maxf(_corner_chord_at_y(st0, r, size.y), _corner_chord_at_y(st1, r, size.y))
				if chord < size.x * 0.5:
					draw_rect(Rect2(Vector2(chord, st0), Vector2(size.x - chord * 2, st1 - st0)), shade)
			# Wood grain lines running along the plank.
			_draw_grain(y0, y1, i)
			# Dark groove between planks.
			if i < plank_count - 1:
				var gch: float = _corner_chord_at_y(y1, r, size.y)
				if gch < size.x * 0.5:
					draw_rect(Rect2(Vector2(gch, y1 - 1.5), Vector2(size.x - gch * 2, 3.0)), _GROOVE)
		# Warm inner edge highlight.
		_round_rect_outline(Rect2(Vector2.ZERO, size), Color(1, 0.9, 0.72, 0.18), r, 2.0)

	func _draw_grain(y0: float, y1: float, seed_i: int) -> void:
		var sd: float = float(seed_i) * 1.73
		for k in 3:
			var gy: float = y0 + (y1 - y0) * (0.28 + 0.22 * k)
			var pts := PackedVector2Array()
			var segs := 16
			for sgi in segs + 1:
				var fx: float = float(sgi) / float(segs)
				var wob: float = sin(fx * 8.5 + sd + k * 2.1) * 2.2
				pts.append(Vector2(fx * size.x, gy + wob))
			draw_polyline(pts, Color(0, 0, 0, 0.10), 1.5, true)

	# Horizontal inset (in pixels) imposed by the rounded silhouette at vertical
	# offset `y` from the top of the bg. Returns 0 outside the corner zones.
	func _corner_chord_at_y(y: float, r: float, h: float) -> float:
		var d: float = -1.0
		if y < r:
			d = r - y                  # depth into the top corner curve
		elif y > h - r:
			d = r - (h - y)            # depth into the bottom corner curve
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
