# Ippo v3 -- User Journey Map

*Generated: March 17, 2026*
*Maps the complete user experience from first open through Month 3+*

---

## Day 1: First Open

### Second 0-10 (App Launch)
- **Current:** App launches, checks onboarding flag, shows `IppoCompleteOnboardingFlow`
- **User Feeling:** Curiosity, slight impatience
- **Problem:** Launch screen is the default Xcode splash -- doesn't set tone
- **Opportunity:** Animated launch with a pet peeking in, sets warm/playful tone immediately

### Minute 0-1 (Welcome + How It Works)
- **Current:** Welcome screen with pawprint icon + "Welcome to Ippo", then 3 how-it-works items
- **User Feeling:** Learning, evaluating whether to continue
- **Problem:** Pawprint icon is generic. 3 items is fine but text-heavy
- **Opportunity:** Replace pawprint with an animated pet character. Show the core loop in a 5-second animation (run -> catch -> care -> evolve) instead of text

### Minute 1-2 (Starter Selection)
- **Current:** 3 starter pets in cards. Tap to select, orange border highlights
- **User Feeling:** Excitement -- first real engagement point
- **Problem:** Cards show image + name + description but no personality. Choice feels arbitrary
- **Opportunity:** Add personality tagline ("Lumira: Playful and adventurous"). Let user name their pet for emotional investment. Make selection feel momentous with a reveal animation

### Minute 2-3 (Auth + Username + Age)
- **Current:** Apple/Google Sign-In, then username input, then age picker (3 separate screens)
- **User Feeling:** Friction -- "let me just use the app"
- **Problem:** 3 screens for account setup before the user has experienced any value
- **Opportunity:** Combine into 1 screen (sign-in button + age input). Defer username to later

### Minute 3-4 (Permissions)
- **Current:** HealthKit permission screen, then notification permission screen
- **User Feeling:** Annoyance -- "why do you need this?"
- **Problem:** Asking for permissions before the user understands why they're needed
- **Research:** Apps that defer permissions to point-of-need see 30-50% higher grant rates
- **Opportunity:** Defer HealthKit to first run attempt. Defer notifications to after first care action

### Minute 4-5 (Watch Setup + Sprint Demo + Tutorials)
- **Current:** Watch pairing check, sprint demo (phone vibrations), chase explanation, coins/XP explanation, care tutorial (TutorialOverlayView), evolution explanation
- **User Feeling:** "When can I actually USE the app?"
- **Problem:** Sprint demo on phone is abstract without a Watch. Care tutorial teaches before user cares about outcomes. 6 tutorial screens in a row is exhausting
- **Opportunity:** Skip ALL of these. Let users learn by doing. Show tooltips contextually instead

### Minute 5-6 (Ready Screen + Home)
- **Current:** "[Pet] is excited to meet you!" then lands on Home screen
- **User Feeling:** Relief (finally done), mild excitement
- **Problem:** Home screen has no clear next action. Pet just sits there
- **Opportunity:** "Go for your first run!" banner prominently displayed with explanation

### Minute 6-10 (First Exploration)
- **Current:** User explores Home (care buttons, XP bar, coins, streak), may check Collection and Shop tabs
- **User Feeling:** Novelty, but fading quickly
- **Problem:** Feeding a pet you just got doesn't feel meaningful. No emotional bond yet
- **Problem:** Shop has items but user doesn't understand why they'd need them
- **Opportunity:** First feeding reaction is MORE dramatic than normal (pet does a special happy dance). Don't show shop until user actually needs something

### Minute 10-30 (IF User Runs)
- **Current:** Switch to Watch, start run, encounters happen after 60s warmup, sprint 25-40s, validation, catch roll at 8%
- **User Feeling:** Excitement during sprint, anticipation during catch roll
- **Problem:** 78% chance of NO catch on a 3-sprint run. Most likely first run outcome: coins + XP + no pet
- **Critical:** This is the make-or-break moment. An unrewarding first run = dramatic D2 drop
- **Opportunity:** GUARANTEE a catch on first valid sprint of first run. Bonus coins. Special "first run" celebration

### Hour 1-4 (Post-Run or Post-Onboarding)
- **If ran:** Post-run summary shown. Maybe caught a pet. Returns to Home
- **If didn't run:** App closed. Pet sits on Home screen alone
- **Problem:** No "come back tonight" hook. No reason to open app again today
- **Opportunity:** Schedule notification 4-6 hours after onboarding: "Lumira is exploring their new home! Come check on them"

### Hour 4-24 (Rest of Day 1)
- **If notification received:** User opens app, feeds pet (30 seconds), leaves
- **If no notification:** App may be forgotten
- **Problem:** 30-second care session isn't enough to build habit
- **Opportunity:** Pet has "settling in" animation only on Day 1 evening. First-day-only content creates unique experience

---

## Day 2: Critical Return

### Morning
- **Current:** No trigger to open app in the morning
- **User Feeling:** May have forgotten app exists overnight
- **Problem:** Care notification scheduled for 2-6pm. Nothing prompts morning engagement
- **Opportunity:** Day 2 ONLY: "Good morning! Lumira is ready for a new day" notification at 8-9am
- **Opportunity:** Pet has "morning" state (stretching, yawning) only visible in first few hours

### Afternoon (2-6pm)
- **Current:** Care notification fires. User opens app, feeds/waters/pets (30 seconds)
- **User Feeling:** "Oh right, this app." Slight guilt if pet mood dropped
- **Problem:** Same experience as Day 1 evening. No new content
- **Opportunity:** Day 2 unlocks something: pet personality text appears in PetDetailView, or a new tooltip about the shop

### Evening
- **Current:** Nothing. No reason to open app again
- **Problem:** No second engagement opportunity
- **Opportunity:** "Bedtime" pet animation (pet yawns, curls up). Brief, delightful, creates "checking in" habit

---

## Day 3: Habit Formation Window

### Current Experience
- Repeat: notification -> open -> care (30 seconds) -> close
- Maybe second run on Watch
- Streak counter shows 2 or 3

### Problems
- No progression visible. No milestones. First evolution is weeks away
- Streak counter at 2-3 is not motivating
- No new content, no surprises, no reason to stay in app past care

### Opportunities
- **3-day streak celebration:** Toast: "3-day streak! Lumira is getting attached to you!" with special pet reaction
- **Micro-milestone:** "Fed your pet 5 times!" achievement-style toast
- **If user ran on Day 1-3:** Should be approaching first evolution IF we lower the threshold to level 5-7
- **First evolution = massive retention hook:** User sees their pet transform. This is the moment that converts casual users to committed ones

---

## Day 4-7: Week 1

### Current Experience
- Repeat daily care + occasional runs
- Level slowly increasing (probably 3-5 by end of week)
- Maybe caught 1 additional pet from running
- Coins accumulating (probably 50-150 depending on runs)

### Problems
- Evolution is the only "big moment" and at current XP rates it's 3-9 weeks away
- No intermediate rewards between evolutions
- No weekly summary or reflection
- Care becomes mechanical, not emotional

### Opportunities
- **Day 7: "1-week streak!" celebration** with special pet reaction (party hat?)
- **First evolution MUST happen this week** (requires lowering threshold to level 5-7)
- **Weekly summary card:** "This week: 3 runs, 150 coins, Lumira grew to level 5!" -- shows progress
- **Level-up mini-celebrations** at levels 5 and 10 with visual pet changes
- **Progressive disclosure:** Shop boosts revealed one at a time as user encounters them organically
- **If caught a second pet:** Collection completion counter becomes visible, drives desire

---

## Week 2-4: Building Investment

### Current Experience
- More runs, more care. Maybe second evolution
- 1-2 caught pets. Collection at 4-5/10
- Economy stabilizing (2-3 runs/week = ~75-125 coins)
- Streak at 10-20 if consistent

### Problems
- Content runs out. Same screens, same interactions, same loop
- Shop boosts feel expensive relative to their value
- No end-game visibility for experienced pets

### Opportunities
- **Pet personality evolves with stage** (new dialogue, new animations)
- **Caught pets bring variety** (each species has different personality)
- **Monthly challenge:** "Run 10 times this month for a special reward"
- **Streak milestones at 14 and 30 days** with meaningful celebrations
- **Bond meter:** "Days together: 15" counter creates attachment

---

## Month 1-3: Collection Drive

### Current Experience
- Approaching collection completion (7 catchable x ~4 runs each = ~28 runs = ~9 weeks at 3/week)
- Pets at various evolution stages
- Daily care is routine
- Economy likely has surplus coins (hardcore runners)

### Problems
- 10 total pets is a small collection. End-game arrives relatively fast
- Max evolution leaves nothing to progress toward
- No content refresh mechanism
- Hardcore runners may have coin inflation (nothing to spend on)

### Opportunities
- **Plan for pet roster expansion** (seasonal drops, limited events)
- **End-game cosmetics:** Pet accessories, habitat decorations, background themes
- **"Legendary" variants** of existing pets (shiny, seasonal colors)
- **Collection completion celebration** when all 10 caught
- **New coin sinks** for veteran players (cosmetics, habitats)

---

## Month 3+: Retention Challenge

### Current Experience
- Collection likely complete
- All pets at high evolution
- Daily care is autopilot
- No new content

### Problems
- Nothing new to earn = potential churn point
- No social features to provide external motivation
- No competitive element
- App becomes "obligation" not "delight"

### Opportunities
- **Social features** (friends, pet comparison, running groups)
- **Seasonal events** (holiday pets, time-limited challenges)
- **Leaderboards** (weekly/monthly running distance)
- **New pet species drops** (quarterly content updates)
- **User-generated challenges or goals**
- **Instagram share cards** for organic user acquisition
- **Achievement system** with display badges in profile

---

## Critical Path Analysis

### Path to First "Wow Moment" (currently)
```
Install -> 15 onboarding screens (~5 min) -> Home -> ??? -> Run -> Maybe catch (22%)
Total time to wow: 20-30 minutes. 78% chance of no wow.
```

### Optimized Path (recommended)
```
Install -> 5 screens (~2 min) -> Home -> "Go Run!" CTA -> Run -> GUARANTEED catch
Total time to wow: 15-20 minutes. 100% chance of wow.
```

### Path to First Evolution (currently)
```
~19-60 days depending on activity level
```

### Optimized Path (recommended)
```
5-7 days for regular runners (lower threshold to level 5-7)
```

### Path to Collection Completion (currently)
```
~2-3 months at 3 runs/week. Reasonable. Keep as-is.
```

---

## User Emotion Map

| Time | Emotion | Driver | Risk |
|------|---------|--------|------|
| First open | Curiosity | New app | Drop-off if onboarding too long |
| Starter pick | Excitement | Cute pets | Quickly fades if nothing follows |
| First care | Mild interest | New mechanic | Feels meaningless without bond |
| First run | Excitement/anxiety | Sprint system | Disappointment if no catch |
| First catch | JOY | Marquee feature | Must happen first run |
| First evolution | DELIGHT | Visual transformation | Must happen week 1 |
| Day 7 streak | Pride | Consistency reward | Must feel earned |
| Pet sad | Guilt | Loss aversion | Must not feel punitive |
| Pet runaway | Panic/anger | Consequence | Must be recoverable |
| Collection complete | Satisfaction | Completionism | Must have "what's next" |

---

*End of User Journey Map*
