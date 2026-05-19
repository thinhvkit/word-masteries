extends Control
## Word Fight — Pre-Battle intro. Shows round, you-vs-enemy, topic.

const Topics := preload("res://games/word_fight/topics.gd")
const Chrome := preload("res://scripts/screen_chrome.gd")

# Enemy roster mirrors word_fight.gd. Kept here so intro can render
# before instantiating the gameplay scene.
const ENEMIES := [
	{"name": "Wriggles Jr.", "hp": 80,  "emoji": "🐛"},
	{"name": "Spelluga",     "hp": 120, "emoji": "🐢"},
	{"name": "Verbosaur",    "hp": 160, "emoji": "🦖"},
	{"name": "Lexigon",      "hp": 220, "emoji": "🐉"},
]

const PLAYER_EMOJI := "🦋"
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
	Chrome.bg_layer(self)
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
	round_lbl.text = "Round %d" % round_num
	round_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	round_lbl.add_theme_font_size_override("font_size", 28)
	round_lbl.add_theme_color_override("font_color", Chrome.TEXT)
	body.add_child(round_lbl)

	# VS row.
	var vs := HBoxContainer.new()
	vs.alignment = BoxContainer.ALIGNMENT_CENTER
	vs.add_theme_constant_override("separation", 28)
	var player_name := GameState.player_name if GameState.player_name != "" else "You"
	vs.add_child(_avatar(player_name, PLAYER_EMOJI, SAGE))
	var vs_lbl := Label.new()
	vs_lbl.text = "VS"
	vs_lbl.add_theme_font_size_override("font_size", 24)
	vs_lbl.add_theme_color_override("font_color", Chrome.TEXT_SEC)
	vs.add_child(vs_lbl)
	vs.add_child(_avatar(enemy.name, enemy.emoji, PINK))
	body.add_child(vs)

	body.add_child(_topic_card(topic))

	var hint := Label.new()
	hint.text = "Words matching the topic deal ×2 damage!"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Chrome.TEXT_SEC)
	body.add_child(hint)

	var start := Chrome.pill_button("Start Battle!", PINK)
	start.custom_minimum_size = Vector2(0, 60)
	start.pressed.connect(_on_start)
	body.add_child(start)

	# Push body content toward vertical center.
	body.add_child(_flex())

func _avatar(name: String, emoji: String, bg: Color) -> Control:
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 6)

	var circle := Panel.new()
	circle.custom_minimum_size = Vector2(72, 72)
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(36)
	sb.shadow_color = Color(0, 0, 0, 0.10)
	sb.shadow_size = 4
	sb.shadow_offset = Vector2i(0, 2)
	circle.add_theme_stylebox_override("panel", sb)
	box.add_child(circle)

	var emoji_lbl := Label.new()
	emoji_lbl.text = emoji
	emoji_lbl.add_theme_font_size_override("font_size", 34)
	emoji_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	emoji_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	emoji_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	circle.add_child(emoji_lbl)

	var name_lbl := Label.new()
	name_lbl.text = name
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 14)
	name_lbl.add_theme_color_override("font_color", Chrome.TEXT)
	box.add_child(name_lbl)
	return box

func _topic_card(topic: String) -> Control:
	var holder := CenterContainer.new()
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(180, 0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = GOLD_BG
	sb.set_corner_radius_all(14)
	sb.set_border_width_all(2)
	sb.border_color = GOLD_BORDER
	sb.content_margin_left = 24
	sb.content_margin_right = 24
	sb.content_margin_top = 12
	sb.content_margin_bottom = 14
	p.add_theme_stylebox_override("panel", sb)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 2)
	var head := Label.new()
	head.text = "Topic"
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_theme_font_size_override("font_size", 12)
	head.add_theme_color_override("font_color", Chrome.TEXT_SEC)
	box.add_child(head)
	var t := Label.new()
	t.text = topic.capitalize()
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 22)
	t.add_theme_color_override("font_color", Chrome.TEXT)
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
