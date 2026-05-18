extends RefCounted
## Static helpers for wireframe screens.
## Each screen is a plain `Control` whose `_ready()` calls these helpers:
##
##   const Screen := preload("res://scripts/wf/wf_screen.gd")
##   const Artboards := preload("res://scripts/wf/artboards.gd")
##
##   func _ready() -> void:
##       custom_minimum_size = Vector2(340, 720)
##       Screen.build(self, Artboards.splash())
##       Screen.tag_nav(self, "Get Started", "login")
##       Screen.wire_nav(self)
##
## Nav targets:
##   "$back"        → Navigator.back()
##   "<id>"         → Navigator.goto("<id>")
##   "reset:<id>"   → Navigator.reset_to("<id>")
##   "replace:<id>" → Navigator.replace("<id>")

# Mount a Phone control under `screen`. Sets minimum size.
static func build(screen: Control, phone: Control) -> void:
	# The screen Control fills the viewport; the phone fills the screen.
	screen.custom_minimum_size = Vector2(0, 0)
	screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	if phone != null:
		phone.set_anchors_preset(Control.PRESET_FULL_RECT)
		phone.custom_minimum_size = Vector2(0, 0)
		screen.add_child(phone)

# Tag the first Button/Label whose text matches `text` with a nav target.
# Optionally attach a side-effect Callable that runs before navigation.
static func tag_nav(screen: Control, text: String, target: String, side_effect: Callable = Callable()) -> Control:
	var ctrl := find_by_text(screen, text)
	if ctrl == null:
		push_warning("tag_nav: no control with text '%s' on %s" % [text, screen.name])
		return null
	ctrl.set_meta("nav", target)
	if side_effect.is_valid():
		ctrl.set_meta("nav_side_effect", side_effect)
	if ctrl is Label:
		(ctrl as Label).mouse_filter = Control.MOUSE_FILTER_STOP
		(ctrl as Label).mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return ctrl

# Tag the Nth match (0-indexed) — used when text isn't unique.
static func tag_nav_nth(screen: Control, text: String, target: String, index: int) -> Control:
	var count := 0
	for n in _walk(screen):
		if (n is Button and (n as Button).text == text) or (n is Label and (n as Label).text == text):
			if count == index:
				n.set_meta("nav", target)
				if n is Label:
					(n as Label).mouse_filter = Control.MOUSE_FILTER_STOP
				return n
			count += 1
	return null

static func find_by_text(root: Node, text: String) -> Control:
	for n in _walk(root):
		if n is Button and (n as Button).text == text:
			return n
		if n is Label and (n as Label).text == text:
			return n
	return null

# Walk every node under `root` and connect tagged buttons/controls to Navigator.
static func wire_nav(root: Node) -> void:
	for n in _walk(root):
		if not n.has_meta("nav"):
			continue
		var target: String = n.get_meta("nav")
		var node: Node = n
		if n is Button:
			(n as Button).pressed.connect(func(): _route(target, node))
		elif n is Control:
			(n as Control).gui_input.connect(func(ev): _on_tap(ev, target, node))

static func _on_tap(ev: InputEvent, target: String, source: Node) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		_route(target, source)
	elif ev is InputEventScreenTouch and ev.pressed:
		_route(target, source)

static func _route(target: String, source: Node) -> void:
	if source != null and source.has_meta("nav_side_effect"):
		var fx: Callable = source.get_meta("nav_side_effect")
		if fx.is_valid():
			fx.call()
	# Navigator is an autoload, reachable from the SceneTree.
	var nav: Node = Engine.get_main_loop().get_root().get_node_or_null("Navigator")
	if nav == null:
		push_warning("Navigator autoload missing")
		return
	if target == "$back":
		nav.back()
	elif target.begins_with("reset:"):
		nav.reset_to(target.substr(6))
	elif target.begins_with("replace:"):
		nav.replace(target.substr(8))
	else:
		nav.goto(target)

static func _walk(n: Node) -> Array:
	var out: Array = [n]
	for c in n.get_children():
		out.append_array(_walk(c))
	return out
