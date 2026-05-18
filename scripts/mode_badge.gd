class_name ModeBadge
extends PanelContainer
## Mode pill — cozy palette.
## Intermediate: sage-tinted background, sage-dark text.
## Advanced: pink-tinted background, pink-dark text.

const SAGE_TINT := Color("#e0f4d8")
const SAGE_DEEP := Color("#3a8a52")
const PINK_TINT := Color("#ffe2eb")
const PINK_DEEP := Color("#c44a6c")

@onready var _label: Label = $Label
var _sb: StyleBoxFlat

func _ready() -> void:
	_sb = StyleBoxFlat.new()
	_sb.set_corner_radius_all(99)
	_sb.content_margin_left = 12
	_sb.content_margin_right = 12
	_sb.content_margin_top = 4
	_sb.content_margin_bottom = 4
	_sb.shadow_color = Color(0, 0, 0, 0.08)
	_sb.shadow_size = 2
	_sb.shadow_offset = Vector2i(0, 1)
	add_theme_stylebox_override("panel", _sb)
	_label.add_theme_font_size_override("font_size", 11)
	_refresh()
	GameState.mode_changed.connect(func(_m): _refresh())

func _refresh() -> void:
	var adv := GameState.mode == GameState.Mode.ADVANCED
	_sb.bg_color = PINK_TINT if adv else SAGE_TINT
	_label.add_theme_color_override("font_color", PINK_DEEP if adv else SAGE_DEEP)
	_label.text = GameState.mode_name()
