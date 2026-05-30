# Word Match — Updated Game Rules v2.0

> **Design goal:** Every 10 seconds should feel different. Players should always have something to chase — a combo, a target word, a bonus tile, a wave clear.

---

## Core Philosophy Changes

| v1 | v2 |
|----|----|
| Single 2-minute timer | Wave-based rounds with time rewards |
| Score by word length only | Multiplier chains + bonus tile system |
| All letters identical | 4 special letter types on the board |
| No goals except "find words" | Target word + secret bonus words each wave |
| Game ends at 0 time | Lives system — game ends on 3 misses |

---

## 1. Letter Tile Types

Each round the 7-letter circle contains a mix of regular and special tiles. Special tiles appear randomly based on wave number.

### Regular tile
Standard letter. Score = `length × 10 XP`.

---

### 🔥 Fire tile (Hot letter)
- Glows orange, animated flicker
- Using it in a word multiplies that word's score **×1.5**
- **Danger:** If you go 30 seconds without using it, it "burns out" — you lose 1 life and it resets to a normal letter
- Appears from: Wave 4+

---

### ⭐ Gold tile (Power letter)
- Glows gold, sparkles
- Using it in a word multiplies that word's score **×2**
- No danger — use any time
- Appears from: Wave 4+

---

### 💎 Diamond tile (Jackpot letter)
- Glows cyan, rotating shine
- Using it in a word multiplies **×3**
- Only appears if player has a combo of 3+ words already active
- Rare — max 1 per round

---

### ☠️ Poison tile (Cursed letter)
- Dark green glow, pulsing
- **Must** be used within 20 seconds or you lose 1 life
- Using it in a word **heals** 1 life if you're below max
- Counts as any vowel (wildcard vowel only)
- Appears from: Wave 4+ (Intermediate) / Wave 2+ (Advanced)

---

### 🌈 Wild tile (Rainbow letter)
- Cycling rainbow animation
- Matches any letter in the alphabet
- Earned via combo ×4 or perfect wave clear — not randomly spawned
- Max 1 held at a time (stored in booster slot)

---

## 2. Combo System

Combos are the heart of the scoring loop. Chain words quickly to multiply everything.

### How combos work

Submit a valid word → combo counter starts. Submit another valid word within the combo window (**6 s** Intermediate / **4 s** Advanced) → combo increases.

| Combo | Multiplier | Visual |
|-------|-----------|--------|
| ×1 | Base | No indicator |
| ×2 | ×1.5 all XP | Orange flame appears |
| ×3 | ×2.0 all XP | Fire grows larger |
| ×4 | ×2.5 all XP | Lightning bolt added |
| ×5+ | ×3.0 all XP | Full FEVER MODE |

**Combo breaks** if:
- 5 seconds pass with no valid word submitted
- An invalid word is submitted (penalty — resets to ×1)
- A life is lost

**Combo bonus on break:**
If combo reaches ×4 or higher before breaking naturally (time out, not invalid word), award a **Combo Bonus** = `combo level × 15 XP`.

---

### FEVER MODE (combo ×5+)

When the player hits combo ×5:
- Background pulses with color
- All XP doubled for the duration
- Timer pauses for **4 seconds** (gift for skillful play)
- Special sound effect + mascot goes wild
- Any word found during Fever = highlighted in the found list with 🔥

FEVER ends when the combo breaks.

---

## 3. Wave System

Replaces the single 2-minute countdown. Each wave has its own mini-goal and time budget.

### Wave structure

```
Wave starts → 40-second timer → meet the goal → wave clear bonus → next wave
                                   ↓ fail
                              lose 1 life, same wave restarts (harder)
```

---

### Wave goals (rotate randomly)

| Goal type | Description | Example |
|-----------|-------------|---------|
| **Word count** | Find N words of any length | Find 5 words |
| **Length target** | Find N words of 4+ letters | Find 3 long words |
| **XP target** | Reach an XP threshold | Earn 150 XP |
| **Speed burst** | Find 3 words in 10 seconds | 3 words fast! |
| **Use the tile** | Use the 🔥 fire tile at least once | Use the hot letter |
| **No mistakes** | Find 4 words without a single invalid attempt | Perfect round |
| **Theme wave** | All found words must match a category | Animal words only |

---

### Wave clear rewards

| Achievement | Bonus |
|-------------|-------|
| Goal met with > 20 s remaining | +30 XP bonus + 5 s carried to next wave |
| Goal met with > 30 s remaining | +60 XP bonus + 10 s carried to next wave |
| Perfect wave (no invalid words) | +50 XP + 1 Wild tile awarded |
| Fever Mode active at wave end | +80 XP bonus |

---

### Wave difficulty scaling

| Waves | Letters | Special tiles | Goal difficulty | Fire tile timer |
|-------|---------|---------------|-----------------|-----------------|
| 1–3 | 7 | None | Easy | — |
| 4–6 | 7 | 1 tile | Normal | 30 s |
| 7–10 | 7 | 1–2 tiles | Medium | 25 s |
| 11–15 | 7 | 2 tiles | Hard | 20 s |
| 16+ | 7 | 2–3 tiles | Very hard | 15 s |

---

## 4. Target Word System

Every wave includes 1 **Target Word** hidden in the letters. Finding it triggers a big reward.

### How it works
- A silhouette of the target word length is shown at the top (e.g. `_ _ _ _ _` for a 5-letter word)
- No letters revealed — player must discover it
- Hint available: tap the silhouette to reveal first letter (costs 20 XP)

### Target word rewards

| Word length | Base reward |
|-------------|-------------|
| 3 letters | +40 XP |
| 4 letters | +80 XP |
| 5 letters | +150 XP |
| 6 letters | +300 XP |
| 7 letters (all tiles) | +600 XP + Life restored + Wild tile |

---

### Bonus secret words

Each round also contains 2–3 **Secret Words** — valid words the game flagged as interesting. Player doesn't know what they are.

- Finding one triggers a surprise "SECRET WORD!" banner
- Reward: `word length × 25 XP` (2.5× normal)
- Secret words are: animals, foods, nature words, or unusual 5+ letter words

---

## 5. Lives System

Replaces instant game-over at timer end.

### Lives
- Start with **3 lives** ❤️❤️❤️
- Lose a life when:
  - 🔥 Fire tile burns out (unused for 30 s)
  - ☠️ Poison tile expires (unused for 20 s)
  - Wave goal fails (timer reaches 0 without meeting the goal)
- Gain a life when:
  - Using ☠️ Poison tile while below max lives
  - Completing Wave 5, 10, 15 (milestone bonus)
  - Finding a 7-letter word

### Game over
All 3 lives lost → game ends → show final score screen with wave reached.

---

## 6. Power-Ups

Earned through gameplay — not bought. Stored in 3 slots at the bottom of the screen.

| Power-up | How to earn | Effect |
|----------|-------------|--------|
| ⏸ **Freeze** | Perfect wave clear | Pauses timer for 8 seconds |
| 🔀 **Shuffle** | Combo ×3 reached | Rerolls all 7 letters (keeps specials) |
| 💡 **Hint** | Finding a secret word | Highlights the letters of 1 valid word |
| 🌈 **Wild** | Combo ×4 streak | Wildcard letter added to the circle |
| ⚡ **Double XP** | Wave 5 / 10 / 15 milestone | All XP ×2 for 15 seconds |

### Power-up rules
- Max 1 of each type held at once
- Cannot be stacked (activating Double XP while one is active has no effect)
- Unused power-ups carry into the next wave

---

## 7. Scoring Formula

```
Word XP  =  (base length score)
          × (special tile multiplier)
          × (combo multiplier)
          × (wave multiplier)
          + (target word bonus if applicable)
          + (secret word bonus if applicable)
```

### Base length score

| Letters | Base XP |
|---------|---------|
| 3 | 10 |
| 4 | 20 |
| 5 | 40 |
| 6 | 80 |
| 7 | 160 |

### Wave multiplier

| Wave | Multiplier |
|------|-----------|
| 1–3 | ×1.0 |
| 4–6 | ×1.2 |
| 7–10 | ×1.5 |
| 11–15 | ×2.0 |
| 16+ | ×2.5 |

---

### Example calculation

> Wave 8 · Combo ×3 · 5-letter word · uses ⭐ Gold tile

```
Base:          5 letters → 40 XP
Gold tile:     × 2.0  =  80 XP
Combo ×3:      × 2.0  =  160 XP
Wave 8:        × 1.5  =  240 XP
```

**One word = 240 XP.**

---

## 8. Star Rating

Shown at wave clear and final game over screen.

| Stars | Condition |
|-------|-----------|
| ⭐ | Goal completed |
| ⭐⭐ | Goal completed + no lives lost this wave |
| ⭐⭐⭐ | Goal completed + no lives lost + combo ×3 or higher reached |

---

## 9. Difficulty Modes

Chosen at game start (tied to the player's Intermediate / Advanced setting).

### Intermediate
- Fire tile timer: 30 s
- Combo window: 6 s
- Hint available: costs 20 XP
- Lives: 3
- Target word hint shown: first letter free

### Advanced
- Fire tile timer: 20 s
- Combo window: 4 s
- Hint available: costs 50 XP
- Lives: 2
- Target word: no hint — silhouette only
- Poison tile: appears from Wave 2

---

## 10. Addiction Loop Summary

```
Start wave
    ↓
Drag letters → build combo → FEVER MODE spike
    ↓
Find target word → big XP reward
    ↓
Hit perfect wave → earn Wild tile + bonus time
    ↓
Next wave → harder goal, new special tiles, higher wave multiplier
    ↓
Combo breaks? → urgency to rebuild
Fire tile ticking? → pressure to use it
Low on lives? → risk vs reward tension
    ↓
Game over → "One more try" — wave number shown as benchmark to beat
```

### The three hooks
1. **Always chasing** — combo counter, fire tile countdown, target word silhouette all running simultaneously
2. **Always surprised** — secret word discovery feels random and exciting
3. **Always close** — lives system means the game rarely ends abruptly; player fights back

---

## 11. Changes from v1 Summary

| Feature | v1 | v2 |
|---------|----|----|
| Timer | Single 2-min countdown | 40 s per wave + carry-over time |
| Lives | None (timer only) | 3 lives, earn and lose dynamically |
| Special tiles | None | 4 types: Fire, Gold, Diamond, Poison |
| Combo system | None | ×1 → ×5 chain with FEVER MODE |
| Goals | None | Rotating wave goals (7 types) |
| Target word | None | 1 per wave with length silhouette |
| Secret words | None | 2–3 per wave, surprise discovery |
| Power-ups | None | 5 types earned through play |
| Scoring | Length × 10 | Length × tile × combo × wave |
| Difficulty | Int / Adv (word lists only) | Full mechanical difference |

---

*Word Match Rules v2.0 — updated for addictive loop design*
