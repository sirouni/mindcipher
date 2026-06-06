# CodeBreaker — Test Document

## Test Environment

- Xcode 16+
- iOS Simulator: iPhone 17 Pro (iOS 26.0)
- Device UDID: `646D50F1-3968-48F7-8711-C9E486537227`
- Build: `xcodebuild -scheme CodeBreaker -destination 'platform=iOS Simulator,id=<UDID>' -derivedDataPath ./build build`

## Automated Tests

### UI Tests (`CodeBreakerUITests/`)
- Home navigation
- Level selection
- Daily challenge flow
- Custom level editor
- Duel mode

### Solvability Tests (repo root scripts)
| File | Coverage |
|------|----------|
| `test_levels.swift` | Classic 240 levels solvable within attempt limits |
| `test_hard_levels.swift` | Hard/Expert/Master level validation |
| `test_all_levels.swift` | Full 240-level sweep |
| `test_lie_*.swift` (5 files) | Lie mode solvability with extra attempts |

## Manual Test Cases

### TC-001: Notes System

| Step | Action | Expected |
|------|--------|----------|
| 1 | Start Free Play (Easy) | 4 slots, 6 colors |
| 2 | Tap Notes button in action bar | Notes grid overlay appears over guess board |
| 3 | Tap a cell in grid | Cell shows ❌ (eliminated) |
| 4 | Tap same cell again | Cell shows ✓ (confirmed) |
| 5 | Tap same cell again | Cell clears |
| 6 | Tap color peg (row header) | Entire row marks eliminated |
| 7 | Tap same peg again | Entire row marks confirmed |
| 8 | Tap same peg again | Entire row clears |
| 9 | Tap "P2" column header | Entire column marks eliminated |
| 10 | Tap "P2" again | Entire column clears |
| 11 | Close notes, select slot with eliminated color | Color picker shows X overlay, button disabled |
| 12 | Mark one color confirmed for a slot | Guess row shows faded hint for that slot |

### TC-002: Hint System

| Step | Action | Expected |
|------|--------|----------|
| 1 | Set `hint_coins` to 3 via `simctl defaults write` | — |
| 2 | Start game | Hint button shows orange "3" badge |
| 3 | Tap hint button | Notes updated with eliminations, badge shows "2", button grays out |
| 4 | Verify notes | 1+ colors eliminated at one position, ≥3 possibilities remain |
| 5 | Start new game | Hint available again (badge "2") |
| 6 | Win 3 games consecutively | Badge increments, "+1 Hint Coin!" shown on 3rd win |

**Test with 0 coins:**
| Step | Action | Expected |
|------|--------|----------|
| 1 | Set `hint_coins` to 0 | — |
| 2 | Start game | Hint button shows gray "0", disabled |
| 3 | Tap hint button | Nothing happens |

### TC-003: Challenge URL (Classic)

| Step | Action | Expected |
|------|--------|----------|
| 1 | Run: `xcrun simctl openurl <UDID> "codebreaker://challenge?s=123456789&l=4&c=6&a=7&d=0&m=0&f=TestPlayer"` | Challenge sheet appears |
| 2 | Verify UI | Shows "Challenge from TestPlayer", Code length 4, Colors 6, Max attempts 7 |
| 3 | No lie warning | Correct (m=0) |
| 4 | Tap "Accept Challenge" | Game starts in Duel Mode, 7 attempts, 4 slots, 6 colors |
| 5 | Repeat with same seed | Same secret code generated |

### TC-004: Challenge URL (Lie Mode)

| Step | Action | Expected |
|------|--------|----------|
| 1 | Run: `xcrun simctl openurl <UDID> "codebreaker://challenge?s=555666777&l=5&c=8&a=12&d=1&m=1&f=Eve"` | Challenge sheet appears |
| 2 | Verify UI | Shows "Challenge from Eve", Code 5, Colors 8, Attempts 12 |
| 3 | Lie warning shown | "Lie Mode — one feedback may be fake!" in red |
| 4 | Accept and play | One feedback will be fake during the game |
| 5 | Same seed → same lie position | Deterministic (same guess# gets lied to) |

### TC-005: Daily Challenge & Calendar

| Step | Action | Expected |
|------|--------|----------|
| 1 | Navigate to Daily Challenge | Calendar shows current month |
| 2 | Completed days show as green circles | Verified with seeded data |
| 3 | Today shows orange ring (if not completed) | Correct |
| 4 | Start daily challenge | Game starts, timer tracking begins |
| 5 | Win game | Score submitted to Game Center (if authenticated) |
| 6 | Return to daily | "Today's challenge complete", day marked in calendar |
| 7 | Streak counter updates | Reflects consecutive completed days |

### TC-006: Game Center Leaderboard

| Step | Action | Expected |
|------|--------|----------|
| 1 | Authenticate (requires sandbox account) | `isAuthenticated = true` |
| 2 | Win daily challenge | Daily score computed, stored, and included in unified leaderboard |
| 3 | Score formula | `(7-attempts)*10000 + max(0, 10000-seconds)` |
| 4 | Tap "Leaderboard" button in Daily view | GKGameCenterViewController opens |
| 5 | Relaunch app after auth | Unified score re-submits from saved data |

**Note:** Game Center does not work on Simulator. Test on real device with sandbox account.

### TC-006B: Unified Leaderboard

| Step | Action | Expected |
|------|--------|----------|
| 1 | Authenticate on real device | Unified leaderboard submission enabled |
| 2 | Complete a Classic campaign level | Total leaderboard score increases |
| 3 | Complete a Lie campaign level | Total leaderboard score increases |
| 4 | Improve a daily score or level from 1★ to 3★ | Total leaderboard score increases |
| 5 | Open leaderboard from Daily / Classic / Lie screens | Same leaderboard opens everywhere |

**Unified score formula:** `best daily scores by date + classic campaign score + lie campaign score`.

### TC-007: Layout (6-peg codes)

| Step | Action | Expected |
|------|--------|----------|
| 1 | Start Free Play Master (6×8) | 6 slots, 8 colors |
| 2 | Submit a guess | Peg row + feedback dots fit within screen |
| 3 | Feedback uses 2-row grid (3+3) | Not overflowing |
| 4 | Open notes | Grid cells properly sized for 6 positions × 8 colors |

### TC-008: Hint Coin Progress on Win

| Step | Action | Expected |
|------|--------|----------|
| 1 | Set `hint_wins_towards_coin` to 2 | — |
| 2 | Win a game | Win overlay shows "+1 Hint Coin! (X total)" |
| 3 | Set `hint_wins_towards_coin` to 0 | — |
| 4 | Win a game | Shows "1/3 wins to next coin" with ●○○ |

## Regression Checklist

After any code change, verify:
- [ ] Classic campaign levels load and unlock correctly
- [ ] Lie mode fires exactly once per game, never on winning guess
- [ ] Notes persist during a game session and reset on new game
- [ ] Hint respects coin balance and deduction limits
- [ ] Daily challenge generates same code for same date
- [ ] Challenge URL generates and receives correctly
- [ ] 5-6 peg layouts don't overflow
- [ ] Tutorial pages (7) all render correctly
- [ ] Sound/haptics toggle works
- [ ] Theme switching works

## Test Data Seeding

```bash
# Set hint coins
xcrun simctl spawn <UDID> defaults write com.codebreaker.app hint_coins -integer 3

# Set wins towards coin
xcrun simctl spawn <UDID> defaults write com.codebreaker.app hint_wins_towards_coin -integer 2

# Set daily completions for calendar testing
xcrun simctl spawn <UDID> defaults write com.codebreaker.app daily_completed_dates -array "2026-06-01" "2026-06-02" "2026-06-03"

# Reset all data
xcrun simctl spawn <UDID> defaults delete com.codebreaker.app
```
