# Ippo v3 -- Game Design Research

*Generated: March 17, 2026*
*Sources: Web research across retention benchmarks, game design theory, competitive analysis, UX/UI research*

---

## 1. Retention Benchmarks

### Industry Standards (Mobile Games)

| Metric | Average | Good | Excellent | Top 1% |
|--------|---------|------|-----------|--------|
| Day 1 | 25-30% | 30-35% | 40%+ | 64-68% |
| Day 7 | 10-13% | 15% | 20%+ | 25%+ |
| Day 30 | 5-6% | 7-10% | 10%+ | 13-15% |

### Fitness Apps Specifically
- D1: 20%, D7: 7%, D30: 3.5-4%
- 80% of fitness app users churn within 90 days
- iOS retains significantly better: D1 35.7% vs Android 27.5%

### Target Benchmarks for Ippo

| Metric | Conservative | Stretch | Rationale |
|--------|-------------|---------|-----------|
| D1 | 30% | 40% | Pet emotional hook compensates for fitness baseline |
| D7 | 12% | 18% | Daily care habit + early evolution visibility |
| D30 | 6% | 10% | Collection drive + deep pet bond |

**Key insight:** D1 is driven by FTUE quality. D7 is about habit formation. D30 is about depth and emotional investment. Ippo needs to nail all three.

---

## 2. Variable-Ratio Reinforcement & Catch Mechanics

### Theory
Variable ratio (VR) schedules produce the highest and most consistent response rates of all reinforcement schedules. Dopamine release happens during *anticipation* of reward, not the reward itself.

### Ippo's Current System Analysis

**Catch rate:** 8% per valid sprint = 1 in 12.5 sprints expected per catch
**Pity timer:** Guaranteed catch at 15 sprints
**Players hitting pity:** (0.92)^15 = 28.6% -- close to the ~30% guideline from gacha design

**Problem:** 78% chance of no catch on a typical 3-sprint run. First-run users are very likely to experience the marquee feature (catching) zero times.

### Recommended Improvements

**Soft pity system** (from gacha best practices):
- Sprints 1-10: 8% base rate
- Sprint 11: 12%
- Sprint 12: 18%
- Sprint 13: 26%
- Sprint 14: 40%
- Sprint 15: 100% (hard pity)

**First-run guarantee:** 100% catch rate on first valid sprint of first run. Delivers the "aha moment" immediately.

**Multi-layer VR:** Add micro-VR within runs -- rare coin bonuses (2x on ~10% of sprints), bonus XP bursts. Multiple layers of anticipation.

**Near-miss mechanic:** Show "A wild [pet] appeared!" then "...but it got away!" on failed catch rolls. Builds desire and confirms the mechanic exists.

---

## 3. First-Time User Experience (FTUE)

### Research Findings
- 38% of users abandon after the first screen alone
- Each additional onboarding screen loses ~20% of remaining users
- 3-step onboarding: 72% completion. 7-step: 16% completion
- Users who complete onboarding are 3x more likely to become paying users
- 70% of users skip traditional onboarding flows entirely
- First reward should happen within 90 seconds

### Ippo's Current State
15-step onboarding. At 20% drop-off per screen, estimated completion: ~21%.

### Recommended Flow (5 screens)
1. **Welcome** -- Animated pet greeting + value prop ("Your running buddy")
2. **Core concept** -- "Run to catch, care daily" (one combined screen)
3. **Choose starter** -- Interactive pet selection (emotional hook = first reward)
4. **Sign in + age** -- Minimal friction (2 fields, 1 screen)
5. **First pet greeting** -- Pet appears, optional naming, done

**Defer to later:**
- HealthKit permission -> first time user taps "Start Run"
- Notification permission -> after first care action
- Watch setup -> when user navigates to Watch app
- Sprint demo -> during first actual run
- Care tutorial -> first time pet needs care
- Evolution explanation -> when evolution approaches

---

## 4. Streak System Design (Duolingo Research)

### Key Statistics
- 9+ million Duolingo users maintain year-plus streaks
- Users who reach 7-day streak are 2.4x more likely to continue the next day
- Lowering the bar to maintain a streak (1 lesson counts) increased 7+ day streaks by 40% and D14 retention by 3.3%
- Duolingo has run 600+ experiments on streaks alone
- iOS widget displaying streak increased commitment by 60%

### Best Practices
- Streak maintenance should be the LOWEST-FRICTION action possible
- Streak's job is to get users to OPEN the app, not force a full session
- Visible but not punitive -- show what streaks EARN, not what breaking COSTS
- "Earn Back" mechanic: if you miss a day, restore by completing extra the next day

### Application to Ippo
- **Care streak** (not run streak): requires just ONE care action per day
- **Weekly cycles**: reset weekly, preventing catastrophic 100-day streak loss
- **Streak milestones** with celebrations: Day 3, 7, 14, 30
- **Earn-back**: if user misses a day, double-care the next day restores it
- **Widget**: iOS Lock Screen widget showing streak count + pet mood

---

## 5. Loss Aversion & Consequences

### Theory
- Losses feel 2x as powerful as equivalent gains (Kahneman & Tversky)
- Breaking a long streak can cause permanent disengagement
- Permanent loss (pet death) is the harshest possible consequence -- risk of rage-quit + 1-star reviews

### Ippo's Current Runaway System
- 14 consecutive sad days + 14 days no interaction = runaway
- Pet is "lost" -- can be rescued for coins
- This is fairly lenient (28 total day-equivalents of neglect)

### Recommendations
- **Replace "ran away" language with "wandered off"** -- softer, less permanent feeling
- **Graduated warnings:** Day 3 neglect: notification. Day 7: pet visibly sad. Day 10: "thinking about leaving." Day 14: wandered off
- **Never delete progress:** Lost pets keep their XP/evolution when rescued
- **Grace periods for new users:** First 7 days of play should have no mood decay (learning phase)
- **Recovery should feel achievable:** 3 runs within a week to bring pet home (not just coins)

---

## 6. Daily Login Rewards

### Research
- Almost all top mobile games implement daily login rewards
- Escalating 7-day calendars with big Day 7 payoff drive the most engagement
- Rewards should be connected to gameplay (food for pet, not abstract gems)
- Returning player bonuses reduce re-entry friction after absence

### Recommended for Ippo
- **Reframe as "daily care bonus"**: opening app + caring = reward
- **Weekly cycle**: Day 1-6: 5 bonus coins per care. Day 7: 25 coins + random treat
- **First-login-of-day animation**: pet greets user (bounce + hearts)
- **Welcome-back package** after 3+ day absence: free food + water + bonus coins
- **Don't make login the ONLY reason to open**: gateway to engagement, not the engagement

---

## 7. Pet Simulation Mechanics (Tamagotchi Research)

### Core Engagement Principles
1. Multiple interconnected needs (hunger, happiness, hygiene)
2. Meaningful but reversible consequences
3. Evolution through care quality (different patterns = different forms)
4. Minimal but deep (3 buttons = deep engagement)
5. Real-time needs (pet exists independently of you)
6. 3-5 distinct care actions is the sweet spot

### Ippo Assessment
Currently 3 care actions (feed, water, pet). This is at the lower end of the sweet spot.

### Recommendations
- **Keep current 3**: Feed, Water, Pet -- each one-tap, distinct
- **Consider 4th**: Play (quick mini-interaction, 10 seconds) for variety
- **Care quality should affect evolution**: high mood average = special visual variants
- **One random notification per day**: random type creates "real creature" feeling
- **Don't over-simulate**: no hygiene, sleep schedules, or discipline. Care complements running, doesn't replace it.

---

## 8. Self-Determination Theory (SDT)

### Three Basic Needs

| Need | Status in Ippo | Strength |
|------|---------------|----------|
| **Autonomy** (choice and control) | Strong -- pet choice, run timing, spend priorities | Good |
| **Competence** (mastery and achievement) | Strong -- sprint feedback, evolution, XP progression | Good |
| **Relatedness** (connection and belonging) | Weak -- pet bond only, no social features | Needs work |

### Key Warning from SDT Research
Feature bloat kills motivation. Gamification has an S-shaped relationship with exercise adherence -- moderate features improve it, but excessive features decrease it. Ippo's current simplicity (run + catch + care + evolve) is a FEATURE, not a gap. Resist adding too many systems.

### Relatedness Improvements (without social features)
- Pet emotional responses: excited on app open, celebrates after runs, sad when neglected
- Pet "personality moments": random animations that surprise the user
- Even passive social proof helps: "14,000 runners caught a pet today"

---

## 9. Economy Analysis

### Detailed Math by User Persona

| Persona | Runs/Week | Coins/Week | Daily Care Cost | Weekly Balance | Verdict |
|---------|-----------|-----------|----------------|---------------|---------|
| Hardcore (5 runs) | 350-450 | 35 | +315 to +415 | Surplus -- needs sinks |
| Regular (3 runs) | 135-175 | 35 | +100 to +140 | Comfortable |
| Casual (2 runs) | 60-72 | 35 | +25 to +37 | Barely sustainable |
| Very Casual (1 run) | 30-36 | 35 | -5 to +1 | DEFICIT |
| Non-runner (0 runs) | 0 | 35 | -35 | CANNOT sustain |

**CRITICAL FINDING:** Very casual and non-runners enter a death spiral: no coins -> no food -> pet gets sad -> slower XP -> less motivation -> churn.

### Evolution Pacing (at current rates)

| Persona | Daily XP (avg) | Days to Level 15 | Assessment |
|---------|---------------|-------------------|-----------|
| Hardcore | 67 | 19 days | Too slow |
| Regular | 38 | 33 days | WAY too slow |
| Casual | 29 | 43 days | Unacceptable |
| Very Casual | 21 | 60 days | Two months |

**CRITICAL FINDING:** First evolution takes 3-9 weeks. Should happen in Week 1 (5-7 days).

### Recommendations
- Lower first evolution threshold: level 15 -> level 5-7
- Add passive XP income (5 XP/min during runs -- already defined, not implemented)
- Provide daily free food+water (1 each) or remove food/water cost entirely
- Front-load XP gains for first 3 days
- Add daily login coin bonus (5 coins)

### Boost ROI Analysis

| Boost | Cost | Expected Value | ROI |
|-------|------|---------------|-----|
| XP Boost | 40 | +18-23 XP/run | Low (XP ≠ coins) |
| Encounter Charm | 25 | 0.75 expected coins | Terrible |
| Coin Boost | 30 | +12-14 coins/run | Negative for casuals |
| Hibernation | 80 | Prevents runaway | High if needed |
| Streak Freeze | 50 | Protects streak | High for streak users |

**Encounter charm and coin boost should be cheaper or more powerful.**

---

## 10. Notification Strategy

### Research
- 88% higher engagement with strategic notifications
- 43% higher uninstall with too many
- 60% of users disable after one irrelevant message
- 2-4 per week maximum. 60% abandon with 5+ weekly
- 6-8 PM is golden engagement window
- Don't ask for permission on first launch

### Ippo's Current System (Good Foundation)
- One care notification per day (2-6pm, random type)
- Run reminder after 3 days
- Runaway warnings (not implemented in production)

### Enhancements
- **Personalize with pet name**: "Lumira is feeling peckish!" not "Your pet needs feeding"
- **Streak protection**: "7-day streak -- don't break it!"
- **Post-run celebration**: "Lumira gained 45 XP from your run!"
- **Absence re-engagement** (day 3-5): "Mossworth misses you..."
- **Delay permission request** until after first care action or first run
- **Actionable buttons**: "Feed" directly from notification (iOS rich notifications)

---

## 11. Sound Design Impact

### Research
- 50%+ of mobile gamers play with sound on
- LTV increases ~10% with professional sound design
- D1 retention +2%, average session +60 seconds from A/B tests
- Poor audio causes permanent muting

### Priority Sounds for Ippo
1. Pet catch jingle (dramatic reveal)
2. Evolution fanfare (musical crescendo, 3-5s)
3. Care action chimes (satisfying crunch for food, splash for water, purr for pet)
4. Coin collection clink
5. XP gain ding
6. Sprint countdown ticking
7. Ambient pet sounds on HomeView (soft breathing, occasional chirps)

**Character:** Warm, organic, cute. Wooden xylophone, soft bells, gentle chimes. Match the cream/amber palette. NOT 8-bit, NOT aggressive, NOT childish.

---

## 12. Celebration Design

### Best Practices
- Quick burst: 1.5-3s for minor rewards
- Extended: 3-5s for major milestones
- Multimodal: visual + haptic + sound together = "magical"
- Sync sound with peak visual moment
- 50-100 particles for mobile (auto-reduce on older devices)

### Recommended Tiers for Ippo

| Tier | Trigger | Duration | Elements |
|------|---------|----------|----------|
| 1. Subtle | Care action | 0.5s | Single heart float + light haptic + soft chime |
| 2. Small | Streak milestone | 2s | Toast banner + medium haptic + streak sound |
| 3. Medium | Run complete | 2s | Confetti burst + pet animation + coin fly-in |
| 4. Major | Pet catch | 3-5s | Dramatic reveal + particle explosion + fanfare |
| 5. Epic | Evolution | 5-8s | Full-screen transformation + crescendo music |

---

## 13. Competitive Feature Matrix

| Feature | Strava | NRC | Duolingo | Pokemon Go | Zombies Run | **Ippo Now** | **Ippo Target** |
|---------|--------|-----|----------|-----------|-------------|-------------|----------------|
| Streaks | No | Yes | Yes | Yes | No | No | **Yes** |
| Social | Yes | Yes | Yes | Yes | No | No | No (v1) |
| Sharing | Yes | Yes | Yes | Yes | No | No | **Yes** |
| Audio | No | Yes | No | No | Yes | No | No (v1) |
| Celebrations | Minimal | Yes | Yes | Yes | No | Partial | **Yes** |
| Collection | No | Yes | No | Yes | Yes | Yes | Yes |
| Daily rewards | No | No | Yes | Yes | No | No | **Yes** |
| Sound effects | Minimal | Yes | Yes | Yes | Yes | No | **Yes** |
| Haptics | No | Minimal | Minimal | Yes | No | Partial | **Yes** |
| Post-activity | Yes | Yes | Yes | No | Yes | Yes | Yes (enhanced) |
| Notifications | Yes | Yes | Yes | Yes | Minimal | Yes | Yes (enhanced) |
| Achievements | Yes | Yes | Yes | Yes | Yes | No | **Yes** |
| Pet/Character | No | No | Yes | Yes | No | Yes | Yes |
| Loss mechanic | No | No | Yes | No | No | Yes | Yes |

---

## 14. Hook Model Analysis (Nir Eyal)

### Ippo's Current Hooks

**Care Hook:**
```
TRIGGER: "Lumira is hungry!" notification (2-4pm)
→ ACTION: Open app, tap Feed (2 seconds)
→ VARIABLE REWARD: Care streak +1, bonus coins, pet happy animation
→ INVESTMENT: Pet mood improves, XP multiplier increases, streak grows
```

**Run Hook:**
```
TRIGGER: Internal desire to run + pet anticipation
→ ACTION: Start Watch run, sprint when prompted (15-30 min)
→ VARIABLE REWARD: Random pet catch (8%), coin variation
→ INVESTMENT: New pet in collection, XP toward evolution, coins for shop
```

### Current Gap: No Tribe Rewards
Social validation is absent. Even passive social proof ("14,000 runners caught a pet today") would strengthen the hook loop.

---

## 15. Progressive Disclosure Strategy

### Research
- 77% of users abandon within 3 days -- progressive disclosure combats this
- 3-step tours: 72% completion. 7-step: 16%

### Recommended Timeline for Ippo

| Time | Reveal |
|------|--------|
| Day 1 | Home (pet + care only). Collection exists but secondary |
| Day 1 first run | Sprint mechanic via Watch. Keep simple |
| Day 2-3 | Shop introduction ("Your pet is hungry -- here's where to buy food") |
| Day 3-5 | Collection view highlight + equipping mechanic |
| Week 2 | Evolution timeline detail view |
| After first evolution | Advanced mechanics (boosts, hibernation) |

**Never show the full feature set on Day 1.** Let the pet relationship drive discovery.

---

*End of Game Design Research*
