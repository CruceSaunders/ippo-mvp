# Ippo v3 -- Future Considerations

*Generated: March 17, 2026*
*Living document for ideas, suggestions, and roadmap items beyond the current sprint*

---

## Already Implemented (This Session)

| Change | Impact | Status |
|--------|--------|--------|
| Mood includes watering (BUG-001) | Core bug fix | Done |
| First-run guaranteed catch | D1 retention +15-20% | Done |
| Soft pity system (increasing catch rates after sprint 10) | Better catch experience | Done |
| Lower first evolution to level 5-8 (from 14-18) | Week 1 evolution | Done |
| Daily free food + water + coins | Prevents casual user death spiral | Done |
| Welcome-back bonus (3+ day absence) | Re-engagement | Done |
| Pet personality text for all 10 pets | Emotional depth | Done |
| Push profile to Watch on equip | Data freshness | Done |
| Delete account dismisses properly | UX bug | Done |
| Debug logging removed from production | Security | Done |
| Double cloud sync removed | Performance | Done |
| Runaway warnings production scheduling | User safety | Done |
| Unused code cleaned (RewardsConfig, config values) | Code health | Done |

---

## High Priority -- Next Sprint

### 1. Onboarding Reduction (15 -> 6-8 steps)
**Research backing:** 3-step onboarding = 72% completion. 15 steps = ~21% completion. Each screen loses ~20%.
**Proposed flow:**
1. Welcome with animated pet
2. Choose starter pet (emotional hook = first reward)
3. Sign in + age (combined)
4. Permissions (combined HealthKit + notifications with "why" explanations)
5. Watch check (skippable)
6. First pet greeting + done

**Defer to point-of-need:** Sprint demo (to first run), care tutorial (to first care need), evolution (to first approach), coins/XP explanation (to first earning)

**Effort:** 4-6 hours
**Expected impact:** FTUE completion +30-50 percentage points

### 2. Streak Milestone Celebrations
**Research backing:** Duolingo users at 7-day streak are 2.4x more likely to continue.
**Implementation:**
- Day 3: Toast notification "3-day streak! Keep it going!"
- Day 7: Card popup with pet wearing a party hat animation
- Day 14: Larger celebration card
- Day 30: Full-screen celebration with confetti

**Effort:** 3 hours
**Expected impact:** D7 retention +10-15%

### 3. "Go for a Run!" CTA on Home
**Research backing:** Users need clear CTAs after onboarding. Current Home has no obvious next action.
**Implementation:** Show a prominent banner on Home when `totalRuns == 0`:
- "Go for your first run! Open the Watch app to start."
- Dismisses after first run is completed
- Includes brief "Sprint when your Watch vibrates to catch new pets!"

**Effort:** 1 hour
**Expected impact:** First-run conversion +20-30%

### 4. Sound Effects (Core Set)
**Research backing:** A/B tests show D1 retention +2%, session length +60s, LTV +10%.
**Priority sounds:**
1. Pet catch jingle (dramatic reveal)
2. Evolution fanfare (musical crescendo, 3-5 seconds)
3. Care chimes (soft crunch for food, splash for water, purr for pet)
4. Coin clink
5. XP gain ding

**Character:** Warm, organic, cute. Wooden xylophone, soft bells. NOT 8-bit.
**Effort:** 4-6 hours (sourcing + SoundManager)
**Expected impact:** D1 +2%, perceived polish dramatically higher

### 5. Collection Completion Counter
**Research backing:** Pokemon Go's Pokedex completion percentage drives behavior.
**Implementation:** Show "3/10 Pets Discovered" progress bar on CollectionView header.
**Effort:** 1 hour

---

## Medium Priority -- Following Sprint

### 6. Tiered Celebration System
Five tiers of celebration matched to achievement significance:
1. **Subtle** (care action): Heart float + light haptic. 0.5s
2. **Small** (streak milestone, level up): Toast banner + medium haptic. 2s
3. **Medium** (run complete): Confetti burst + pet animation + coin fly-in. 2s
4. **Major** (pet catch): Dramatic reveal + particle explosion + fanfare. 3-5s
5. **Epic** (evolution): Full-screen transformation + crescendo. 5-8s

### 7. Instagram Share Card Generator
Generate a 9:16 image with pet + run stats + streak + Ippo branding. One-tap share to Instagram Stories. This is the primary organic growth channel.

### 8. Living Home Screen Environment
Time-of-day gradient background (warm sunrise AM, golden afternoon, cool evening). Pet positioned "on ground" not floating. Subtle parallax.

### 9. Autonomous Pet Behavior
State machine: idle -> walking -> playing -> sleeping -> looking at user. Random transitions every 5-15 seconds. Pet feels alive even when you're not interacting.

### 10. Achievement/Badge System
10-15 initial achievements: First Run, First Catch, First Evolution, 7-Day Streak, 10 Runs, Full Collection, etc. Beautiful shareable badge images.

### 11. Micro-Milestone Toasts
"First feeding!", "5 runs completed!", "Level 10!", etc. Distributed throughout the experience to prevent reward droughts between evolutions.

### 12. Weekly Summary Card
Every 7 days, auto-present: "This week: X runs, Y coins, Lumira grew Z levels!" Shareable.

---

## Lower Priority -- Future Versions

### 13. Social Features
- Friend list with pet comparison
- "Kudos" on friends' runs (Strava-style, one-tap)
- Weekly leagues (Duolingo-style promotion/relegation)
- Pet "playdates" with friends' pets
- Passive social proof: "14,000 runners caught a pet today"

### 14. Seasonal Content
- Limited-time catchable pets (holiday variants, seasonal colors)
- Seasonal habitat decorations
- Time-limited challenges with exclusive rewards
- Monthly "featured pet" with boosted catch rate

### 15. Advanced Pet Features
- Pet accessories (hats, scarves, ribbons) -- coin sink for veterans
- Customizable habitats/home screens
- Branching evolution paths (care quality determines adult form)
- Pet trading between friends
- "Shiny" variants of existing pets (rare visual differences)

### 16. Monetization
- Light subscription ($2.99-4.99/mo) for bonus coins, exclusive pets, cosmetics
- Keep core gameplay free (NRC model proves free builds audiences)
- Gate cosmetics and extras, never core care items
- Coins remain the primary currency; premium currency optional

### 17. Apple Watch Complications & Widgets
- Lock Screen widget: pet mood + streak count
- Watch complication: pet face + next care reminder
- Research says iOS widgets increase commitment by 60% (Duolingo data)

### 18. Audio Coaching During Runs
- Brief pet-voiced motivational messages during runs
- Sprint encouragement: "Lumira believes in you! Sprint!"
- Post-sprint: "Great sprint! Lumira is impressed."
- Requires professional voice acting; defer until budget allows

### 19. Notification Enhancements
- Actionable buttons: "Feed" directly from notification (iOS rich notifications)
- Morning motivation (8-9am): pet says good morning (first week only)
- Streak protection: "7-day streak at risk!"
- Absence re-engagement (day 3-5): "Mossworth misses you..."
- Badge count on app icon for unresolved care needs

### 20. Progressive Disclosure
- Day 1: Home only (pet + care). Collection tab secondary
- Day 2-3: Shop introduced ("Your pet is hungry -- here's where to buy food")
- Day 3-5: Collection view highlighted + equipping mechanic
- Week 2: Evolution timeline detail
- After first evolution: Boosts and hibernation introduced

---

## Economy Ideas

### Daily Login Reward Calendar (Future Enhancement)
Currently implemented: flat daily bonus (1 food + 1 water + 5-10 coins).
Future: escalating weekly calendar:
- Day 1-6: 5 coins + 1 food + 1 water
- Day 7: 25 coins + 3 food + 3 water + random treat
- Resets weekly (not monthly -- prevents catastrophic loss)

### Returning Player Package
Currently implemented: 3+ days absence = 3 food + 3 water + 20 coins.
Future enhancement: scale with absence length:
- 3-6 days: small package (3+3+20)
- 7-13 days: medium package (5+5+50)
- 14+ days: large package (10+10+100) + "welcome back" pet animation

### Streak Repair Mechanic
If streak breaks, offer 24-hour window to "repair" by completing double activity (2 care actions + 1 run). Costs 25 coins. Duolingo's "Earn Back" mechanic improved D14 retention by 3.3%.

### Coin Sinks for Veterans
Players running 5x/week accumulate 350-450 coins/week with only 35/week care costs. Surplus creates meaninglessness. Future sinks:
- Pet accessories (50-200 coins each)
- Habitat themes (100-500 coins)
- Name change tokens (50 coins)
- "Gift" items for friends (future social)

---

## Research-Backed Design Principles to Follow

1. **Autonomy > Obligation**: Users choose when to run, which pet to equip, how to spend coins. Never mandate.
2. **First Win Fast**: Guaranteed catch on first run. Evolution in Week 1. Streak milestone at Day 3.
3. **Loss Aversion Lite**: Pet gets sad (reversible), not dead (permanent). 14-day grace period is right.
4. **Variable Rewards on Predictable Base**: Coins guaranteed every sprint. Catches are the variable surprise.
5. **Progressive Disclosure**: Don't overwhelm. Reveal features as users need them.
6. **Minimal but Deep**: 3 care actions, 3 evolution stages, 10 pets. Depth comes from combinations, not quantity.
7. **Sound Matters**: 10% LTV increase. Priority investment.
8. **Streaks Drive Opens, Not Sessions**: The streak's job is to get users to OPEN the app. The pet's job is to keep them there.

---

## Technical Debt to Address

| Item | Priority | Effort |
|------|----------|--------|
| Remove unused iOS engine files (SprintEngine, SprintValidator, EncounterManager) | Low | 30 min |
| Remove unused UI components (CelebrationModal, ProgressRing, etc.) or wire them in | Low | 30 min |
| Implement Firestore transaction for username reservation (BUG-009) | Medium | 1 hour |
| Add Watch sync retry with exponential backoff (BUG-010) | Medium | 1.5 hours |
| Smart cloud merge for boosts (BUG-006) | Medium | 1 hour |
| Debounce cloud sync (currently every `save()` triggers Firestore write) | Medium | 1 hour |
| Add instrumentation/analytics event logging | High | 3 hours |

---

*This document is a living roadmap. Update as features are implemented and new ideas emerge.*
