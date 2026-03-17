# Ippo v3 -- Bug Report

*Generated: March 17, 2026*
*Source: Static code analysis + architecture review*
*Status: Pre-fix documentation. All bugs identified from code review.*

---

## Summary

| Severity | Count |
|----------|-------|
| Critical | 1 |
| High | 5 |
| Medium | 6 |
| Low | 5 |
| **Total** | **17** |

---

## Critical Bugs

### BUG-001: Mood calculation ignores watering

**Severity:** Critical
**System:** Mood System
**File:** `IppoMVP/IppoMVP/Data/UserData.swift` line 273-296

**Description:** `recalculateMood()` checks `lastFedDate`, `lastPettedDate`, and `lastRunDate` but does NOT check `lastWateredDate`. Watering a pet has zero effect on mood despite being presented as a core care action.

**Reproduction:**
1. Start with a pet that has mood=1 (Sad)
2. Water the pet
3. Observe mood -- it does NOT change

**Expected:** Watering should contribute to mood score (score += 1 if watered today)
**Actual:** Mood ignores watering entirely

**Fix:** Add `lastWateredDate` check to `recalculateMood()`:
```swift
if let lastWatered = pet.lastWateredDate, calendar.isDateInToday(lastWatered) {
    score += 1
}
```
**Impact:** This changes mood from a 0-3 scale (run + feed + pet) to a 0-4 scale. Need to adjust the clamp: `mood = clamp(score >= 3 ? 3 : score >= 2 ? 2 : 1)` or adjust the mapping so 4 inputs map to 3 mood levels.

**Affected Systems:** Mood -> XP Rate -> Evolution Speed -> Runaway Timer -> UI

**Effort:** 30 minutes (including threshold adjustment)

---

## High Bugs

### BUG-002: pushProfileToWatch() never called

**Severity:** High
**System:** Watch-Phone Sync
**File:** `IppoMVP/IppoMVP/Services/WatchConnectivityService.swift`

**Description:** The `pushProfileToWatch()` method exists and works, but is never called from anywhere in the codebase. When a user changes age (affecting maxHR for sprint validation) or equips a different pet, the Watch doesn't receive the update until it independently requests sync (which only happens on WCSession activation).

**Reproduction:**
1. Equip a different pet on phone
2. Check Watch -- still shows old pet name/image
3. Force-quit Watch app and relaunch -- now shows correct pet

**Expected:** Watch should update immediately when profile/pet changes on phone
**Actual:** Watch uses stale data until it reinitializes

**Fix:** Call `WatchConnectivityService.shared.pushProfileToWatch()` after `equipPet()` and age changes. Also push full sync data (not just estimatedMaxHR).

**Affected Systems:** Watch display, sprint validation (if maxHR changes), catch availability

**Effort:** 1 hour

---

### BUG-003: CloudService debug logging in production

**Severity:** High
**System:** Cloud Sync
**File:** `IppoMVP/IppoMVP/Services/CloudService.swift` lines ~145, ~151

**Description:** `isUsernameTaken()` and `reserveUsername()` contain debug logging that writes to the hardcoded path `/Users/crucegauntlet/Desktop/Ippo MVP/.cursor/debug.log`. This will fail on any user's device and could cause crashes or data leaks.

**Reproduction:** Call `isUsernameTaken()` on a real device -- the file write will silently fail (no crash, but the path is a privacy concern in the binary).

**Expected:** No hardcoded local filesystem paths in production code
**Actual:** Debug file paths compiled into production binary

**Fix:** Remove all `FileManager` debug logging from `CloudService.swift`. Use `TelemetryLogger` or `print()` under `#if DEBUG` instead.

**Affected Systems:** Username validation, cloud service reliability

**Effort:** 15 minutes

---

### BUG-004: DeleteAccountSheet doesn't dismiss on success

**Severity:** High
**System:** Auth / Profile
**File:** `IppoMVP/IppoMVP/UI/Views/ProfileView.swift`

**Description:** `performDeletion()` in `DeleteAccountSheet` deletes the user's account (Firebase Auth + Firestore) but never calls `dismiss()` or updates the auth state to trigger navigation back to the login screen. User is stuck on the deletion sheet with no way to proceed.

**Reproduction:**
1. Go to Profile -> Delete Account
2. Type confirmation text
3. Tap Delete
4. Account is deleted but sheet remains visible

**Expected:** Sheet dismisses, app navigates to LoginView
**Actual:** User stuck on DeleteAccountSheet

**Fix:** After successful deletion, call `dismiss()` and ensure `AuthService.isAuthenticated` is set to false (which should happen via Firebase Auth state listener, but verify the timing).

**Affected Systems:** Auth, navigation, user experience

**Effort:** 30 minutes

---

### BUG-005: Double syncFromCloud on login

**Severity:** High
**System:** Cloud Sync
**Files:** `LoginView.swift`, `IppoMVPApp.swift` / `ContentView.swift`

**Description:** Both `LoginView.onChange(isAuthenticated)` and `ContentView.task` call `syncFromCloud()`. This causes two redundant Firestore reads on every login. The `cloudSyncInFlight` guard prevents concurrent execution but not sequential double-calls.

**Reproduction:** Sign in -- observe two Firestore read operations in console

**Expected:** Single cloud sync on login
**Actual:** Two sequential cloud syncs

**Fix:** Remove `syncFromCloud()` from one location. Prefer keeping it in `ContentView.task` (which is the canonical entry point) and removing from `LoginView`.

**Affected Systems:** Cloud sync, Firestore costs, login performance

**Effort:** 15 minutes

---

### BUG-008: Runaway warnings not scheduled in production

**Severity:** High
**System:** Notifications
**File:** `IppoMVP/IppoMVP/Systems/NotificationSystem.swift`

**Description:** `scheduleRunawayWarning()` uses a 5-second trigger for debug purposes. There is no production implementation that schedules warnings at the intended milestones (7, 4, 2 days before runaway). Users receive no warning before their pet runs away.

**Reproduction:** Let a pet's consecutiveSadDays approach 14 -- no warning notifications are received

**Expected:** Notifications at 7 days (warning), 4 days (urgent), 2 days (critical) before runaway
**Actual:** No warnings in production

**Fix:** Implement production scheduling based on `consecutiveSadDays` and `daysSinceLastInteraction`. Schedule warnings when values reach 7, 10, 12 (corresponding to 7, 4, 2 days remaining).

**Affected Systems:** Notifications, user engagement, pet retention

**Effort:** 2 hours

---

## Medium Bugs

### BUG-006: Cloud merge drops cloud boosts

**Severity:** Medium
**System:** Cloud Sync
**File:** `IppoMVP/IppoMVP/Services/CloudService.swift`

**Description:** `mergeData()` always uses local `activeBoosts`, ignoring any boosts that exist in cloud data. Multi-device users who purchase boosts on one device lose them when syncing from another.

**Fix:** Merge boosts by union (combine both lists, deduplicate by type, keep the one with the later expiry).

**Effort:** 1 hour

---

### BUG-007: Encounter charm cost mismatch

**Severity:** Medium
**System:** Economy
**File:** `IppoMVP/IppoMVP/Config/EconomyConfig.swift`

**Description:** `encounterCharmCost = 25` in code but the app spec (`IPPO_APP_SPEC.md`) says 60 coins. One is wrong.

**Fix:** Determine intended price and align code + spec. Given the economy analysis (25 coins has negative ROI, 60 coins is even worse), recommend keeping 25 or reducing to 20.

**Effort:** 10 minutes

---

### BUG-009: Username race condition

**Severity:** Medium
**System:** Cloud Sync
**File:** `IppoMVP/IppoMVP/Services/CloudService.swift`

**Description:** `reserveUsername()` first deletes the old username document, then creates the new one. Brief window exists where another user could claim the released name.

**Fix:** Use a Firestore batch write or transaction to atomically delete old + create new.

**Effort:** 1 hour

---

### BUG-010: No Watch sync retry

**Severity:** Medium
**System:** Watch-Phone Sync
**File:** `IppoMVPWatch Watch App/Services/WatchConnectivityServiceWatch.swift`

**Description:** If phone is unreachable when Watch activates, `requestSync()` fails silently with no retry. Watch uses stale cached data.

**Fix:** Add retry with exponential backoff (e.g., retry at 5s, 15s, 45s) on `requestSync()` failure.

**Effort:** 1.5 hours

---

### BUG-011: Spec says 10 evolution stages, code has 3

**Severity:** Medium
**System:** Documentation
**Files:** `docs/IPPO_APP_SPEC.md`, `PetDetailView.swift`

**Description:** The spec references "10 stages" and "10 dots in evolution timeline," but the code has 3 stages (Baby, Teen, Adult) with 3 image names per pet. PetDetailView's evolution timeline may render incorrectly if it uses the spec's 10-dot layout.

**Fix:** Update spec to reflect 3 stages. Verify PetDetailView timeline shows 3 dots, not 10.

**Effort:** 30 minutes

---

### BUG-012: Passive coin/XP income defined but not implemented

**Severity:** Medium
**System:** Economy / Rewards
**Files:** `EconomyConfig.swift`, `PetConfig.swift`, `RewardsConfig.swift`

**Description:** `coinsPerMinuteRunning = 1` and `xpPerMinuteRunning = 5` are defined in config files but never referenced in any code. The spec says "1 coin/minute" running income but all rewards are sprint-based only.

**Fix:** Either implement passive income (add time-based rewards in `WatchRunManager` or `completeRun()`) or remove the unused config values and update the spec.

**Effort:** 2 hours if implementing, 15 minutes if removing

---

## Low Bugs

### BUG-013: Streak freeze has no active indicator

**Severity:** Low
**System:** UI
**File:** `IppoMVP/IppoMVP/UI/Views/HomeView.swift`

**Description:** User can purchase streak freeze in shop but there's no visual indicator on HomeView that streak freeze is active. User has no way to know their streak is protected without checking the shop.

**Fix:** Add a shield icon or banner near the streak counter when `inventory.isStreakFrozen` is true.

**Effort:** 30 minutes

---

### BUG-014: Coin boost has no active indicator

**Severity:** Low
**System:** UI
**File:** `IppoMVP/IppoMVP/UI/Views/HomeView.swift`

**Description:** Similar to BUG-013. Coin boost has no UI feedback. HomeView already shows XP boost and hibernation banners but not coin boost or streak freeze.

**Fix:** Add banner or badge for active coin boost, similar to existing XP boost banner.

**Effort:** 30 minutes

---

### BUG-015: Unused compiled components

**Severity:** Low
**System:** Code Quality
**Files:** `CelebrationModal.swift`, `ProgressRing.swift` (includes StreakCounter, WeeklyProgressDots, EffortRing)

**Description:** Multiple UI components are compiled into the binary but never used in v3 views. Dead code increases binary size and maintenance burden.

**Fix:** Either remove the unused components or wire them into the appropriate views (WeeklyProgressDots could be used on HomeView for streak calendar).

**Effort:** 30 minutes to remove, 2-4 hours to integrate

---

### BUG-016: Unused iOS engine files

**Severity:** Low
**System:** Code Quality
**Files:** `SprintEngine.swift`, `SprintValidator.swift`, `EncounterManager.swift`

**Description:** The iOS-side sprint engine, validator, and encounter manager are compiled but never wired to any UI or system. All sprint/encounter logic runs on the Watch via `WatchRunManager`.

**Fix:** Remove from iOS target or move to an archive group. Keep `SprintValidator` if it's used by `SprintValidatorTests.swift`.

**Effort:** 30 minutes

---

### BUG-017: RewardsConfig entirely unused

**Severity:** Low
**System:** Code Quality
**File:** `IppoMVP/IppoMVP/Config/RewardsConfig.swift`

**Description:** `RewardsConfig` duplicates values from `EconomyConfig` and `PetConfig` (coinsPerSprint, xpPerSprint, baseCatchRate, etc.) but is never referenced anywhere in the codebase.

**Fix:** Delete `RewardsConfig.swift`.

**Effort:** 5 minutes

---

## Test Suites

### Test Suite 1: Pet Care (8 tests)

| ID | Test | Steps | Expected |
|----|------|-------|----------|
| TC-1.1 | Feed pet | Set food=5, tap Feed | Food -1, +5 XP, bounce, hearts |
| TC-1.2 | Feed when empty | Set food=0 | Feed button disabled |
| TC-1.3 | Feed twice same day | Feed once, try again | Second feed disabled, no XP |
| TC-1.4 | Water pet | Set water=5, tap Water | Water -1, +5 XP |
| TC-1.5 | Pet (rub) pet | Drag ~80px | No inventory cost, +2 XP |
| TC-1.6 | All care same day | Feed + Water + Pet | All XP awarded, all disabled after |
| TC-1.7 | Care persistence | Feed, kill app, reopen | Feed still recorded |
| TC-1.8 | Midnight rollover | Set lastFedDate=yesterday | Feed re-enabled |

### Test Suite 2: Mood (6 tests)

| ID | Test | Steps | Expected |
|----|------|-------|----------|
| TC-2.1 | Happy conditions | Run + feed + pet today | Mood=3 (Happy) |
| TC-2.2 | Content mood | Feed + pet, no run | Mood=2 (Content) |
| TC-2.3 | Sad mood | No care for days | Mood=1 (Sad) |
| TC-2.4 | Mood affects XP | Set Sad, add XP | XP multiplied by 0.6x |
| TC-2.5 | Water and mood | Water only | BUG-001: watering does NOT affect mood |
| TC-2.6 | Mood during hibernation | Activate hibernation, skip days | Mood frozen |

### Test Suite 3: Economy (7 tests)

| ID | Test | Steps | Expected |
|----|------|-------|----------|
| TC-3.1 | Sprint coins | Simulate 3-sprint run | +24-36 coins |
| TC-3.2 | Catch bonus | Simulate run with catch | +25 extra coins |
| TC-3.3 | Shop purchase | Buy Food (3 coins) | Coins -3, food +1, toast |
| TC-3.4 | Insufficient coins | Set coins=0, try buy | Button disabled |
| TC-3.5 | Bulk purchase | Buy Food Pack (12 coins) | Coins -12, food +5 |
| TC-3.6 | Coin boost | Activate boost, simulate run | +40% coins per sprint |
| TC-3.7 | Persistence | Buy item, kill app, reopen | State persisted |

### Test Suite 4: XP & Evolution (7 tests)

| ID | Test | Steps | Expected |
|----|------|-------|----------|
| TC-4.1 | Sprint XP | Simulate valid sprint | +15-25 XP (mood-adjusted) |
| TC-4.2 | Care XP | Feed pet | +5 XP (mood-adjusted) |
| TC-4.3 | XP boost | Activate boost, feed | XP = base * mood * 1.3 |
| TC-4.4 | Level up | Add XP near threshold | Level increments |
| TC-4.5 | Evolution | Set 1 level below threshold, add XP | EvolutionAnimationView triggers |
| TC-4.6 | Evolution persistence | Trigger evolution, kill app | New stage persisted |
| TC-4.7 | Max level | Set level 30, add XP | No crash, XP capped |

### Test Suite 5: Collection (7 tests)

| ID | Test | Steps | Expected |
|----|------|-------|----------|
| TC-5.1 | Initial state | Complete onboarding | 1 owned, 9 undiscovered |
| TC-5.2 | Catch pet | Simulate catch of pet_04 | Added to collection |
| TC-5.3 | Equip pet | Tap pet -> Equip | Orange border, HomeView updates |
| TC-5.4 | Undiscovered | Check uncaught pets | Shows "???" + hint |
| TC-5.5 | Lost pet | Force runaway | Moves to Lost section |
| TC-5.6 | Rescue | Have coins, tap Rescue | Coins deducted, pet restored |
| TC-5.7 | Grant all | AdminDebug grant all | All 10 in collection |

### Test Suite 6: Watch-Phone Sync (5 tests)

| ID | Test | Steps | Expected |
|----|------|-------|----------|
| TC-6.1 | Sync activation | Open Watch app | Receives profile + pet data |
| TC-6.2 | Equip change | Equip different pet on phone | Watch shows new pet after sync |
| TC-6.3 | Run summary | Complete Watch run | Phone receives, updates state |
| TC-6.4 | Catch on Watch | Catch pet during run | Phone adds pet to collection |
| TC-6.5 | Phone unreachable | Turn off phone, open Watch | Uses cached data |

### Test Suite 7: Cloud Sync (4 tests)

| ID | Test | Steps | Expected |
|----|------|-------|----------|
| TC-7.1 | Save to cloud | Feed pet, check Firestore | Document updated |
| TC-7.2 | Load from cloud | Sign out, sign in | State restored |
| TC-7.3 | Merge conflict | Modify on two devices | Higher totalRuns wins |
| TC-7.4 | Username taken | Try taken username | Error shown |

### Test Suite 8: Onboarding (6 tests)

| ID | Test | Steps | Expected |
|----|------|-------|----------|
| TC-8.1 | Full flow | Walk through 15 steps | Completes, shows Home |
| TC-8.2 | Back navigation | Go to step 5, go back | Previous step shown |
| TC-8.3 | Auth failure | Cancel Sign-In | Error shown, can retry |
| TC-8.4 | Skip Watch | No Watch paired | Verify blocking behavior |
| TC-8.5 | Returning user | Sign out, sign in | Cloud data loaded |
| TC-8.6 | Username taken | Enter taken username | Shows taken indicator |

### Test Suite 9: Notifications (5 tests)

| ID | Test | Steps | Expected |
|----|------|-------|----------|
| TC-9.1 | Care notification | Wait/trigger via AdminDebug | Notification with pet name |
| TC-9.2 | Open from notif | Tap notification | Opens to Home |
| TC-9.3 | After care | Feed pet | Hungry notification cancelled |
| TC-9.4 | Run reminder | Don't run 3 days | Reminder fires |
| TC-9.5 | Runaway warning | Set sad days high | BUG-008: No production warnings |

### Test Suite 10: Edge Cases (8 tests)

| ID | Test | Steps | Expected |
|----|------|-------|----------|
| TC-10.1 | No pets | Remove all pets | Empty states shown |
| TC-10.2 | All lost | Force all runaway | Only Lost section |
| TC-10.3 | Zero coins | Set coins=0 | Shop disabled, pet free |
| TC-10.4 | Max coins | Set coins=999999 | No overflow |
| TC-10.5 | App kill during run | Kill phone, end Watch run | Pending summary appears |
| TC-10.6 | Date manipulation | Jump 30 days forward | Runaway triggers |
| TC-10.7 | Rapid tapping | Tap Feed 10x fast | Only one registers |
| TC-10.8 | Memory pressure | Many apps open | No crash |

---

*Total: 63 test cases across 10 suites*
*End of Bug Report*
