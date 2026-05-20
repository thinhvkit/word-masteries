extends Control
## Story Tell — pick a story with N blanks, the player types into each,
## scoring rewards length and grammatical guesses.

const Chrome := preload("res://scripts/screen_chrome.gd")
const Fx := preload("res://games/word_fight/fx.gd")

const PURPLE_LIGHT := Color("#ece1f5")
const PURPLE_DARK := Color("#7a4caf")
const PINK := Color("#e07a8c")
const PINK_DARK := Color("#c95e74")
const SAGE_LIGHT := Color("#dff1e0")
const SAGE_DARK := Color("#4a7d4a")
const GOLD_LIGHT := Color("#fff4e0")
const GOLD_DARK := Color("#b48218")
const BLUE := Color("#3d8bb5")

const VIBRANT_GOLD := Color("#ffd027")
const VIBRANT_GOLD_DARK := Color("#7a4a00")
const VIBRANT_MAGENTA := Color("#ff3aa8")
const VIBRANT_MAGENTA_DARK := Color("#7a0e4a")
const VIBRANT_GREEN := Color("#3ad6a8")
const VIBRANT_GREEN_DARK := Color("#0a6650")
const DARK_CARD := Color("#1a1240")
const DARK_CARD_BORDER := Color("#3a2a78")

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
var _inputs: Array = []  # holds Control wrappers, each with a meta("line_edit")
var _submitted: bool = false
var _scores: Array = []  # [{yours, score, max, good, sample}, ...]
var _body: VBoxContainer

func _ready() -> void:
	_story = STORIES[randi() % STORIES.size()]
	var bg := _AnimatedBoardBG.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
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

	# Story card — dark vibrant card so the animated bg shows through subtly.
	var card := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(DARK_CARD.r, DARK_CARD.g, DARK_CARD.b, 0.85)
	sb.set_corner_radius_all(18)
	sb.set_border_width_all(2)
	sb.border_color = DARK_CARD_BORDER
	sb.shadow_color = Color(0, 0, 0, 0.25)
	sb.shadow_size = 6
	sb.shadow_offset = Vector2i(0, 3)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 16
	sb.content_margin_bottom = 16
	card.add_theme_stylebox_override("panel", sb)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	card.add_child(box)

	for i in _story.segments.size():
		var seg: String = _story.segments[i]
		if not seg.is_empty():
			var lbl := Label.new()
			lbl.text = seg.strip_edges()
			lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			lbl.add_theme_font_size_override("font_size", 17)
			lbl.add_theme_color_override("font_color", Color.WHITE)
			lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.45))
			lbl.add_theme_constant_override("outline_size", 3)
			lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			box.add_child(lbl)
		if i < _story.segments.size() - 1:
			var input: Control = _blank_input(i + 1)
			_inputs.append(input)
			box.add_child(input)

	_body.add_child(card)

	var hint := Label.new()
	hint.text = "Longer, grammatically correct answers score higher!"
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", VIBRANT_GOLD)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_body.add_child(hint)

	# Submit wrapped in magenta glow ring.
	var submit_wrap := Control.new()
	submit_wrap.custom_minimum_size = Vector2(0, 56)
	var submit_glow := Panel.new()
	submit_glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	submit_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var glow_sb := StyleBoxFlat.new()
	glow_sb.bg_color = Color(0, 0, 0, 0)
	glow_sb.set_corner_radius_all(32)
	glow_sb.shadow_color = Color(1.0, 0.4, 0.7, 0.0)
	glow_sb.shadow_size = 0
	submit_glow.add_theme_stylebox_override("panel", glow_sb)
	submit_wrap.add_child(submit_glow)
	var submit := Chrome.pill_button("Submit Story", VIBRANT_MAGENTA, Color.WHITE)
	submit.set_anchors_preset(Control.PRESET_FULL_RECT)
	submit.pressed.connect(_submit)
	submit_wrap.add_child(submit)
	_body.add_child(submit_wrap)
	for input_ctrl in _inputs:
		var le := _line_edit_for(input_ctrl)
		if le != null:
			le.text_changed.connect(func(_t): _refresh_submit(submit, submit_glow))
	_refresh_submit(submit, submit_glow)

func _blank_input(n: int) -> Control:
	# Wrap the LineEdit in a static glow Panel so focus visuals don't restyle
	# the interactive panel (which on mobile web caused the LineEdit to defocus).
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(0, 48)
	holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var glow := Panel.new()
	glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var glow_sb := StyleBoxFlat.new()
	glow_sb.bg_color = Color(0, 0, 0, 0)
	glow_sb.set_corner_radius_all(14)
	glow_sb.shadow_color = Color(1.0, 0.4, 0.7, 0.0)
	glow_sb.shadow_size = 0
	glow.add_theme_stylebox_override("panel", glow_sb)
	holder.add_child(glow)

	var card := PanelContainer.new()
	card.set_anchors_preset(Control.PRESET_FULL_RECT)
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#ffffff")
	sb.set_corner_radius_all(12)
	sb.set_border_width_all(2)
	sb.border_color = Color("#e0d8c8")
	sb.shadow_color = Color(0, 0, 0, 0.18)
	sb.shadow_size = 3
	card.add_theme_stylebox_override("panel", sb)
	holder.add_child(card)

	var le := LineEdit.new()
	le.placeholder_text = "Blank #%d…" % n
	le.add_theme_font_size_override("font_size", 16)
	le.add_theme_color_override("font_color", VIBRANT_MAGENTA_DARK)
	le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	le.size_flags_vertical = Control.SIZE_EXPAND_FILL
	le.focus_mode = Control.FOCUS_ALL
	le.mouse_filter = Control.MOUSE_FILTER_STOP
	var le_box := StyleBoxFlat.new()
	le_box.bg_color = Color(0, 0, 0, 0)
	le_box.content_margin_left = 12
	le_box.content_margin_right = 12
	le_box.content_margin_top = 12
	le_box.content_margin_bottom = 12
	le.add_theme_stylebox_override("normal", le_box)
	le.add_theme_stylebox_override("focus", le_box)
	le.add_theme_stylebox_override("read_only", le_box)
	card.add_child(le)

	le.focus_entered.connect(func(): _set_input_glow(glow, true))
	le.focus_exited.connect(func(): _set_input_glow(glow, false))
	card.gui_input.connect(func(event: InputEvent):
		if (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed):
			le.grab_focus())
	# Stash the LineEdit on the holder so _inputs can be queried generically.
	holder.set_meta("line_edit", le)
	return holder

func _set_input_glow(glow: Panel, on: bool) -> void:
	var sb := glow.get_theme_stylebox("panel") as StyleBoxFlat
	if sb == null: return
	var fresh: StyleBoxFlat = sb.duplicate()
	fresh.shadow_color = Color(1.0, 0.4, 0.7, 0.5 if on else 0.0)
	fresh.shadow_size = 12 if on else 0
	glow.add_theme_stylebox_override("panel", fresh)

func _refresh_submit(btn: Button, glow_panel: Panel = null) -> void:
	var all_filled := true
	for input_ctrl in _inputs:
		var le := _line_edit_for(input_ctrl)
		if le == null or le.text.strip_edges().is_empty():
			all_filled = false
			break
	btn.disabled = not all_filled
	if glow_panel != null:
		var sb := glow_panel.get_theme_stylebox("panel") as StyleBoxFlat
		if sb != null:
			var fresh: StyleBoxFlat = sb.duplicate()
			fresh.shadow_color = Color(1.0, 0.4, 0.7, 0.55 if all_filled else 0.0)
			fresh.shadow_size = 20 if all_filled else 0
			glow_panel.add_theme_stylebox_override("panel", fresh)

func _line_edit_for(holder: Variant) -> LineEdit:
	if holder is LineEdit:
		return holder
	if holder is Control and (holder as Control).has_meta("line_edit"):
		return (holder as Control).get_meta("line_edit") as LineEdit
	return null

func _submit() -> void:
	_scores.clear()
	for i in _inputs.size():
		var le := _line_edit_for(_inputs[i])
		var text := le.text.strip_edges() if le != null else ""
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
	head.text = "STORY SCORED!"
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_theme_font_size_override("font_size", 30)
	head.add_theme_color_override("font_color", VIBRANT_GOLD)
	head.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.55))
	head.add_theme_constant_override("outline_size", 5)
	_body.add_child(head)

	var stat := Label.new()
	stat.text = "%d / %d" % [total, max_total]
	stat.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stat.add_theme_font_size_override("font_size", 22)
	stat.add_theme_color_override("font_color", Color.WHITE)
	stat.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.45))
	stat.add_theme_constant_override("outline_size", 3)
	_body.add_child(stat)

	# Celebration: confetti + popup; banner + fireworks if a strong score.
	await get_tree().process_frame
	Fx.score_popup(self, Vector2(size.x * 0.5 - 24, 120), "+%d XP" % total, true, VIBRANT_GOLD)
	var froms: Array = []
	var cols: Array = [VIBRANT_GOLD, VIBRANT_MAGENTA, VIBRANT_GREEN, Color("#3aa8ff")]
	for i in _scores.size():
		froms.append(Vector2(size.x * (0.2 + 0.18 * i), 200))
	Fx.confetti_to(self, froms, Vector2(size.x * 0.5, 100), cols)
	if max_total > 0 and float(total) / float(max_total) >= 0.7:
		Fx.banner(self, "GREAT STORY!", VIBRANT_GOLD, VIBRANT_GOLD_DARK)
		Fx.fireworks(self, Vector2(size.x * 0.5, size.y * 0.35))

	for i in _scores.size():
		_body.add_child(_score_card(i))

	var next := Chrome.pill_button("Next Story", VIBRANT_MAGENTA, Color.WHITE, "res://assets/icons/arrow_right.svg")
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
	sb.bg_color = Color(DARK_CARD.r, DARK_CARD.g, DARK_CARD.b, 0.82)
	sb.set_corner_radius_all(14)
	sb.set_border_width_all(2)
	sb.border_color = DARK_CARD_BORDER
	sb.shadow_color = Color(0, 0, 0, 0.22)
	sb.shadow_size = 4
	sb.shadow_offset = Vector2i(0, 2)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	card.add_theme_stylebox_override("panel", sb)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	card.add_child(box)
	var head := HBoxContainer.new()
	var label := Label.new()
	label.text = "Blank %d" % (i + 1)
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", VIBRANT_GOLD)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(label)
	var chip_bg: Color = VIBRANT_GREEN if s.good else VIBRANT_MAGENTA
	var chip_fg: Color = VIBRANT_GREEN_DARK if s.good else Color.WHITE
	head.add_child(Chrome.chip("%d/%d" % [s.score, s.max], chip_bg, chip_fg))
	box.add_child(head)
	var you := Label.new()
	you.text = 'You: "%s"' % s.yours
	you.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	you.add_theme_font_size_override("font_size", 13)
	you.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
	box.add_child(you)
	var sample_row := HBoxContainer.new()
	sample_row.add_theme_constant_override("separation", 6)
	box.add_child(sample_row)
	var bulb_path := "res://assets/icons/bulb.svg"
	if ResourceLoader.exists(bulb_path):
		var bulb := TextureRect.new()
		bulb.texture = load(bulb_path)
		bulb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		bulb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bulb.custom_minimum_size = Vector2(16, 16)
		bulb.modulate = VIBRANT_GOLD
		bulb.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		bulb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sample_row.add_child(bulb)
	var sample := Label.new()
	sample.text = 'Sample: "%s"' % s.sample
	sample.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sample.add_theme_font_size_override("font_size", 12)
	sample.add_theme_color_override("font_color", VIBRANT_GOLD)
	sample.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sample_row.add_child(sample)
	return card

func _clear_body() -> void:
	for c in _body.get_children():
		c.queue_free()

func _back() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

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
