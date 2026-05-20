extends Control
## Shared "Coming soon" stub for unimplemented mini-games.
## Set `game_id` and `title` via the inspector.

@export var game_id: String = ""
@export var title: String = "Coming soon"

func _ready() -> void:
	$V/Title.text = title
	$V/Sub.text = '"%s" is on the roadmap.' % title
	($V/Accent as ColorRect).color = Palette.game_color(game_id)
	$V/BackBtn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
