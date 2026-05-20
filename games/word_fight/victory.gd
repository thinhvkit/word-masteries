extends Control
## Word Fight — Victory results screen. Reads GameState.wf_session.

const UI := preload("res://scripts/results_ui.gd")

const ENEMY_COUNT := 4  # mirrors word_fight.gd ENEMIES.size()

func _ready() -> void:
	var s: Dictionary = GameState.wf_session
	_build_ui(s)

func _build_ui(s: Dictionary) -> void:
	UI.bg_layer(self, Palette.BG)

	var body := VBoxContainer.new()
	body.anchor_right = 1.0
	body.anchor_bottom = 1.0
	body.offset_left = 24
	body.offset_top = 40
	body.offset_right = -24
	body.offset_bottom = -24
	body.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_theme_constant_override("separation", 16)
	add_child(body)

	body.add_child(_center_svg("res://assets/icons/party.svg", 96))
	body.add_child(UI.center_label("Victory!", 32, Palette.SAGE_DARK))
	body.add_child(UI.center_label("You defeated %s" % str(s.get("enemy_name", "")), 18, Palette.TEXT_SECONDARY))

	# Stat boxes
	var stats := HBoxContainer.new()
	stats.alignment = BoxContainer.ALIGNMENT_CENTER
	stats.add_theme_constant_override("separation", 32)
	stats.add_child(UI.stat_box("Damage dealt", str(int(s.get("damage_dealt", 0))), Palette.SAGE_DARK))
	stats.add_child(UI.stat_box("Words used", str(int(s.get("words_used", 0))), Palette.PINK_DARK))
	body.add_child(stats)

	# Summary card
	var card := UI.card(Palette.SURFACE, Palette.BORDER, 12, 16)
	var sbox := VBoxContainer.new()
	sbox.add_theme_constant_override("separation", 8)
	sbox.add_child(UI.center_label("Battle Summary", 18, Palette.TEXT))
	var longest: String = str(s.get("longest_word", ""))
	var longest_display: String = "%s (%d)" % [longest, longest.length()] if longest != "" else "—"
	sbox.add_child(UI.kv_row("Longest word", longest_display))
	sbox.add_child(UI.kv_row("Topic matches", "%d words" % int(s.get("topic_matches", 0))))
	sbox.add_child(UI.kv_row("Rainbows used", str(int(s.get("rainbows_used", 0)))))
	sbox.add_child(UI.kv_row("Score earned", "+%d pts" % int(s.get("score_earned", 0)), true))
	card.add_child(sbox)
	body.add_child(card)

	# Buttons
	var cur_idx: int = int(s.get("enemy_idx", 0))
	var is_last: bool = (cur_idx + 1) >= ENEMY_COUNT
	var next_label: String = "Back to Map" if is_last else "Next Battle"
	var next_btn := UI.primary_btn(next_label)
	if not is_last and ResourceLoader.exists("res://assets/icons/arrow_right.svg"):
		next_btn.icon = load("res://assets/icons/arrow_right.svg")
		next_btn.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		next_btn.expand_icon = false
		next_btn.add_theme_constant_override("icon_max_width", 22)
		next_btn.add_theme_constant_override("h_separation", 8)
	next_btn.pressed.connect(_on_next.bind(is_last))
	body.add_child(next_btn)

	if not is_last:
		var map_btn := UI.ghost_btn("Back to Map")
		map_btn.pressed.connect(_on_back)
		body.add_child(map_btn)

func _on_next(is_last: bool) -> void:
	if is_last:
		_on_back()
		return
	# Advance enemy and route through intro for next battle.
	GameState.wf_session["enemy_idx"] = int(GameState.wf_session.get("enemy_idx", 0)) + 1
	get_tree().change_scene_to_file("res://games/word_fight/intro.tscn")

func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _center_svg(path: String, size_px: int) -> Control:
	# Centered TextureRect at native aspect, used in place of an emoji mascot.
	var holder := CenterContainer.new()
	if ResourceLoader.exists(path):
		var tex := TextureRect.new()
		tex.texture = load(path)
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.custom_minimum_size = Vector2(size_px, size_px)
		tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(tex)
	return holder
