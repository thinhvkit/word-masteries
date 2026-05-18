extends Control
## Design canvas — vertical stack of all 26 wireframe artboards.
## Each artboard is its own scene under `res://scenes/wireframes/screens/`.

const WF := preload("res://scripts/wf/wf.gd")
const SCREENS_DIR := "res://scenes/wireframes/screens/"

const SECTIONS := [
	{
		"id": "onboarding", "title": "1 · Onboarding Flow",
		"items": [
			["Splash", "splash"],
			["Login", "login"],
			["Name & Avatar", "name_entry"],
			["Mode Select", "mode_select"],
		],
	},
	{
		"id": "hub", "title": "2 · Hub — World Map (3 variations)",
		"items": [
			["A: Vertical Path", "hub_a"],
			["B: Winding Road", "hub_b"],
			["C: Card List", "hub_c"],
		],
	},
	{
		"id": "wordfight", "title": "3 · Word Fight — Turn-Based Battle",
		"items": [
			["Pre-Battle", "wf_intro"],
			["A: Classic Board", "wf_game_a"],
			["B: Dark Arena", "wf_game_b"],
			["Rainbow Booster", "wf_rainbow"],
			["Victory", "wf_victory"],
			["Defeat", "wf_defeat"],
		],
	},
	{
		"id": "wordmatch", "title": "4 · Word Match — Circle Drag",
		"items": [
			["Gameplay", "wm_game"],
			["Results", "wm_results"],
		],
	},
	{
		"id": "wordfound", "title": "5 · Word Found — Letter Rows & Waves",
		"items": [
			["Gameplay", "wfnd_game"],
			["Wave Complete", "wfnd_wave"],
			["Game Over", "wfnd_over"],
		],
	},
	{
		"id": "storytell", "title": "6 · Story Tell — Fill in the Blanks",
		"items": [
			["Gameplay", "st_game"],
			["AI Scoring Results", "st_results"],
		],
	},
	{
		"id": "wordtype", "title": "7 · Word Type — Word Forms Quiz",
		"items": [
			["Gameplay", "wt_game"],
			["All Forms Revealed", "wt_results"],
		],
	},
	{
		"id": "descpic", "title": "8 · Describe Picture — Image Sentences",
		"items": [
			["Gameplay", "dp_game"],
			["AI Scoring Results", "dp_results"],
		],
	},
	{
		"id": "listen", "title": "9 · Listen & Dictate — Audio Spelling",
		"items": [
			["Gameplay", "ld_game"],
			["Results + Sentence", "ld_results"],
		],
	},
]

@onready var stack: VBoxContainer = $Scroll/Stack

func _ready() -> void:
	# Canvas title block
	stack.add_child(_canvas_title())
	for sec in SECTIONS:
		stack.add_child(_section(sec))

func _canvas_title() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 24)
	pad.add_theme_constant_override("margin_top", 32)
	pad.add_theme_constant_override("margin_right", 24)
	pad.add_theme_constant_override("margin_bottom", 12)
	pad.add_child(box)
	var t := WF.make_label("Word Masteries — Wireframes", 38, WF.TEXT, true)
	box.add_child(t)
	var s := WF.make_label("Full app flow · Mobile · All 7 mini-games", 20, WF.MUTED)
	box.add_child(s)
	return pad

func _section(sec: Dictionary) -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 24)
	pad.add_theme_constant_override("margin_right", 24)
	pad.add_theme_constant_override("margin_top", 16)
	pad.add_theme_constant_override("margin_bottom", 16)
	pad.add_child(v)
	# Section heading
	var head := WF.make_label(sec.title, 26, WF.TEXT, true)
	v.add_child(head)
	# Horizontal row of artboards
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 780)
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	scroll.add_child(row)
	for entry in sec.items:
		row.add_child(_artboard_block(entry[0], entry[1]))
	return pad

func _artboard_block(label: String, scene_id: String) -> Control:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	col.add_child(WF.screen_label(label))
	var frame := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = WF.PAPER
	sb.set_border_width_all(2)
	sb.border_color = WF.BORDER
	sb.set_corner_radius_all(20)
	frame.add_theme_stylebox_override("panel", sb)
	var path := SCREENS_DIR + scene_id + ".tscn"
	var screen: Control = null
	if ResourceLoader.exists(path):
		var packed: PackedScene = load(path)
		if packed != null:
			screen = packed.instantiate()
	if screen == null:
		screen = _placeholder(label)
	frame.add_child(screen)
	col.add_child(frame)
	return col

func _placeholder(label: String) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(340, 720)
	var l := WF.make_label("(%s missing)" % label, 18, WF.MUTED)
	l.set_anchors_preset(Control.PRESET_CENTER)
	c.add_child(l)
	return c
