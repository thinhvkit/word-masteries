extends SceneTree
func _initialize() -> void:
	await process_frame
	var w := get_root().get_node("Words")
	var t0 := Time.get_ticks_msec()
	var r: Array[String] = w.words_from_letters("etaoinshrdlucmpgwf", 3, false)
	var t1 := Time.get_ticks_msec()
	print("words_from_letters: ", r.size(), " results in ", t1 - t0, " ms")
	quit()
