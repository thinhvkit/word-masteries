extends Control
## Hub C — Card List (all 7 games selectable)

const Screen := preload("res://scripts/wf/wf_screen.gd")
const Artboards := preload("res://scripts/wf/artboards.gd")

# Each card's "Play" button + its title label are tappable.
const ROUTES := [
	["Word Fight", "wf_intro"],
	["Word Match", "wm_game"],
	["Word Found", "wfnd_game"],
	["Story Tell", "st_game"],
	["Word Type",  "wt_game"],
	["Describe Picture", "dp_game"],
	["Listen & Dictate", "ld_game"],
]

func _ready() -> void:
	Screen.build(self, Artboards.hub_c())
	for i in ROUTES.size():
		Screen.tag_nav_nth(self, "Play", ROUTES[i][1], i)
		Screen.tag_nav_nth(self, ROUTES[i][0], ROUTES[i][1], 0)
	Screen.wire_nav(self)
