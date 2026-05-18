extends Control
## Word Match — Results

const Screen := preload("res://scripts/wf/wf_screen.gd")
const Artboards := preload("res://scripts/wf/artboards.gd")

func _ready() -> void:
	Screen.build(self, Artboards.wm_results())
	Screen.tag_nav(self, "Play Again", "replace:wm_game")
	Screen.tag_nav(self, "Back to Map", "reset:hub_c")
	Screen.wire_nav(self)
