extends SceneTree

func _initialize() -> void:
	var scene := load("res://games/word_fight/word_fight.tscn") as PackedScene
	var root := scene.instantiate()
	get_root().add_child(root)
	get_root().size = Vector2i(390, 844)
	await process_frame
	await process_frame

	var grid: GridContainer = root.get_node("V/BoardCenter/Board")
	var current: Label = root.get_node("V/Top/Current")
	var submit: Button = root.get_node("V/Actions/Submit")
	var status: Label = root.get_node("V/Status")
	var enemy_hp: Label = root.get_node("V/HUD/Enemy/HP")
	var rb_btn: Button = root.get_node("V/Actions/Rainbow")

	var letters := []
	for c in grid.get_children(): letters.append(c.letter)
	print("=== BOARD ===")
	for r in 5:
		var row := []
		for c in 5: row.append(letters[r*5+c])
		print(" ", " ".join(row))

	# --- Test 1: tile click via Button.pressed (simulates real click) ---
	print("\n=== TEST 1: tap tile #0 ===")
	grid.get_child(0).pressed.emit()
	await process_frame
	print(" tile#0.button_pressed.selected_order=", grid.get_child(0).selected_order)
	print(" current label=", current.text, "  submit_disabled=", submit.disabled)

	# --- Test 2: real InputEvent routed through viewport ---
	print("\n=== TEST 2: real mouse event at tile #1 center ===")
	root._clear_chain()
	var t1 = grid.get_child(1)
	var center: Vector2 = t1.get_global_rect().get_center()
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.position = center; press.global_position = center
	press.pressed = true
	get_root().push_input(press)
	await process_frame
	var rel := InputEventMouseButton.new()
	rel.button_index = MOUSE_BUTTON_LEFT
	rel.position = center; rel.global_position = center
	rel.pressed = false
	get_root().push_input(rel)
	await process_frame
	print(" tile#1.selected_order=", t1.selected_order)

	# --- Test 3: form a real word and submit ---
	print("\n=== TEST 3: form a real word + submit ===")
	root._clear_chain()
	var pool := ""
	for L in letters: pool += L.to_lower()
	var words: Array[String] = get_root().get_node("Words").words_from_letters(pool, 3, false)
	if words.is_empty():
		print(" no formable words"); quit(); return
	# Prefer a 4-letter word for visible damage.
	words.sort_custom(func(a, b): return a.length() > b.length())
	var word: String = words[0] if words[0].length() <= 6 else words[words.size()/2]
	print(" trying word:", word)
	var used := {}; var path: Array = []
	for ch in word.to_upper():
		for i in grid.get_child_count():
			if used.has(i): continue
			if grid.get_child(i).letter == ch:
				used[i] = true; path.append(i); break
	for i in path:
		grid.get_child(i).pressed.emit()
	await process_frame
	print(" formed=", current.text, "  submit_disabled=", submit.disabled)
	var hp_before := int(enemy_hp.text)
	submit.pressed.emit()
	await process_frame
	print(" status=", status.text)
	print(" enemy_hp:", hp_before, "->", int(enemy_hp.text), "  (damage=", hp_before - int(enemy_hp.text), ")")

	# --- Test 4: invalid word feedback ---
	print("\n=== TEST 4: invalid word ===")
	root._is_player_turn = true; root._busy = false
	root._clear_chain()
	# Find 3 consonants unlikely to form a word.
	var picked: Array = []
	for i in grid.get_child_count():
		var L = grid.get_child(i).letter
		if "BCDFGHJKLMNPQRSTVWXYZ".find(L) != -1 and picked.size() < 3:
			picked.append(i)
	for i in picked: grid.get_child(i).pressed.emit()
	await process_frame
	print(" formed=", current.text)
	submit.pressed.emit()
	await process_frame
	print(" status=", status.text)
	print(" current label after:", current.text, " (should be ✗ ... if invalid)")

	# --- Test 5: rainbow booster flow ---
	print("\n=== TEST 5: rainbow booster ===")
	root._is_player_turn = true; root._busy = false
	root._rainbows = 1
	root._refresh_hud()
	print(" rb btn text=", rb_btn.text, " disabled=", rb_btn.disabled)
	rb_btn.pressed.emit()
	print(" after use: auto_busy=", root._rainbow_auto_busy, " rb.text=", rb_btn.text)

	# --- Test 6: clear chain ---
	print("\n=== TEST 6: clear chain ===")
	root._is_player_turn = true; root._busy = false
	root._clear_chain()
	grid.get_child(0).pressed.emit()
	grid.get_child(1).pressed.emit()
	print(" before clear: word=", current.text, " selected=", root._selected.size())
	root._clear_chain()
	print(" after clear: word=", current.text, " selected=", root._selected.size())

	# --- Test 7: tap selected tile to pop back ---
	print("\n=== TEST 7: tap selected tile to pop chain ===")
	grid.get_child(0).pressed.emit()
	grid.get_child(1).pressed.emit()
	grid.get_child(2).pressed.emit()
	print(" 3 selected, word=", current.text)
	grid.get_child(1).pressed.emit()  # tap tile #1 (at chain pos 1) → pop back to before it
	print(" after tapping #1: selected size=", root._selected.size(), " word=", current.text)

	quit()
