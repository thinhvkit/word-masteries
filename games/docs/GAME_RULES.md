# Masteries — Game Rules

This file is the source of truth for every game's rules and scoring. Mechanics here mirror the live code under `games/<game_id>/`.

**Global modifier:** the chosen difficulty mode multiplies every game's base XP via `GameState.add_xp(...)`:
- **Intermediate** — ×1.0
- **Advanced** — ×2.0

Minimum word length across word games: **3**.

---

## 1. Word Fight

Turn-based battle on a 5×5 letter board. The player and an AI enemy alternate; each forms a word from board tiles to deal damage.

**Setup**
- Player HP: **200**.
- Enemies (round order, HP, AI skill):
  1. Wriggles Jr. — HP 80, skill 0.4
  2. Spelluga — HP 120, skill 0.6
  3. Verbosaur — HP 160, skill 0.8
  4. Lexigon — HP 220, skill 1.0
- A **topic** is drawn for the battle (food, animals, weather, etc.). Topic words deal bonus damage.

**Forming a word**
- Tap board tiles in order to build a word (any 8-directional path; same tile cannot appear twice in one chain).
- Word must be ≥ 3 letters and present in the dictionary.
- Each consumed tile is replaced from the top with a new letter; the board always has ≥ 4 vowels.

**Damage**
- Base damage = `word_length × 10`.
- **Topic match**: ×2 damage and ×2 XP.
- **Rainbow boost**: while armed, the next submitted word deals an additional ×2 damage. Armed via the Rainbow button when you have a charge.

**Rainbow charges**
- Form 4 consecutive ≥ 5-letter words to earn one Rainbow charge (max 3 stored). Breaking the streak with a < 5-letter word resets the counter.

**XP**
- Per word: `word_length × 10 + 5 × streak`. Topic-match doubles the result. Mode multiplier applied last.
- Defeating an enemy awards a flat **+100 XP** bonus.

**End states**
- Enemy HP → 0: Victory screen, advance to next enemy.
- Player HP → 0: Defeat screen.

---

## 2. Word Match

Drag across a ring of 6–8 letters to form words against a 2-minute timer.

**Setup**
- Round time: **120 seconds**.
- A curated letter pool is picked based on difficulty mode (Intermediate: 6–7 letters; Advanced: 7–8 letters). Vowel guarantee: ≥ 2 vowels visible.

**Forming a word**
- Drag (or touch-drag) across letter circles. Lift to submit.
- Minimum length: **3**. The same letter circle can be reused **non-consecutively** in the same chain.
- A word can only be scored once per round (duplicates silently fail).

**Scoring**
- Base XP = `word_length × 10` (mode multiplier applied via `GameState.add_xp`).
- Lift on too short / not-a-word / already-found → shake feedback, no score.

**End state**
- Timer hits 0 → results screen with score, found words, and top missed words by length.

---

## 3. Word Found

Wave-based puzzle. Form valid words from a fixed letter pool to fill each wave's length-target pips.

**Setup**
- Per wave a curated 7–9 letter anchor word seeds Row 1 (e.g., `STREAMING`, `PAINTERS`, `REACTIONS`).
- Each tile sits in Row 1 (AVAILABLE). Tap to move it into Row 2 (MOVED); tap again to send it back.
- A **Targets card** lists how many words of each length the wave needs (e.g., 2× 3-letter, 1× 4-letter).
- Hard cap: 40 waves.

**Forming a word**
- Build a word in Row 2 by tapping Row 1 tiles. Min length **3**.
- Submit checks the dictionary:
  - **Valid + new this wave** → score, tiles return to AVAILABLE (letters are infinitely reusable).
  - **Already submitted this wave** OR **not a word** → shake feedback, no score.

**Scoring**
- Base XP = `word_length × 10`.
- **Target match** (length equals a still-needed target): fills one pip on that target row.
- **Bonus word** (length > the longest target on this wave): base × **1.5**. Logged as a bonus but doesn't fill a pip.
- Mode multiplier applied via `GameState.add_xp`.

**Difficulty templates by wave tier**
| Waves | Tier | Intermediate | Advanced |
|---|---|---|---|
| 1–5 | Easy | 2×3, 1×4 | 2×4, 1×5 |
| 6–15 | Medium | 3×3, 2×4 | 3×4, 2×5 |
| 16+ | Hard | 4×3, 2×4, 1×5 | 3×4, 3×5, 1×6 |

**Wave end**
- All pips filled → "WAVE N!" banner + fireworks → next wave with fresh letters.
- No fail state: the pool is pre-validated to contain enough valid words for every target length, and each unique word counts once.

---

## 4. Word Type

Given a base word, type up to 4 derived forms (inflections / derivations) within the time you spend.

**Setup**
- One random entry from the curated bank (e.g., `Careful` → adverb/adjective/noun forms).
- 4 input slots.

**Scoring**
- **+20 XP per recognized form** matched against the entry's accepted forms.
- Mode multiplier applied.

**End state**
- Submit reveals every accepted form with type + example sentences; awards XP for the recognized ones.

---

## 5. Describe Picture

Complete sentence stems describing a placeholder scene.

**Setup**
- One scene drawn from the bank; each scene has 4 stems (e.g., "She is …", "She wears …").
- 4 input fields.

**Scoring (per field)**
- Let `n` = character count of the answer (trimmed).
- `pts = min(25, round(n × 2 + (5 if n > 12 else 0)))`
- "OK" threshold: `pts ≥ 15`.
- Max per scene: **100** (4 × 25). Sum is sent to `GameState.add_xp`.

**End state**
- Results screen shows your sentence, your score, the max, and a sample answer per stem.

---

## 6. Story Tell

Fill blanks in a short story; longer / more grammatical answers score higher.

**Setup**
- One story drawn from the bank with N blanks.

**Scoring (per blank, slot index `i` starting at 0)**
- `max_pts = 30 + i × 5` (later blanks are worth more)
- Let `n` = character count of the answer.
- `pts = min(max_pts, round(n × 2.5 + (10 if n > 15 else 0)))`
- "Good" threshold: `pts ≥ 0.7 × max_pts`.

**End state**
- Results screen shows each answer, its score, and a sample. Total XP sent to `GameState.add_xp`.

---

## 7. Listen & Dictate

Hear a word, type it correctly. Replays cost points.

**Setup**
- One word from the curated bank (with definition + IPA stored for results).
- Player can press "Play" repeatedly; each replay is counted.

**Scoring**
- Let `len` = word length, `r` = replays used.
- `base = len × 10` if typed correctly, else `round(len × 3.0)`.
- `penalty = r × 10`.
- `earned = max(0, base − penalty)`.
- Mode multiplier applied via `GameState.add_xp`.

**End state**
- Results screen shows correct/incorrect, your spelling vs. truth, accuracy %, replay count, and XP.

---

## Cross-cutting

- **XP persistence**: `GameState.add_xp(game_id, base)` adds `round(base × mode_multiplier)` to both the per-game total and overall `total_xp`. Saved to `user://masteries.save`.
- **Player avatar**: chosen on login, persisted in `GameState.player_avatar`. Shown in main menu greeting, Word Fight HUD/intro, and any future avatar-using surface.
- **Mode switch**: changes only the multiplier and the per-game difficulty templates that read `GameState.mode` (currently Word Match pool sizes and Word Found target templates).
