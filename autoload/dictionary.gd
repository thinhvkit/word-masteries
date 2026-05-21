extends Node
## Local English dictionary. Loads a newline-delimited word list at startup.
## Designed to be hot-swappable: drop in SCOWL/WordNet/Words at the same path
## (res://data/words.txt) — no code changes needed.

const WORDS_PATH := "res://data/words.txt"

var _words: Dictionary = {}      # word(lower) -> true, used as a hash set for O(1) is_valid
# Parallel per-length signature buckets (built once at load):
var _by_length_words: Array = []     # _by_length_words[n] -> PackedStringArray
var _by_length_masks: Array = []     # _by_length_masks[n] -> PackedInt32Array (26-bit letter present mask)
var _by_length_counts: Array = []    # _by_length_counts[n] -> PackedByteArray (flat, stride 26)

func _ready() -> void:
	_load_words()

func _load_words() -> void:
	if not FileAccess.file_exists(WORDS_PATH):
		push_warning("Dictionary: words.txt missing at %s" % WORDS_PATH)
		return
	var f := FileAccess.open(WORDS_PATH, FileAccess.READ)
	while not f.eof_reached():
		var line := f.get_line().strip_edges().to_lower()
		if line.is_empty() or line.begins_with("#"):
			continue
		_words[line] = true
		var n := line.length()
		while _by_length_words.size() <= n:
			_by_length_words.append(PackedStringArray())
			_by_length_masks.append(PackedInt32Array())
			_by_length_counts.append(PackedByteArray())
		var mask := 0
		var counts := PackedByteArray()
		counts.resize(26)
		var ok := true
		for i in n:
			var code := line.unicode_at(i) - 97
			if code < 0 or code >= 26:
				ok = false
				break
			mask |= 1 << code
			counts[code] += 1
		if not ok:
			continue
		var ws: PackedStringArray = _by_length_words[n]
		ws.append(line)
		_by_length_words[n] = ws
		var ms: PackedInt32Array = _by_length_masks[n]
		ms.append(mask)
		_by_length_masks[n] = ms
		var dst: PackedByteArray = _by_length_counts[n]
		dst.append_array(counts)
		_by_length_counts[n] = dst
	print("Dictionary loaded: %d words" % _words.size())

func is_valid(word: String) -> bool:
	var w := word.strip_edges().to_lower()
	if _words.has(w):
		return true
	return _morph_valid(w)

## True if `word` is a standard inflected form of a base dictionary word.
## The bundled list (macOS web2) is a 1934 headword list with no plurals,
## tenses or adverbs, so we accept a word when stripping a common English
## suffix (-s, -es, -ies, -ed, -ied, -ing, -ly, -ily, -er, -est, ...) yields
## a valid base word.
func _morph_valid(word: String) -> bool:
	var n := word.length()
	# Plurals / 3rd-person: -ies -> y, -es, -s
	if n >= 5 and word.ends_with("ies"):
		if _words.has(word.substr(0, n - 3) + "y"):   # parties -> party
			return true
	if n >= 4 and word.ends_with("es"):
		if _words.has(word.substr(0, n - 2)):         # boxes -> box, goes -> go
			return true
	if n >= 4 and word.ends_with("s") and not word.ends_with("ss"):
		if _words.has(word.substr(0, n - 1)):         # cats -> cat, likes -> like
			return true
	# Past tense: -ied -> y, -ed
	if n >= 5 and word.ends_with("ied"):
		if _words.has(word.substr(0, n - 3) + "y"):   # tried -> try
			return true
	if n >= 5 and word.ends_with("ed"):
		var stem := word.substr(0, n - 2)
		# walked -> walk ; liked -> like (restore e) ; stopped -> stop (un-double)
		if _words.has(stem) or _words.has(stem + "e") or _undoubled_valid(stem):
			return true
	# Continuous: -ing
	if n >= 6 and word.ends_with("ing"):
		var stem := word.substr(0, n - 3)
		# walking -> walk ; liking -> like ; running -> run
		if _words.has(stem) or _words.has(stem + "e") or _undoubled_valid(stem):
			return true
	# Adverbs: -ily -> y, -ly
	if n >= 5 and word.ends_with("ily"):
		if _words.has(word.substr(0, n - 3) + "y"):   # easily -> easy
			return true
	if n >= 5 and word.ends_with("ly"):
		if _words.has(word.substr(0, n - 2)):         # slowly -> slow
			return true
	# Comparatives / superlatives: -iest -> y, -est, -ier -> y, -er
	if n >= 6 and word.ends_with("iest"):
		if _words.has(word.substr(0, n - 4) + "y"):   # happiest -> happy
			return true
	if n >= 6 and word.ends_with("est"):
		var stem := word.substr(0, n - 3)
		if _words.has(stem) or _words.has(stem + "e") or _undoubled_valid(stem):
			return true
	if n >= 5 and word.ends_with("ier"):
		if _words.has(word.substr(0, n - 3) + "y"):   # happier -> happy
			return true
	if n >= 5 and word.ends_with("er"):
		var stem := word.substr(0, n - 2)
		if _words.has(stem) or _words.has(stem + "e") or _undoubled_valid(stem):
			return true
	return false

## True if `stem` ends in a doubled consonant and dropping one yields a valid
## word (stopp -> stop, runn -> run, bigg -> big).
func _undoubled_valid(stem: String) -> bool:
	var n := stem.length()
	if n < 3:
		return false
	var last := stem[n - 1]
	if last == stem[n - 2] and "aeiou".find(last) == -1:
		return _words.has(stem.substr(0, n - 1))
	return false

func size() -> int:
	return _words.size()

## Returns all dictionary words that can be formed by picking letters from
## `letters` (each occurrence consumed once unless `allow_reuse`).
func words_from_letters(letters: String, min_len: int = 3, allow_reuse: bool = false, max_len: int = -1) -> Array[String]:
	var out: Array[String] = []
	var board_counts := PackedByteArray()
	board_counts.resize(26)
	var board_mask := 0
	var letters_len := letters.length()
	for i in letters_len:
		var code := letters.unicode_at(i)
		if code >= 65 and code <= 90:
			code += 32  # to lowercase
		code -= 97
		if code >= 0 and code < 26:
			board_counts[code] += 1
			board_mask |= 1 << code
	var inv_mask := ~board_mask
	var effective_max: int = max_len if max_len > 0 else (letters_len if not allow_reuse else _by_length_words.size() - 1)
	for n in range(min_len, effective_max + 1):
		if n >= _by_length_words.size():
			break
		var words: PackedStringArray = _by_length_words[n]
		var masks: PackedInt32Array = _by_length_masks[n]
		var counts: PackedByteArray = _by_length_counts[n]
		var count_size := words.size()
		for wi in count_size:
			if (masks[wi] & inv_mask) != 0:
				continue
			if allow_reuse:
				out.append(words[wi])
				continue
			var base := wi * 26
			var fits := true
			for c in 26:
				if counts[base + c] > board_counts[c]:
					fits = false
					break
			if fits:
				out.append(words[wi])
	return out
