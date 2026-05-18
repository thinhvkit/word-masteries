extends Control
## Word Fight — Rainbow Booster

const Screen := preload("res://scripts/wf/wf_screen.gd")
const Artboards := preload("res://scripts/wf/artboards.gd")

func _ready() -> void:
	Screen.build(self, Artboards.wf_rainbow())
	Screen.tag_nav(self, "Cancel", "$back")
	Screen.wire_nav(self)
