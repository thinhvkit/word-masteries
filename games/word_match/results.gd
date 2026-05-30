extends Control
## Word Match — Results screen. Reads GameState.wm_session.

const UI := preload("res://scripts/results_ui.gd")
const Chrome := preload("res://scripts/screen_chrome.gd")

func _ready() -> void:
	_build_ui(GameState.wm_session)

func _build_ui(s: Dictionary) -> void:
	UI.bg_layer(self, Palette.BG)

	var back_btn := Button.new()
	back_btn.text = "Back"
	if ResourceLoader.exists("res://assets/icons/arrow_left.svg"):
		back_btn.icon = load("res://assets/icons/arrow_left.svg")
		back_btn.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		back_btn.expand_icon = false
		back_btn.add_theme_constant_override("icon_max_width", 20)
		back_btn.add_theme_constant_override("h_separation", 6)
	back_btn.position = Vector2(12, 12)
	back_btn.size = Vector2(96, 32)
	back_btn.pressed.connect(_on_back)
	add_child(back_btn)

	var scroll := Chrome.scroll_container()
	scroll.anchor_right = 1.0
	scroll.anchor_bottom = 1.0
	scroll.offset_left = 16
	scroll.offset_top = 56
	scroll.offset_right = -16
	scroll.offset_bottom = -16
	add_child(scroll)

	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 14)
	scroll.add_child(body)

	var stars := _stars_text(int(s.get("stars", 0)))
	body.add_child(UI.center_label(str(s.get("reason", "Game Over")), 32, Palette.TEXT))
	body.add_child(UI.center_label("%s  •  %d letter sets" % [stars, int(s.get("sets", 1))], 16, Palette.TEXT_SECONDARY))

	# Stat boxes
	var found_words: Array = s.get("found_words", [])
	var possible: int = int(s.get("possible_count", 0))
	var score: int = int(s.get("score", 0))
	var high_score: int = int(s.get("high_score", score))
	var is_new_high_score: bool = bool(s.get("is_new_high_score", false))
	var best_combo: int = int(s.get("best_combo", 0))
	var secret_words: Array = s.get("secret_words", [])

	var stats := HBoxContainer.new()
	stats.alignment = BoxContainer.ALIGNMENT_CENTER
	stats.add_theme_constant_override("separation", 32)
	stats.add_child(UI.stat_box("Score", str(score), Palette.BLUE_DARK))
	stats.add_child(UI.stat_box("Best", str(high_score), Palette.GOLD_DARK if is_new_high_score else Palette.BLUE_DARK))
	stats.add_child(UI.stat_box("Words Found", str(found_words.size()), Palette.SAGE_DARK))
	body.add_child(stats)

	var run_stats := HBoxContainer.new()
	run_stats.alignment = BoxContainer.ALIGNMENT_CENTER
	run_stats.add_theme_constant_override("separation", 32)
	run_stats.add_child(UI.stat_box("Best Combo", "x%d" % maxi(1, best_combo), Palette.PINK_DARK))
	run_stats.add_child(UI.stat_box("Secrets", str(secret_words.size()), Palette.TERRACOTTA))
	run_stats.add_child(UI.stat_box("Sets", str(int(s.get("sets", 1))), Palette.GOLD_DARK))
	body.add_child(run_stats)

	if is_new_high_score:
		body.add_child(UI.center_label("New high score", 18, Palette.GOLD_DARK))

	# Pool (small hint of the round)
	var pool := str(s.get("pool", ""))
	if pool != "":
		body.add_child(UI.center_label("Pool: " + pool, 14, Palette.TEXT_SECONDARY))

	# Found-words card
	var found_card := UI.card(Palette.SURFACE, Palette.BORDER, 12, 14)
	var found_box := VBoxContainer.new()
	found_box.add_theme_constant_override("separation", 8)
	var found_title := Label.new()
	found_title.text = "You found"
	found_title.add_theme_color_override("font_color", Palette.TEXT)
	found_title.add_theme_font_size_override("font_size", 16)
	found_box.add_child(found_title)
	if found_words.is_empty():
		found_box.add_child(UI.center_label("No words this round — try again!", 13, Palette.TEXT_SECONDARY))
	else:
		# Found pills — text only; the green chip already signals "found".
		found_box.add_child(UI.flow_pills(found_words, Color("#e6f5ea"), Palette.SAGE_DARK))
	found_card.add_child(found_box)
	body.add_child(found_card)

	# Missed (capped) card
	var missed_top: Array = s.get("missed_top", [])
	if not missed_top.is_empty():
		var miss_card := UI.card(Palette.SURFACE, Palette.BORDER, 12, 14)
		var miss_box := VBoxContainer.new()
		miss_box.add_theme_constant_override("separation", 8)
		var miss_title := Label.new()
		miss_title.text = "You could have found"
		miss_title.add_theme_color_override("font_color", Palette.TEXT)
		miss_title.add_theme_font_size_override("font_size", 16)
		miss_box.add_child(miss_title)
		miss_box.add_child(UI.flow_pills(missed_top, Color("#fbeaea"), Palette.TERRACOTTA))
		var summary := UI.center_label("You found %d of %d possible words" % [found_words.size(), possible], 13, Palette.TEXT_SECONDARY)
		summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		miss_box.add_child(summary)
		miss_card.add_child(miss_box)
		body.add_child(miss_card)
	else:
		body.add_child(UI.center_label("You found every word possible!", 14, Palette.SAGE_DARK))

	# Buttons
	var play_btn := UI.primary_btn("Play Again")
	play_btn.pressed.connect(_on_play_again)
	body.add_child(play_btn)

	var map_btn := UI.ghost_btn("Back to Map")
	map_btn.pressed.connect(_on_back)
	body.add_child(map_btn)

func _on_play_again() -> void:
	get_tree().change_scene_to_file("res://games/word_match/word_match.tscn")

func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _stars_text(stars: int) -> String:
	if stars >= 3:
		return "***"
	if stars == 2:
		return "**"
	if stars == 1:
		return "*"
	return "-"
