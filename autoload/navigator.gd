extends Node
## Stack-based screen router for the wireframe app.
## Screens are identified by short ids matching files under
## res://scenes/wireframes/screens/<id>.tscn.

const SCREENS_DIR := "res://scenes/wireframes/screens/"
const SPECIAL_BACK := "$back"

var _stack: Array[String] = []   # screen ids, most recent last

func goto(id: String) -> void:
	if id == SPECIAL_BACK:
		back()
		return
	_stack.append(id)
	_load(id)

func replace(id: String) -> void:
	# Replace current top of stack (no growth).
	if _stack.is_empty():
		_stack.append(id)
	else:
		_stack[-1] = id
	_load(id)

func back() -> void:
	if _stack.size() <= 1:
		# Already at root; just reload to avoid empty state.
		if _stack.is_empty():
			return
		_load(_stack[-1])
		return
	_stack.pop_back()
	_load(_stack[-1])

func current() -> String:
	return "" if _stack.is_empty() else _stack[-1]

func reset_to(id: String) -> void:
	_stack.clear()
	_stack.append(id)
	_load(id)

func _load(id: String) -> void:
	var path := SCREENS_DIR + id + ".tscn"
	if not ResourceLoader.exists(path):
		push_warning("Navigator: missing screen %s" % path)
		return
	get_tree().change_scene_to_file(path)
