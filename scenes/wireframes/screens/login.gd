extends Control
## Login

const Screen := preload("res://scripts/wf/wf_screen.gd")
const Artboards := preload("res://scripts/wf/artboards.gd")

func _ready() -> void:
	Screen.build(self, Artboards.login())
	Screen.tag_nav(self, "Log In", "name_entry")
	Screen.tag_nav(self, "Continue with Google", "name_entry")
	Screen.tag_nav(self, "Continue with Apple", "name_entry")
	Screen.tag_nav(self, "Don't have an account? Sign Up", "name_entry")
	Screen.wire_nav(self)
