extends SceneTree

func _initialize() -> void:
	var Dict := load("res://autoload/dictionary.gd")
	var d: Node = Dict.new()
	d._ready()
	# Realistic-ish board letters (25 tiles, common-letter biased).
	# Realistic 25-tile board: weighted toward common letters, with duplicates.
	# Avg ~14-16 distinct letters, mirrors Scrabble bag.
	var letters := "EEEAAAIIOONNRRTLSDGUCMBPHF"
	var iters := 5
	var total := 0
	var t0 := Time.get_ticks_usec()
	for i in iters:
		var res: Array = d.words_from_letters(letters, 3, false, 7)
		total = res.size()
	var t1 := Time.get_ticks_usec()
	print("Dict size: ", d.size())
	print("Formable (len 3-7) from '", letters, "': ", total)
	print("Avg query time: ", float(t1 - t0) / iters / 1000.0, " ms")

	for w in ["cat", "swim", "rainbow", "qzxjk", "elephant"]:
		print(" is_valid(", w, ") = ", d.is_valid(w))
	quit()
