extends Control
## Listen & Dictate — Gameplay

const Screen := preload("res://scripts/wf/wf_screen.gd")
const Artboards := preload("res://scripts/wf/artboards.gd")

func _ready() -> void:
	Screen.build(self, Artboards.ld_game())
	Screen.tag_nav(self, "Submit (fill all boxes)", "ld_results")
	Screen.wire_nav(self)
