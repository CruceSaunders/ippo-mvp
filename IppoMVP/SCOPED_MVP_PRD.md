# Ippo Scoped-Down MVP PRD

**Version:** 3.0 (Super-Scoped MVP)
**Date:** February 2026
**Status:** In Development

---

## Overview

This is the most minimal version of the Ippo running app. The core loop is: run with Apple Watch, encounter random sprint challenges, earn RP (Reputation Point) Boxes, open them for RP, climb ranks, and compete with friends on weekly leaderboards.

**Removed from previous MVP:** Pets, pet evolution, ability trees, coins, gems, shop, achievements, challenges, daily rewards, pet food, XP boosts.

**Kept:** Full Watch sprint encounter system, sprint validation (HR + cadence), RP earning, rank progression, XP/leveling, daily streak.

**New:** Friends system, groups with weekly leaderboards, RP decay, rank divisions.

---

## Core Features

### 1. Watch App (Sprint Encounters)
- **Start Run** -> random encounters during run
- **First vibration** = sprint challenge started (30-45 seconds)
- Sprint validation via HR increase + cadence (60% threshold)
- **Second vibration** = chase over (success or fail)
- Valid sprint = 1 RP Box earned
- Recovery period between encounters
- **End Run** -> summary shows RP Boxes earned, XP gained

### 2. RP Box System
- Each valid sprint earns exactly 1 RP Box
- Open on the phone app (1.5s animation delay)
- Each box yields 1-25 RP with weighted distribution:
  - Common (1-5 RP): 50% chance
  - Uncommon (6-10 RP): 25% chance
  - Rare (11-15 RP): 15% chance
  - Epic (16-20 RP): 7% chance
  - Legendary (21-25 RP): 3% chance

### 3. iOS App Structure (3 Tabs)

**Tab 1: Home**
- Profile header (name, level, rank tier, streak)
- Start run CTA (directs to Watch)
- RP Box opening section (open boxes, see results)
- Stats grid (runs, sprints, RP, streak)
- Level progress (1 XP per minute of running, cap at 100)
- RP / rank progress
- Recent runs

**Tab 2: Ranks**
- Current rank + division display (e.g., "Gold II")
- Progress to next rank
- RP decay information
- All 5 ranks x 3 divisions = 15 tiers listed

**Tab 3: Social**
- Friends list (add by username, accept requests)
- Groups (create, invite friends)
- Weekly leaderboard within groups (resets Monday)
- No chat feature

### 4. Rank System (5 Ranks x 3 Divisions)
- Bronze III/II/I (0-499 RP)
- Silver III/II/I (500-1999 RP)
- Gold III/II/I (2000-4999 RP)
- Platinum III/II/I (5000-11999 RP)
- Diamond III/II/I (12000+ RP)

### 5. RP Decay System
- Applied on app launch if user missed running
- Bronze: 0 decay (protected)
- Silver: 2-5 RP/day missed
- Gold: 5-10 RP/day missed
- Platinum: 10-15 RP/day missed
- Diamond: 15-25 RP/day missed

### 6. XP / Level System
- 1 XP per minute of running
- Level cap: 100
- Levels are cosmetic (no gameplay effect)

### 7. Daily Streak
- Run every day to maintain streak
- Streak breaks if you skip a day
- Streak displayed on profile

### 8. Friends & Groups
- Search users by username
- Send/accept friend requests
- Create groups, invite friends
- Weekly RP leaderboard per group (resets Monday)
- Push notification when friend completes a run (batched per run, not per box)

### 9. Authentication
- Apple Sign-In
- Google Sign-In (Firebase)
- Username creation during onboarding

---

## Technical Architecture

### iOS App
- SwiftUI with 3-tab TabView
- UserData singleton (ObservableObject)
- Local persistence via UserDefaults
- Firebase Firestore for cloud sync, friends, groups
- Firebase Auth for Apple/Google Sign-In
- Firebase Cloud Messaging for push notifications

### watchOS App
- HealthKit workout sessions
- HR + cadence sprint validation
- WatchConnectivity for syncing run data to phone
- States: idle -> running <-> sprinting -> summary

### Data Flow
- Watch: track run, validate sprints, count RP Boxes earned
- Watch -> Phone: send run summary via WatchConnectivity
- Phone: store run, add RP Boxes to inventory
- Phone: user opens RP Boxes for RP
- Phone -> Firestore: sync profile, friends, groups

---

## What Was Archived (Available in `_archived/`)

All removed features are preserved in `IppoMVP/_archived/` for future use:
- Pet system (10 pets, evolution, feeding, mood)
- Ability tree system (player + pet abilities)
- Shop (coins, gems, pet food, XP boosts)
- Achievements system
- Challenges system (weekly + monthly)
- Daily rewards system
- Associated views, types, configs, and tests
