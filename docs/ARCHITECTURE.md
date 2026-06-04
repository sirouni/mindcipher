# CodeBreaker — Technical Design Document

## Overview

CodeBreaker is a Mastermind-style iOS puzzle game built with SwiftUI. Players guess a secret color code using feedback from each attempt. The unique differentiator is **Lie Mode** where one feedback per game is intentionally false.

## Architecture

```
User → HomeView
         ├─ Classic → LevelSelect → GameViewModel.startGame → GameEngine
         ├─ Lie     → LieLevelSelect → startLieGame (lieMode)
         ├─ Free    → FreePlaySetup → startFreePlay
         ├─ Duel    → DuelSetup → startDuel
         ├─ Daily   → DailyChallengeView → startDuel + isDailyChallenge
         ├─ Editor  → LevelEditorView → manual engine
         └─ URL     → ChallengeManager → startChallenge (seed-based)

Win path: StatsManager + HintCoinManager + ProgressManager + Achievements + Game Center
```

### Layers

- **Views** — SwiftUI, create `GameViewModel`, call `start*` methods
- **GameViewModel** — game state machine, notes, hints, phase transitions
- **GameEngine** — secret code generation, feedback evaluation, lie logic
- **Managers (singletons)** — persistence via UserDefaults

## Source Files

| File | Purpose |
|------|---------|
| `CodeBreakerApp.swift` | App entry, deep links, Game Center auth, ChallengeManager/GameView |
| `Models.swift` | Domain models: PegColor, GameEngine, Level, Progress, Stats, HintCoins, SeededRNG |
| `GameViewModel.swift` | Game state, notes system, hint logic, all start flows |
| `GameView.swift` | Main play UI, notes grid, action bar, result overlay, share |
| `HomeView.swift` | Home hub with all mode entries |
| `DailyChallengeView.swift` | Daily challenge, calendar, streak, Game Center leaderboard |
| `LevelSelectView.swift` | Classic 240-level campaign grid |
| `LieLevelSelectView.swift` | Lie campaign (separate progress) |
| `LevelEditorView.swift` | Custom level parameter builder |
| `TutorialView.swift` | 7-page tutorial (rules, notes, hints, lie mode) |
| `Theme.swift` | Colors, glass card modifier, peg/feedback views |
| `ThemePicker.swift` | 4 skins (Agent, Cyber, Military, Minimal) |
| `SoundManager.swift` | Procedural tones + haptics |
| `L10n.swift` | Bilingual strings (en/zh) |

## Core Data Model

### PegColor
```swift
enum PegColor: Int, CaseIterable { case red=0, green, blue, yellow, purple, orange, cyan, pink }
```

### GameEngine

Seed-based deterministic code generation. All constructors now save a `seed` property.

```swift
class GameEngine {
    let seed: UInt64
    let secretCode: [PegColor]
    let codeLength: Int
    let availableColors: [PegColor]
    let maxAttempts: Int
    let lieMode: Bool
    
    init(codeLength:colorCount:allowDuplicates:maxAttempts:lieMode:)  // generates random seed
    init(seed:codeLength:colorCount:allowDuplicates:maxAttempts:lieMode:)  // deterministic
    init(secretCode:colorCount:maxAttempts:)  // for duel (player-set code)
}
```

### Feedback
```swift
struct Feedback {
    let exact: Int    // right color, right position
    let partial: Int  // right color, wrong position
    let isLie: Bool   // true if this feedback was faked
}
```

### Difficulty Presets

| Difficulty | Length | Colors | Attempts | Duplicates |
|------------|--------|--------|----------|------------|
| Beginner | 3 | 4 | 10 | No |
| Easy | 4 | 6 | 9 | No |
| Medium | 4 | 6 | 9 | Yes |
| Hard | 5 | 7 | 10 | Yes |
| Expert | 5 | 8 | 12 | Yes |
| Master | 6 | 8 | 14 | Yes |

## Lie Mode

- One feedback per game is replaced with a "close" fake (differs by ≤1 in exact/partial)
- Lie fires at a predetermined guess index within the "optimal solve" window
- Winning guess is never a lie
- Post-game reveals which row was fake

### Lie Attempt Calculation
```
optimalSteps = {3→4, 4→6, 5+→8}
lieAttemptNumber = (rng.next() % (optimalSteps - 1)) + 1
```

## Challenge URL Scheme

### Format
```
codebreaker://challenge?s=<seed>&l=<length>&c=<colors>&a=<attempts>&d=<dup>&m=<mode>&f=<name>
```

| Param | Type | Description |
|-------|------|-------------|
| `s` | UInt64 | Seed (required, non-zero) |
| `l` | Int | Code length (default: 4) |
| `c` | Int | Color count (default: 6) |
| `a` | Int | Max attempts (default: 7) |
| `d` | 0/1 | Allow duplicates (default: 0) |
| `m` | Int | Mode: 0=classic, 1=lie (extensible) |
| `f` | String | Challenger name (URL-encoded) |

Same seed + same params = same secret code (deterministic via SeededRNG).

## Notes System

Per-position, per-color markers:
- `nil` — unmarked
- `.eliminated` — color ruled out for this position
- `.confirmed` — color confirmed for this position

Interactions:
- Single cell tap: nil → eliminated → confirmed → nil
- Row tap (color peg): cycle all positions for that color
- Column tap (PX header): toggle all colors at that position (eliminated ↔ clear only)
- Eliminated colors are disabled in the color picker
- Single confirmed color shows as faded hint in guess row

## Hint System

### Economy (HintCoinManager)
- Win 3 games → +1 coin
- Login 2 consecutive days → +1 coin
- 1 hint per game maximum

### Logic (findBestDeduction)
- Select position with most unmarked colors
- If >2 wrong colors remain: eliminate up to `wrongColors/3` (keep ≥3 possibilities)
- If ≤2 wrong remain: confirm correct color and auto-fill slot

## Game Center

- Leaderboard ID: `com.codebreaker.app.daily`
- Score: `(maxAttempts - attempts) * 10000 + max(0, 10000 - elapsedSeconds)`
- Submitted on daily challenge win only
- Auth on app launch via `GKLocalPlayer.local.authenticateHandler`

## Level Progression

- 240 levels: 6 tiers × 40 levels each
- Sequential unlock (complete N-1 to unlock N)
- Stars: ≤30% attempts used → 3★, ≤60% → 2★, else 1★
- Lie campaign: separate 240 levels with extra attempts, separate progress

### Tiers
| Tier | Levels | Name | Difficulty |
|------|--------|------|------------|
| 1 | 1-40 | Junior Agent | Beginner |
| 2 | 41-80 | Agent | Easy |
| 3 | 81-120 | Senior Agent | Medium |
| 4 | 121-160 | Elite Agent | Hard |
| 5 | 161-200 | Chief Agent | Expert |
| 6 | 201-240 | Legend Agent | Master |

## Daily Challenge

- Fixed: 4 pegs, 6 colors, 7 attempts, no duplicates
- Code seeded from date string hash (same puzzle worldwide per day)
- Completion tracked in `DailyStreakManager` with calendar visualization
- Game Center leaderboard for daily scores

## Persistence

All via UserDefaults:
- `completedLevels` / `lie_completedLevels` — completed level IDs
- `starsByLevel` / `lie_starsByLevel` — star ratings
- `stats_*` — games played/won, streaks, total attempts
- `hint_*` — coins, wins towards coin, login streak
- `daily_*` — per-date completion flags
- `daily_completed_dates` — array for calendar
- `achievements_unlocked` — unlocked achievement IDs
- `app_skin` — current theme
