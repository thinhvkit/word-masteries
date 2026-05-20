extends Node
## Global session state — player name, difficulty mode, score totals.

signal mode_changed(mode: String)
signal score_added(game: String, amount: int)

enum Mode { INTERMEDIATE, ADVANCED }

const SAVE_PATH := "user://masteries.save"

var player_name: String = ""
var player_avatar: String = "butterfly"   # id under res://assets/avatars/<id>.svg
var mode: int = Mode.INTERMEDIATE
var total_xp: int = 0
var per_game_xp: Dictionary = {}  # game_id -> int

# Transient cross-scene state for Word Fight intro/game/results flow.
# Not persisted. Populated by intro/game, read by victory/defeat.
var wf_session: Dictionary = {
	"enemy_idx": 0,           # which enemy is up next
	"enemy_name": "",
	"enemy_max_hp": 0,
	"enemy_hp_left": 0,       # at end of battle (0 if defeated)
	"player_hp_left": 0,
	"topic": "",
	"damage_dealt": 0,
	"words_used": 0,
	"longest_word": "",
	"topic_matches": 0,
	"rainbows_used": 0,
	"score_earned": 0,
}

# Word Match: pool + found/possible words, score, time used.
var wm_session: Dictionary = {
	"pool": "",
	"found_words": [] as Array,        # in order found
	"possible_count": 0,               # total formable from pool
	"missed_top": [] as Array,         # top-N missed by length
	"score": 0,
	"time_used": 0.0,
}

func mode_name() -> String:
	return "Intermediate" if mode == Mode.INTERMEDIATE else "Advanced"

func mode_multiplier() -> float:
	# GDD scoring: Easy ×1.0 | Hard ×2.0
	return 1.0 if mode == Mode.INTERMEDIATE else 2.0

func set_mode(m: int) -> void:
	mode = m
	mode_changed.emit(mode_name())
	save()

func add_xp(game_id: String, base_amount: int) -> int:
	var amt := int(round(base_amount * mode_multiplier()))
	total_xp += amt
	per_game_xp[game_id] = per_game_xp.get(game_id, 0) + amt
	score_added.emit(game_id, amt)
	save()
	return amt

func save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return
	var data := {
		"player_name": player_name,
		"player_avatar": player_avatar,
		"mode": mode,
		"total_xp": total_xp,
		"per_game_xp": per_game_xp,
	}
	f.store_string(JSON.stringify(data))

func load_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	player_name = parsed.get("player_name", "")
	player_avatar = parsed.get("player_avatar", "butterfly")
	mode = parsed.get("mode", Mode.INTERMEDIATE)
	total_xp = parsed.get("total_xp", 0)
	per_game_xp = parsed.get("per_game_xp", {})

func _ready() -> void:
	load_save()
