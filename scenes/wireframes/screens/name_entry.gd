extends Control
## Name & Avatar

const Screen := preload("res://scripts/wf/wf_screen.gd")
const Artboards := preload("res://scripts/wf/artboards.gd")

func _ready() -> void:
	Screen.build(self, Artboards.name_entry())
	Screen.tag_nav(self, "Continue", "mode_select", func():
		if GameState.player_name.is_empty():
			GameState.player_name = "Alex"
			GameState.save())
	Screen.wire_nav(self)
