extends Control
## Splash + Username combined (Masteries kit screens 1+2).

const AVATARS := ["fox","butterfly","frog","lion","parrot","octopus","dolphin","panda"]
const DOT_COLORS := [
	"#6dd68a", "#ffc844", "#ff8844", "#7cc5e8",
	"#b88adf", "#6fc8b8", "#ff8faa",
]
const TEXT := Color("#5a4840")
const TEXT_SEC := Color("#9a8a7e")
const SURFACE := Color("#ffffff")
const BORDER := Color("#e8e0d8")
# Primary accent — pink instead of Duolingo green.
const PRIMARY := Color("#ff8faa")
const PRIMARY_DARK := Color("#e86888")
# Legacy names so the rest of the file (avatars + button factories) compiles unchanged.
const GREEN := PRIMARY
const GREEN_DARK := PRIMARY_DARK

@onready var mascot_holder: Control = $V/Top/Mascot
@onready var title_lbl: Label = $V/Top/Title
@onready var tagline_lbl: Label = $V/Top/Tagline
@onready var dots_row: HBoxContainer = $V/Top/Dots
@onready var avatars_grid: GridContainer = $V/Avatars
@onready var name_field: PanelContainer = $V/NameField
@onready var name_edit: LineEdit = $V/NameField/Edit
@onready var continue_btn: Button = $V/Continue

var _avatar_idx: int = 0
var _name_sb: StyleBoxFlat
var _avatar_btns: Array[Control] = []

# Web fallback: Godot 4.x has known mobile-LineEdit bugs (iOS keyboard never
# opens; Android typing doesn't propagate). On web we overlay a real HTML
# <input> element over the name field and sync its value into name_edit.
const _WEB_INPUT_ID := "masteries_name_input"
var _web_input_active := false

func _ready() -> void:
	_build_mascot()
	_style_title()
	_build_dots()
	_build_avatars()
	_style_name_field()
	_style_continue()
	if not GameState.player_name.is_empty():
		name_edit.text = GameState.player_name
		_refresh_name()
	var saved_idx := AVATARS.find(GameState.player_avatar)
	if saved_idx >= 0:
		_avatar_idx = saved_idx
	name_edit.text_changed.connect(func(_t): _refresh_name())
	name_edit.text_submitted.connect(func(_t): _try_continue())
	continue_btn.pressed.connect(_try_continue)
	# On web, install the HTML <input> overlay (skipped on native).
	if OS.has_feature("web"):
		call_deferred("_install_web_input")

func _build_mascot() -> void:
	var MascotScript := preload("res://scripts/wriggles.gd")
	var m := MascotScript.new()
	m.draw_size = 130.0
	mascot_holder.add_child(m)
	mascot_holder.custom_minimum_size = Vector2(0, 130 * 0.85 + 4)
	# Center horizontally inside its row.
	m.set_anchors_preset(Control.PRESET_CENTER_TOP)
	m.position = Vector2(-65, 0)

func _style_title() -> void:
	title_lbl.text = "Masteries"
	title_lbl.add_theme_font_size_override("font_size", 48)
	title_lbl.add_theme_color_override("font_color", TEXT)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tagline_lbl.text = "Level up your words."
	tagline_lbl.add_theme_font_size_override("font_size", 16)
	tagline_lbl.add_theme_color_override("font_color", TEXT_SEC)
	tagline_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _build_dots() -> void:
	dots_row.alignment = BoxContainer.ALIGNMENT_CENTER
	dots_row.add_theme_constant_override("separation", 8)
	for hex in DOT_COLORS:
		var d := _Dot.new()
		d.color = Color(hex)
		dots_row.add_child(d)

func _build_avatars() -> void:
	avatars_grid.columns = 4
	avatars_grid.add_theme_constant_override("h_separation", 10)
	avatars_grid.add_theme_constant_override("v_separation", 10)
	for i in AVATARS.size():
		var btn := _make_avatar(AVATARS[i], i)
		avatars_grid.add_child(btn)
		_avatar_btns.append(btn)
	_refresh_avatars()

func _make_avatar(id: String, idx: int) -> Control:
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 72)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.text = ""
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(func():
		_avatar_idx = idx
		_refresh_avatars())

	# Centered SVG inside the button. Mouse passthrough so button receives taps.
	var tex_path := "res://assets/avatars/%s.svg" % id
	if ResourceLoader.exists(tex_path):
		var icon := TextureRect.new()
		icon.texture = load(tex_path)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.set_anchors_preset(Control.PRESET_FULL_RECT)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# Inset slightly so the icon doesn't kiss the border.
		icon.offset_left = 8
		icon.offset_top = 8
		icon.offset_right = -8
		icon.offset_bottom = -8
		b.add_child(icon)
	return b

func _refresh_avatars() -> void:
	for i in _avatar_btns.size():
		var b := _avatar_btns[i] as Button
		var active := i == _avatar_idx
		var sb := StyleBoxFlat.new()
		sb.bg_color = PRIMARY if active else SURFACE
		sb.set_corner_radius_all(18)
		sb.set_border_width_all(2)
		sb.border_color = PRIMARY_DARK if active else BORDER
		sb.shadow_color = Color(0, 0, 0, 0.15 if active else 0.08)
		sb.shadow_size = 4 if active else 3
		sb.shadow_offset = Vector2i(0, 2 if active else 1)
		var press := sb.duplicate() as StyleBoxFlat
		press.shadow_size = 1
		press.shadow_offset = Vector2i(0, 0)
		press.content_margin_top = 2
		b.add_theme_stylebox_override("normal", sb)
		b.add_theme_stylebox_override("hover", sb)
		b.add_theme_stylebox_override("pressed", press)
		b.add_theme_stylebox_override("focus", sb)
		b.add_theme_color_override("font_color", Color.WHITE if active else TEXT)

func _style_name_field() -> void:
	_name_sb = StyleBoxFlat.new()
	_name_sb.bg_color = SURFACE
	_name_sb.corner_radius_top_left = 16
	_name_sb.corner_radius_top_right = 16
	_name_sb.corner_radius_bottom_left = 16
	_name_sb.corner_radius_bottom_right = 16
	_name_sb.border_width_left = 2
	_name_sb.border_width_right = 2
	_name_sb.border_width_top = 2
	_name_sb.border_width_bottom = 2
	_name_sb.border_color = BORDER
	# IMPORTANT: zero padding on the wrapper so the LineEdit fills the entire
	# tappable area. iOS Safari only opens the virtual keyboard when the touch
	# lands directly on the LineEdit (its hidden HTML <input>), not on padding.
	_name_sb.content_margin_left = 0
	_name_sb.content_margin_right = 0
	_name_sb.content_margin_top = 0
	_name_sb.content_margin_bottom = 0
	name_field.add_theme_stylebox_override("panel", _name_sb)
	name_field.mouse_filter = Control.MOUSE_FILTER_PASS
	name_edit.placeholder_text = "Your display name"
	name_edit.add_theme_font_size_override("font_size", 16)
	name_edit.add_theme_color_override("font_color", TEXT)
	name_edit.add_theme_color_override("font_placeholder_color", TEXT_SEC)
	name_edit.focus_mode = Control.FOCUS_ALL
	name_edit.mouse_filter = Control.MOUSE_FILTER_STOP
	name_edit.virtual_keyboard_enabled = true
	name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_edit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	# Use transparent StyleBoxFlat (NOT StyleBoxEmpty) with explicit content margins.
	# StyleBoxEmpty has no defined text region, which on Android Chrome / iOS Safari
	# causes typed characters from the virtual keyboard to render offscreen.
	var le_box := StyleBoxFlat.new()
	le_box.bg_color = Color(0, 0, 0, 0)
	# LineEdit owns its own visual padding now that the wrapper has none.
	le_box.content_margin_left = 16
	le_box.content_margin_right = 16
	le_box.content_margin_top = 14
	le_box.content_margin_bottom = 14
	name_edit.add_theme_stylebox_override("normal", le_box)
	name_edit.add_theme_stylebox_override("focus", le_box)
	name_edit.add_theme_stylebox_override("read_only", le_box)

func _refresh_name() -> void:
	var has := not name_edit.text.strip_edges().is_empty()
	_name_sb.border_color = GREEN if has else BORDER
	continue_btn.disabled = not has

func _style_continue() -> void:
	continue_btn.custom_minimum_size = Vector2(0, 56)
	continue_btn.text = "Continue"
	continue_btn.add_theme_font_size_override("font_size", 17)
	continue_btn.focus_mode = Control.FOCUS_NONE
	var arrow_path := "res://assets/icons/arrow_right.svg"
	if ResourceLoader.exists(arrow_path):
		continue_btn.icon = load(arrow_path)
		continue_btn.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		continue_btn.expand_icon = false
		continue_btn.add_theme_constant_override("icon_max_width", 24)
		continue_btn.add_theme_constant_override("h_separation", 10)
	Palette.style_button(continue_btn, PRIMARY, Color.WHITE, 16)
	var disabled := Palette.chunky_button_stylebox(Color("#d8cdc0"), 16)
	continue_btn.add_theme_stylebox_override("disabled", disabled)
	continue_btn.add_theme_color_override("font_disabled_color", Color.WHITE)
	continue_btn.disabled = true

func _try_continue() -> void:
	if _web_input_active:
		_pull_web_input_value()
	var n := name_edit.text.strip_edges()
	if n.is_empty():
		return
	GameState.player_name = n
	GameState.player_avatar = AVATARS[_avatar_idx]
	GameState.save()
	get_tree().change_scene_to_file("res://scenes/mode_select.tscn")

# ---------------- Web HTML <input> overlay ----------------

func _install_web_input() -> void:
	if not Engine.has_singleton("JavaScriptBridge"):
		return
	# Create the overlay element once. Style approximates the Godot field so
	# it looks natural over the cream background.
	var initial: String = name_edit.text
	var js_create := """
		(function(){
			var old = document.getElementById('%s');
			if (old) old.remove();
			var inp = document.createElement('input');
			inp.id = '%s';
			inp.type = 'text';
			inp.value = %s;
			inp.placeholder = 'Your display name';
			inp.autocomplete = 'off';
			inp.autocapitalize = 'words';
			inp.autocorrect = 'off';
			inp.spellcheck = false;
			inp.maxLength = 24;
			inp.style.cssText = [
				'position:absolute','padding:0 16px','margin:0','border:none','outline:none',
				'background:transparent','color:#5a4840','font-size:16px','font-family:sans-serif',
				'box-sizing:border-box','z-index:9999','touch-action:auto','pointer-events:auto',
				'-webkit-user-select:text','user-select:text','-webkit-touch-callout:default',
				'-webkit-appearance:none','appearance:none'
			].join(';');
			document.body.appendChild(inp);
			// Stop Godot's global key listeners from swallowing our key events.
			// iOS Safari was showing the keyboard but routing keystrokes to the canvas.
			var stop = function(e){ e.stopPropagation(); };
			['keydown','keyup','keypress','input','compositionstart','compositionupdate','compositionend','beforeinput'].forEach(function(t){
				inp.addEventListener(t, stop, true);
			});
			// On focus, blur the canvas so it can't intercept input.
			inp.addEventListener('focus', function(){
				var c = document.querySelector('canvas');
				if (c && c.blur) c.blur();
			});
			var pushValue = function(e){ window.__masteries_name = e.target.value; };
			inp.addEventListener('input', pushValue);
			inp.addEventListener('compositionend', pushValue);
			inp.addEventListener('change', pushValue);
			inp.addEventListener('keydown', function(e){
				if (e.key === 'Enter') {
					window.__masteries_submit = true;
					inp.blur();
				}
			});
			window.__masteries_name = inp.value;
		})();
	""" % [_WEB_INPUT_ID, _WEB_INPUT_ID, JSON.stringify(initial)]
	_js_eval(js_create, true)
	_web_input_active = true
	# Hide the Godot LineEdit's text + caret so it doesn't double-render under the HTML input.
	name_edit.add_theme_color_override("font_color", Color(0, 0, 0, 0))
	name_edit.add_theme_color_override("font_placeholder_color", Color(0, 0, 0, 0))
	name_edit.caret_blink = false
	set_process(true)

func _process(_delta: float) -> void:
	if not _web_input_active:
		return
	if not Engine.has_singleton("JavaScriptBridge"):
		return
	# Reposition the HTML input over the name field every frame.
	var rect: Rect2 = name_field.get_global_rect()
	var vp: Vector2 = get_viewport().get_visible_rect().size
	# Position absolute (document-relative) instead of fixed, because iOS Safari's
	# visual viewport shifts on keyboard show and yanks fixed elements to the top.
	# Adding scrollX/Y converts the canvas's viewport-relative rect into document
	# coordinates so the overlay stays glued to the actual name_field.
	var js_pos := """
		(function(){
			var inp = document.getElementById('%s');
			if (!inp) return;
			var canvas = document.querySelector('canvas');
			if (!canvas) return;
			var cr = canvas.getBoundingClientRect();
			var sx = cr.width / %f;
			var sy = cr.height / %f;
			var pageX = cr.left + (window.scrollX || window.pageXOffset || 0);
			var pageY = cr.top  + (window.scrollY || window.pageYOffset || 0);
			inp.style.left = (pageX + %f * sx) + 'px';
			inp.style.top = (pageY + %f * sy) + 'px';
			inp.style.width = (%f * sx) + 'px';
			inp.style.height = (%f * sy) + 'px';
		})();
	""" % [_WEB_INPUT_ID, vp.x, vp.y, rect.position.x, rect.position.y, rect.size.x, rect.size.y]
	_js_eval(js_pos, true)
	# Pump current value back into Godot so _refresh_name + Continue button work.
	_pull_web_input_value()
	var submit_pressed: Variant = _js_eval("window.__masteries_submit || false", true)
	if bool(submit_pressed):
		_js_eval("window.__masteries_submit = false", true)
		_try_continue()

func _pull_web_input_value() -> void:
	if not Engine.has_singleton("JavaScriptBridge"):
		return
	var v: Variant = _js_eval("window.__masteries_name || ''", true)
	if v == null:
		return
	var s := str(v)
	if s != name_edit.text:
		name_edit.text = s
		_refresh_name()

func _exit_tree() -> void:
	if _web_input_active and Engine.has_singleton("JavaScriptBridge"):
		_js_eval("var x=document.getElementById('%s'); if(x) x.remove();" % _WEB_INPUT_ID, true)

func _js_eval(src: String, use_global_ctx: bool = true) -> Variant:
	# Routed through Engine.get_singleton so this script still parses on
	# non-web platforms where the JavaScriptBridge global doesn't exist.
	if not Engine.has_singleton("JavaScriptBridge"):
		return null
	var js: Object = Engine.get_singleton("JavaScriptBridge")
	return js.call("eval", src, use_global_ctx)

class _Dot extends Control:
	var color: Color = Color.WHITE :
		set(v):
			color = v
			queue_redraw()
	func _ready() -> void:
		custom_minimum_size = Vector2(8, 8)
		size = Vector2(8, 8)
	func _draw() -> void:
		draw_circle(size * 0.5, 4, color)
