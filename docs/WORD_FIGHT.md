# Word Fight — Design Reference

Turn-based word-battler on a 5×5 letter board. Spell dictionary words to damage
the enemy; the enemy spells words back and sabotages your board. Special gem
tiles, enemy abilities, items, and a story-world map give battles depth and
long-term stakes.

This document reflects the **current implemented state** of the game.

---

## Battle basics

- **Board:** 5×5 tiles. Tap letters to chain a word (min 3 letters), Submit to
  attack. Tiles are consumed and refilled after each word.
- **Turns:** player and enemy alternate. Each side spells one word per turn.
- **Win/lose:** reduce the enemy's HP to 0 to win; if your HP hits 0 you lose.
- **Battle length:** tuned so a typical battle lasts **~20-30 of the player's
  words** — a real back-and-forth duel.

### Damage formula

Base damage scales **quadratically** with word length:

```
base = length² × 8
```

| Length | 3 | 4 | 5 | 6 | 7 |
|--------|---|---|---|---|---|
| Base   | 72 | 128 | 200 | 288 | 392 |

Final word damage:

```
(base + fire_bonus + diamond_bonus)
  × topic(×2)  × gold_mult  × rainbow(×2)  × item dmg_mult
```

- **Topic bonus:** a word matching the battle's topic deals ×2.
- **Rainbow:** 3 consecutive 5+ letter words earn a rainbow charge (max 3);
  arming one makes the next word deal ×2. 
- The live preview under the word pill shows the computed damage.

---

## Gem tiles (special tiles)

~15% of tiles spawn as a gem (`GEM_SPAWN_CHANCE = 0.15`, plus any `gem_rate_bonus`
from items). Spawn weighting: Fire 22 / Healing 20 / Poison 18 / Ice 16 /
Gold 16 / Diamond 8.

Every gem type has a distinct **fill color**, a **type emblem** (drawn bottom-
left), and an **idle animation**. Normal tiles all share one uniform warm-cream
color so gems stand out.

| Gem | Color | Emblem / animation | Effect when used in a word |
|-----|-------|--------------------|----------------------------|
| Fire | red | flame + rising embers | +40 damage each. Carries a 3-turn fuse; if left unused it burns away and deals **180** self-damage |
| Ice | blue | snowflake + frost glints | ≥1 used → enemy **frozen**, skips its next turn |
| Gold | yellow | sparkle + glint sweep | damage ×(1 + gold_count): 1 gold ×2, 2 ×3 |
| Poison | green | droplet + rising bubbles | enemy gains **3 poison stacks** each (damage-over-time) |
| Diamond | cyan | cut-gem + shimmer/twinkle | **+150** damage each |
| Healing | purple | heart + pulsing halo | restores **350** HP each (capped at max HP) |

Fire fuses tick down at the start of each player turn.

---

## Enemy hazards

Enemies inflict hazards on your tiles (see Enemy abilities below). A hazard is
drawn over the tile's normal/gem fill.

| Hazard | Behavior |
|--------|----------|
| Burning | 3-turn fuse; on expiry deals **160** self-damage and clears. Using the tile in a word clears it harmlessly |
| Locked | unselectable for 2 turns, then thaws |
| Stone | permanent, unselectable, never consumed. Capped at 3 tiles to avoid soft-locks |
| Poisoned | selectable, but each poisoned tile used in a word deals **90** self-damage; reverts to normal after use |

The green **Poison gem** (helps you) and the green **Poisoned hazard** (hurts
you) are visually distinct — a bright jewel vs. a murky, blotched tile.

---

## Combatant statuses & enemy abilities

Tracked statuses: `_enemy_frozen`, `_enemy_poison` (stacks), `_leech_turns`.

- **Poison:** at the start of the enemy turn it takes `stacks × 26`; stacks then
  decay by 1.
- **Leech:** at the start of each player turn, the player loses **150 HP** and
  the enemy heals 150; lasts 3 turns.
- **Frozen:** the enemy's whole turn is skipped, then the flag clears.

Each enemy has an `abilities` list. On its turn it attacks with a word and,
with chance `0.3 + skill × 0.3`, also triggers one random ability (with a
banner + FX):

| Ability | Effect |
|---------|--------|
| Scramble | shuffles the letters of all non-Stone/non-Locked tiles |
| Burn | turns up to 3 plain tiles into Burning hazards |
| Lock | locks up to 2 tiles |
| Stone | turns 1 tile to Stone (skipped if 3 already exist) |
| Poison tiles | turns up to 3 tiles into Poisoned hazards |
| Leech | applies Leech for 3 turns |

Small status lines under each avatar show Frozen / Poison ×N / Leeched ×N.

---

## Meta-progression

### Lex (the player)

- **Max HP:** `6000 + (level − 1) × 300`, plus any item `max_hp_bonus`.
- **Leveling:** XP to next level is `level × 200`. Winning a battle grants
  `140 + tier × 55` XP (tier = world_idx × 4 + enemy_idx, 0-15).
- **Gold:** winning grants ≈ `(40 + tier × 25) × gold_mult` gold.
- All progression (level, XP, gold, owned/equipped items, world progress) is
  persisted in the save file.

### Items (shop)

Bought with gold, equipped up to **3 at once** for passive battle effects.

| Item | Type | Cost | Effect |
|------|------|------|--------|
| Oak Wand | weapon | 120 | +10% word damage |
| Ember Blade | weapon | 200 | Fire gems deal +50% bonus |
| Scholar's Tome | weapon | 180 | start each battle with 1 rainbow |
| Leather Vest | armor | 120 | +1200 max HP |
| Iron Aegis | armor | 240 | −20% damage taken |
| Sage Cloak | armor | 200 | immune to Poisoned-tile self damage |
| Lucky Charm | charm | 150 | +50% gold earned |
| Healing Pendant | charm | 240 | heal 160 HP at the start of each turn |
| Gem Magnet | charm | 160 | +5% gem spawn rate |

### Story worlds

4 themed worlds × 4 enemies (reusing the 4 avatars). Clearing a world's last
enemy unlocks the next world. Enemy HP ramps gently so battle length stays in
the 20-30 band as difficulty rises via skill + abilities.

| World | Topics | Enemies (HP) |
|-------|--------|--------------|
| Whispering Woods | food, animal | Wriggles Jr. 4800 · Spelluga 5100 · Verbosaur 5400 · Lexigon 5700 |
| Mount Olympus | shape, color | Hydra Hatchling 5900 · Medusa Quill 6100 · Minotaur Maw 6300 · Sphinx of Riddles 6500 |
| Arabian Nights | food, color | Sand Serpent 6600 · Lamp Wraith 6750 · Roc of the Dunes 6900 · Vizier of Verses 7050 |
| Transylvania | animal, shape | Crypt Crawler 7150 · Quill Bat 7250 · Frankenword 7350 · Count Lexula 7400 |

---

## Screen flow

```
Main Menu → World Map → Intro → Battle → Victory / Defeat → World Map
                  └──────── Shop ────────┘
```

## Source files

| File | Role |
|------|------|
| `games/word_fight/word_fight.gd` | battle controller — turns, damage, gems, hazards, abilities, statuses |
| `games/word_fight/tile_node.gd` | `WFTile` — tile drawing, gem emblems & animations, hazard decorations |
| `games/word_fight/fx.gd` | FX library — colors, popups, banners, particles |
| `games/word_fight/worlds.gd` | world + enemy roster data |
| `games/word_fight/items.gd` | item catalog + equipped-effect aggregation |
| `games/word_fight/topics.gd` | topic→word membership for the ×2 bonus |
| `games/word_fight/intro.gd` | pre-battle screen |
| `games/word_fight/victory.gd` / `defeat.gd` | results screens, reward payout |
| `games/word_fight/world_map.gd` / `shop.gd` | meta-progression screens |
| `autoload/game_state.gd` | persisted state — Lex level/XP/HP, gold, items, world progress |

## Tuning

All combat constants are centralized at the top of `word_fight.gd`
(`DMG_LEN_MULT`, gem bonuses, hazard damage, etc.); enemy HP lives in
`worlds.gd`; player HP scaling in `game_state.gd` (`lex_max_hp`). Battle length
targets a typical ~4-5 letter player — adjust these to retune.
