extends Node
## Masteries design tokens — cozy Forest-Match style.
## Cream BG, brown ink, pink primary, sage success, gold accent.

# Core surfaces / text
const BG             := Color("#faf5ed")
const BG_SOFT        := Color("#f0e8dd")
const SURFACE        := Color("#ffffff")
const TEXT           := Color("#5a4840")
const TEXT_SECONDARY := Color("#9a8a7e")
const TEXT_SEC       := Color("#9a8a7e")
const HAIRLINE       := Color("#e8e0d8")
const BORDER         := Color("#e8e0d8")

# Brand
const PINK           := Color("#ff8faa")
const PINK_DARK      := Color("#e86888")
const SAGE           := Color("#6dd68a")
const SAGE_DARK      := Color("#4fb86b")
const GOLD           := Color("#ffc844")
const GOLD_DARK      := Color("#dba830")
const MUSHROOM       := Color("#ff8844")
const MUSHROOM_DARK  := Color("#d96624")
const TERRACOTTA     := Color("#e86888")

# Legacy aliases — kept so older code keeps compiling, mapped to cozy equivalents.
const GREEN        := Color("#6dd68a")
const GREEN_DARK   := Color("#4fb86b")
const YELLOW       := Color("#ffc844")
const YELLOW_DARK  := Color("#dba830")
const CORAL        := Color("#ff8844")
const CORAL_DARK   := Color("#d96624")
const BLUE         := Color("#7cc5e8")
const BLUE_DARK    := Color("#4fa3c8")
const PURPLE       := Color("#b88adf")
const PURPLE_DARK  := Color("#8c5cb8")
const TEAL         := Color("#6fc8b8")
const TEAL_DARK    := Color("#3fa090")
const RED          := Color("#e86888")
const RED_DARK     := Color("#c44a6c")

static func game_color(game_id: String) -> Color:
	match game_id:
		"word_fight":       return Color("#ff8844")
		"word_match":       return Color("#7cc5e8")
		"word_found":       return Color("#6dd68a")
		"story_tell":       return Color("#b88adf")
		"word_type":        return Color("#ffc844")
		"describe_picture": return Color("#6fc8b8")
		"listen_dictate":   return Color("#ff8faa")
		_: return Color("#6dd68a")

static func game_color_dark(game_id: String) -> Color:
	return game_color(game_id).darkened(0.18)

static func darken(c: Color) -> Color:
	return c.darkened(0.15)

# ----- chunky-button factory (soft drop shadow) -----

static func chunky_button_stylebox(bg_color: Color, radius: int = 14) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg_color
	s.set_corner_radius_all(radius)
	s.content_margin_left = 16
	s.content_margin_right = 16
	s.content_margin_top = 10
	s.content_margin_bottom = 10
	s.shadow_color = Color(0, 0, 0, 0.18)
	s.shadow_size = 4
	s.shadow_offset = Vector2i(0, 2)
	return s

static func chunky_button_hover(bg_color: Color, radius: int = 14) -> StyleBoxFlat:
	var s := chunky_button_stylebox(bg_color.lightened(0.08), radius)
	s.shadow_color = Color(0, 0, 0, 0.22)
	s.shadow_size = 6
	s.shadow_offset = Vector2i(0, 3)
	return s

static func chunky_button_pressed(bg_color: Color, radius: int = 14) -> StyleBoxFlat:
	var s := chunky_button_stylebox(bg_color.darkened(0.08), radius)
	s.content_margin_top = 12
	s.content_margin_bottom = 8
	s.shadow_size = 2
	s.shadow_offset = Vector2i(0, 1)
	return s

static func style_button(btn: Button, bg_color: Color, fg_color: Color = Color("#ffffff"), radius: int = 14) -> void:
	btn.add_theme_color_override("font_color", fg_color)
	btn.add_theme_color_override("font_hover_color", fg_color)
	btn.add_theme_color_override("font_pressed_color", fg_color)
	btn.add_theme_color_override("font_focus_color", fg_color)
	btn.add_theme_stylebox_override("normal", chunky_button_stylebox(bg_color, radius))
	btn.add_theme_stylebox_override("hover", chunky_button_hover(bg_color, radius))
	btn.add_theme_stylebox_override("pressed", chunky_button_pressed(bg_color, radius))
	var focus := chunky_button_stylebox(bg_color, radius)
	focus.border_color = GOLD
	focus.set_border_width_all(2)
	btn.add_theme_stylebox_override("focus", focus)
