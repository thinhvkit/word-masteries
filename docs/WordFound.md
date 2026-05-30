# Word Found — Game Design Plan

---

## Overview

**Word Found** is a mobile word puzzle game where players spell words from a set of letter tiles. Each wave brings a fresh set of quest targets, a new nature-themed background, and escalating challenges. The core loop is fast, satisfying, and designed to keep teenagers and casual players hooked.

---

## Word Rules

| Rule | Detail |
|---|---|
| Minimum length | 3 letters |
| No repeats | Same word can't be submitted twice per wave |
| Valid dictionary | Curated word list matched to available letters |
| Submit enabled | Only when word is valid + new |
| Undo | Tap any selected tile to remove it and everything after |

---

## Target System

Each wave randomly assigns **3 quest targets** from 21+ different types.  
Targets reset and refresh every wave with new combinations.

### Target Categories

| Category | Examples |
|---|---|
| **By length** | 3 letter words, 4 letter words, 5 letter words, 6+ letter words, Short (≤3), Long (5+) |
| **By first letter** | Starts with G, H, B, R, E, T, N |
| **By word type** | Nouns, Verbs / Actions, Animals, Nature words |
| **By pattern** | Has 2+ vowels, Ends with N / R / T, Has repeated letter |

---

## Scoring

| Word length | Base coins |
|---|---|
| 3 letters | 10 🪙 |
| 4 letters | 50 🪙 |
| 5 letters | 100 🪙 |
| 6 letters | 180 🪙 |
| 7+ letters | 250 🪙 |

### Multipliers (stack)
- **Bonus tile used** → ×1.5
- **Fever Mode active** → ×2
- **Streak ×2** (3 consecutive words) → ×2
- **Streak ×3** (6 consecutive words) → ×3

---

## Streak & Fever Mode

- Every correct word adds to the streak counter
- **4 consecutive correct words** → Fever Mode activates (10 seconds)
- Fever Mode: 2× coins, purple/pink background pulse, timer shown
- Any wrong attempt or wave end resets streak
- Streak badge shown in header with multiplier label

---

## Wave Timer

- **Easy:** 90 seconds per wave
- **Advanced:** 60 seconds per wave
- Colorful bar across top of screen
  - Green (>50% remaining)
  - Yellow (25–50%)
  - Red (<25%)
  - Hot pink/orange in Fever Mode
- Wave ends automatically at 0

---

## Wave Complete

Star rating based on targets completed:

| Targets hit | Stars |
|---|---|
| All 3 | ⭐⭐⭐ |
| 2 | ⭐⭐ |
| 1 | ⭐ |
| 0 | 🌟 (participation) |

Modal shows:
- Star display
- Per-target result (✓ / ✗)
- Total coins earned
- Total words submitted
- "Next Wave →" button with preview of next theme icon

---

## Hints

- 3 hints available at game start (+1 hint reward per wave)
- Tap 💡 to reveal: **"Starts with: G _"**
- Costs 1 hint per use

### Earning Extra Hints — Bonus Word System

A **bonus word** is any valid word submitted that doesn't advance any of the 3 active wave targets.

```
Every 10 bonus words found → +1 Hint earned automatically
```

- The 💡 button shows two counters:
  - **Top:** current hint count (e.g. `3`)
  - **Bottom:** bonus word progress toward next hint (e.g. `7/10`)
- When a hint is earned, a `+1 Hint!` badge pops above the button
- Encourages players to explore words beyond the targets — rewarding curiosity and vocabulary range

---

## Nature Themes (5 total, cycle every 5 submits)

| # | Theme | Icon | Vibe |
|---|---|---|---|
| 1 | Sunset Desert | 🌵 | Warm orange, red sky |
| 2 | Tropical Beach | 🏖️ | Blue ocean, golden sand |
| 3 | Snowy Peak | ❄️ | Deep blue, white mountains |
| 4 | Christmas | 🎄 | Dark forest, festive lights |
| 5 | Summer Vibe | ☀️ | Bright yellow, teal ocean |

Background transitions smoothly (1.2s ease) between themes.

---

## Difficulty Modes

| | Easy | Advanced |
|---|---|---|
| Wave time | 90s | 60s |
| Target totals | Lower (4/4/2/1) | Higher (6/6/4/2) |
| Score multiplier | Standard | Standard |
| Hints at start | 3 | 3 |

---

## Difficulty Selection Screen

- Warm cream background with floating confetti dots
- Two cards: 🌱 Easy · 🔥 Advanced
- On pick:
  - Selected card scales up, emoji bounces + spins
  - Other card fades/shrinks
  - Personalized compliment banner springs in
  - Color burst radial flash fills the screen
  - Transitions to game after 2 seconds

### Compliment Messages

**Easy pick:**
- "Smart choice! 🌟 Every legend starts here."
- "You're already winning! 💚 Let's go!"
- "The best journey starts with one word! 🚀"

**Advanced pick:**
- "Bold move! 🔥 You're on another level!"
- "Challenge accepted! ⚡ Show them what you've got!"
- "That's the spirit! 💪 Fearless and ready!"

---

## Word Feedback (Praise System)

| Word length | Praise examples |
|---|---|
| 3 | Nice! 😊 · Cool! 👍 · Sweet! 🍬 |
| 4 | Good job! ✨ · Awesome! 🌟 · Nailed it! 💫 |
| 5 | Great!! 🔥 · Brilliant! ⚡ · Wow!! 💥 |
| 6 | Amazing!!! 🚀 · Incredible! 🌈 · On fire!! 🎯 |
| 7 | LEGENDARY!! 👑 · UNSTOPPABLE! ⚜️ |
| 8+ | GODLIKE!!!! 💎 · WORD MASTER! 🏆 |

Praise is shown below the word display with coin badge (+50🪙).  
In Fever Mode, praise text glows hot pink.

---

## Future Ideas

- 🌍 World map progression (unlock new letter sets per region)
- 🏅 Daily challenge with fixed letter set and leaderboard
- 🎵 Sound effects — tile tap, word submit, fever activation, wave complete
- 💬 Multiplayer: race a friend to find words first
- 🧩 Special tiles: wildcard ✨, double-score 💰, time-freeze ⏸
- 📈 XP / level system beyond coins
- 🎨 Player-unlockable tile skins and board themes
- 🔔 Push notifications for daily streak reminders
