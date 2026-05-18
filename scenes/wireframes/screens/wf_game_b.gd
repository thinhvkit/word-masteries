extends Control
## Word Fight — Dark Arena

const Screen := preload("res://scripts/wf/wf_screen.gd")
const Artboards := preload("res://scripts/wf/artboards.gd")

func _ready() -> void:
	Screen.build(self, Artboards.wf_game_b())

	Screen.wire_nav(self)
