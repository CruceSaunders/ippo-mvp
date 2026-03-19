# Watch-Phone Communication Audit
## Ippo iOS/watchOS App — Swarm C Report

---

## 1. MESSAGE SCHEMA TABLE

Every WCSession message type with sender, receiver, fields, types, and nil handling.

| Message Type | Direction | Sender Encodes | Receiver Decodes | Nil/Missing Handling | Notes |
|--------------|-----------|----------------|------------------|----------------------|-------|
| **profileSync** | Phone → Watch | `type`: String, `estimatedMaxHR`: Int | `type` as? String, `estimatedMaxHR` as? Int | `maxHR > 0` check before applying | **STALE**: Only maxHR sent; no pet name/image/mood |
| **hapticBuzz** | Phone → Watch | `type`: String | `type` as? String | Guard returns if type nil | No payload |
| **syncRequest** | Watch → Phone | `type`: String | `type` as? String | ReplyHandler path only if type == "syncRequest" | Requires reply |
| **syncRequest response** | Phone → Watch | `status`, `estimatedMaxHR`, `ownedPetIds`, `catchablePetIds`, `hasEncounterCharm`, `sprintsSinceLastCatch`, `equippedPetName`, `equippedPetImageName`, `equippedPetMood`, `equippedPetLevel`, `equippedPetStageName` (all optional except status/estimatedMaxHR) | Each field cast with `as?` | Missing fields leave Watch state unchanged (stale) | `equippedPet*` only if `userData.equippedPet != nil` |
| **runEnded** | Watch → Phone | `type`, `durationSeconds`, `distanceMeters`, `sprintsCompleted`, `sprintsTotal`, `coinsEarned`, `xpEarned`, `averageHR`, `totalCalories`, `petCaughtId?`, `sprintsSinceLastCatch` | Each with `?? 0` or `as? String` | Safe defaults | Phone ignores `sprintsTotal`, `averageHR`, `totalCalories` |

### Field-by-Field Details

**profileSync (Phone → Watch)**
| Field | Sender Type | Receiver Type | Missing/Nil |
|-------|-------------|---------------|-------------|
| type | String | String | Guard returns |
| estimatedMaxHR | Int | Int | Ignored if ≤ 0 |

**runEnded (Watch → Phone)**
| Field | Sender Type | Receiver Type | Missing/Nil |
|-------|-------------|---------------|-------------|
| type | String | String | Must be "runEnded" |
| durationSeconds | Int | Int | → 0 |
| distanceMeters | Double | Double | → 0 |
| sprintsCompleted | Int | Int | → 0 |
| sprintsTotal | Int | — | Not decoded |
| coinsEarned | Int | Int | → 0 |
| xpEarned | Int | Int | → 0 |
| averageHR | Int | — | Not decoded |
| totalCalories | Double | — | Not decoded |
| petCaughtId | String? | String? | nil |
| sprintsSinceLastCatch | Int | Int | Optional apply |

**syncRequest response (Phone → Watch)**
| Field | Sender Type | Receiver Type | Missing/Nil |
|-------|-------------|---------------|-------------|
| status | String | — | — |
| estimatedMaxHR | Int | Int | Ignored if ≤ 0 |
| ownedPetIds | [String] | [String] | → [] (unchanged) |
| catchablePetIds | [String] | [String] | → [] (unchanged) |
| hasEncounterCharm | Bool | Bool | Unchanged |
| sprintsSinceLastCatch | Int | Int | Unchanged |
| equippedPetName | String? | String? | Unchanged |
| equippedPetImageName | String? | String? | Unchanged |
| equippedPetMood | Int? | Int? | Unchanged |
| equippedPetLevel | Int? | Int? | Unchanged |
| equippedPetStageName | String? | String? | Unchanged |

### randomElement() on catchablePetIds

**Answer: Does NOT crash.**

```swift
// WatchRunManager.selectRandomUnownedPet()
let available = connectivity.catchablePetIds.filter { !connectivity.ownedPetIds.contains($0) }
return available.randomElement()
```

- `[].randomElement()` returns `nil` in Swift.
- `selectRandomUnownedPet()` returns `String?`; caller handles `nil` (no catch).
- If `catchablePetIds` is empty (e.g. Watch never synced), `available` is empty → `nil` → no crash.

---

## 2. SYNC STATE MATRIX

Behavior in each phone/watch state combination.

| Phone State | Watch State | Behavior |
|-------------|-------------|----------|
| **Foreground** | **Foreground** | Normal. `session.isReachable` true. sendMessage works. requestSync gets reply. |
| **Background** | **Foreground** | Phone may be suspended. WCSession can still deliver messages when app is backgrounded; delivery is best-effort. Run summary may be delayed until phone wakes. |
| **Killed** | **Running** | **DANGEROUS**. Phone process is dead. Watch's `sendMessage` for runEnded requires reachable counterpart. If phone is killed, Watch is NOT reachable. `sendRunSummary` returns early (`guard session.isReachable`). **Run summary is LOST.** No applicationContext/transferUserInfo fallback. |
| **Watch sends runEnded, phone unreachable** | — | `session.sendMessage` fails or times out. Watch's errorHandler logs "Failed to send run summary". **Data is lost.** No retry, no queue. |
| **Watch requests sync, phone unreachable** | — | **BUG-010**. `requestSync()` has `guard session.isReachable else { return }`. Watch returns immediately without sending. No fallback. User runs with stale data (wrong maxHR, wrong catchable list, wrong equipped pet). |
| **Phone pushes profile, Watch unreachable** | — | `pushProfileToWatch()` has `guard session.isReachable else { return }`. Returns silently. Watch never gets update. |

### WCSession Reachability

- `sendMessage` requires the counterpart to be reachable (in memory, foreground or recently active).
- No `applicationContext` or `transferUserInfo` is used; all communication is `sendMessage` only.
- When unreachable: senders bail out, no queuing.

---

## 3. DATA FRESHNESS TABLE

After each phone action, does the Watch get notified?

| Phone Action | Push/Sync Called? | What's Sent | Watch Updated? | Stale? |
|--------------|------------------|-------------|----------------|--------|
| **equipPet** | `pushProfileToWatch()` | `estimatedMaxHR` only | maxHR only | **YES** — Pet name, image, mood, level, stage NOT pushed |
| **buyBoost (encounter charm)** | None | — | — | **YES** — `hasEncounterCharm` NOT pushed until next syncRequest |
| **Pet evolves** | None | — | — | **YES** — New stage/image NOT pushed |
| **rescuePet** | None | — | — | **NO** — Rescue doesn't change catch logic; equipped pet unchanged |
| **Pet runs away** | `pushProfileToWatch()` | `estimatedMaxHR` only | maxHR only | **YES** — ownedPetIds, equipped pet not pushed |
| **Login / app foreground** | None (no explicit sync) | — | — | Watch must call `requestSync` on activation |

### pushProfileToWatch Limitation

```swift
// WatchConnectivityService.pushProfileToWatch()
session.sendMessage(["type": "profileSync", "estimatedMaxHR": maxHR], ...)
```

Only `estimatedMaxHR` is sent. Equipped pet name, image, mood, level, stage are **never** pushed via profileSync. The Watch gets those only from `syncRequest` response.

---

## 4. RUN SUMMARY DELIVERY PATH

End-to-end trace from Watch `endRun()` to phone processing.

### 4.1 Watch: endRun()

1. Stops timers, ends workout session.
2. Builds `WatchRunSummary`:
   - `durationSeconds`: Int(elapsedTime)
   - `distanceMeters`: from `readFinalDistance()` (HealthKit or currentDistance)
   - `sprintsCompleted`, `sprintsTotal`: from run state
   - `coinsEarned`, `xpEarned`: from accumulators
   - `averageHR`: from allHRSamples
   - `totalCalories`: from `readFinalCalories()`
   - `petCaughtId`: optional
   - `sprintsSinceLastCatch`: from run state

2. Calls `WatchConnectivityServiceWatch.shared.sendRunSummary(runSummary!)`

### 4.2 Watch: sendRunSummary()

1. **Simulator**: Returns early, no send.
2. **Device**: `guard session.isReachable else { return }` — if phone unreachable, **silently drops**.
3. Builds payload:
   ```swift
   ["type": "runEnded", "durationSeconds": ..., "distanceMeters": ..., "sprintsCompleted": ..., "sprintsTotal": ..., "coinsEarned": ..., "xpEarned": ..., "averageHR": ..., "totalCalories": ..., "petCaughtId"?: ..., "sprintsSinceLastCatch": ...]
   ```
4. `session.sendMessage(payload, replyHandler: nil, errorHandler: {...})`

### 4.3 Phone: didReceiveMessage

1. `WatchConnectivityService.session(_:didReceiveMessage:)` receives message.
2. Checks `message["type"] as? String == "runEnded"` → calls `handleRunSummary(message)`.
3. Sets `lastSyncDate = Date()`.

### 4.4 Phone: handleRunSummary

1. Parses:
   - `durationSeconds` as? Int ?? 0
   - `distanceMeters` as? Double ?? 0
   - `sprintsCompleted` as? Int ?? 0
   - `coinsEarned` as? Int ?? 0
   - `xpEarned` as? Int ?? 0
   - `petCaughtId` as? String
   - `sprintsSinceLastCatch` as? Int (optional apply)

2. Creates `CompletedRun(id: UUID(), date: Date(), ...)` — new ID each time.

3. `userData.completeRun(run)`:
   - Inserts into runHistory
   - Updates profile (totalRuns, duration, distance)
   - If sprintsCompleted >= 1: adds coins, XP, updates streak
   - Consumes per-run boosts

4. If `petCaughtId`: `userData.addPet(definitionId: petId)`

5. If `sprintsSinceLastCatch`: updates profile, saves

6. `userData.pendingRunSummary = run` → triggers PostRunSummaryView

### 4.5 Idempotency

**Not idempotent.** If the same run summary is delivered twice (e.g. retry, duplicate delivery):

- Two `CompletedRun` entries in runHistory
- Coins and XP applied twice
- `addPet` is idempotent (checks `!ownedPets.contains`)
- `pendingRunSummary` overwritten; user may see summary twice

No run ID or checksum is used to deduplicate.

### 4.6 Edge Cases: 0 Sprints, Negative, NaN

| Case | Handling |
|------|----------|
| **0 sprints** | `sprintsCompleted` = 0. `completeRun` treats as invalidated run: no coins/XP, no streak update. Run still added to history. |
| **Negative values** | No validation. Negative duration/distance/coins/XP would be stored and applied. |
| **NaN** | `as? Double` can yield `Double.nan`. Would be stored in CompletedRun. `isFinite` not checked. |
| **Nil numeric fields** | Default to 0 via `?? 0`. |

---

## 5. isFirstRunEver Logic (BUG)

```swift
// WatchRunManager.completeSprint()
let isFirstRunEver = WatchConnectivityServiceWatch.shared.ownedPetIds.count <= 1 && !didCatchPet
```

**Problem:** With 3 starters, `ownedPetIds` = `["pet_01", "pet_02", "pet_03"]` after sync. So `ownedPetIds.count` = 3.

- `3 <= 1` is false.
- `isFirstRunEver` is always false with 3 starters.

**Intended behavior:** Guarantee a catch on the user’s first run (only starters, no prior catches).

**Fix:** Use starter count, e.g.:

```swift
let starterCount = 3  // or GameData.starterPetIds.count
let isFirstRunEver = WatchConnectivityServiceWatch.shared.ownedPetIds.count <= starterCount && !didCatchPet
```

Or define “first run” as “no catchable pets owned yet”:

```swift
let hasOnlyStarters = WatchConnectivityServiceWatch.shared.ownedPetIds.isSubset(of: Set(GameData.petDefinitions.filter(\.isStarter).map(\.id)))
let isFirstRunEver = hasOnlyStarters && !didCatchPet
```

---

## 6. BUGS FOUND

| ID | Severity | Description |
|----|----------|-------------|
| **BUG-001** | High | `pushProfileToWatch` sends only `estimatedMaxHR`. Equipped pet name, image, mood, level, stage never pushed. Watch shows stale pet until next syncRequest. |
| **BUG-002** | High | Run summary lost when phone is killed. `sendMessage` requires reachability; no applicationContext/transferUserInfo. |
| **BUG-003** | High | Run summary lost when phone unreachable. Watch returns early, logs error, no retry. |
| **BUG-010** | High | `requestSync` returns early when phone unreachable. Watch runs with stale data. |
| **BUG-004** | Medium | `buyItem(encounterCharm)` does not push `hasEncounterCharm` to Watch. User may run without charm benefit. |
| **BUG-005** | Medium | Pet evolution does not push new stage/image to Watch. |
| **BUG-006** | Medium | Run summary processing is not idempotent. Duplicate delivery doubles coins/XP and run history. |
| **BUG-007** | Medium | `isFirstRunEver` broken with 3 starters (`ownedPetIds.count <= 1` never true). First-run guaranteed catch never triggers. |
| **BUG-008** | Low | No validation for negative or NaN in run summary. |
| **BUG-009** | Low | Phone ignores `sprintsTotal`, `averageHR`, `totalCalories` from run summary. |

---

## 7. CONFIDENCE

**85%**

- Message schema and sync flow: **95%** (from direct code inspection).
- State matrix: **80%** (WCSession behavior inferred from docs and patterns; not tested).
- Data freshness: **90%** (all call sites for `pushProfileToWatch` and `buyItem` checked).
- Run summary path: **95%**.
- isFirstRunEver: **100%** (logic error is clear).

---

## Recommendations

1. **pushProfileToWatch**: Include full equipped pet data (name, image, mood, level, stage) in profileSync.
2. **Run summary delivery**: Use `transferUserInfo` or `updateApplicationContext` for run summary when `sendMessage` fails or counterpart is unreachable.
3. **requestSync fallback**: When unreachable, retry on a timer or on next activation; consider caching last known good state.
4. **buyItem(encounterCharm)**: Call `pushProfileToWatch` or add a dedicated `inventorySync` message.
5. **Pet evolution**: Push updated equipped pet data after evolution.
6. **Idempotency**: Add a run ID (e.g. from Watch) and skip processing if already seen.
7. **isFirstRunEver**: Change condition to account for 3 starters (e.g. `<= 3` or “only starters”).
