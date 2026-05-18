extends Control
## Story Tell — Gameplay

const Screen := preload("res://scripts/wf/wf_screen.gd")
const Artboards := preload("res://scripts/wf/artboards.gd")

func _ready() -> void:
	Screen.build(self, Artboards.st_game())
	Screen.tag_nav(self, "Submit Story", "st_results")
	Screen.wire_nav(self)
