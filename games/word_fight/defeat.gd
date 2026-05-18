extends Control
## Word Fight — Defeat results screen. Reads GameState.wf_session.

const UI := preload("res://scripts/results_ui.gd")

func _ready() -> void:
	_build_ui(GameState.wf_session)

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

	body.add_child(UI.center_label("💔", 56, Palette.TEXT))
	body.add_child(UI.center_label("Defeated!", 32, Palette.TERRACOTTA))
	var enemy_name: String = str(s.get("enemy_name", ""))
	body.add_child(UI.center_label("%s was too strong this time" % enemy_name, 18, Palette.TEXT_SECONDARY))

	var stats := HBoxContainer.new()
	stats.alignment = BoxContainer.ALIGNMENT_CENTER
	stats.add_theme_constant_override("separation", 32)
	stats.add_child(UI.stat_box("Your HP left", str(int(s.get("player_hp_left", 0))), Palette.TERRACOTTA))
	stats.add_child(UI.stat_box("Enemy HP left", str(int(s.get("enemy_hp_left", 0))), Palette.TEXT_SECONDARY))
	body.add_child(stats)

	var tip := UI.card(Palette.SURFACE, Palette.BORDER, 12, 16)
	var tip_lbl := Label.new()
	tip_lbl.text = "Tip: Try longer words for more damage, and match the topic for a ×2 bonus!"
	tip_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip_lbl.add_theme_color_override("font_color", Palette.TEXT_SECONDARY)
	tip_lbl.add_theme_font_size_override("font_size", 15)
	tip.add_child(tip_lbl)
	body.add_child(tip)

	var retry_btn := UI.primary_btn("Try Again")
	retry_btn.pressed.connect(_on_retry)
	body.add_child(retry_btn)

	var map_btn := UI.ghost_btn("Back to Map")
	map_btn.pressed.connect(_on_back)
	body.add_child(map_btn)

func _on_retry() -> void:
	# Keep current enemy_idx — retry against the same enemy.
	get_tree().change_scene_to_file("res://games/word_fight/intro.tscn")

func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
