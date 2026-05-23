extends Control
## Word Fight — item shop. Buy items with gold and equip up to
## GameState.EQUIP_SLOTS for passive battle effects.

const Items := preload("res://games/word_fight/items.gd")
const Chrome := preload("res://scripts/screen_chrome.gd")

var _list: VBoxContainer
var _gold_label: Label
var _slots_label: Label

func _ready() -> void:
	_build()

func _build() -> void:
	Chrome.bg_layer(self)
	var back := Chrome.header(self, "Item Shop")
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://games/word_fight/world_map.tscn"))

	var root := VBoxContainer.new()
	root.anchor_right = 1.0
	root.anchor_bottom = 1.0
	root.offset_left = 14
	root.offset_top = Chrome.HEADER_H + 8
	root.offset_right = -14
	root.offset_bottom = -10
	root.add_theme_constant_override("separation", 10)
	add_child(root)

	# Balance bar.
	var bar := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Palette.SURFACE
	sb.set_corner_radius_all(16)
	sb.set_border_width_all(2)
	sb.border_color = Palette.BORDER
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	bar.add_theme_stylebox_override("panel", sb)
	var bar_row := HBoxContainer.new()
	bar.add_child(bar_row)
	_gold_label = Label.new()
	_gold_label.add_theme_font_size_override("font_size", 18)
	_gold_label.add_theme_color_override("font_color", Palette.GOLD_DARK)
	bar_row.add_child(_gold_label)
	var bar_spacer := Control.new()
	bar_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar_row.add_child(bar_spacer)
	_slots_label = Label.new()
	_slots_label.add_theme_font_size_override("font_size", 15)
	_slots_label.add_theme_color_override("font_color", Palette.TEXT_SECONDARY)
	_slots_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bar_row.add_child(_slots_label)
	root.add_child(bar)

	var scroll := Chrome.scroll_container()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 10)
	scroll.add_child(_list)

	_refresh()

func _refresh() -> void:
	_gold_label.text = "%d gold" % GameState.gold
	_slots_label.text = "Equipped %d / %d" % [GameState.equipped_items.size(), GameState.EQUIP_SLOTS]
	for c in _list.get_children():
		c.queue_free()
	for item in Items.all():
		_list.add_child(_item_card(item))

func _item_card(item: Dictionary) -> Control:
	var id: String = str(item.id)
	var owned: bool = id in GameState.owned_items
	var equipped: bool = id in GameState.equipped_items

	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb := StyleBoxFlat.new()
	sb.bg_color = Palette.SURFACE
	sb.set_corner_radius_all(16)
	sb.set_border_width_all(2)
	sb.border_color = Palette.SAGE if equipped else Palette.BORDER
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", sb)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 3)
	row.add_child(info)

	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 8)
	info.add_child(name_row)
	var nm := Label.new()
	nm.text = str(item.name)
	nm.add_theme_font_size_override("font_size", 17)
	nm.add_theme_color_override("font_color", Palette.TEXT)
	name_row.add_child(nm)
	name_row.add_child(_type_chip(str(item.type)))

	var desc := Label.new()
	desc.text = str(item.desc)
	desc.add_theme_font_size_override("font_size", 13)
	desc.add_theme_color_override("font_color", Palette.TEXT_SECONDARY)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(190, 0)
	info.add_child(desc)

	var cost := Label.new()
	cost.text = "Owned" if owned else "%d gold" % int(item.cost)
	cost.add_theme_font_size_override("font_size", 13)
	cost.add_theme_color_override("font_color", Palette.SAGE_DARK if owned else Palette.GOLD_DARK)
	info.add_child(cost)

	var btn := Button.new()
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(100, 46)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if not owned:
		btn.text = "Buy"
		var affordable: bool = GameState.gold >= int(item.cost)
		btn.disabled = not affordable
		Palette.style_button(btn, Palette.GOLD if affordable else Palette.HAIRLINE, Palette.TEXT, 12)
		if not affordable:
			btn.add_theme_stylebox_override("disabled", Palette.chunky_button_stylebox(Palette.HAIRLINE, 12))
		btn.pressed.connect(_on_buy.bind(id))
	elif equipped:
		btn.text = "Unequip"
		Palette.style_button(btn, Palette.SAGE, Color.WHITE, 12)
		btn.pressed.connect(_on_unequip.bind(id))
	else:
		btn.text = "Equip"
		var room: bool = GameState.equipped_items.size() < GameState.EQUIP_SLOTS
		btn.disabled = not room
		Palette.style_button(btn, Palette.PINK if room else Palette.HAIRLINE, Color.WHITE, 12)
		if not room:
			btn.add_theme_stylebox_override("disabled", Palette.chunky_button_stylebox(Palette.HAIRLINE, 12))
		btn.pressed.connect(_on_equip.bind(id))
	row.add_child(btn)
	return panel

func _type_chip(type_name: String) -> Control:
	var col := Palette.MUSHROOM
	match type_name:
		"weapon": col = Palette.RED
		"armor": col = Palette.BLUE
		"charm": col = Palette.PURPLE
	var p := PanelContainer.new()
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	p.add_theme_stylebox_override("panel", sb)
	var l := Label.new()
	l.text = type_name.to_upper()
	l.add_theme_font_size_override("font_size", 10)
	l.add_theme_color_override("font_color", Color.WHITE)
	p.add_child(l)
	return p

func _on_buy(id: String) -> void:
	var item := Items.by_id(id)
	if item.is_empty():
		return
	if GameState.spend_gold(int(item.cost)):
		GameState.owned_items.append(id)
		GameState.save()
	_refresh()

func _on_equip(id: String) -> void:
	if id in GameState.equipped_items:
		return
	if GameState.equipped_items.size() >= GameState.EQUIP_SLOTS:
		return
	GameState.equipped_items.append(id)
	GameState.save()
	_refresh()

func _on_unequip(id: String) -> void:
	GameState.equipped_items.erase(id)
	GameState.save()
	_refresh()
