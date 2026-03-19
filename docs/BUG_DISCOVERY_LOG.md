# Ippo v3 -- Bug Discovery Log

*Created: March 18, 2026*
*Source: Comprehensive testing Phases 1-3*

---

## Consolidated Bug List (All Phases)

### From BUG_REPORT.md (Status Updates)

| Original ID | Description | Old Status | New Status | Evidence |
|---|---|---|---|---|
| BUG-001 | Mood ignores watering | Open | **FIXED** | UserData.swift:299-301 checks lastWateredDate |
| BUG-002 | pushProfileToWatch never called | Open | **FIXED** | Called at UserData.swift:109 and :337 |
| BUG-003 | CloudService debug logging in production | Open | **FIXED** | Uses print() now, no hardcoded paths |
| BUG-004 | DeleteAccountSheet doesn't dismiss | Open | **FIXED** | Calls dismiss() at ProfileView.swift:404 |
| BUG-005 | Double syncFromCloud on login | Open | **FIXED** | LoginView.onChange is empty (line 126-127) |
| BUG-006 | Cloud merge drops cloud boosts | Open | **CONFIRMED OPEN** | mergeData uses local activeBoosts only |
| BUG-007 | Encounter charm cost mismatch (25 vs 60) | Open | **CONFIRMED OPEN** | Code=25, Spec=60; code is correct for economy |
| BUG-008 | Runaway warnings not scheduled in production | Open | **FIXED** | scheduleRunawayWarning uses proper UNTimeIntervalNotificationTrigger |
| BUG-009 | Username race condition | Open | **CONFIRMED OPEN** | CloudService.swift:157-164, delete-then-create |
| BUG-010 | No Watch sync retry | Open | **CONFIRMED OPEN** | requestSync() returns early if !isReachable |
| BUG-011 | Spec says 10 stages, code has 3 | Open | **CONFIRMED OPEN** | Documentation debt |
| BUG-012 | Passive income defined but unused | Open | **CONFIRMED OPEN** | coinsPerMinuteRunning/xpPerMinuteRunning unused |
| BUG-013 | Streak freeze has no active indicator | Open | **CONFIRMED OPEN** | No UI banner in HomeView |
| BUG-014 | Coin boost has no active indicator | Open | **CONFIRMED OPEN** | No UI banner in HomeView |
| BUG-015 | Unused compiled components | Open | **CONFIRMED OPEN** | CelebrationModal, ProgressRing not used |
| BUG-016 | Unused iOS engine files | Open | **CONFIRMED OPEN** | SprintEngine, EncounterManager dead code |
| BUG-017 | RewardsConfig entirely unused | Open | **CONFIRMED OPEN** | Never referenced |

### NEW Bugs from Phase 1 Swarms

| ID | Severity | System | Description | Source | File/Line |
|---|---|---|---|---|---|
| NEW-001 | **HIGH** | Mood/Runaway | Mood not recalculated on app open. checkRunaway() uses mood but recalculateMood() is only called during care actions. After 3 days of neglect, mood stays at last value (could be 3/Happy), so runaway never triggers even though the pet should be sad. | Swarm B | UserData.swift checkRunaway / ContentView onAppear |
| NEW-002 | **HIGH** | Mood/Run | Mood not recalculated after run completion. completeRun() updates lastRunDate (a mood input) but never calls recalculateMood(). Mood stays stale until next care action. | Swarm B | UserData.swift completeRun() |
| NEW-003 | **HIGH** | Watch Sync | pushProfileToWatch() only sends estimatedMaxHR, not pet data. After equipping a different pet, Watch shows stale pet name/image/mood until Watch independently re-syncs (only on WCSession activation). | Swarm C | WatchConnectivityService.swift:32-42 |
| NEW-004 | **HIGH** | Watch Sync | Run summary can be lost when phone is unreachable. sendRunSummary uses sendMessage() which requires phone to be reachable. No fallback to transferUserInfo or applicationContext. Coins/XP/catch data permanently lost. | Swarm C | WatchConnectivityServiceWatch sendRunSummary |
| NEW-005 | **MEDIUM** | Watch Sync | Run summary not idempotent. If WCSession delivers the same message twice (unlikely but possible), completeRun() would double-count coins, XP, and add duplicate run history. No dedup by run ID. | Swarm C | UserData.swift completeRun |
| NEW-006 | **MEDIUM** | Watch | isFirstRunEver logic broken. Checks `ownedPetIds.count <= 1` but starters give 3 ownedPetIds. First-run guaranteed catch never triggers. | Swarm C | WatchRunManager.swift completeSprint |
| NEW-007 | **MEDIUM** | Notification | notifyPetRanAway() is never called. When a pet runs away in checkRunaway(), no notification is sent to the user. They only discover it by opening the app. | Swarm B | UserData.swift checkRunaway, NotificationSystem.swift |
| NEW-008 | **MEDIUM** | Cloud Merge | Multiple equipped pets after merge. If local has pet_01 equipped and cloud has pet_03 equipped, after merge both have isEquipped=true. equippedPet returns first match, but state is inconsistent. | Swarm A | CloudService.swift mergeData |
| NEW-009 | **MEDIUM** | Watch Sync | Encounter charm purchase not pushed to Watch. hasEncounterCharm on Watch stays stale until next sync. User buys charm before run but Watch doesn't know about it. | Swarm C | UserData buyItem / WatchConnectivityService |
| NEW-010 | **LOW** | UI/Timer | HomeView sleep timer never invalidated. startSleepAnimation() creates Timer.scheduledTimer that is never invalidated on view disappear. Tab switches can leak timers. | Swarm D | HomeView.swift startSleepAnimation |
| NEW-011 | **LOW** | UI/Timer | FloatingZ timers never invalidated. Similar to NEW-010, FloatingZ views create timers that persist. | Swarm D | HomeView.swift FloatingZ |
| NEW-012 | **LOW** | Dead Code | ShopSheet.swift is never used. Only ShopView is used in the app. | Swarm D | ShopSheet.swift |
| NEW-013 | **LOW** | Dead Code | Multiple unused config constants. PetConfig.baseCatchRate, pityTimerSprints, encounterCharmRate, runawayDaysAccelerated all unused (Watch uses hardcoded values). | Swarm B | PetConfig.swift |
| NEW-014 | **LOW** | Dead Code | NotificationSystem.notifyPetRanAway exists but is never called. | Swarm B | NotificationSystem.swift |
| NEW-015 | **LOW** | Dead Code | WatchConnectivityService.refreshStatus() never called. | Swarm B | WatchConnectivityService.swift |
| NEW-016 | **LOW** | Dead Code | TelemetryLogger.logSprint() and logRewards() never called. | Swarm B | TelemetryLogger.swift |
| NEW-017 | **LOW** | Config | Sprint duration mismatch: iOS SprintConfig 30-45s, Watch WatchSprintConfig 25-40s. iOS config unused but creates documentation confusion. | Swarm B | SprintConfig.swift vs WatchRunManager.swift |
| NEW-018 | **LOW** | Onboarding | Sprint demo timer in OnboardingFlow not invalidated on view disappear. | Swarm D | OnboardingFlow.swift |
| NEW-019 | **LOW** | Persistence | OwnedPet.consecutiveSadDays and .isLost use decode() not decodeIfPresent(). Old data without these keys could fail to decode. | Swarm A | PetTypes.swift |
| NEW-020 | **LOW** | UI | No explicit "You have no pets" empty state if all pets are lost AND 0 owned (edge case). | Swarm D | CollectionView.swift |

---

## Priority Summary

| Priority | Count | Description |
|---|---|---|
| P0 (blocks usage) | 0 | None |
| P1 (data loss/corruption) | 3 | NEW-001 (runaway logic wrong), NEW-004 (run summary lost), NEW-005 (duplicate run) |
| P2 (incorrect behavior) | 5 | NEW-002, NEW-003, NEW-006, NEW-007, NEW-008, NEW-009 |
| P3 (visual/polish) | 3 | BUG-013, BUG-014, NEW-010, NEW-011, NEW-020 |
| P4 (code quality/dead code) | 8 | BUG-015-017, NEW-012-018 |

---

*End of Bug Discovery Log*
