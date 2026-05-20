extends RefCounted
## Word Fight FX library — animated background, chain overlay, particle bursts,
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
	if amount >= 120: return Color("#ff3838")   # crimson
	if amount >= 80:  return Color("#ff7a1f")   # orange
	if amount >= 50:  return Color("#ffd027")   # gold
	return Color.WHITE

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
