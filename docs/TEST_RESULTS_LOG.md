# Ippo v3 -- Test Results Log

*Created: March 18, 2026*

---

## Phase 1: Deep Static Analysis (Completed)

### Swarm A: Data Integrity & State Management

| Test ID | Test Description | Result | Confidence | Notes |
|---|---|---|---|---|
| A-1.1 | Every @Published mutation calls save() | PASS | 95% | All mutations go through save(); addPetXP is private, callers save |
| A-1.2 | Mood-affecting mutations call recalculateMood() | FAIL | 100% | completeRun() updates lastRunDate but never recalculates mood (NEW-002) |
| A-1.3 | Watch-relevant changes call pushProfileToWatch() | PARTIAL | 90% | equipPet and checkRunaway push; addPet and rescuePet do NOT |
| A-2.1 | Persistence round-trip for PlayerProfile | PASS | 80% | Auto-synthesis; risk if new fields added without defaults |
| A-2.2 | Persistence round-trip for OwnedPet | FAIL | 90% | consecutiveSadDays and isLost use decode() not decodeIfPresent() (NEW-019) |
| A-2.3 | Persistence round-trip for PlayerInventory | PASS | 80% | Auto-synthesis; same forward-compat risk |
| A-3.1 | Cloud merge - coins not dupeable | PASS | 95% | Coins taken from winning profile, not summed |
| A-3.2 | Cloud merge - activeBoosts | FAIL | 100% | Local always wins, cloud boosts dropped (BUG-006) |
| A-3.3 | Cloud merge - ownedPets union | PARTIAL | 85% | Union works but isEquipped can be inconsistent (NEW-008) |
| A-4.1 | MainActor safety | PASS | 95% | All access paths via @MainActor; WCSession delegates dispatch correctly |
| A-5.1 | Pattern-based bug prediction | PASS | 70% | No N-1 patterns found beyond already-fixed BUG-001 |

### Swarm B: Cross-System Cascade Analysis

| Test ID | Test Description | Result | Confidence | Notes |
|---|---|---|---|---|
| B-1.1 | Feed cascade complete | PASS | 95% | All effects traced, nothing missing |
| B-1.2 | Water cascade complete | PASS | 95% | Same as feed |
| B-1.3 | Pet (rub) cascade complete | PASS | 95% | No inventory cost, less XP |
| B-1.4 | Run completion cascade | FAIL | 90% | Mood not recalculated after run (NEW-002) |
| B-1.5 | Catch cascade complete | PASS | 90% | Via run summary delivery |
| B-1.6 | Equip cascade complete | PASS | 95% | Push to Watch works |
| B-1.7 | Buy food cascade | PASS | 95% | Simple and correct |
| B-1.8 | Buy XP boost cascade | PASS | 90% | Boost added correctly |
| B-1.9 | App open after absence | FAIL | 85% | Mood not recalculated before checkRunaway (NEW-001) |
| B-1.10 | Pet runaway cascade | FAIL | 80% | notifyPetRanAway never called (NEW-007) |
| B-1.11 | Rescue cascade | PASS | 90% | Watch not pushed but low impact |
| B-1.12 | Evolution cascade | PASS | 95% | PendingEvolution set correctly |
| B-2.1 | Coins reverse mapping | PASS | 95% | Cannot go negative |
| B-2.2 | Mood reverse mapping | FAIL | 85% | Missing recalc points |
| B-2.3 | Streak reverse mapping | PASS | 90% | Freeze/hibernation checked |
| B-3.1 | Dead code detection | PASS | 90% | Found 15+ orphan functions/files |
| B-4.1 | Config consistency | PARTIAL | 85% | Sprint duration mismatch iOS vs Watch |

### Swarm C: Watch-Phone Communication

| Test ID | Test Description | Result | Confidence | Notes |
|---|---|---|---|---|
| C-1.1 | Message schema validation | PASS | 90% | All fields have safe defaults |
| C-2.1 | Sync state machine | FAIL | 80% | Run summary lost when phone unreachable (NEW-004) |
| C-3.1 | Data freshness after equip | FAIL | 85% | Only maxHR pushed, not pet data (NEW-003) |
| C-3.2 | Data freshness after charm purchase | FAIL | 80% | Charm not pushed to Watch (NEW-009) |
| C-4.1 | Run summary delivery path | PARTIAL | 85% | Works but not idempotent (NEW-005) |
| C-5.1 | isFirstRunEver logic | FAIL | 100% | Always false with 3 starters (NEW-006) |

### Swarm D: UI Completeness & Error States

| Test ID | Test Description | Result | Confidence | Notes |
|---|---|---|---|---|
| D-1.1 | HomeView state coverage | PASS | 85% | All major states handled |
| D-1.2 | CollectionView state coverage | PARTIAL | 80% | Missing 0-owned edge case (NEW-020) |
| D-1.3 | ShopView state coverage | PASS | 90% | Handles 0 coins |
| D-1.4 | OnboardingFlow state coverage | PASS | 85% | Handles auth failure |
| D-2.1 | Navigation flow audit | PASS | 90% | No dead ends found |
| D-3.1 | Timer lifecycle audit | FAIL | 100% | Sleep/FloatingZ timers leak (NEW-010/011) |
| D-3.2 | OnboardingFlow timer lifecycle | FAIL | 90% | Sprint demo timer not cleaned (NEW-018) |
| D-4.1 | ShopView vs ShopSheet comparison | PASS | 100% | ShopSheet is dead code (NEW-012) |
| D-5.1 | Accessibility audit | FAIL | 70% | Multiple missing labels |

---

*End of Test Results Log*
