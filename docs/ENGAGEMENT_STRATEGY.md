# Ippo v3 -- Engagement Strategy

*Generated: March 17, 2026*
*Backed by: Game Design Research, Competitive Analysis, User Journey Map, Economy Analysis*

---

## Executive Summary

Three critical findings demand immediate action:

1. **First run has 78% chance of NO pet catch.** The marquee feature probably won't happen during a user's first experience. Fix: guarantee first-run catch.

2. **First evolution takes 19-60 days.** The biggest reward is weeks away. Fix: lower threshold so evolution happens in Week 1.

3. **Onboarding has 15 steps.** Industry data shows ~79% drop-off. Fix: reduce to 5 screens.

These three changes alone could dramatically improve D1 and D7 retention.

---

## Day 1 Optimization

### Goals
- User bonds with pet within 5 minutes
- User understands core loop within 10 minutes
- User experiences a pet catch on first run (if they run)
- User has reason to return tomorrow

### Specific Changes

**1. Reduce onboarding to 5 screens** (MD-13)
Current: 15 steps. Target: 5 screens.
- Screen 1: Welcome with animated pet
- Screen 2: Core concept (one screen)
- Screen 3: Choose starter (emotional hook)
- Screen 4: Sign in + age (one screen)
- Screen 5: Pet greeting + done
- Defer: HealthKit (to first run), notifications (to first care), Watch setup (to Watch app), sprint demo (to first run), care tutorial (to first care need), evolution (to first approach)

**2. First-run guaranteed catch** (MD-01)
- If `profile.totalRuns == 0`, set catch rate to 100% on first valid sprint
- Implementation: in `WatchRunManager`, check `totalRuns` from sync data
- After first catch, revert to standard 8% rate

**3. "Go for a run!" CTA on Home** (MD-18)
- Show prominent banner on Home after onboarding: "Go for your first run! Open the Watch app to start."
- Auto-hide after first run is completed
- Include brief explanation: "Sprint when your Watch vibrates to catch new pets!"

**4. Post-onboarding notification** (new)
- Schedule notification 4-6 hours after onboarding completion
- Copy: "Lumira is exploring their new home! Come check on them."
- Deep-links to Home screen

**5. First care reaction is special** (M-16 enhanced)
- First-ever feeding triggers a unique "wow" reaction: pet does a happy dance, extra-large hearts, sparkle effect
- Only on first care action ever (not first daily)
- Creates a memorable moment

### Expected Impact
- FTUE completion: 21% -> 50%+ (fewer screens)
- First-run satisfaction: 22% -> 100% catch rate
- D1 return: baseline -> +15-20% (notification + catch hook)

---

## Day 2-3 Optimization

### Goals
- User returns Day 2 (care habit begins)
- User feels progress (not stagnation)
- Streak begins to matter
- New content reveals prevent boredom

### Specific Changes

**6. Pet greets user on app open** (M-16)
- Every app open: pet does a happy bounce + hearts animation
- First open of each day: special "good morning" or "welcome back" variant
- Implementation: check `lastOpenDate` in `ContentView.onAppear`

**7. Day 2 morning notification** (new, one-time)
- 8-9am Day 2 only: "Good morning! Lumira is ready for a new day!"
- Creates morning engagement moment
- Only fires once (Day 2 after install)

**8. Micro-milestone toasts** (MD-16)
- "First feeding!" -- toast on first-ever feed
- "5 runs completed!" -- toast at run milestone
- "3-day streak!" -- special celebration
- Implementation: milestone tracker in UserData, toast system on HomeView

**9. Streak visual on Home** (MD-03)
- Weekly dot calendar (M T W T F S S) below XP bar
- Filled dots for active days
- Reuse existing `WeeklyProgressDots` component (currently unused)

**10. Progressive shop discovery** (new)
- Don't show full shop on Day 1
- Day 1-2: only Food and Water visible
- Day 3-4: after running, Boosts section appears
- Week 2: after first evolution approaches, Protection section appears
- Implementation: feature flags based on `daysSinceInstall` and activity milestones

### Expected Impact
- D2 return: baseline -> +10-15% (morning notification + greeting + milestones)
- D3 return: baseline -> +8-12% (streak momentum + micro-milestones)

---

## Week 1 Optimization

### Goals
- First evolution happens (biggest reward)
- User has caught 1-2 additional pets
- Streak reaches 7 days with celebration
- User understands the full loop

### Specific Changes

**11. Lower first evolution threshold** (MD-15)
- Current: level 14-18 (1000-2000+ XP). Takes 19-60 days.
- Target: level 5-7 (46-127 XP). Takes 3-7 days.
- Adjust per-pet thresholds: Baby->Teen at level 5-7, Teen->Adult at level 14-18
- This means SECOND evolution is where the current first one is -- preserving long-term pacing

**12. Streak milestone celebrations** (MD-02)
- Day 3: Toast: "3-day streak! Keep it going!"
- Day 7: Card popup: "1-week streak! Lumira is getting attached to you!" with special pet animation
- Day 14: Card popup with confetti
- Day 30: Full-screen celebration

**13. Weekly summary card** (new)
- Every 7 days, show a summary card on Home: "This week: X runs, Y coins, Lumira grew Z levels!"
- Auto-appears on first open of the new week
- Sharable as image (foundation for share card feature)

**14. First-run bonus rewards** (MD-14)
- Double coins and XP on first run (if `totalRuns == 0`)
- Shows "First Run Bonus!" label on post-run summary
- Creates extra excitement and progression boost

### Expected Impact
- D7 return: baseline -> +15-25% (evolution hook + streak milestone + summary)
- First evolution within Week 1 is the single most impactful retention change

---

## Month 1 Optimization

### Goals
- Collection growing (3-5 pets)
- Multiple evolutions seen
- Daily care is habitual
- Economy is sustainable

### Specific Changes

**15. Collection completion counter** (MD-06)
- Show "3/10 Pets" progress bar on CollectionView header
- Creates visible goal and drives desire

**16. Pet personality text** (MD-17)
- Add personality field to GamePetDefinition
- Show in PetDetailView: "Lumira: Playful and adventurous. Loves morning runs."
- Each pet feels unique, driving collection motivation

**17. Bond-level indicator** (new)
- Show "Days Together: 15" on PetDetailView
- Creates emotional attachment to specific pets
- Higher bond could unlock subtle visual changes (future)

**18. Notification copy personalization** (MD-12)
- Use pet name: "Lumira is hungry!" not "Your pet needs feeding"
- Reference streak: "7-day streak -- don't break it!"
- Post-run: "Lumira gained 45 XP from your run!"
- Absence: "Mossworth misses you... he's been waiting by the door."

### Expected Impact
- D30 return: baseline -> +5-8% (collection drive + personality + personalized notifications)

---

## Economy Rebalancing

### Problem
Very casual runners (1x/week) cannot sustain daily care costs (35 coins/week > 30-36 coins income).

### Recommended Fix Options (pick one or combine)

**Option A: Daily free food + water**
- Give 1 free food + 1 free water per day (costs 0 coins)
- Purchased food/water become "extras" for missed days or multiple pets
- Impact: removes care cost entirely for one pet

**Option B: Daily login coin bonus**
- 5 coins per day just for opening the app
- Weekly: 35 coins = exactly covers care costs
- Impact: ensures even non-runners can care for their pet

**Option C: Reduce care costs**
- Food: 3 -> 1 coin. Water: 2 -> 1 coin
- Daily cost drops from 5 to 2 coins (14/week)
- Impact: 1 run/week covers care easily

**Recommendation: Option A** (daily free food + water). This:
- Eliminates the death spiral for casual users
- Preserves spending incentive (bulk packs, boosts)
- Creates daily login reason (collect free items)
- Mirrors Duolingo's free hearts mechanic

---

## XP Curve Rebalancing

### Problem
First evolution at level 14-18 takes 19-60 days. Should happen in Week 1.

### Recommended Approach
Add a third evolution stage by splitting the curve:

| Stage | Name | Level | Approx Days (Regular) |
|-------|------|-------|----------------------|
| 1 | Baby | 1 | Day 1 (start) |
| 2 | Teen | 5-7 | Day 3-5 (Week 1) |
| 3 | Adult | 14-18 | Day 15-25 (Week 3-4) |

This means:
- Lower Baby->Teen threshold from ~1250 XP to ~46-127 XP
- Keep Teen->Adult at current levels
- First evolution is fast and exciting
- Second evolution remains a meaningful long-term goal

---

## Catch Rate Optimization

### Problem
8% flat rate = 78% chance of no catch on first run.

### Recommended Approach
1. **First run:** 100% catch on first valid sprint
2. **Soft pity after sprint 10:** catch rate ramps from 8% to 40% at sprint 14, 100% at 15
3. **Near-miss feedback:** "A wild Bramble appeared! ...but it got away!" on failed catch rolls (builds desire)

---

## Implementation Priority

### Must-Do (before next test build)
1. Fix BUG-001 (mood ignores watering) -- 30 min
2. Fix BUG-003 (debug logging) -- 15 min
3. Fix BUG-004 (delete account stuck) -- 30 min
4. First-run guaranteed catch -- 2 hours
5. Lower first evolution threshold -- 1 hour

### Should-Do (next sprint)
6. Reduce onboarding to 5-8 screens -- 4 hours
7. Streak milestone celebrations -- 2 hours
8. Pet greets on app open -- 1 hour
9. "Go Run!" CTA for new users -- 1 hour
10. Micro-milestone toasts -- 3 hours

### Nice-to-Have (following sprint)
11. Sound effects (6-8 core sounds) -- 4 hours
12. Weekly summary card -- 3 hours
13. Collection completion counter -- 1 hour
14. Notification copy personalization -- 2 hours
15. Economy rebalancing (daily free food/water) -- 2 hours

---

## Changes Catalog (Full)

### Minor Changes (< 1 hour each): 19 items

| ID | Change | Impact |
|----|--------|--------|
| M-01 | Fix mood to include watering | Core bug fix |
| M-02 | Remove debug logging | Production safety |
| M-03 | Fix delete account dismiss | UX bug fix |
| M-04 | Push profile to Watch on equip/age | Data freshness |
| M-05 | Deduplicate syncFromCloud | Performance |
| M-06 | Streak freeze indicator | Feature visibility |
| M-07 | Coin boost indicator | Feature visibility |
| M-08 | Align encounter charm cost | Economy consistency |
| M-09 | 8pt spacing grid | Visual polish |
| M-10 | Consistent card shadows | Visual polish |
| M-11 | PetImageView accessibility labels | Accessibility |
| M-12 | MoodIndicator accessibility labels | Accessibility |
| M-13 | Remove unused RewardsConfig | Code cleanup |
| M-14 | Update spec (3 stages, not 10) | Documentation |
| M-15 | Remove unused config values | Code cleanup |
| M-16 | Pet greets on app open | Engagement |
| M-17 | Larger care button targets | Accessibility + UX |
| M-18 | PetDetailView empty state | Completeness |
| M-19 | Cloud sync loading state | Completeness |

### Medium Changes (1-4 hours each): 18 items

| ID | Change | Impact |
|----|--------|--------|
| MD-01 | First-run guaranteed catch | D1 retention |
| MD-02 | Streak milestone celebrations | D7 retention |
| MD-03 | Weekly streak calendar on Home | Daily engagement |
| MD-04 | Pet idle animation variety | Emotional bond |
| MD-05 | Enhanced post-run summary | Run satisfaction |
| MD-06 | Collection completion counter | Collection drive |
| MD-07 | Production runaway warnings | Pet safety |
| MD-08 | Smart cloud merge for boosts | Multi-device |
| MD-09 | Username Firestore transaction | Data integrity |
| MD-10 | Watch sync retry | Reliability |
| MD-11 | Event instrumentation | Measurement |
| MD-12 | Notification personalization | Engagement |
| MD-13 | Onboarding reduction (15->5-8) | FTUE completion |
| MD-14 | First-run bonus rewards | D1 excitement |
| MD-15 | XP curve rebalancing | Week 1 evolution |
| MD-16 | Micro-milestone toasts | Progression feel |
| MD-17 | Pet personality text | Emotional depth |
| MD-18 | "Go Run!" CTA for new users | First-run conversion |

### Major Changes (4+ hours each): 10 items

| ID | Change | Impact |
|----|--------|--------|
| MJ-01 | Sound effects system | Engagement + polish |
| MJ-02 | Living home environment | Emotional bond |
| MJ-03 | Autonomous pet behavior | Pet feels alive |
| MJ-04 | Instagram share cards | Viral growth |
| MJ-05 | Tiered celebration system | Reward satisfaction |
| MJ-06 | Achievement/badge system | Progression variety |
| MJ-07 | Daily login reward system | Daily retention |
| MJ-08 | Remove dead code | Code health |
| MJ-09 | Full accessibility pass | Inclusion + App Store |
| MJ-10 | Analytics dashboard | Decision making |

---

*End of Engagement Strategy*
