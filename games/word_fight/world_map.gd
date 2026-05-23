extends Control
## Word Fight — story-world map. Pick a world + enemy to battle, or open the shop.
## Reads GameState.wf_world_progress for unlock state.

const Worlds := preload("res://games/word_fight/worlds.gd")
const Chrome := preload("res://scripts/screen_chrome.gd")

func _ready() -> void:
	_build()

func _build() -> void:
	Chrome.bg_layer(self)
	var back := Chrome.header(self, "Story Map")
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))

	var root := VBoxContainer.new()
	root.anchor_right = 1.0
	root.anchor_bottom = 1.0
	root.offset_left = 14
	root.offset_top = Chrome.HEADER_H + 8
	root.offset_right = -14
	root.offset_bottom = -10
	root.add_theme_constant_override("separation", 10)
	add_child(root)

	root.add_child(_top_bar())

	var scroll := Chrome.scroll_container()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 12)
	scroll.add_child(list)
	for w in Worlds.world_count():
		list.add_child(_world_card(w))

# --- Lex / gold summary + shop entry ---
func _top_bar() -> Control:
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Palette.SURFACE
	sb.set_corner_radius_all(16)
	sb.set_border_width_all(2)
	sb.border_color = Palette.BORDER
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", sb)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)

	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 2)
	row.add_child(info)
	var lv := Label.new()
	lv.text = "Lex  ·  Level %d" % GameState.lex_level
	lv.add_theme_font_size_override("font_size", 16)
	lv.add_theme_color_override("font_color", Palette.TEXT)
	info.add_child(lv)
	var sub := Label.new()
	sub.text = "HP %d    XP %d/%d" % [GameState.lex_max_hp(), GameState.lex_xp, GameState.lex_xp_to_next()]
	sub.add_theme_font_size_override("font_size", 12)
	sub.add_theme_color_override("font_color", Palette.TEXT_SECONDARY)
	info.add_child(sub)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)

	var gold := Label.new()
	gold.text = "%d gold" % GameState.gold
	gold.add_theme_font_size_override("font_size", 16)
	gold.add_theme_color_override("font_color", Palette.GOLD_DARK)
	gold.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(gold)

	var shop := Button.new()
	shop.text = "Shop"
	shop.focus_mode = Control.FOCUS_NONE
	Palette.style_button(shop, Palette.PINK, Color.WHITE, 12)
	shop.pressed.connect(func(): get_tree().change_scene_to_file("res://games/word_fight/shop.tscn"))
	row.add_child(shop)
	return panel

func _world_card(world_idx: int) -> Control:
	var data: Dictionary = Worlds.world(world_idx)
	var unlocked := Worlds.is_world_unlocked(world_idx, GameState.wf_world_progress)

	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb := StyleBoxFlat.new()
	sb.bg_color = Palette.SURFACE if unlocked else Palette.BG_SOFT
	sb.set_corner_radius_all(18)
	sb.set_border_width_all(2)
	sb.border_color = Palette.GOLD if unlocked else Palette.BORDER
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", sb)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)

	var title := Label.new()
	title.text = str(data.name) if unlocked else "%s  (Locked)" % str(data.name)
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Palette.TEXT if unlocked else Palette.TEXT_SECONDARY)
	box.add_child(title)

	var sub := Label.new()
	sub.text = str(data.subtitle) if unlocked else "Clear the previous world to unlock this one."
	sub.add_theme_font_size_override("font_size", 12)
	sub.add_theme_color_override("font_color", Palette.TEXT_SECONDARY)
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(sub)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	for e in Worlds.ENEMIES_PER_WORLD:
		row.add_child(_enemy_node(world_idx, e))
	box.add_child(row)
	return panel

func _enemy_node(world_idx: int, enemy_idx: int) -> Control:
	var enemy: Dictionary = Worlds.enemy(world_idx, enemy_idx)
	var progress: Array = GameState.wf_world_progress
	var available := Worlds.is_enemy_unlocked(world_idx, enemy_idx, progress)
	var cleared := available and int(progress[world_idx]) > enemy_idx

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 3)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(62, 62)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.focus_mode = Control.FOCUS_NONE
	btn.expand_icon = true
	btn.disabled = not available
	var svg := "res://assets/avatars/%s.svg" % str(enemy.get("avatar", "octopus"))
	if ResourceLoader.exists(svg):
		btn.icon = load(svg)
	var ring := Palette.SAGE_DARK if cleared else (Palette.PINK if available else Palette.BORDER)
	var bg := Palette.SURFACE if available else Palette.BG_SOFT
	var nsb := _circle_style(bg, ring)
	btn.add_theme_stylebox_override("normal", nsb)
	btn.add_theme_stylebox_override("hover", _circle_style(bg.lightened(0.05), ring))
	btn.add_theme_stylebox_override("pressed", _circle_style(bg.darkened(0.05), ring))
	btn.add_theme_stylebox_override("disabled", nsb)
	if not available:
		btn.modulate = Color(0.62, 0.62, 0.62, 1)
	btn.pressed.connect(_on_enemy_pressed.bind(world_idx, enemy_idx))
	col.add_child(btn)

	var name_lbl := Label.new()
	name_lbl.text = str(enemy.get("name", ""))
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_lbl.custom_minimum_size = Vector2(76, 0)
	name_lbl.add_theme_font_size_override("font_size", 10)
	name_lbl.add_theme_color_override("font_color", Palette.TEXT if available else Palette.TEXT_SECONDARY)
	col.add_child(name_lbl)

	var tag := Label.new()
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.add_theme_font_size_override("font_size", 10)
	if cleared:
		tag.text = "Cleared"
		tag.add_theme_color_override("font_color", Palette.SAGE_DARK)
	elif available:
		tag.text = "Battle!"
		tag.add_theme_color_override("font_color", Palette.PINK_DARK)
	else:
		tag.text = "Locked"
		tag.add_theme_color_override("font_color", Palette.TEXT_SECONDARY)
	col.add_child(tag)
	return col

func _circle_style(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(31)
	s.set_border_width_all(3)
	s.border_color = border
	s.content_margin_left = 6
	s.content_margin_right = 6
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	return s

func _on_enemy_pressed(world_idx: int, enemy_idx: int) -> void:
	GameState.wf_session["world_idx"] = world_idx
	GameState.wf_session["enemy_idx"] = enemy_idx
	GameState.wf_world_idx = world_idx
	GameState.save()
	get_tree().change_scene_to_file("res://games/word_fight/intro.tscn")
