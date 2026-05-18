extends Control
## Describe Picture — Gameplay

const Screen := preload("res://scripts/wf/wf_screen.gd")
const Artboards := preload("res://scripts/wf/artboards.gd")

func _ready() -> void:
	Screen.build(self, Artboards.dp_game())
	Screen.tag_nav(self, "Submit All", "dp_results")
	Screen.wire_nav(self)
