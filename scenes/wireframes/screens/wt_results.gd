extends Control
## Word Type — Results

const Screen := preload("res://scripts/wf/wf_screen.gd")
const Artboards := preload("res://scripts/wf/artboards.gd")

func _ready() -> void:
	Screen.build(self, Artboards.wt_results())
	Screen.tag_nav(self, "Next Word →", "replace:wt_game")
	Screen.wire_nav(self)
