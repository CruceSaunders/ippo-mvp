# Ippo v3 -- Complete System Audit

*Generated: March 17, 2026*
*Status: Comprehensive system-level documentation of every feature, data flow, and cross-system interaction*

---

## 1. Architecture Overview

Ippo v3 is a dual-platform app (iOS + watchOS) with a single source of truth (`UserData.swift`) on the phone. The Watch runs independently during workouts and syncs results to the phone via WatchConnectivity.

```
┌─────────────────────────────────────────────────────────┐
│                    iOS App                                │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐               │
│  │ HomeView │  │Collection│  │ ShopView │               │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘               │
│       │              │              │                     │
│       └──────────────┼──────────────┘                     │
│                      │                                    │
│              ┌───────▼────────┐                           │
│              │   UserData     │◄──── Single Source of     │
│              │   (singleton)  │      Truth                │
│              └───┬───┬───┬───┘                           │
│                  │   │   │                                │
│    ┌─────────────┘   │   └─────────────┐                 │
│    ▼                 ▼                 ▼                  │
│ DataPersistence  CloudService  WatchConnectivity          │
│ (UserDefaults)   (Firestore)   (WCSession)               │
└─────────────────────────────────────────────────────────┘
                       │
          ─────────────┼─────────────
                       │
┌─────────────────────────────────────────────────────────┐
│                  watchOS App                              │
│  ┌──────────────────────────────────────┐                │
│  │        WatchRunManager               │                │
│  │  (HealthKit, Sprint, Encounter,      │                │
│  │   Catch Roll, Run Summary)           │                │
│  └──────────────┬───────────────────────┘                │
│                 │                                         │
│     WatchConnectivityServiceWatch                        │
│     (sends run results to phone)                         │
└─────────────────────────────────────────────────────────┘
```

---

## 2. System-by-System Documentation

### 2.1 Sprint/Encounter Engine

**Location:** `IppoMVPWatch Watch App/Engine/WatchRunManager.swift`
**Also (unused on iOS):** `IppoMVP/Engine/Sprint/SprintEngine.swift`, `SprintValidator.swift`, `IppoMVP/Engine/Encounter/EncounterManager.swift`

**Purpose:** Manages the entire run lifecycle on Watch: workout session, encounter timing, sprint validation, pet catch rolls, and run summary generation.

**Public API:**
- `startRun()` -- Begins HealthKit workout, starts encounter timer
- `pauseRun()` / `endRun()` -- Pause or end the workout
- `resetToIdle()` -- Returns to pre-run state
- `checkAndRequestHealthKit()` / `requestHealthKitPermissions()`

**Published State:**
- `runState`: idle, running, sprinting, summary
- `isPaused`, `elapsedTime`, `currentHR`, `currentDistance`, `currentCalories`
- `totalSprints`, `sprintsCompleted`, `isInRecovery`, `recoveryRemaining`
- `sprintTimeRemaining`, `sprintProgress`, `runSummary`
- `lastSprintSuccess`, `showSprintResult`, `didCatchPet`, `caughtPetName`

**Constants (WatchSprintConfig):**

| Constant | Value |
|----------|-------|
| minSprintDuration | 25s |
| maxSprintDuration | 40s |
| recoveryDuration | 45s |

**Constants (WatchEncounterConfig):**

| Time Since Last | Probability/sec |
|----------------|-----------------|
| 60-90s | 0.002 |
| 90-120s | 0.005 |
| 120-150s | 0.0083 |
| 150-180s | 0.0128 |
| >=180s | 1.0 (guaranteed) |

**Warmup:** 60s before first encounter (5s in Simulator)

**Sprint Validation (Watch):**
- Simulator: always valid
- With hrZone4Threshold > 0: 50% of HR samples must be in zone 4
- Otherwise: hrIncrease/20 score, combined (hrScore * 0.65 + 0.35) * 100 >= 60

**Rewards per valid sprint:**
- Coins: 8-12 (random)
- XP: 15-25 (random)
- Catch roll: 8% base, 11% with encounter charm
- Pity timer: guaranteed catch at 15 dry sprints

**Data Flow:**
1. Run starts -> HealthKit workout session begins
2. Encounter timer fires -> Sprint state activated
3. Sprint ends -> Validation check -> Rewards calculated
4. Catch roll (if valid sprint) -> Pet assigned from `catchablePetIds`
5. Recovery timer (45s) -> Next encounter cycle
6. Run ends -> `WatchRunSummary` sent to phone via `WatchConnectivityServiceWatch.sendRunSummary()`

**Cross-System Interactions:**
- --> Economy: awards coins per sprint + catch bonus
- --> XP: awards XP per sprint (modified by mood + boosts on phone side)
- --> Collection: catch roll adds pet to ownedPets
- --> Watch Sync: sends complete run summary to phone
- --> Streak: run completion triggers `updateStreak()` on phone
- --> Profile: increments totalRuns, totalSprints, totalDistanceMeters, totalDurationSeconds
- --> Mood: updates `lastRunDate`, feeding into mood calculation
- --> Notifications: run activity resets "run reminder" timer
- --> Boosts: per-run boosts consumed after run on phone side

---

### 2.2 Pet Care System

**Location:** `IppoMVP/IppoMVP/Data/UserData.swift` (methods: `feedPet()`, `waterPet()`, `petPet()`)

**Purpose:** Handles daily care interactions with the equipped pet. Each action awards XP, affects mood, and consumes inventory.

**Public API:**
- `feedPet() -> Bool` -- Consumes 1 food, awards 5 XP, updates lastFedDate
- `waterPet() -> Bool` -- Consumes 1 water, awards 5 XP, updates lastWateredDate
- `petPet() -> Bool` -- Free action, awards 2 XP, updates lastPettedDate

**Rules:**
- Each care action can only award XP once per calendar day (checked via `canEarnFeedXP`, `canEarnWaterXP`, `canEarnPetXP`)
- Feed/water require inventory > 0
- Pet (rub) is always free
- XP is modified by: mood multiplier, XP boost, streak bonus
- Evolution can trigger from care XP
- Feeding/watering clears matching active care need notification

**BUG: `recalculateMood()` does NOT check `lastWateredDate`. Watering has zero effect on mood.**

**Cross-System Interactions:**
- --> Mood: feeding and petting improve mood (watering does NOT - BUG-001)
- --> XP: 5 XP (feed), 5 XP (water), 2 XP (pet) -- all mood-adjusted
- --> Inventory: consumes 1 food or 1 water
- --> Evolution: XP gain may trigger stage change -> PendingEvolution
- --> Notifications: feeding/watering may clear active care need
- --> Streak: via `recordInteraction()` on the pet action itself (NOT called from feedPet/waterPet/petPet directly -- but they call `save()` which triggers cloud sync)
- --> Cloud: every care action triggers `save()` -> local + cloud persist
- --> UI: triggers bounce animation, hearts overlay, floating XP label

---

### 2.3 Mood System

**Location:** `UserData.recalculateMood(at:)` (line 273)

**Purpose:** Calculates pet mood (1=Sad, 2=Content, 3=Happy) based on recent care activity.

**Algorithm:**
```
score = 0
if ranToday or ranYesterday: score += 1
if fedToday: score += 1
if pettedToday: score += 1
mood = clamp(score, 1, 3)
```

**BUG:** Watering is not included in the score. `lastWateredDate` is never checked.

**Mood Effects:**

| Mood | Value | XP Multiplier | Visual |
|------|-------|---------------|--------|
| Happy | 3 | 1.0x | Green capsule, leaf icon |
| Content | 2 | 0.85x | Yellow capsule |
| Sad | 1 | 0.6x | Red capsule |

**Skipped during hibernation** (`inventory.isHibernating`).

**Cross-System Interactions:**
- --> XP Rate: multiplier applied to ALL XP gains (sprint, care, etc.)
- --> Runaway: `consecutiveSadDays` increments when mood=1
- --> UI: MoodIndicator color/icon, care need text
- --> Evolution Speed: indirect via XP multiplier (sad = ~40% slower)
- --> Notifications: affects notification copy urgency

---

### 2.4 XP & Evolution System

**Location:** `UserData.addXP()` (line 124), `UserData.addPetXP()` (line 234), `PetConfig.swift`

**Purpose:** Manages experience accumulation, level progression, and evolution stage transitions.

**XP Modifiers (stacking):**
1. Mood multiplier: Happy=1.0x, Content=0.85x, Sad=0.6x
2. XP Boost: +30% when active
3. Streak Bonus: up to +10% (scales linearly, capped at 30-day streak)

**XP Curve:** `floor(10 * n^3 / 27)` cumulative XP required per level

**Key Thresholds:**

| Level | Cumulative XP |
|-------|--------------|
| 5 | 46 |
| 10 | 333 |
| 15 | 1,250 |
| 20 | 2,963 |
| 25 | 5,787 |
| 30 | 10,000 |

**Evolution Stages:** 3 stages (Baby, Teen, Adult) with per-pet level thresholds:

| Pet | Baby->Teen (Stage 2) | Teen->Adult (Stage 3) |
|-----|---------------------|----------------------|
| Lumira | Level 15 | Level 24 |
| Mossworth | Level 16 | Level 25 |
| Dewdrop | Level 17 | Level 26 |
| Bramble | Level 14 | Level 23 |
| Zephyr | Level 18 | Level 27 |
| Coraline | Level 15 | Level 26 |
| Cinders | Level 17 | Level 24 |
| Glaciel | Level 16 | Level 27 |
| Shale | Level 14 | Level 25 |
| Stella | Level 18 | Level 24 |

**Evolution Trigger:** When `addXP()` or `addPetXP()` increases pet level past an evolution threshold, a `PendingEvolution` struct is created, which triggers `EvolutionAnimationView` on the next UI render.

**Dual XP Tracking:** Player profile has its own XP/level (via `addXP()`), and each pet has independent XP/level (via `addPetXP()`). Both increment simultaneously when the equipped pet earns XP.

**Cross-System Interactions:**
- --> Level: XP drives level via cubic curve
- --> Stage: level compared against per-pet evolutionLevels
- --> UI: XPProgressBar, EvolutionAnimationView (fullscreen)
- --> Collection: stage changes update pet image
- --> Watch Sync: level/stage visible on next sync
- --> Profile: player-level XP tracked separately

---

### 2.5 Economy System

**Location:** `EconomyConfig.swift`, `UserData.addCoins()`, `UserData.spendCoins()`

**All Constants:**

| Constant | Value |
|----------|-------|
| startingCoins | 20 |
| coinsPerSprint | 8-12 |
| coinsForCatchingPet | 25 |
| foodCost | 3 |
| waterCost | 2 |
| foodPackCount / Cost | 5 / 12 |
| waterPackCount / Cost | 5 / 8 |
| xpBoostCost | 40 |
| encounterCharmCost | 25 |
| coinBoostCost | 30 |
| hibernationCost | 80 |
| streakFreezeCost | 50 |
| xpBoostDurationHours | 2 |
| xpBoostMultiplier | 0.30 (+30%) |
| encounterCharmBonus | 0.03 (+3%) |
| coinBoostMultiplier | 0.40 (+40%) |
| hibernationDays | 7 |
| streakFreezeDays | 3 |
| maxStreakBonusPercent | 0.10 (+10%) |
| streakBonusCap | 30 days |
| startingFood | 3 |
| startingWater | 3 |

**Cross-System Interactions:**
- --> Shop: coins are the sole currency
- --> Inventory: purchases increase food/water/boost counts
- --> Care: food/water enable care actions
- --> Boosts: purchased boosts modify XP/catch/coin rates
- --> Rescue: coins spent to recover lost pets (50-200 based on stage)
- --> Cloud: coin balance synced to Firestore

---

### 2.6 Collection System

**Location:** `GameData.swift` (static definitions), `UserData.ownedPets`

**Pet Roster:** 10 pets total
- 3 starters (isStarter=true): Lumira (pet_01), Mossworth (pet_02), Dewdrop (pet_03)
- 7 catchable: Bramble (pet_04), Zephyr (pet_05), Coraline (pet_06), Cinders (pet_07), Glaciel (pet_08), Shale (pet_09), Stella (pet_10)

**Static Data per Pet:** id, name, description, hintText, stageImageNames[3], evolutionLevels, isStarter

**Dynamic Data per OwnedPet:** id, petDefinitionId, evolutionStage, level, experience, mood, lastFedDate, lastWateredDate, lastPettedDate, isEquipped, caughtDate, consecutiveSadDays, isLost

**Catchable Pet Selection:** `GameData.catchablePetIds` = all non-starter pet IDs. Synced to Watch via `WatchConnectivityService`. Watch selects randomly from this list on catch.

**Cross-System Interactions:**
- --> Home: equipped pet is primary interaction target
- --> Care: only equipped pet receives care
- --> Watch: equipped pet info + catchablePetIds synced
- --> Evolution: per-pet thresholds from definition
- --> UI: CollectionView grid, PetDetailView, equip/unequip

---

### 2.7 Notification System

**Location:** `IppoMVP/Systems/NotificationSystem.swift`

**Notification Types:**

| Type | Trigger | Timing |
|------|---------|--------|
| Daily Care | Scheduled daily | Random hour 14-17, random minute |
| Run Reminder | No run for 3 days | 3 * 86400 seconds from last run |
| Runaway Warning | Approaching runaway threshold | Debug only (5s trigger) -- NOT in production |
| Pet Ran Away | Pet actually runs away | Immediate when detected |

**BUG:** Runaway warnings are only implemented for debug. No production scheduling.

**Cross-System Interactions:**
- --> Engagement: daily care notification drives app opens
- --> Mood: notifications prompt care to prevent decay
- --> Retention: run reminder after 3 days of inactivity

---

### 2.8 Watch-Phone Sync

**Location:** `WatchConnectivityService.swift` (iOS), `WatchConnectivityServiceWatch.swift` (watchOS)

**Message Types:**

| Direction | Type | Payload |
|-----------|------|---------|
| Watch->Phone | `syncRequest` | (empty) -- reply contains profile+pet data |
| Phone->Watch | syncRequest reply | estimatedMaxHR, ownedPetIds, catchablePetIds, hasEncounterCharm, equipped pet info |
| Watch->Phone | `runEnded` | durationSeconds, distanceMeters, sprintsCompleted, coinsEarned, xpEarned, petCaughtId |
| Phone->Watch | `profileSync` | estimatedMaxHR |
| Phone->Watch | `hapticBuzz` | (empty) |

**Sync Trigger:** Watch sends `syncRequest` on WCSession activation. Phone replies with current data.

**BUG:** `pushProfileToWatch()` exists but is NEVER called. Watch only gets updates when it initiates sync.

**BUG:** No retry mechanism if phone is unreachable. Sync silently fails.

---

### 2.9 Cloud Sync

**Location:** `CloudService.swift`, `DataPersistence.swift`

**Local Persistence:** `UserDefaults.standard` key `com.cruce.IppoMVP.userData.v3` (JSON-encoded `SaveableUserData`)

**Cloud Persistence:** Firestore `users/{uid}` document

**Sync Flow:**
1. Every `save()` call -> `DataPersistence.saveUserData()` (local) + `CloudService.syncToCloud()` (cloud, fire-and-forget)
2. On login: `syncFromCloud()` -> load cloud -> merge with local -> save both

**Merge Strategy:**
- Profile: higher `totalRuns` wins. Ties: most recent `lastRunDate`. Cumulative stats use `max()`
- Pets: union by `petDefinitionId` (cloud pets added if not local)
- Inventory: `max(food, water)`. ActiveBoosts always from LOCAL (BUG-006)
- Run History: union by id, sorted by date, capped at 50

**BUG:** Debug logging writes to hardcoded path in `isUsernameTaken()` and `reserveUsername()`.
**BUG:** `activeBoosts` always uses local, dropping cloud boosts on multi-device.
**BUG:** Username reservation has race condition (delete then create).

---

### 2.10 Auth System

**Location:** `AuthService.swift`

**Methods:** Apple Sign-In, Google Sign-In, Sign Out, Delete Account

**Admin Detection:** Hardcoded UID set + email patterns + UserDefaults override

**Post-Auth Flow:** `handlePostSignIn()` -> load cloud data -> if cloud has pets, overwrite local

**Cross-System Interactions:**
- --> Cloud: auth UID gates all Firestore operations
- --> Onboarding: auth completion advances onboarding
- --> Profile: provides displayName, email, UID

---

### 2.11 Streak System

**Location:** `UserData.updateStreak()` (line 420)

**Algorithm:**
1. Set `lastInteractionDate` to now
2. If lastRunDate exists:
   - Same day or yesterday: increment streak (if daysDiff==1 or streak==0)
   - More than 1 day gap AND not hibernating AND not streak-frozen: reset to 1
3. If no lastRunDate: set streak to 1
4. Update longestStreak = max(current, longest)

**Streak is based on RUNNING, not care.** Only `updateStreak()` is called from `completeRun()`.

**XP Bonus:** Up to +10% based on streak length (linear, capped at 30 days)

---

### 2.12 Shop System

**Location:** `ShopView.swift` (UI), `UserData.buyItem()` (logic)

**Items:**

| Item | Cost | Effect |
|------|------|--------|
| Food (1x) | 3 | +1 food |
| Water (1x) | 2 | +1 water |
| Food Pack (5x) | 12 | +5 food |
| Water Pack (5x) | 8 | +5 water |
| XP Boost | 40 | +30% XP for 2 hours |
| Encounter Charm | 25 | 8%->11% catch rate, 1 run |
| Coin Boost | 30 | +40% coins, 1 run |
| Hibernation | 80 | 7-day freeze on mood/runaway |
| Streak Freeze | 50 | 3-day streak protection |

---

### 2.13 Runaway & Rescue System

**Location:** `UserData.checkRunaway()` (line 299), `UserData.rescuePet()` (line 322)

**Runaway Conditions:** `consecutiveSadDays >= 14` AND `daysSinceLastInteraction >= 14`

**Runaway Effects:** pet.isLost = true, pet.isEquipped = false, profile.equippedPetId = nil

**Rescue Costs:** Stage 1: 50 coins, Stage 2: 100 coins, Stage 3: 200 coins

**Rescue Effects:** pet.isLost = false, pet.mood = 1 (Sad), consecutiveSadDays = 0

---

### 2.14 Boost System

**Location:** `PlayerInventory` (in `RewardTypes.swift`), `UserData.buyItem()`, `UserData.consumePerRunBoosts()`

**Active Boosts:** Stored as `[ActiveBoost]` with type + expiresAt

| Boost | Duration | Effect | Consumed |
|-------|----------|--------|----------|
| XP Boost | 2 hours | +30% XP | Time-based expiry |
| Encounter Charm | 24h (fallback) | +3% catch rate | After 1 run |
| Coin Boost | 24h (fallback) | +40% coins | After 1 run |
| Streak Freeze | 3 days | Protects streak | Time-based expiry |
| Hibernation | 7 days | Freezes mood/runaway | Time-based expiry |

`consumePerRunBoosts()` removes encounter charm and coin boost after run completion.

---

### 2.15 Onboarding System

**Location:** `OnboardingFlow.swift` (`IppoCompleteOnboardingFlow`)

**15 Steps:**
0. Welcome
1. Auth (Apple/Google Sign-In)
2. Username
3. Age
4. Starter Pet Selection
5. Permissions (Health + Notifications)
6. Watch Setup
7. How Runs Work
8. Sprint Demo (interactive vibrations)
9. Chase Explanation
10. Catching Pets
11. Coins/XP Explanation
12. Care Tutorial (`TutorialOverlayView`)
13. Evolution Explanation
14. Ready Screen

**Completion:** Sets `hasCompletedOnboarding = true` in UserDefaults, navigates to ContentView.

---

## 3. Complete Cross-System Interaction Matrix

Each cell describes the interaction between the row system and the column system.

| | Sprint Engine | Care | Mood | XP/Evolution | Economy | Collection | Notifications | Watch Sync | Cloud | Auth | Streak | Shop | Runaway | Boosts |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **Sprint Engine** | - | - | Updates lastRunDate | Awards 15-25 XP/sprint | Awards 8-12 coins/sprint + 25 catch | Catch adds pet | Resets run reminder | Sends summary | Via UserData.save() | - | Triggers updateStreak() | - | - | Consumed after run |
| **Care** | - | - | Recalculates mood | Awards 5/5/2 XP | - | - | Clears care notification | - | Via save() | - | - | - | Resets sad days if mood improves | XP boost applied |
| **Mood** | - | - | - | Multiplier on all XP | - | - | Affects notification urgency | - | - | - | - | - | Sad days increment | - |
| **XP/Evolution** | - | - | Mood multiplier applied | - | - | Stage updates pet image | - | Level/stage synced | Via save() | - | Streak bonus applied | - | - | XP boost applied |
| **Economy** | Source of coins | Care costs food/water | - | - | - | Rescue costs coins | - | - | Coin balance synced | - | - | Deducts on purchase | Rescue costs coins | Purchase costs coins |
| **Collection** | Catch adds pet | Only equipped pet cared for | - | Per-pet thresholds | - | - | - | CatchablePetIds synced | Pets synced | - | - | - | Lost pet section | - |
| **Notifications** | - | Prompts care | - | - | - | - | - | - | - | - | Streak at risk | - | Runaway warnings | - |
| **Watch Sync** | Receives run data | - | - | - | - | Sends catchablePetIds | - | - | - | - | - | - | - | Sends hasEncounterCharm |
| **Cloud** | Run history synced | - | - | - | Coins synced | Pets merged | - | - | - | UID required | - | - | - | LOCAL always wins (BUG) |
| **Auth** | - | - | - | - | - | - | - | - | Gates all ops | - | - | - | - | - |
| **Streak** | Updated on run | - | - | XP bonus up to +10% | - | - | Streak at risk notif | - | Synced | - | - | - | - | Streak freeze protects |
| **Shop** | - | Provides food/water | - | - | Costs coins | - | - | - | Via save() | - | - | - | Provides hibernation | Provides boosts |
| **Runaway** | - | - | Triggered by sad days | - | Rescue costs | Moves pet to lost | Warning notifications | - | Via save() | - | - | - | - | Hibernation prevents |
| **Boosts** | Charm/coin consumed | XP boost on care | - | XP boost +30% | - | Charm +3% catch | - | Charm state synced | LOCAL always wins | - | Freeze protects | Purchased | Hibernation prevents | - |

---

## 4. Instrumentation Strategy

### Events to Track

| Event | Properties | Purpose |
|-------|-----------|---------|
| `app_opened` | source (notification/direct/widget), day_since_install | DAU, notification effectiveness |
| `onboarding_step_completed` | step_number, step_name, time_spent_seconds | Drop-off analysis |
| `onboarding_completed` | total_time_seconds, starter_pet_chosen | Completion rate |
| `run_started` | day_since_install, runs_total, is_first_run | Run adoption |
| `run_completed` | duration, distance, sprints, coins, xp, pet_caught | Run quality |
| `sprint_triggered` | time_since_run_start, sprint_number | Encounter pacing |
| `sprint_completed` | passed, score, hr_score, cadence_score | Validation tuning |
| `pet_caught` | pet_id, run_number, sprints_since_last_catch | Catch rate reality |
| `pet_catch_missed` | pet_id, sprints_since_last_catch | Near-miss tracking |
| `care_action` | type, mood_before, mood_after, time_of_day | Care engagement |
| `shop_purchase` | item_id, cost, coins_remaining | Economy health |
| `evolution_triggered` | pet_id, from_stage, to_stage, days_since_catch | Progression pacing |
| `pet_ran_away` | pet_id, days_sad, days_no_interaction | Loss events |
| `pet_rescued` | pet_id, cost | Recovery rate |
| `boost_activated` | boost_type, cost | Boost popularity |
| `notification_opened` | notification_type, hours_since_sent | Notification ROI |
| `streak_broken` | streak_length, days_since_last_run | Streak fragility |
| `streak_milestone` | streak_length | Milestone tracking |
| `session_duration` | seconds, screens_visited | Engagement depth |
| `tab_switched` | from_tab, to_tab | Navigation patterns |
| `pet_equipped` | pet_id, previous_pet_id | Pet preference |
| `app_backgrounded` | session_duration, last_screen | Session analysis |

### Key Derived Metrics
- D1/D7/D30 retention (% users returning)
- FTUE completion rate
- Run adoption rate (% completing first run on Day 1)
- Care engagement rate (% performing 1+ care/day)
- Actual catch rate vs. theoretical
- Average streak length before break
- Economy health (average coin balance trajectory)
- Session depth (screens/session, time/session)
- Notification conversion (% leading to app open within 1 hour)

### Implementation Approach
- Extend existing `TelemetryLogger.swift` from DEBUG-only to production logging
- Events saved to local JSON file per session
- Upload to Firestore `analytics` collection on cloud sync
- No third-party SDK (privacy, simplicity)

---

## 5. Sound & Haptics Inventory

### Current State: ZERO sound effects

| Context | iOS Haptic | Watch Haptic | Sound | Gap |
|---------|-----------|-------------|-------|-----|
| Sprint start (Watch) | - | `.start` | None | Need |
| Sprint end success | - | `.success` | None | Need |
| Sprint end fail | - | `.failure` | None | Need |
| Pet catch | `playPetCatch()` (custom pattern) | `.notification` | None | Critical |
| Evolution | `playEvolution()` (custom pattern) | - | None | Critical |
| Feed pet | `playLight()` | - | None | Need |
| Water pet | `playLight()` | - | None | Need |
| Pet (rub) | `playLight()` | - | None | Need |
| Shop purchase | `playSuccess()` | - | None | Need |
| Coin earned | - | - | None | Need |
| Level up | - | - | None | Need |
| App open | - | - | None | Nice-to-have |
| Streak milestone | - | - | None | Need |
| Error/insufficient | `playError()` | - | None | Minor |
| Tab switch | `playSelection()` | - | None | OK |

### Recommended Sound Design
- Character: warm, organic, cute -- wooden xylophone, soft bells, gentle chimes
- Audience: 16-30 female -- not 8-bit, not aggressive, not childish
- Priority: pet catch jingle, evolution fanfare, care chime, coin clink, XP ding
- Must work on silent mode (haptics as fallback)

---

## 6. Performance Considerations

| Area | Current State | Risk |
|------|--------------|------|
| UserDefaults size | Full UserData JSON including 50 run histories | Medium -- could grow large |
| Cloud sync frequency | Every `save()` triggers `syncToCloud()` | High -- rapid care actions = 3 writes/second |
| Image loading | 30 imagesets (10 pets x 3 stages) via asset catalog | Low -- iOS handles lazy loading |
| Watch memory | WatchRunManager holds all HR/distance samples in memory | Medium for long runs |
| Timer management | Multiple Timer instances in WatchRunManager | Medium -- verify proper invalidation |
| HealthKit queries | Continuous during runs | Low -- standard HealthKit pattern |
| Animations | Pet float + hearts + XP labels simultaneously | Low -- simple SwiftUI animations |
| Collection grid | LazyVGrid with 10 items | Low |
| Evolution animation | Fullscreen confetti + 3D rotation | Low-Medium -- GPU intensive but brief |

---

## 7. Accessibility Status

| Check | Status | Notes |
|-------|--------|-------|
| Image accessibility labels | Unknown | PetImageView may lack labels |
| Button accessibility hints | Unknown | Care buttons need verification |
| Color contrast (WCAG AA) | Likely passes | textPrimary #2D2A26 on background #FFF8F0 |
| VoiceOver support | Unknown | Drag-and-drop care may not work |
| Dynamic Type | Unknown | SF Rounded should scale |
| Reduce Motion | Partial | EvolutionAnimationView respects it |
| Tap targets (44x44pt) | Unknown | Care buttons need verification |
| Color-only info | Partial | Mood uses icon + text + color |

---

*End of System Audit*
