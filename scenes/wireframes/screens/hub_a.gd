extends Control
## Hub A — Vertical Path (every node selectable)

const Screen := preload("res://scripts/wf/wf_screen.gd")
const Artboards := preload("res://scripts/wf/artboards.gd")

const ROUTES := [
	["Word Fight", "wf_intro"],
	["Word Match", "wm_game"],
	["Word Found", "wfnd_game"],
	["Story Tell", "st_game"],
	["Word Type",  "wt_game"],
	["Describe Pic", "dp_game"],
	["Listen", "ld_game"],
]

func _ready() -> void:
	Screen.build(self, Artboards.hub_a())
	Screen.tag_nav(self, "Play now!", "wfnd_game")
	for r in ROUTES:
		Screen.tag_nav_nth(self, r[0], r[1], 0)
	Screen.wire_nav(self)
