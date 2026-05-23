class_name WFWorlds
## Word Fight — story worlds. Each world is a themed run of 4 enemies with
## scaling HP, widening ability sets, and a themed topic pool.
## Reuses the 4 existing avatars (wriggles_jr / spelluga / verbosaur / lexigon).
##
## Ability ids: "scramble", "burn", "lock", "stone", "poison", "leech".

const WORLDS := [
	{
		"name": "Whispering Woods",
		"subtitle": "Where Lex first learned to spell.",
		"topics": ["food", "animal", "nature", "noun"],
		"enemies": [
			{"name": "Wriggles Jr.", "avatar": "wriggles_jr", "hp": 4800, "skill": 0.55, "abilities": []},
			{"name": "Spelluga",      "avatar": "spelluga",    "hp": 5100, "skill": 0.66, "abilities": ["scramble"]},
			{"name": "Verbosaur",     "avatar": "verbosaur",   "hp": 5400, "skill": 0.78, "abilities": ["scramble", "burn"]},
			{"name": "Lexigon",       "avatar": "lexigon",     "hp": 5700, "skill": 0.90, "abilities": ["burn", "poison"]},
		],
	},
	{
		"name": "Mount Olympus",
		"subtitle": "Greek myths guard the longest words.",
		"topics": ["shape", "color", "body", "adjective"],
		"enemies": [
			{"name": "Hydra Hatchling",  "avatar": "wriggles_jr", "hp": 5900, "skill": 0.62, "abilities": ["scramble"]},
			{"name": "Medusa Quill",     "avatar": "spelluga",    "hp": 6100, "skill": 0.74, "abilities": ["scramble", "lock"]},
			{"name": "Minotaur Maw",     "avatar": "verbosaur",   "hp": 6300, "skill": 0.85, "abilities": ["burn", "lock"]},
			{"name": "Sphinx of Riddles","avatar": "lexigon",     "hp": 6500, "skill": 0.95, "abilities": ["lock", "poison", "scramble"]},
		],
	},
	{
		"name": "Arabian Nights",
		"subtitle": "A thousand tales, a thousand traps.",
		"topics": ["clothing", "home", "weather", "verb"],
		"enemies": [
			{"name": "Sand Serpent",    "avatar": "wriggles_jr", "hp": 6600, "skill": 0.68, "abilities": ["burn", "scramble"]},
			{"name": "Lamp Wraith",     "avatar": "spelluga",    "hp": 6750, "skill": 0.80, "abilities": ["lock", "poison"]},
			{"name": "Roc of the Dunes","avatar": "verbosaur",   "hp": 6900, "skill": 0.90, "abilities": ["burn", "stone"]},
			{"name": "Vizier of Verses","avatar": "lexigon",     "hp": 7050, "skill": 1.00, "abilities": ["lock", "poison", "leech"]},
		],
	},
	{
		"name": "Transylvania",
		"subtitle": "The final word waits in the dark.",
		"topics": ["animal", "sport", "verb", "adjective"],
		"enemies": [
			{"name": "Crypt Crawler", "avatar": "wriggles_jr", "hp": 7150, "skill": 0.75, "abilities": ["poison", "scramble", "burn"]},
			{"name": "Quill Bat",     "avatar": "spelluga",    "hp": 7250, "skill": 0.86, "abilities": ["lock", "burn", "leech"]},
			{"name": "Frankenword",   "avatar": "verbosaur",   "hp": 7350, "skill": 0.94, "abilities": ["stone", "lock", "poison"]},
			{"name": "Count Lexula",  "avatar": "lexigon",     "hp": 7400, "skill": 1.00, "abilities": ["scramble", "burn", "lock", "stone", "poison", "leech"]},
		],
	},
]

const ENEMIES_PER_WORLD := 4

static func world_count() -> int:
	return WORLDS.size()

static func world(world_idx: int) -> Dictionary:
	return WORLDS[clampi(world_idx, 0, WORLDS.size() - 1)]

static func enemies_in(world_idx: int) -> Array:
	return world(world_idx).enemies

static func enemy(world_idx: int, enemy_idx: int) -> Dictionary:
	var list: Array = enemies_in(world_idx)
	return list[clampi(enemy_idx, 0, list.size() - 1)]

## Picks a random topic from the world's themed pool.
static func random_topic(world_idx: int) -> String:
	var topics: Array = world(world_idx).topics
	if topics.is_empty():
		return "food"
	return topics[randi() % topics.size()]

## True if `world_idx` is unlocked — world 0 is always open; later worlds need
## the previous world fully cleared.
static func is_world_unlocked(world_idx: int, progress: Array) -> bool:
	if world_idx <= 0:
		return true
	if world_idx - 1 >= progress.size():
		return false
	return int(progress[world_idx - 1]) >= ENEMIES_PER_WORLD

## True if a specific enemy node can be entered (cleared ones replayable, plus
## the next uncleared one).
static func is_enemy_unlocked(world_idx: int, enemy_idx: int, progress: Array) -> bool:
	if not is_world_unlocked(world_idx, progress):
		return false
	var cleared: int = int(progress[world_idx]) if world_idx < progress.size() else 0
	return enemy_idx <= cleared
