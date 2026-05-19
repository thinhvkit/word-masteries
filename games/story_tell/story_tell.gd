extends Control
## Story Tell — pick a story with N blanks, the player types into each,
## scoring rewards length and grammatical guesses.

const Chrome := preload("res://scripts/screen_chrome.gd")

const PURPLE_LIGHT := Color("#ece1f5")
const PURPLE_DARK := Color("#7a4caf")
const PINK := Color("#e07a8c")
const PINK_DARK := Color("#c95e74")
const SAGE_LIGHT := Color("#dff1e0")
const SAGE_DARK := Color("#4a7d4a")
const GOLD_LIGHT := Color("#fff4e0")
const GOLD_DARK := Color("#b48218")
const BLUE := Color("#3d8bb5")

const STORIES := [
	{
		"segments": [
			"Last summer, Maria went to the beach with her family. She ",
			" in the warm ocean waves. Her brother ",
			" while their parents relaxed under a big umbrella. At the end of the day, everyone felt ",
			".",
		],
		"samples": ["loved swimming in the cool water", "was building a huge sandcastle", "happy and tired"],
	},
	{
		"segments": [
			"Every morning, the old baker ",
			" before the sun rose. His shop smelled like ",
			" and people would ",
			" just to buy his famous bread.",
		],
		"samples": ["woke up very early", "fresh bread and cinnamon", "line up outside"],
	},
]

var _story: Dictionary
var _inputs: Array[LineEdit] = []
var _submitted: bool = false
var _scores: Array = []  # [{yours, score, max, good, sample}, ...]
var _body: VBoxContainer

func _ready() -> void:
	_story = STORIES[randi() % STORIES.size()]
	Chrome.bg_layer(self)
	var back := Chrome.header(self, "Story Tell", "story_tell", PURPLE_LIGHT, PURPLE_DARK)
	back.pressed.connect(_back)

	var scroll := ScrollContainer.new()
	scroll.anchor_left = 0.0
	scroll.anchor_right = 1.0
	scroll.anchor_top = 0.0
	scroll.anchor_bottom = 1.0
	scroll.offset_top = Chrome.HEADER_H
	scroll.offset_left = 16
	scroll.offset_right = -16
	scroll.offset_bottom = -16
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 14)
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_body)
	_build_form()

func _build_form() -> void:
	_clear_body()
	_inputs.clear()

	# Story card with inline blanks (rendered as a stack of segment labels +
	# LineEdit blanks since Godot has no inline-flow text mixing).
	var card := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Chrome.SURFACE
	sb.set_corner_radius_all(16)
	sb.set_border_width_all(1)
	sb.border_color = Chrome.BORDER
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 14
	sb.content_margin_bottom = 14
	card.add_theme_stylebox_override("panel", sb)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	card.add_child(box)

	for i in _story.segments.size():
		var seg: String = _story.segments[i]
		if not seg.is_empty():
			var lbl := Label.new()
			lbl.text = seg.strip_edges()
			lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			lbl.add_theme_font_size_override("font_size", 16)
			lbl.add_theme_color_override("font_color", Chrome.TEXT)
			lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			box.add_child(lbl)
		if i < _story.segments.size() - 1:
			var input := _blank_input(i + 1)
			_inputs.append(input)
			box.add_child(input)

	_body.add_child(card)

	var hint := Label.new()
	hint.text = "Longer, grammatically correct answers score higher!"
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Chrome.TEXT_SEC)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.add_child(hint)

	var submit := Chrome.pill_button("Submit Story", PINK)
	submit.pressed.connect(_submit)
	_body.add_child(submit)
	for input in _inputs:
		input.text_changed.connect(func(_t): _refresh_submit(submit))
	_refresh_submit(submit)

func _blank_input(n: int) -> LineEdit:
	var le := LineEdit.new()
	le.placeholder_text = "Blank #%d…" % n
	le.add_theme_font_size_override("font_size", 16)
	le.add_theme_color_override("font_color", PINK_DARK)
	var input_sb := StyleBoxFlat.new()
	input_sb.bg_color = Color("#fde6ec")
	input_sb.set_corner_radius_all(12)
	input_sb.set_border_width_all(2)
	input_sb.border_color = PINK
	input_sb.content_margin_left = 12
	input_sb.content_margin_right = 12
	input_sb.content_margin_top = 8
	input_sb.content_margin_bottom = 8
	le.add_theme_stylebox_override("normal", input_sb)
	le.add_theme_stylebox_override("focus", input_sb)
	return le

func _refresh_submit(btn: Button) -> void:
	for input in _inputs:
		if input.text.strip_edges().is_empty():
			btn.disabled = true
			return
	btn.disabled = false

func _submit() -> void:
	_scores.clear()
	for i in _inputs.size():
		var text := _inputs[i].text.strip_edges()
		var n: int = text.length()
		var max_pts: int = 30 + i * 5
		var pts: int = mini(max_pts, int(round(n * 2.5 + (10 if n > 15 else 0))))
		var good: bool = pts >= int(max_pts * 0.7)
		_scores.append({"yours": text, "score": pts, "max": max_pts, "good": good, "sample": _story.samples[i]})
	var total := 0
	for s in _scores:
		total += int(s.score)
	GameState.add_xp("story_tell", total)
	_submitted = true
	_build_results()

func _build_results() -> void:
	_clear_body()

	var total := 0
	var max_total := 0
	for s in _scores:
		total += int(s.score)
		max_total += int(s.max)

	var head := Label.new()
	head.text = "Story Scored!"
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_theme_font_size_override("font_size", 24)
	head.add_theme_color_override("font_color", Chrome.TEXT)
	_body.add_child(head)

	var stat := Label.new()
	stat.text = "Total: %d / %d" % [total, max_total]
	stat.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stat.add_theme_font_size_override("font_size", 18)
	stat.add_theme_color_override("font_color", PINK_DARK)
	_body.add_child(stat)

	for i in _scores.size():
		_body.add_child(_score_card(i))

	var next := Chrome.pill_button("Next Story →", PINK)
	next.pressed.connect(func():
		_story = STORIES[randi() % STORIES.size()]
		_submitted = false
		_build_form())
	_body.add_child(next)

	var back := Chrome.pill_button("Back to Menu", Chrome.SURFACE, Chrome.TEXT)
	back.pressed.connect(_back)
	_body.add_child(back)

func _score_card(i: int) -> Control:
	var s: Dictionary = _scores[i]
	var card := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Chrome.SURFACE
	sb.set_corner_radius_all(12)
	sb.set_border_width_all(1)
	sb.border_color = Chrome.BORDER
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	card.add_theme_stylebox_override("panel", sb)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	card.add_child(box)
	var head := HBoxContainer.new()
	var label := Label.new()
	label.text = "Blank %d" % (i + 1)
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Chrome.TEXT)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(label)
	var chip_bg: Color = SAGE_LIGHT if s.good else GOLD_LIGHT
	var chip_fg: Color = SAGE_DARK if s.good else GOLD_DARK
	head.add_child(Chrome.chip("%d/%d" % [s.score, s.max], chip_bg, chip_fg))
	box.add_child(head)
	var you := Label.new()
	you.text = 'You: "%s"' % s.yours
	you.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	you.add_theme_font_size_override("font_size", 13)
	you.add_theme_color_override("font_color", Chrome.TEXT)
	box.add_child(you)
	var sample := Label.new()
	sample.text = '💡 Sample: "%s"' % s.sample
	sample.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sample.add_theme_font_size_override("font_size", 12)
	sample.add_theme_color_override("font_color", BLUE)
	box.add_child(sample)
	return card

func _clear_body() -> void:
	for c in _body.get_children():
		c.queue_free()

func _back() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
