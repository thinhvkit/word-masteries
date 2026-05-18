extends Control
## Word Found — Wave Complete

const Screen := preload("res://scripts/wf/wf_screen.gd")
const Artboards := preload("res://scripts/wf/artboards.gd")

func _ready() -> void:
	Screen.build(self, Artboards.wfnd_wave())
	Screen.tag_nav(self, "Start Wave 4 →", "replace:wfnd_game")
	Screen.wire_nav(self)
