extends Control
## Word Fight — Pre-Battle intro. Shows round, you-vs-enemy, topic.

const Topics := preload("res://games/word_fight/topics.gd")
const UI := preload("res://scripts/results_ui.gd")

# Enemy roster mirrors word_fight.gd. Kept here so intro can render
# before instantiating the gameplay scene.
const ENEMIES := [
	{"name": "Wriggles Jr.", "hp": 80},
	{"name": "Spelluga",     "hp": 120},
	{"name": "Verbosaur",    "hp": 160},
	{"name": "Lexigon",      "hp": 220},
]

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

	_build_ui(idx + 1, enemy.name, topic)

func _build_ui(round_num: int, enemy_name: String, topic: String) -> void:
	UI.bg_layer(self, Palette.BG)

	var back_btn := Button.new()
	back_btn.text = "← Back"
	back_btn.position = Vector2(12, 12)
	back_btn.size = Vector2(80, 32)
	back_btn.pressed.connect(_on_back)
	add_child(back_btn)

	var body := VBoxContainer.new()
	body.anchor_right = 1.0
	body.anchor_bottom = 1.0
	body.offset_left = 24
	body.offset_top = 60
	body.offset_right = -24
	body.offset_bottom = -32
	body.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_theme_constant_override("separation", 24)
	add_child(body)

	body.add_child(UI.center_label("Round %d" % round_num, 28, Palette.TEXT))

	# VS row
	var vs := HBoxContainer.new()
	vs.alignment = BoxContainer.ALIGNMENT_CENTER
	vs.add_theme_constant_override("separation", 24)
	vs.add_child(_avatar(GameState.player_name if GameState.player_name != "" else "You", Palette.SAGE))
	vs.add_child(UI.center_label("VS", 32, Palette.TEXT_SECONDARY))
	vs.add_child(_avatar(enemy_name, Palette.TERRACOTTA))
	body.add_child(vs)

	# Topic card
	var topic_card := UI.card(Color("#fff1c4"), Palette.GOLD_DARK, 12, 16)
	var topic_box := VBoxContainer.new()
	topic_box.alignment = BoxContainer.ALIGNMENT_CENTER
	topic_box.add_child(UI.center_label("Topic", 14, Palette.TEXT_SECONDARY))
	topic_box.add_child(UI.center_label(topic.capitalize(), 24, Palette.TEXT))
	topic_card.add_child(topic_box)
	body.add_child(topic_card)

	body.add_child(UI.center_label("Words matching the topic deal ×2 damage!", 14, Palette.TEXT_SECONDARY))

	var start_btn := UI.primary_btn("Start Battle!")
	start_btn.pressed.connect(_on_start)
	body.add_child(start_btn)

func _avatar(name: String, color: Color) -> Control:
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	var circle := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.corner_radius_top_left = 32
	sb.corner_radius_top_right = 32
	sb.corner_radius_bottom_left = 32
	sb.corner_radius_bottom_right = 32
	circle.add_theme_stylebox_override("panel", sb)
	circle.custom_minimum_size = Vector2(64, 64)
	box.add_child(circle)
	box.add_child(UI.center_label(name, 14, Palette.TEXT))
	return box

func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_start() -> void:
	get_tree().change_scene_to_file("res://games/word_fight/word_fight.tscn")
