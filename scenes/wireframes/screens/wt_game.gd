extends Control
## Word Type — Gameplay

const Screen := preload("res://scripts/wf/wf_screen.gd")
const Artboards := preload("res://scripts/wf/artboards.gd")

func _ready() -> void:
	Screen.build(self, Artboards.wt_game())
	Screen.tag_nav(self, "Submit", "wt_results")
	Screen.wire_nav(self)
