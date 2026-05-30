# Word Match — VFX Plan

> **Design principle:** Every visual, audio, and haptic effect is proportional to the action that triggers it. Small actions get micro feedback. Big words get full celebrations. Never over-respond to a small moment.

---

## Legend

| Tag | Type |
|-----|------|
| 🎬 Animation | CSS keyframe / transform effect |
| ✨ Particle | Burst, confetti, sparkle system |
| 🔊 Sound | Web Audio API procedural tone |
| 🖥 UI State | Color, text, layout change |
| 📳 Haptic | Vibration pattern (mobile) |

---

## 1. Drag — Letter Selection

### First tap / drag start
| Type | Effect |
|------|--------|
| 🎬 Animation | Bubble scales `1.0 → 1.15`, `translateY –4px` |
| 🔊 Sound | Soft pop — sine 500 Hz, 50 ms |
| 📳 Haptic | Light impact (`UIImpactFeedbackStyleLight`) |

> Elevation gives the illusion of "lifting" the bubble off the board.

---

### Each new letter added
| Type | Effect |
|------|--------|
| 🎬 Animation | Connection line draws from previous → new bubble (`stroke-dashoffset` animation) |
| 🎬 Animation | New bubble pulses `scale 1.0 → 1.12 → 1.0`, 120 ms |
| ✨ Particle | 2–3 tiny sparkles emit from bubble center |
| 🔊 Sound | Rising pitch — each letter adds +1 semitone to the series |
| 🖥 UI State | Word bar updates live with the new letter |

> Ascending pitch builds anticipation as the word grows longer.

---

### Drag back (deselect)
| Type | Effect |
|------|--------|
| 🎬 Animation | Line retracts — erases from tail backward |
| 🎬 Animation | Bubble settles back down, `scale 1.12 → 1.0` |
| 🔊 Sound | Descending soft thud — 300 Hz, 40 ms |

---

### 3-letter threshold reached
| Type | Effect |
|------|--------|
| 🎬 Animation | Word bar border pulses green 2× |
| 🖥 UI State | Damage / XP preview fades in below the word bar |
| 🔊 Sound | Short chime — C5 sine, 80 ms |

> Signals "this is now submittable" without interrupting the drag flow.

---

## 2. Word Submit — Success

### Valid 3-letter word (+10 XP)
| Type | Effect |
|------|--------|
| 🎬 Animation | Word bar flashes white → green, 200 ms, resets to pink |
| ✨ Particle | 6–8 circle particles burst from word bar center |
| 🔊 Sound | 3-note ascending arpeggio (C – E – G) |
| 🎬 Animation | `+10 XP` floats upward, fades out over 800 ms |
| 📳 Haptic | Medium impact |

---

### Valid 4-letter word (+20 XP)
| Type | Effect |
|------|--------|
| 🎬 Animation | Word bar flash + slightly wider particle spread |
| ✨ Particle | 10 particles — circles |
| 🔊 Sound | 4-note arpeggio (C – E – G – C5) |
| 🎬 Animation | `+20 XP` floats up, slightly larger text |
| 📳 Haptic | Medium impact |

---

### Valid 5-letter word (+40 XP)
| Type | Effect |
|------|--------|
| ✨ Particle | 14 particles — mix of circles and stars |
| 🎬 Animation | Mascot bounces — `translateY –10 → 0`, 300 ms easing |
| 🔊 Sound | 4-note arpeggio + sparkle shimmer layer on top |
| 🖥 UI State | `+40 XP` in larger golden text |
| 📳 Haptic | Medium-heavy impact |

---

### Valid 6+ letter word (+80 / +160 XP)
| Type | Effect |
|------|--------|
| ✨ Particle | 22 particles — confetti colors, spread 200 px radius |
| 🎬 Animation | "AMAZING!" banner drops from top, shakes, exits after 1.2 s |
| 🎬 Animation | Board rim flashes gold glow 3× |
| 🔊 Sound | Full 7-note fanfare + bell shimmer layer |
| 🖥 UI State | `+80 / +160 XP` with ⭐ spin animation |
| 📳 Haptic | Heavy impact + 1 notification buzz |

---

## 3. Word Submit — Failure

### Not a real word
| Type | Effect |
|------|--------|
| 🎬 Animation | Word bar shakes — ±7 px, 4 cycles, 350 ms |
| 🎬 Animation | Bar flashes red → resets to pink |
| 🔊 Sound | Descending two-tone buzz — 150 Hz → 120 Hz |
| 📳 Haptic | Error pattern — 2 short buzzes |

> Connection lines snap back with rubber-band easing (overshoot then settle).

---

### Already used word
| Type | Effect |
|------|--------|
| 🎬 Animation | Word bar shakes + ✗ stamp animation |
| 🖥 UI State | Previously found word pill briefly highlighted |
| 🔊 Sound | Softer buzz — signals "known" not "wrong" |

---

### Lifted with fewer than 3 letters
| Type | Effect |
|------|--------|
| 🎬 Animation | Bubbles bounce back to rest positions |
| 🔊 Sound | Very soft thud — near-silent, 200 Hz, 30 ms |

> Intentionally subtle — no penalty feeling for accidental short drags.

---

## 4. Timer Events

### 30 seconds remaining
| Type | Effect |
|------|--------|
| 🖥 UI State | Timer color shifts yellow → orange |
| 🔊 Sound | Subtle tick starts — 1× per second |

---

### 10 seconds remaining
| Type | Effect |
|------|--------|
| 🎬 Animation | Timer pulses `scale 1.0 → 1.1` each second |
| 🖥 UI State | Timer color → red, background flushes faint red |
| 🔊 Sound | Louder tick, higher pitch (800 Hz) |
| 📳 Haptic | 1 light buzz per second |

---

### Time up
| Type | Effect |
|------|--------|
| 🎬 Animation | Screen dims to 70% opacity over 400 ms |
| ✨ Particle | Full confetti shower if score ≥ 3 stars |
| 🔊 Sound | Win: 5-note fanfare · Lose: descending sigh |
| 🎬 Animation | Score card bounces in — cubic-bezier overshoot easing |
| 📳 Haptic | Win: 2 long buzzes · Lose: 1 descending buzz |

---

## 5. Ambient / Board Life

### Board idle (no drag active)
| Type | Effect |
|------|--------|
| 🎬 Animation | Bubbles float gently — staggered bob, 2.5–3.5 s cycle per bubble |
| 🎬 Animation | Background leaves and decorations sway — slow CSS rotation |

> Keeps the game feeling alive even between words.

---

### New letter set loaded
| Type | Effect |
|------|--------|
| 🎬 Animation | Bubbles fly in from center — staggered 40 ms per bubble |
| 🔊 Sound | Whoosh + 7 plop notes as each bubble lands |

---

### Mascot comment triggered
| Type | Effect |
|------|--------|
| 🎬 Animation | Mascot bounces once |
| 🎬 Animation | Speech bubble scales in `0 → 1`, overshoot |
| 🎬 Animation | Speech bubble scales out `1 → 0` after 2.5 s |

---

## 6. Intensity Scale

Effects are always proportional to the action. Particle count, audio volume, haptic intensity, and animation scale ramp together.

| Level | Trigger | Particles | Audio | Haptic |
|-------|---------|-----------|-------|--------|
| **Micro** | Tap, drag start, deselect | 0 | Soft pop / thud | Light |
| **Low** | 3-letter word | 6–8 | 3-note arpeggio | Medium |
| **Medium** | 5-letter word | 14 | 4-note + shimmer | Medium-heavy |
| **Max** | 6+ letter word | 22+ | Full fanfare | Heavy + buzz |

> Never trigger a max-level response for a small action.

---

## 7. Submit Sequence — Timing (ms)

All effects triggered at finger lift (`t = 0`). Everything resolves by **500 ms** so the player can start the next drag immediately.

```
t = 0 ms      Finger lifts — validation fires
t = 0–80 ms   Word bar flashes success / error color
t = 0–120 ms  Audio arpeggio begins
t = 40–200 ms Particles burst from word bar
t = 60–300 ms XP float rises and fades
t = 80–500 ms Mascot reacts (5+ letter words only)
t = 500 ms    Word bar resets to default pink
```

---

## 8. Technical Notes

### Animation
- Use `transform` and `opacity` only for all animations — no layout-triggering properties
- All bubble floats use `will-change: transform` for GPU compositing
- Wrap ambient animations in `@media (prefers-reduced-motion: no-preference)` — opt-out by default

### Particles
- Particles are `<div>` or `<canvas>`-based — CSS `@keyframes` for trajectory
- Each particle gets randomized: angle, speed (50–150 px), size (3–6 px), lifetime (1.2–1.8 s)
- Color set per word length: blue (3-letter), green (4-letter), purple (5-letter), gold/multi (6+)

### Sound (Web Audio API)
- Lazy-init `AudioContext` on first user gesture to comply with browser autoplay policy
- All tones are procedurally generated oscillators — no audio files needed
- Ascending pitch series: each drag step increments frequency by 1 semitone (`f × 2^(1/12)`)
- Master gain kept at 0.3 to avoid clipping; reduce further if multiple sounds overlap

### Haptics (Mobile)
- Use `navigator.vibrate()` for Android pattern support
- iOS: use `UIImpactFeedbackGenerator` / `UINotificationFeedbackGenerator` via React Native / native bridge
- Always check `navigator.vibrate` exists before calling — no-op on desktop

### Performance budget
| Effect layer | Target cost |
|---|---|
| Ambient bubble float | < 1 ms/frame (transform only) |
| Particle burst (22 particles) | < 3 ms/frame |
| Audio generation | < 0.5 ms (oscillator scheduling) |
| Board redraw on drag | < 4 ms/frame (SVG path update) |

---

*Last updated: Word Match VFX Plan v1.0*
