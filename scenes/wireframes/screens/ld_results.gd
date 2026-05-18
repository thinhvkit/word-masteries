extends Control
## Listen & Dictate — Results

const Screen := preload("res://scripts/wf/wf_screen.gd")
const Artboards := preload("res://scripts/wf/artboards.gd")

func _ready() -> void:
	Screen.build(self, Artboards.ld_results())
	Screen.tag_nav(self, "Next Word →", "replace:ld_game")
	Screen.tag_nav(self, "Back to Map", "reset:hub_c")
	Screen.wire_nav(self)
