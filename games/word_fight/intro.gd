extends Control
## Word Fight — Pre-Battle intro. Shows round, you-vs-enemy, topic.

const Topics := preload("res://games/word_fight/topics.gd")
const Chrome := preload("res://scripts/screen_chrome.gd")
const Fx := preload("res://games/word_fight/fx.gd")

const VIBRANT_GOLD := Color("#ffd027")
const VIBRANT_GOLD_DARK := Color("#7a4a00")
const VIBRANT_MAGENTA := Color("#ff3aa8")
const VIBRANT_MAGENTA_DARK := Color("#7a0e4a")
const VIBRANT_BLUE := Color("#3aa8ff")
const DARK_CARD := Color("#1a1240")
const DARK_CARD_BORDER := Color("#3a2a78")

# Enemy roster mirrors word_fight.gd. Kept here so intro can render
# before instantiating the gameplay scene.
const ENEMIES := [
	{"name": "Wriggles Jr.", "hp": 80,  "avatar": "wriggles_jr"},
	{"name": "Spelluga",     "hp": 120, "avatar": "spelluga"},
	{"name": "Verbosaur",    "hp": 160, "avatar": "verbosaur"},
	{"name": "Lexigon",      "hp": 220, "avatar": "lexigon"},
]
const SAGE := Color("#a7d99a")
const PINK := Color("#e07a8c")
const PINK_DARK := Color("#c95e74")
const GOLD_BG := Color("#fff1c4")
const GOLD_BORDER := Color("#f0d890")
const CORAL_LIGHT := Color("#ffdcc7")
const CORAL_DARK := Color("#c95a1f")

func _ready() -> void:
	# Reset session counters for a fresh battle.
	GameState.wf_session["damage_dealt"] = 0
	GameState.wf_session["words_used"] = 0
	GameState.wf_session["longest_word"] = ""
	GameState.wf_session["topic_matches"] = 0
	GameState.wf_session["rainbows_used"] = 0
	GameState.wf_session["score_earned"] = 0

	var idx: int = int(GameState.wf_session.get("enemy_idx", 0)) % ENEMIES.size()
	var enemy: Dictionary = ENEMIES[idx]
	var topic: String = Topics.random_topic()
	GameState.wf_session["enemy_idx"] = idx
	GameState.wf_session["enemy_name"] = enemy.name
	GameState.wf_session["enemy_max_hp"] = int(enemy.hp)
	GameState.wf_session["topic"] = topic

	_build_ui(idx + 1, enemy, topic)

func _build_ui(round_num: int, enemy: Dictionary, topic: String) -> void:
	# Animated gradient backdrop (matches the in-game board).
	var bg := _AnimatedBoardBG.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var back := Chrome.header(self, "Word Fight", "word_fight", CORAL_LIGHT, CORAL_DARK)
	back.pressed.connect(_on_back)

	var body := VBoxContainer.new()
	body.anchor_left = 0.0
	body.anchor_right = 1.0
	body.anchor_top = 0.0
	body.anchor_bottom = 1.0
	body.offset_left = 28
	body.offset_top = Chrome.HEADER_H + 24
	body.offset_right = -28
	body.offset_bottom = -28
	body.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_theme_constant_override("separation", 18)
	add_child(body)

	var round_lbl := Label.new()
	round_lbl.text = "ROUND %d" % round_num
	round_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	round_lbl.add_theme_font_size_override("font_size", 36)
	round_lbl.add_theme_color_override("font_color", VIBRANT_GOLD)
	round_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.55))
	round_lbl.add_theme_constant_override("outline_size", 6)
	body.add_child(round_lbl)

	# VS row.
	var vs := HBoxContainer.new()
	vs.alignment = BoxContainer.ALIGNMENT_CENTER
	vs.add_theme_constant_override("separation", 28)
	var player_name := GameState.player_name if GameState.player_name != "" else "You"
	vs.add_child(_avatar(player_name, "res://assets/avatars/%s.svg" % GameState.player_avatar, SAGE))
	var vs_lbl := Label.new()
	vs_lbl.text = "VS"
	vs_lbl.add_theme_font_size_override("font_size", 36)
	vs_lbl.add_theme_color_override("font_color", VIBRANT_MAGENTA)
	vs_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.65))
	vs_lbl.add_theme_constant_override("outline_size", 6)
	vs.add_child(vs_lbl)
	vs.add_child(_avatar(enemy.name, "res://assets/avatars/%s.svg" % str(enemy.avatar), PINK))
	body.add_child(vs)

	body.add_child(_topic_card(topic))

	var hint := Label.new()
	hint.text = "Words matching the topic deal ×2 damage!"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.92))
	hint.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.45))
	hint.add_theme_constant_override("outline_size", 3)
	body.add_child(hint)

	# Start button wrapped with a magenta glow ring.
	var start_wrap := Control.new()
	start_wrap.custom_minimum_size = Vector2(0, 64)
	var start_glow := Panel.new()
	start_glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	start_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var glow_sb := StyleBoxFlat.new()
	glow_sb.bg_color = Color(0, 0, 0, 0)
	glow_sb.set_corner_radius_all(36)
	glow_sb.shadow_color = Color(1.0, 0.4, 0.7, 0.55)
	glow_sb.shadow_size = 24
	start_glow.add_theme_stylebox_override("panel", glow_sb)
	start_wrap.add_child(start_glow)
	var start := Chrome.pill_button("Start Battle!", VIBRANT_MAGENTA, Color.WHITE)
	start.set_anchors_preset(Control.PRESET_FULL_RECT)
	start.pressed.connect(_on_start)
	start_wrap.add_child(start)
	body.add_child(start_wrap)

	# Push body content toward vertical center.
	body.add_child(_flex())

func _avatar(name: String, svg_path: String, bg: Color) -> Control:
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 6)

	var circle := Panel.new()
	circle.custom_minimum_size = Vector2(96, 96)
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(48)
	sb.set_border_width_all(3)
	sb.border_color = Color(1, 1, 1, 0.8)
	sb.shadow_color = Color(bg.r, bg.g, bg.b, 0.6)
	sb.shadow_size = 12
	sb.shadow_offset = Vector2i(0, 2)
	circle.add_theme_stylebox_override("panel", sb)
	box.add_child(circle)

	if ResourceLoader.exists(svg_path):
		var icon := TextureRect.new()
		icon.texture = load(svg_path)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.set_anchors_preset(Control.PRESET_FULL_RECT)
		icon.offset_left = 8
		icon.offset_top = 8
		icon.offset_right = -8
		icon.offset_bottom = -8
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		circle.add_child(icon)

	var name_lbl := Label.new()
	name_lbl.text = name
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 16)
	name_lbl.add_theme_color_override("font_color", Color.WHITE)
	name_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.55))
	name_lbl.add_theme_constant_override("outline_size", 3)
	box.add_child(name_lbl)
	return box

func _topic_card(topic: String) -> Control:
	var holder := CenterContainer.new()
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(220, 0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = VIBRANT_GOLD
	sb.set_corner_radius_all(20)
	sb.set_border_width_all(3)
	sb.border_color = Color("#dba830")
	sb.shadow_color = Color(VIBRANT_GOLD.r, VIBRANT_GOLD.g, VIBRANT_GOLD.b, 0.55)
	sb.shadow_size = 14
	sb.shadow_offset = Vector2i(0, 3)
	sb.content_margin_left = 24
	sb.content_margin_right = 24
	sb.content_margin_top = 14
	sb.content_margin_bottom = 16
	p.add_theme_stylebox_override("panel", sb)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 4)
	var head := Label.new()
	head.text = "TOPIC"
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_theme_font_size_override("font_size", 14)
	head.add_theme_color_override("font_color", VIBRANT_GOLD_DARK)
	box.add_child(head)
	var t := Label.new()
	t.text = topic.capitalize()
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 28)
	t.add_theme_color_override("font_color", VIBRANT_GOLD_DARK)
	box.add_child(t)
	p.add_child(box)
	holder.add_child(p)
	return holder

func _flex() -> Control:
	var c := Control.new()
	c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return c

func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_start() -> void:
	get_tree().change_scene_to_file("res://games/word_fight/word_fight.tscn")

# ---------------- animated vibrant backdrop ----------------
class _AnimatedBoardBG extends Control:
	var _t: float = 0.0
	func _ready() -> void:
		set_process(true)
		clip_contents = true
	func _process(delta: float) -> void:
		_t += delta * 0.3
		queue_redraw()
	func _draw() -> void:
		var palette := [
			Color("#3aa8ff"), Color("#7a55ff"), Color("#ff3aa8"),
			Color("#ff7a1f"), Color("#ffd027"), Color("#3ad6a8"),
		]
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.04, 0.12, 1))
		var bands := 22
		var w := size.x
		var h := size.y
		for i in bands:
			var t0: float = float(i) / float(bands)
			var t1: float = float(i + 1) / float(bands)
			var phase: float = fmod(t0 + _t, 1.0) * palette.size()
			var idx: int = int(phase) % palette.size()
			var nxt: int = (idx + 1) % palette.size()
			var f: float = phase - floor(phase)
			var col: Color = palette[idx].lerp(palette[nxt], f)
			col.a = 0.5
			draw_rect(Rect2(Vector2(0, h * t0), Vector2(w, h * (t1 - t0))), col)
