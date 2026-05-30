# Word Match — Game Rules v2.1

> **Design goal:** One 2-minute session. Always something to chase — a combo, a special tile ticking down, a target word, a secret discovery. Timer ends → game ends. Clean and simple.

---

## Core Structure

```
Game start → 2-minute countdown → timer hits 0 → final score screen
```

No waves. No wave goals. No carry-over time. One continuous session where the pressure comes from the combo system, special tiles, and targets — not from wave resets.

---

## What Changed from v1

| Feature | v1 | v2.1 |
|---------|----|----|
| Timer | Single 2-min countdown | Single 2-min countdown ✅ (kept) |
| Letter set | Fixed for full game | Refreshes every 45 s automatically |
| Scoring | Length × 10 only | Length × tile multiplier × combo |
| Special tiles | None | 4 types appear during the game |
| Combo system | None | ×1 → ×5 chain with FEVER MODE |
| Target word | None | 1 active at all times, refreshes on find |
| Secret words | None | 2–3 hidden per letter set |
| Lives | None | None — timer is the only end condition |
| Power-ups | None | 3 types, earned during play |

---

## 1. Letter Circle

- **7 letters** arranged in a circle at all times
- Letters are **reusable** — the same letter can appear in multiple words
- Letters **refresh every 45 seconds** automatically (smooth swap animation)
- On refresh: special tiles re-roll, new target word is set
- Player can also tap **Shuffle** power-up to refresh early

### Vowel guarantee
Every letter set contains at least **2 vowels** and at most **4 vowels**. Generated at refresh — never a dead board.

---

## 2. Letter Tile Types

The circle contains normal letters plus up to **2 special tiles** at a time. Special tiles are placed randomly on refresh.

---

### Regular tile
Standard letter. Base score = `length × 10 XP`.

---

### 🔥 Fire tile — Hot letter
- Glows orange with animated flicker
- Using it in any word: score **×1.5**
- **Danger:** Burns out after **25 s** if unused → you miss the bonus (no life loss — this is a timeout game)
- Burned-out fire tile becomes a normal letter instantly
- Visual warning: flames shrink as timer counts down, red flash at 5 s

> Intermediate: 30 s burn timer · Advanced: 20 s

---

### ⭐ Gold tile — Power letter
- Glows gold with rotating sparkle
- Using it in any word: score **×2**
- No danger — use it whenever
- Stays on board until used, then replaced on next refresh

---

### 💎 Diamond tile — Jackpot letter
- Glows cyan with rotating shine
- Using it in any word: score **×3**
- Only spawns when the player has an active combo of **×3 or higher**
- Stays until used or combo breaks — on combo break it disappears
- Maximum 1 diamond on the board at a time

---

### ☠️ Poison tile — Cursed letter
- Dark green glow, pulsing
- **Must** be used within **20 s** or score penalty: **−30 XP**
- Using it: acts as a **wildcard vowel** (A / E / I / O / U — game picks best fit)
- No life loss — penalty is XP only, keeping the session continuous

> Intermediate: appears after 60 s · Advanced: appears after 30 s

---

### 🌈 Wild tile — Rainbow letter
- Cycling rainbow border
- Matches **any letter** in the alphabet
- **Not random** — earned only via Combo ×4 (see Power-Ups)
- Stored in the booster slot, placed on board when activated
- Max 1 wild on board at a time

---

## 3. Combo System

The core tension loop. Chain words quickly to multiply all XP earned.

### How combos build

Submit a valid word → combo starts. Submit another valid word within **5 seconds** → combo level rises.

| Combo level | XP multiplier | Visual |
|------------|--------------|--------|
| ×1 | ×1.0 | No indicator |
| ×2 | ×1.5 | Small orange flame top-left |
| ×3 | ×2.0 | Flame grows |
| ×4 | ×2.5 | Lightning bolt joins flame |
| ×5+ | ×3.0 | **FEVER MODE** |

### Combo breaks when:
- **5 seconds pass** with no valid word submitted
- **Invalid word submitted** — hard reset to ×1 (penalty for guessing)

### Combo bonus on natural break (timeout only):
If combo was ×4+ and breaks from time (not invalid word) → award `combo level × 15 XP` as a goodbye bonus.

---

### FEVER MODE (combo ×5+)

The highlight moment of each session.

- Background pulses with color waves
- All XP **doubled** (stacks on top of ×3.0 combo = effectively ×6 base)
- Timer **pauses for 4 seconds** — reward for skillful chaining
- Mascot animates wildly
- Found words in Fever are marked 🔥 in the word list

**Fever ends** when the combo breaks.

---

## 4. Target Word

One **Target Word** is always active during the session, shown as a silhouette above the board.

```
Example:  _ _ _ _ _   (5-letter word hidden in the current letters)
```

### Rules
- The target word is always formable from the current 7 letters
- On refresh (every 45 s), a new target word is set automatically
- Finding the target word also counts as a normal scored word — rewards stack

### Hint system
- Tap the silhouette → reveals the **first letter** (costs 20 XP · Advanced: costs 50 XP)
- One hint available per target word

### Target word rewards

| Length | Bonus XP |
|--------|----------|
| 3 letters | +40 |
| 4 letters | +80 |
| 5 letters | +150 |
| 6 letters | +300 |
| 7 letters (all tiles used) | +600 + Wild tile earned |

---

## 5. Secret Words

Each letter set contains **2–3 secret words** — valid words the game pre-flagged as interesting (animals, foods, nature, or rare 5+ letter words). The player doesn't know what they are.

- Finding one triggers a **"SECRET WORD! 🎉"** surprise banner
- Reward: `word length × 25 XP` (2.5× normal rate)
- Secret words reset with each letter refresh

---

## 6. Letter Set Refresh (every 45 s)

At 45 s and 90 s into the game, the letter circle refreshes automatically.

### Refresh sequence
1. Letters fan out and disappear (300 ms animation)
2. New 7 letters fly in from center (staggered 40 ms each)
3. New special tiles assigned
4. New target word silhouette shown
5. New secret words pre-loaded (player doesn't see them)

### Combo on refresh
- If player has an active combo when refresh triggers → **combo is preserved** for 5 s after the new letters appear (grace window to keep the chain alive)

---

## 7. Power-Ups

Earned during play. Stored in up to 3 slots on screen. No purchasing.

| Power-up | How to earn | Effect | Limit |
|----------|-------------|--------|-------|
| ⏸ **Freeze** | Find a 6-letter word | Pauses countdown timer for 8 s | Max 1 held |
| 🔀 **Shuffle** | Combo ×3 reached | Refreshes all 7 letters early (keeps active specials) | Max 1 held |
| 💡 **Hint** | Find a secret word | Highlights the path for 1 valid word on the current board | Max 2 held |
| 🌈 **Wild** | Combo ×4 reached | Places a wildcard letter on the board | Max 1 held |
| ⚡ **Double XP** | Find 10 words in one session | All XP ×2 for 15 s | Max 1 per game |

### Power-up rules
- Cannot stack two of the same type
- Unused power-ups **do not carry** between sessions (this is a single-session game)
- Using a power-up never breaks your combo

---

## 8. Scoring Formula

```
Word XP  =  (base length score)
          × (special tile multiplier, if tile used)
          × (combo multiplier)
          × (Double XP if active)
          + (target word bonus, if applicable)
          + (secret word bonus, if applicable)
```

### Base length score

| Letters | Base XP |
|---------|---------|
| 3 | 10 |
| 4 | 20 |
| 5 | 40 |
| 6 | 80 |
| 7 | 160 |

### Example — mid-game combo

> Combo ×3 · 5-letter word · uses ⭐ Gold tile

```
Base:       40 XP
Gold ×2:    80 XP
Combo ×3:   × 2.0  = 160 XP
```

**160 XP from one word.**

### Example — FEVER MODE

> Combo ×5 (Fever) · 4-letter word · no special tile

```
Base:          20 XP
Combo ×3.0:    60 XP
Fever ×2:      120 XP
```

**120 XP from a basic 4-letter word.**

---

## 9. End Screen

When the 2-minute timer hits 0:

- Gentle slowdown animation — last word floats up
- Score card bounces in with final XP total
- Star rating shown (1–3 stars)
- Word list displayed — secret words revealed with 🔐 icon
- Best combo reached shown as a stat
- "Play Again" resets everything — new letters, new targets, fresh timer

### Star rating

| Stars | Condition (Intermediate) | Condition (Advanced) |
|-------|--------------------------|----------------------|
| ⭐ | ≥ 100 XP | ≥ 150 XP |
| ⭐⭐ | ≥ 250 XP | ≥ 400 XP |
| ⭐⭐⭐ | ≥ 500 XP + combo ×3 reached | ≥ 700 XP + combo ×4 reached |

---

## 10. Difficulty Modes

Set at login. Applies for the full session.

| Setting | Intermediate | Advanced |
|---------|-------------|----------|
| Timer | 120 s | 120 s |
| Combo window | 6 s | 4 s |
| Fire tile burn | 30 s | 20 s |
| Poison penalty | −20 XP | −40 XP |
| Poison appears | After 60 s | After 30 s |
| Diamond appears | Combo ×3 | Combo ×3 |
| Hint cost | 20 XP | 50 XP |
| Secret words | 2 per set | 3 per set |
| Target word hint | First letter free | Silhouette only |

---

## 11. Addiction Loop — Timeout Edition

```
Game starts (120 s)
    ↓
Drag letters → build combo ×2 → ×3 → ×4 → Diamond spawns!
    ↓
Fire tile appears — 25 s ticking → use it before it burns
    ↓
Combo ×5 → FEVER MODE → timer pauses 4 s → double everything
    ↓
Find target word → big XP spike → new target appears
    ↓
Find secret word → surprise! → Hint power-up earned
    ↓
45 s mark → letters refresh → new specials → combo grace window
    ↓
90 s mark → letters refresh again → final push
    ↓
Timer hits 0 → game ends → score locked → star rating shown
```

### The three tension engines (no waves needed)

1. **Combo window (5 s)** — constant micro-urgency between every word. Player is always racing the invisible 5-second clock.
2. **Special tile countdowns** — fire tile burning out and poison tile threatening XP loss create overlapping pressure without ending the game.
3. **Target word silhouette** — always something to solve. Even when words feel hard to find, the player is scanning for a specific goal.

---

*Word Match Rules v2.1 — single-session timeout model*
