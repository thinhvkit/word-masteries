extends Control
## Mode Select

const Screen := preload("res://scripts/wf/wf_screen.gd")
const Artboards := preload("res://scripts/wf/artboards.gd")

func _ready() -> void:
	Screen.build(self, Artboards.mode_select())
	Screen.tag_nav(self, "Start Playing", "reset:hub_c", func():
		GameState.set_mode(GameState.Mode.INTERMEDIATE))
	Screen.wire_nav(self)
