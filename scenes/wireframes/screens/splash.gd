extends Control
## Splash

const Screen := preload("res://scripts/wf/wf_screen.gd")
const Artboards := preload("res://scripts/wf/artboards.gd")

func _ready() -> void:
	Screen.build(self, Artboards.splash())
	Screen.tag_nav(self, "Get Started", "login")
	Screen.tag_nav(self, "Already have an account? Log in", "login")
	Screen.wire_nav(self)
