extends Control
## Describe Picture — Results

const Screen := preload("res://scripts/wf/wf_screen.gd")
const Artboards := preload("res://scripts/wf/artboards.gd")

func _ready() -> void:
	Screen.build(self, Artboards.dp_results())
	Screen.tag_nav(self, "Next Picture →", "replace:dp_game")
	Screen.wire_nav(self)
