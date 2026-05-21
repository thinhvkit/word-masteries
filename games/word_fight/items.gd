class_name WFItems
## Word Fight — item catalog. Items are bought with gold in the shop and
## equipped (max GameState.EQUIP_SLOTS) for passive battle effects.
##
## Effect keys read by word_fight.gd:
##   dmg_mult        — multiplies final word damage          (multiplicative)
##   fire_bonus_mult — multiplies Fire-gem bonus damage       (multiplicative)
##   dmg_taken_mult  — multiplies incoming damage             (multiplicative)
##   gold_mult       — multiplies gold rewards                (multiplicative)
##   max_hp_bonus    — flat max-HP increase                   (additive)
##   start_rainbow   — rainbow charges granted at battle start(additive)
##   heal_per_turn   — HP restored at the start of each turn  (additive)
##   gem_rate_bonus  — added gem spawn probability            (additive)
##   poison_immune   — ignores Poisoned-tile self damage      (flag)

const CATALOG := [
	{"id": "oak_wand",        "name": "Oak Wand",        "type": "weapon",
		"cost": 120, "desc": "+10% word damage",                 "effect": {"dmg_mult": 1.10}},
	{"id": "ember_blade",     "name": "Ember Blade",     "type": "weapon",
		"cost": 200, "desc": "Fire gems deal +50% bonus damage",  "effect": {"fire_bonus_mult": 1.5}},
	{"id": "scholars_tome",   "name": "Scholar's Tome",  "type": "weapon",
		"cost": 180, "desc": "Start each battle with 1 rainbow",  "effect": {"start_rainbow": 1}},
	{"id": "leather_vest",    "name": "Leather Vest",    "type": "armor",
		"cost": 120, "desc": "+1200 max HP",                      "effect": {"max_hp_bonus": 1200}},
	{"id": "iron_aegis",      "name": "Iron Aegis",      "type": "armor",
		"cost": 240, "desc": "-20% damage taken",                 "effect": {"dmg_taken_mult": 0.8}},
	{"id": "sage_cloak",      "name": "Sage Cloak",      "type": "armor",
		"cost": 200, "desc": "Immune to poisoned tiles",          "effect": {"poison_immune": true}},
	{"id": "lucky_charm",     "name": "Lucky Charm",     "type": "charm",
		"cost": 150, "desc": "+50% gold earned",                  "effect": {"gold_mult": 1.5}},
	{"id": "healing_pendant", "name": "Healing Pendant", "type": "charm",
		"cost": 240, "desc": "Heal 160 HP at the start of a turn","effect": {"heal_per_turn": 160}},
	{"id": "gem_magnet",      "name": "Gem Magnet",      "type": "charm",
		"cost": 160, "desc": "+5% gem spawn rate",                "effect": {"gem_rate_bonus": 0.05}},
]

static func all() -> Array:
	return CATALOG

static func by_id(id: String) -> Dictionary:
	for it in CATALOG:
		if it.id == id:
			return it
	return {}

## Sum of an additive effect key across all equipped items.
static func sum_effect(key: String) -> float:
	var total := 0.0
	for id in GameState.equipped_items:
		var it := by_id(id)
		if it.has("effect") and it.effect.has(key):
			total += float(it.effect[key])
	return total

## Product of a multiplicative effect key across all equipped items (1.0 if none).
static func mult_effect(key: String) -> float:
	var m := 1.0
	for id in GameState.equipped_items:
		var it := by_id(id)
		if it.has("effect") and it.effect.has(key):
			m *= float(it.effect[key])
	return m

## True if any equipped item carries a truthy flag for `key`.
static func has_effect(key: String) -> bool:
	for id in GameState.equipped_items:
		var it := by_id(id)
		if it.has("effect") and bool(it.effect.get(key, false)):
			return true
	return false
