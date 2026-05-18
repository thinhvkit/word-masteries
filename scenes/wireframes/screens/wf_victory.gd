extends Control
## Word Fight — Victory

const Screen := preload("res://scripts/wf/wf_screen.gd")
const Artboards := preload("res://scripts/wf/artboards.gd")

func _ready() -> void:
	Screen.build(self, Artboards.wf_victory())
	Screen.tag_nav(self, "Next Battle →", "wf_intro")
	Screen.tag_nav(self, "Back to Map", "reset:hub_c")
	Screen.wire_nav(self)
