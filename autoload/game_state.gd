extends Node
## Global session state — player name, avatar, score totals.

signal score_added(game: String, amount: int)

const SAVE_PATH := "user://masteries.save"

var player_name: String = ""
var player_avatar: String = "butterfly"   # id under res://assets/avatars/<id>.svg
var total_xp: int = 0
var per_game_xp: Dictionary = {}  # game_id -> int
var sound_on: bool = true
var wm_high_score: int = 0

# --- Word Fight meta-progression (persisted) ---
var lex_level: int = 1
var lex_xp: int = 0                          # xp toward the next level
var gold: int = 0                            # currency spent in the shop
var owned_items: Array = []                  # item ids the player owns
var equipped_items: Array = []               # item ids equipped (max 3)
var wf_world_idx: int = 0                    # last-visited world on the map
var wf_world_progress: Array = [0, 0, 0, 0]  # enemies cleared per world

const EQUIP_SLOTS := 3

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

# Word Found: persisted so the player can resume mid-wave.
var wfound_save: Dictionary = {}

# Word Match: pool + found/possible words, score, time used.
var wm_session: Dictionary = {
	"pool": "",
	"found_words": [] as Array,        # in order found
	"possible_count": 0,               # total formable from pool
	"missed_top": [] as Array,         # top-N missed by length
	"score": 0,
	"time_used": 0.0,
}

func add_xp(game_id: String, base_amount: int) -> int:
	var amt := maxi(0, base_amount)
	total_xp += amt
	per_game_xp[game_id] = per_game_xp.get(game_id, 0) + amt
	score_added.emit(game_id, amt)
	save()
	return amt

func record_word_match_score(score: int) -> Dictionary:
	var previous := wm_high_score
	var clean_score := maxi(0, score)
	var is_new := clean_score > wm_high_score
	if is_new:
		wm_high_score = clean_score
		save()
	return {
		"previous_high_score": previous,
		"high_score": wm_high_score,
		"is_new_high_score": is_new,
	}

# --- Word Fight meta-progression helpers ---

## XP required to advance from the current level to the next.
func lex_xp_to_next() -> int:
	return lex_level * 200

## Lex's max HP, scaling +300 per level above 1.
func lex_max_hp() -> int:
	return 6000 + (lex_level - 1) * 300

## Adds level XP, rolling over level-ups. Returns the number of levels gained.
func add_lex_xp(amount: int) -> int:
	lex_xp += maxi(0, amount)
	var gained := 0
	while lex_xp >= lex_xp_to_next():
		lex_xp -= lex_xp_to_next()
		lex_level += 1
		gained += 1
	save()
	return gained

func add_gold(amount: int) -> void:
	gold = maxi(0, gold + amount)
	save()

## Spends gold if affordable. Returns true on success.
func spend_gold(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	save()
	return true

## Records that `enemy_idx` in `world_idx` was cleared (keeps the furthest reached).
func mark_enemy_cleared(world_idx: int, enemy_idx: int) -> void:
	if world_idx < 0 or world_idx >= wf_world_progress.size():
		return
	wf_world_progress[world_idx] = maxi(int(wf_world_progress[world_idx]), enemy_idx + 1)
	save()

func save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return
	var data := {
		"player_name": player_name,
		"player_avatar": player_avatar,
		"total_xp": total_xp,
		"per_game_xp": per_game_xp,
		"lex_level": lex_level,
		"lex_xp": lex_xp,
		"gold": gold,
		"owned_items": owned_items,
		"equipped_items": equipped_items,
		"wf_world_idx": wf_world_idx,
		"wf_world_progress": wf_world_progress,
		"sound_on": sound_on,
		"wm_high_score": wm_high_score,
		"wfound_save": wfound_save,
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
	total_xp = parsed.get("total_xp", 0)
	per_game_xp = parsed.get("per_game_xp", {})
	lex_level = maxi(1, int(parsed.get("lex_level", 1)))
	lex_xp = int(parsed.get("lex_xp", 0))
	gold = int(parsed.get("gold", 0))
	owned_items = parsed.get("owned_items", [])
	equipped_items = parsed.get("equipped_items", [])
	wf_world_idx = int(parsed.get("wf_world_idx", 0))
	wm_high_score = int(parsed.get("wm_high_score", 0))
	# JSON numbers round-trip as floats — coerce the progress array back to ints.
	var prog: Variant = parsed.get("wf_world_progress", [0, 0, 0, 0])
	if prog is Array and (prog as Array).size() == 4:
		wf_world_progress = [int(prog[0]), int(prog[1]), int(prog[2]), int(prog[3])]
	sound_on = parsed.get("sound_on", true)
	wfound_save = parsed.get("wfound_save", {})
	_apply_sound()

func _apply_sound() -> void:
	Audio.set_sfx_enabled(sound_on)
	Audio.set_music_enabled(sound_on)

func toggle_sound() -> void:
	sound_on = not sound_on
	_apply_sound()
	save()

func _ready() -> void:
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
	load_save()
