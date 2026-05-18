extends Control
## Story Tell — Results

const Screen := preload("res://scripts/wf/wf_screen.gd")
const Artboards := preload("res://scripts/wf/artboards.gd")

func _ready() -> void:
	Screen.build(self, Artboards.st_results())
	Screen.tag_nav(self, "Next Story →", "replace:st_game")
	Screen.wire_nav(self)
