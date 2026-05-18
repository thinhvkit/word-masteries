extends Control
## Word Fight — Pre-Battle

const Screen := preload("res://scripts/wf/wf_screen.gd")
const Artboards := preload("res://scripts/wf/artboards.gd")

func _ready() -> void:
	Screen.build(self, Artboards.wf_intro())
	Screen.tag_nav(self, "Start Battle!", "wf_game_a")
	Screen.wire_nav(self)
