# AI Context Document for Ippo Development

**Last Updated:** January 4, 2026  
**Purpose:** Provide persistent context for AI assistants across chat sessions.

---

## 🔴 CRITICAL: Documentation Maintenance

**AI assistants MUST actively maintain project documentation WITH EVERY PROMPT.**

### MANDATORY Document Updates

**On EVERY conversation (no exceptions):**
1. **Update this context doc** with new learnings, user preferences, decisions made
2. **Update `mvp-requirements.md`** as tasks are completed (mark ✅ or ❌)
3. **Update `Supplementary_Systems_PRD.md`** when designing/implementing systems not in the 3 core PRDs

**When relevant:**
4. **Update `undefined-items.md`** when items get defined or new undefined items emerge
5. **Update `ui-development-plan.md`** as UI work progresses or plans change
6. **Update relevant core PRDs** when features are finalized (with user approval)

### The Four Core PRDs

| PRD | Purpose | Update When |
|-----|---------|-------------|
| `IEI_System_PRD.md` | IEI calculation engine | 🔒 LOCKED - Do not modify without explicit approval |
| `Real_Time_Chase_System_PRD.md` | Chase mechanics | 🔒 LOCKED - Do not modify without explicit approval |
| `Ippo Engine-Building Progression System (PRD).md` | RP, pets, loot, shop | When core economy changes |
| `Supplementary_Systems_PRD.md` | **Everything else** - Auth, Upgrades, Achievements, Onboarding, Settings, etc. | **Every time** you design or implement a system not in the other 3 PRDs |

### Why This Matters

- No knowledge gaps between chat sessions
- User and AI stay on the same page
- Project history is preserved
- Future AI assistants have full context
- A developer could recreate the entire app from these 4 PRDs

**Log everything the user says about:**
- Their preferences and working style
- Design decisions and rationale
- Technical choices
- Things that didn't work
- Future plans and ideas

### Enforcement

If this doc (AI-CONTEXT.md) is provided as context, the AI MUST:
1. Check if any documentation needs updating based on the conversation
2. Update relevant docs before or after completing the user's request
3. If uncertain whether to update, err on the side of updating

---

## 1. Project Overview

**Ippo** is an Apple Watch + iOS running game where real-world running effort drives gameplay. Users play a chase game while running (on Apple Watch) and manage their progression/inventory on their iPhone.

### Core Systems (Status)

| System | PRD | Status | Notes |
|--------|-----|--------|-------|
| **IEI (Instantaneous Effort Index)** | `docs/IEI_System_PRD.md` | ✅ Locked | Backend logic complete. Do not modify core math without explicit approval. |
| **Real-Time Chase System** | `docs/Real_Time_Chase_System_PRD.md` | ✅ Locked | VRR, segments, haptics, recovery all implemented. Do not modify without approval. |
| **Engine-Building Progression** | `docs/Ippo Engine-Building Progression System (PRD).md` | 🔄 Flexible | Needs ideation, definition, and iteration. AI should help design this. |

### Architecture

- **watchOS App:** Runs during workouts. Displays IEI/zone, delivers haptic instructions, tracks chase progress. Minimal UI—haptics-first.
- **iOS App:** Main game hub. Inventory, pets, shop, upgrades, loot boxes, profile, social features. Most UI lives here.
- **Shared Logic:** IEI engine, chase engine, types, configs—shared between both targets.

---

## 2. About the User

- **Coding Experience:** Very limited. Learning through vibe coding with AI assistance.
- **Tools:** Cursor IDE, Xcode (new to both).
- **Decision Style:** Wants AI to propose ideas, suggest alternatives, and catch potential issues proactively.

### How to Interact

1. **Don't take requests at face value.** If there's a better approach, say so before implementing.
2. **Be proactive.** Suggest improvements, flag concerns, propose alternatives.
3. **Ask clarifying questions** rather than inferring on ambiguous requests.
4. **Be concise** but thorough. Code-first answers, not tutorials.
5. **When something isn't defined,** don't just implement a placeholder—ask or propose options first.
6. **Update documentation** after every significant conversation or decision.
7. **Keep logs** of user preferences, decisions, and project evolution in this doc.
8. **After large changes, run `npm run lint`** (NOT `npm run build`) to check for errors.

### 🔴 CRITICAL: Thoroughness Standards

**This is a professional app, NOT a shabby MVP.** Every request must be handled with completeness.

**When asked to audit, review, or "make sure everything works":**
- ✅ Backend functionality (logic, data flow, state management)
- ✅ Frontend functionality (UI renders correctly, interactive elements work)
- ✅ UI completeness (are there views for ALL states? empty states? loading? errors?)
- ✅ UI polish (does it look professional? proper spacing? consistent design?)
- ✅ User flow (can user navigate naturally? are transitions smooth?)
- ✅ Edge cases (what happens on first run? empty data? errors?)
- ✅ Feedback mechanisms (popups, overlays, haptics, sounds where appropriate)
- ✅ Accessibility (can user understand what's happening at all times?)

**DO NOT:**
- ❌ Focus only on backend and ignore frontend
- ❌ Say "everything looks good" without checking UI/UX
- ❌ Claim work is "complete" when it's actually not (forcing user to discover gaps later)
- ❌ Deliver half-finished work disguised as finished work

**Clarification on follow-up questions:**
- ✅ Asking clarifying questions BEFORE starting work = GOOD (fills in gaps, avoids wrong assumptions)
- ❌ User having to ask follow-up questions AFTER AI claims completion = BAD (means AI didn't deliver what was promised)

**Example (Dec 19, 2025 lesson learned):**
> User asked to audit Apple Watch code for IEI and Chase systems. Initial response focused on backend (engines, managers, configs) and said "everything looks solid." User had to specifically ask about UI before gaps were identified (missing encounter popups, chase result overlays, reward feedback, session stats view). This should have been caught in the FIRST pass.

**The standard:** When user asks "is everything working/complete?", assume they mean:
1. Does the code compile? ✅
2. Does the logic work? ✅
3. Does the UI exist for all features? ✅
4. Does the UI look professional? ✅
5. Is the user experience complete? ✅
6. Would this be acceptable in a shipped app? ✅

### User Preferences (Explicit)

- **Agentically complete tasks** - Do everything in one message before reporting back
- **No high-level answers** - Give actual code and explanations, not "here's how you can..."
- **Be casual** unless otherwise specified
- **Be terse** - Get to the point
- **Treat as expert** - No hand-holding
- **Value good arguments over authorities**
- **Consider contrarian ideas** - Not just conventional wisdom
- **Speculation OK** - Just flag it
- **No moral lectures**
- **Respect Prettier preferences** when providing code
- **🔴 NO HALF-ASSED WORK** - Every deliverable must be complete, professional, and production-ready
- **🔴 Audit = EVERYTHING** - Backend + Frontend + UI + UX + Polish + User Flow
- **🔴 Don't make user ask twice** - Anticipate the full scope of requests

---

## 3. Development Approach by System

### IEI System & Chase System (Locked)
- These PRDs are **final**. Implement exactly as specified.
- Changes require explicit user approval.
- If you see a potential issue with the spec, flag it but don't change it. Mention it to the user.

### Engine-Building Progression System (Flexible)
- This PRD is a **rough guide**, not a final spec.
- Many details are undefined (exact pet abilities, upgrade trees, RP formulas, rank names, etc.).
- **Workflow for undefined features:**
  1. **Ideate:** Discuss options, pros/cons, creative ideas
  2. **Define:** Write spec into PRD or separate doc
  3. **Build:** Implement after user approves the spec
- AI should act as a **game design advisor**—help create an engaging, balanced game loop.

### UI Development
- Use **placeholders** for art, names, and values.
- Focus on **structure and flow** first, polish later.
- Everything will be revised—don't over-invest in aesthetics yet.
- **Art and animations are LAST PRIORITY** - Get everything functional first

---

## 4. Technical Context

### Current Codebase Structure

```
Ippo/Ippo/
├── Config/           # All tunables (IEIConfig, ChaseConfig, etc.)
├── Core/Types/       # Shared types (IEITypes, ChaseTypes, RewardTypes, PlayerTypes, PetTypes)
├── Data/             # GameData (static), UserData (per-user), PlaceholderData (legacy)
├── Engine/
│   ├── IEI/          # IEIEngine, CalibrationManager
│   ├── Chase/        # ChaseEngine, EncounterManager, SegmentEvaluator, etc.
│   └── RunSession/   # RunSessionManager (orchestrates everything)
├── Systems/Rewards/  # RewardsManager (stub)
├── Utils/            # HapticsManager, TelemetryLogger
└── UI/
    ├── Design/       # AppColors, AppTypography, AppSpacing
    ├── Components/   # Buttons, Cards, Badges, Progress, System
    └── Views/        # HomeTab, PetsTab, ShopTab, LeaderboardTab, ProfileTab, RunView, InventoryView
```

### Key Design Principles

1. **Config-driven:** All tunables in `Config/` files. Changing numbers shouldn't require code changes elsewhere.
2. **Modular:** Engines are independent, communicate via published state.
3. **Testable:** Sensor data can be simulated for testing without a real watch.
4. **Observable:** Telemetry logging for debugging and tuning.

### Data Architecture (December 2024 Refactor)

**GameData** (`Data/GameData.swift`)
- Static, global game definitions
- 106 pet definitions with actual images from AI_pets folder
- Never changes per-user
- Accessed via `GameData.shared`

**UserData** (`Data/UserData.swift`)
- Per-user dynamic data
- Profile, owned pets, inventory, stats, run history
- In DEBUG builds, loads test data for simulator testing
- Accessed via `UserData.shared`
- Uses `@Published` for SwiftUI reactivity

**PlaceholderData** (`Data/PlaceholderData.swift`)
- Legacy file, being phased out
- Still used by ShopTab (needs migration)
- Contains mock shop items, achievements, upgrades

### What's Implemented

**Core Systems:**
- ✅ IEI calculation engine (normalization, weighting, smoothing, trends)
- ✅ Calibration (Day-1 and continuous)
- ✅ Chase system (VRR encounters, segment builder, evaluation, recovery)
- ✅ Safety/burnout detection
- ✅ Haptic patterns (defined, not tested on device)
- ✅ Telemetry logging
- ✅ HealthKit integration (SensorBridge.swift)
- ✅ CoreMotion integration (SensorBridge.swift)
- ✅ Mock sensor system for simulator testing (MockSensorProvider, DebugControlsView)
- ✅ 106 pet definitions with real images

**iOS UI (COMPLETE):**
- ✅ Design system (Colors, Typography, Spacing)
- ✅ Component library (Buttons, Cards, Badges, Progress, System)
- ✅ Auth flow (Splash, Sign-In placeholder, Onboarding)
- ✅ HomeTab (Full dashboard)
- ✅ PetsTab (Collection, detail, equip, feed)
- ✅ ShopTab (Categories, purchase flow - UI only)
- ✅ LeaderboardTab (Rankings, progression)
- ✅ ProfileTab (Stats, upgrades, achievements, settings)
- ✅ Run flow (Pre-run, active, post-run)
- ✅ InventoryView (Boxes, Items, Boosts tabs)
- ✅ CSGO-style loot box opening animation

**Watch UI:**
- ✅ WatchStartView
- ✅ WatchRunningView (IEI display, chase view, controls)
- ✅ WatchSummaryView
- ✅ Debug controls (simulator only)

### What's Implemented (December 2024 Updates)

**Services Layer:**
- ✅ AuthService - Local authentication with profile switching
- ✅ DataPersistence - Local save/load for all user data
- ✅ WatchConnectivityService - iOS and watchOS sides (untested on device)

**Game Systems:**
- ✅ RPCalculator - Full RP formula per PRD
- ✅ LootBoxSystem - Complete drop tables, pity system, duplicate handling
- ✅ PetSystem - Feeding, mood decay, leveling with shards
- ✅ ShopSystem - Purchase, rotation, daily deals
- ✅ UpgradeSystem - Skill tree with 27 upgrades across 3 categories
- ✅ AchievementSystem - 66 achievements with progress tracking and celebrations
- ✅ ShopSystem - Purchases, daily deals, featured items
- ✅ Premium currency (Gems) - Defined with icon

### What's NOT Implemented Yet

- ✅ Firebase/Backend (auth, database, cloud sync) - DONE!
- ✅ Real Apple Sign-In with Firebase - DONE!
- ❌ In-App Purchases (requires Developer Account)
- ❌ **Player Upgrade System** - Core progression missing!
- ❌ **Achievement System** - No achievements exist
- ❌ Real leaderboard (mock data only)
- ❌ Day-1 Calibration UX (Watch screens)
- ❌ Sound effects
- ❌ Social features
- ❌ Custom art assets (using real pet images, placeholder everything else)

### Known Bugs (FIXED in December 2024)

| Bug | Status | Fix |
|-----|--------|-----|
| Quick Actions "Shop" button doesn't navigate | ✅ Fixed | TabSelection.shared pattern |
| Currency shows $ instead of coin icon | ✅ Fixed | Gold coin icon |
| Loot boxes only give coins | ✅ Fixed | LootBoxSystem.swift with full drops |

### Remaining Issues

| Issue | Location | Priority |
|-------|----------|----------|
| ShopTab uses PlaceholderData | ShopTab.swift | P1 - Should migrate to UserData |
| WatchConnectivity untested | WatchConnectivityService | P0 - Needs real device |
| Calibration UX not built | Watch App | P1 - Needs design |

### Manual Steps Required

1. Run: `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`
2. Open Xcode and add watchOS app target named "IppoWatch"
3. Add shared files to both iOS and watchOS targets
4. Add HealthKit capability to watchOS target
5. Add required Info.plist keys for health permissions

---

## 5. Data & Backend Plans

### Firebase (Planned)
- **Auth:** Apple Sign-In (primary), possibly email/Google
- **Firestore:** User profiles, inventory, pets, run history
- **Cloud Functions:** (Later) Leaderboards, social features
- **Real-time sync:** Yes, for future social features

### Data to Persist
- User profile (RP, rank, level, currency)
- Owned pets and their state (level, mood, XP, shards)
- Upgrades purchased
- Inventory (loot boxes, boosts, items)
- Run history / stats
- Calibration profile

---

## 6. Target Audience

- **Age:** 14-26 years old
- **Goal:** Make running addictive through gamification
- **Tone:** Fun, engaging, rewarding—not preachy about fitness

---

## 7. Open Questions & Undefined Areas

Tracked in `docs/undefined-items.md`. Many previously undefined items now defined:

**Now Defined ✅:**
- ✅ Currency names: Coins (soft), Gems (premium)
- ✅ Loot drop tables: Complete in LootBoxSystem.swift
- ✅ RP formula: Complete in RPCalculator.swift
- ✅ Pet mood mechanics: 1-10 scale, feeding, decay
- ✅ Shop pricing: Defined in ShopSystem.swift
- ✅ Streak mechanics: 5 RP per day, max 50

**Still Needs Definition (Critical):**
- ❌ **Player Upgrade System** - Categories A-E designed in Supplementary PRD, needs user approval
- ❌ **Achievement System** - 25+ achievements designed in Supplementary PRD, needs user approval
- ❌ IAP pricing tiers (requires Developer Account)

**Important:**
- ⚠️ Pet ability exact values (basic values exist, may need tuning)
- ⚠️ Economy balance (needs playtesting)
- ⚠️ Rank unlock perks (ranks exist, perks don't)

---

## 8. Files to Reference

| File | Purpose |
|------|---------|
| `docs/IEI_System_PRD.md` | IEI spec (🔒 locked) |
| `docs/Real_Time_Chase_System_PRD.md` | Chase spec (🔒 locked) |
| `docs/Ippo Engine-Building Progression System (PRD).md` | RP, Pets, Loot, Shop (flexible) |
| `docs/Supplementary_Systems_PRD.md` | **CRITICAL** - Everything NOT in the 3 core PRDs (Auth, Upgrades, Achievements, etc.) |
| `docs/mvp-requirements.md` | Complete MVP checklist with task status |
| `docs/undefined-items.md` | Tracks what needs definition |
| `docs/development-plan.md` | Phase-by-phase build plan |
| `docs/ui-development-plan.md` | UI/frontend roadmap |
| `docs/placeholder-tracker.md` | Tracks placeholder elements |
| `docs/gamification-expertise-roadmap.md` | 16-week learning plan for gamification mastery |

---

## 9. Communication Reminders

- **For locked systems:** Implement as specified. Flag concerns but don't deviate.
- **For flexible systems:** Ideate → Define → Build. Don't skip steps.
- **For UI:** Placeholder everything. Structure > polish. **BUT structure must be COMPLETE.**
- **For unknowns:** Ask, don't assume.
- **General:** Be an expert advisor, not just a code generator.

### Quality Bar for All Deliverables

| Request Type | What It ACTUALLY Means |
|--------------|------------------------|
| "Audit the code" | Check backend logic + frontend UI + user flow + edge cases + polish |
| "Make sure it works" | Compile ✅ + Logic ✅ + UI exists ✅ + UI is professional ✅ + UX is complete ✅ |
| "Is this ready?" | Would you ship this to paying customers today? |
| "Review this system" | Full system audit including all touchpoints and user-facing elements |
| "Build this feature" | Backend + Frontend + All states (loading, empty, error, success) + Polish |

**Default assumption:** User wants production-quality work, not prototype-quality work.

---

## 10. User Log & Decisions

*Chronological log of user preferences, decisions, and important notes.*

### December 2024 - Initial Setup

- **User skill level:** Very limited coding experience, learning through vibe coding with AI
- **Tools:** Cursor IDE + Xcode (new to both)
- **Decision style:** Wants AI to propose ideas, catch issues proactively, suggest alternatives

### 🔑 App Identifiers & Configuration

| Identifier | Value | Notes |
|------------|-------|-------|
| **iOS Bundle ID** | `com.cruce.Ippo` | Main iPhone app |
| **watchOS Bundle ID** | `com.cruce.Ippo.watchkitapp` | Watch companion app |
| **App Group** | `group.cruce.ippo.shared` | Shared data between iOS & watchOS |
| **Team ID** | `W2S75WFR39` | Apple Developer Team (Bernhard's team) |
| **App Store Connect SKU** | `Ippo-001` | Unique identifier in App Store Connect |
| **App Name** | `Ippo` | Display name on App Store |
| **Current Version** | `1.0 (3)` | First successful TestFlight build - Dec 21, 2025 |

### 🔐 Enabled Capabilities

| Capability | iOS App | Watch App | Notes |
|------------|---------|-----------|-------|
| **HealthKit** | ✅ | ✅ | Heart rate, workouts |
| **Sign in with Apple** | ✅ | - | Authentication |
| **In-App Purchase** | ✅ | - | Premium currency (Gems) |
| **App Groups** | ✅ | ✅ | `group.cruce.ippo.shared` |

### 📋 Required Info.plist Keys (Added)

| Key | iOS | Watch | Value |
|-----|-----|-------|-------|
| Privacy - Health Share Usage Description | ✅ | ✅ | "Ippo reads your heart rate and workout data to calculate your effort level during runs." |
| Privacy - Health Update Usage Description | ✅ | ✅ | "Ippo saves your workout sessions to track your running progress." |
| Privacy - Motion Usage Description | ✅ | ✅ | "Ippo uses motion data to detect your running cadence and stride for accurate effort tracking." |
- **Target demographic:** Ages 14-26
- **UI approach:** Placeholders first, polish later
- **Documentation preference:** AI should constantly update docs and keep logs on user/project decisions
- **Watch app type:** Companion app for existing iOS app (not standalone)

### December 17, 2024 - Simulator Testing

- **iOS UI scaffold completed:** TabView with 5 tabs (Home, Pets, Shop, Leaderboard, Profile)
- **Watch UI scaffold completed:** Start view, running view (IEI display, chase view, controls), summary view
- **Simulator testing approach established:**
  - User prefers testing in **Xcode simulators** (iPhone + Apple Watch) over TestFlight
  - **Mock sensor system created** for Watch simulator testing
  - `MockSensorProvider` generates fake IEI data with adjustable values
  - `DebugControlsView` provides UI to control mock data during testing
  - Auto-enables in simulator, allows testing chase triggers, zone transitions, etc.
- **Testing in Xcode:**
  - **iPhone:** Select "Ippo" scheme → iPhone simulator destination → Cmd+R
  - **Watch:** Select "IppoWatch Watch App" scheme → Watch simulator destination → Cmd+R
- **Watch interaction model clarified:** User primarily interacts with Watch app before run (start), during run (glance at IEI), and after run (end). Most UI is triggered through run lifecycle, not manual navigation. Watch is haptics-first.

### December 18, 2024 - Full UI Implementation

- **Comprehensive UI Development Plan created:** Complete screen inventory with 150+ screens documented
- **Development approach defined:**
  - Build iPhone front-end and back-end first (Phases 1-11)
  - Then build Apple Watch UI (Phase 12)
  - Then Watch-iPhone sync (Phase 13)
  - Then TestFlight for real-device testing (Phase 14)
  - Social features deferred to Phase 15
- **User preference:** Wants detailed, self-contained phase documentation so any phase can be fed to AI independently and implemented without additional context
- **Asset approach:** Placeholder art acceptable, can be replaced later. AI should note when assets are required per phase.

### December 18, 2024 - Pet Images & Data Architecture

- **106 pet images integrated** from AI_pets folder
- **Data architecture refactored:**
  - `GameData.swift` - Static game definitions (pets, ranks, etc.)
  - `UserData.swift` - Per-user dynamic data (profile, owned pets, inventory)
  - Debug data loads only in DEBUG builds
- **User clarification:** Placeholder data should only be for testing profile, not baked into the game for all users

### December 18, 2024 - Authentication Discussion

- **Apple Developer Account:** User does NOT have one yet ($99/year required)
- **Current auth implementation:** Local-only testing system (AuthService + DataPersistence)
- **What's deferred until Developer Account obtained:**
  - Real Sign in with Apple
  - Firebase Auth integration
  - TestFlight distribution
  - App Store submission
- **TODO when Developer Account obtained:**
  1. Set up Firebase project
  2. Configure Sign in with Apple in Apple Developer portal
  3. Integrate Firebase Auth with real Apple Sign-In
  4. Migrate DataPersistence to Firestore
  5. Set up TestFlight for beta testing

### December 18, 2024 - MVP Analysis Session

**User Request:** Create comprehensive analysis of everything missing before App Store submission

**Key Insights from User:**
- "Quick Actions shop button doesn't work" - Navigation bug identified
- "Loot boxes always give coins and nothing else" - Drop tables incomplete
- "I don't know if metrics like RP will actually track if I go on a run" - Tracking not connected
- "We need a real leaderboard that actually works"
- "Shop where I can actually buy things and those things will actually go to my inventory"
- "Need premium currency as well"
- "Monetization model... can't just be a money symbol for coins, needs to be a coin symbol"
- **Priority Order:** Art and animations go LAST. Get everything functional first.

**Documents Created:**
- `docs/mvp-requirements.md` - Complete MVP checklist with all tasks

**Next Steps (User's Plan):**
1. Set up authentication and individual data saving
2. Work through MVP requirements systematically
3. Art and animations last

### December 18, 2024 - Major Systems Implementation

**Implemented:**
- Local AuthService with profile switching for testing
- DataPersistence for all user data (UserDefaults-based)
- WatchConnectivityService (iOS + watchOS) - message types, queuing
- RPCalculator with full PRD-based formula
- LootBoxSystem with complete drop tables, pity system
- PetSystem with feeding (3x/day limit), mood decay, shard-based leveling
- ShopSystem with purchases, daily deals, featured items
- Fixed UI bugs (Shop navigation, currency icons, loot drops)

**User Decision:** Defer Apple Developer Account purchase for now, build locally first

### December 18, 2024 - PRD Analysis & 4th PRD Creation

**User Request:** Analyze all 3 PRDs against codebase, identify gaps, create 4th PRD for everything else

**Analysis Results:**
- IEI System PRD: ~85% complete (missing: Day-1 calibration UX, continuous calibration drift)
- Chase System PRD: ~90% complete (needs real device haptic testing)
- Engine-Building PRD: ~60% complete (missing: Upgrade System, Achievement System)

**Created:**
- `docs/Supplementary_Systems_PRD.md` - 4th PRD covering:
  - Authentication System
  - **Player Upgrade System** (5 categories, 20+ upgrades - needs implementation)
  - **Achievement System** (25+ achievements - needs implementation)
  - Onboarding System
  - Calibration UX
  - Settings System
  - Notification System
  - Data Architecture
  - Tutorial System
  - Social Features

**User Preferences (New):**
- AI should update Supplementary_Systems_PRD.md whenever designing/implementing non-core systems
- AI should always update relevant docs with every prompt
- Wants to ideate on Upgrade System and Achievement System before implementation

### December 20, 2025 - Apple Developer & TestFlight Setup

**Completed full Apple Developer account setup:**
1. Created App IDs in Developer Portal (iOS + watchOS) with capabilities
2. Enabled capabilities in Xcode: Sign in with Apple, In-App Purchase, App Groups
3. Created App Group `group.cruce.ippo.shared` for Watch-iPhone data sharing
4. Created app record in App Store Connect (SKU: `Ippo-001`)
5. Added required Info.plist keys for HealthKit permissions
6. Added app icon (axolotl mascot with headband)
7. Successfully archived and uploaded first TestFlight build: **Ippo 1.0 (1)**

**Issues encountered & resolved:**
- Wrong team initially selected (personal vs App Manager team) → switched teams
- App Group name conflict → used `group.cruce.ippo.shared` instead of `group.com.cruce.Ippo`
- Duplicate Info.plist conflict → added keys through Xcode Info tab instead of file
- Missing app icons → added placeholder icon via appicon.co
- Missing HealthKit usage descriptions → added to both targets

**Additional issues encountered (Dec 21):**
- Builds showed "Uploaded to Apple" but weren't appearing in TestFlight → check email for rejection reasons
- Missing NSMotionUsageDescription → added to both targets
- Export compliance question → answered "None of the algorithms mentioned above"

**✅ RESOLVED: Ippo 1.0 (3) is live on TestFlight!**

**TestFlight Troubleshooting Learnings:**
- Builds can silently fail - always check email (including spam/promotions)
- "Uploaded to Apple" in Xcode ≠ available in TestFlight (processing can reject)
- Each rejection requires incrementing build number and re-uploading
- Export compliance must be answered before testers can install

---

### December 19, 2025 - Quality Standards & Thoroughness Feedback

**Context:** User asked AI to audit Apple Watch code to ensure IEI and Chase systems were complete and ready for TestFlight.

**What happened:**
- AI's initial pass focused on backend systems (engines, configs, types, managers)
- AI reported "everything looks solid" and "BUILD SUCCEEDED"
- User then asked specifically about UI - "make sure there is UI for all the various things"
- AI discovered missing UI elements: encounter popups, chase result overlays, reward feedback, session stats view
- These should have been identified in the FIRST pass

**User's feedback (verbatim essence):**
> "This is not just a shabby MVP. This is supposed to be a professional app, and if everything is not done to completion and to a tee, then I'm not doing my job right."
> "When I ask for in-depth analysis of code and to make sure everything is working and functional, I'm not just talking about backend functionality. I'm also talking about frontend functionality, about the UI, about the professionalism of the UI, about user flow - EVERYTHING."
> "I don't want any half-assed jobs."

**Learnings documented:**
1. "Audit" or "review" means FULL scope - backend, frontend, UI, UX, polish
2. User should never have to ask twice for completeness
3. Professional quality is the baseline expectation
4. When in doubt, check MORE not less
5. A successful compile is step 1 of N, not the finish line

---

### December 18, 2024 - Upgrade & Achievement System Ideation

**🔴 CRITICAL MVP CLARIFICATION:**
- This is NOT a conventional MVP
- It's the **official first market-ready version** that will earn money
- Must be flawless and a solid running game/fitness app
- All systems should be complete and polished

**Upgrade System Decisions:**

| Decision | User Choice |
|----------|-------------|
| Categories | 3 categories: Loot Engine, RP Engine, Pet Engine. NO Shop/Economy category. QoL should be baseline. |
| Loot upgrades | NO increasing chance of rarer boxes (removes gambling addiction) |
| Structure | **Skill Tree with Branches** - massive UI screen |
| Resources | Coins (most), Upgrade Tokens (high-level), Gems (speed up/easier) |
| Power Scaling | Whatever is most addictive |
| Rank Gating | Yes, but NOT too strict. Must allow extensive upgrading before walls. |
| Reversibility | Yes, but NO refunds. "Are you sure?" confirmation. |
| Progression Speed | Fast early (dopamine hits), slows after ~1 month, every few runs mid-game |
| Difficulty Scaling | Linear, but loot tables increase so still upgrade-able |

**Achievement System Decisions:**

| Decision | User Choice |
|----------|-------------|
| Count | 50+ achievements |
| Visibility | Most visible, ~20% hidden for discovery |
| Progress | Progress bars |
| Celebration | Scales with rarity (small → full screen) |
| Rewards | Coins, Gems, Badges, Items, Boosts (activatable), Abilities, Titles |
| Game Center | Not for first version |
| Points system | No (unless significantly enhances UX) |

**Achievement Ideas (User Suggestions):**
- Distance milestones (first 5K, 10K, marathon)
- Pet leveling
- Player level
- Pet collection
- Average RP gain
- Use judgment on what actually enhances UX

---

## 11. Testing & Development Workflow

### Running in Simulators

**iPhone Simulator:**
1. Select scheme: "Ippo"
2. Select destination: Any iPhone (e.g., "iPhone 15 Pro")
3. Press Cmd+R

**Apple Watch Simulator:**
1. Select scheme: "IppoWatch Watch App"
2. Select destination: Any Watch (e.g., "Apple Watch Series 11 (46mm)")
3. Press Cmd+R
4. Mock sensor data auto-enabled—use Debug tab to control IEI values

### Mock Sensor System (Watch Simulator)

Located in `IppoWatch Watch App/Debug/`:
- **MockSensorProvider.swift:** Generates fake sensor samples with configurable IEI
- **DebugControlsView.swift:** UI to adjust mock values during testing

**Auto-sim modes:**
- Manual (slider control)
- Easy Jog (Z2)
- Steady Run (Z3)
- Hard Run (Z4)
- Sprint (Z5)
- Variable (realistic oscillation)
- Chase Trigger Sim (stays in encounter-eligible zones)

**Quick actions:** Zone buttons (Z1-Z5), Spike (jump to Z5), Drop (fall to Z1)

---

## 12. Color Scheme

- Dark theme (background: #0A0A0F)
- Electric cyan accent (#00D4FF)
- Gold for rewards/currency (#FFD700)
- 5 rarity colors (gray→green→blue→purple→orange)
- 5 zone colors (green→lime→yellow→orange→red)

**Pet Type Colors:**
- Abyssal: Deep purple (#6B21A8)
- Aquatic: Ocean blue (#0EA5E9)
- Celestial: Pink (#F0ABFC)
- Infernal: Fire red (#DC2626)
- Radiant: Golden (#FBBF24)
- Verdant: Nature green (#22C55E)

---

## Development Milestones

| Date | Milestone |
|------|-----------|
| Dec 19, 2025 | **Apple Developer Account access upgraded to App Manager** - Can now create apps, manage TestFlight, and access dev/distribution certificates |
| Dec 19, 2025 | **Apple Watch code audit complete** - IEI, Chase, Calibration, Haptics, Rewards, UI all built and compiling |
| Dec 21, 2025 | **🎉 TESTFLIGHT LIVE!** - Ippo 1.0 (3) available for testing on real iPhone + Apple Watch |
| Jan 4, 2026 | **Major fixes for TestFlight testing** - Watch navigation fixed, HealthKit permission handling improved, Cloud service scaffolding added, iOS UI polished, Shop wired to real data |
| Jan 4, 2026 | **🔥 Firebase Integration Complete** - Firebase Auth + Firestore fully wired. Apple Sign-In works with Firebase. User data syncs to cloud. |
| Jan 5, 2026 | **🎯 Watch App Calibration & Chase Fix** - Calibration now collects REAL sensor data and saves to Firebase. Chase system with full haptics verified. Complete data flow: Watch → Phone → Firebase. |

---

## Notes

- **PlaceholderData.swift** is legacy - fully phased out. All views now use UserData.
- **UserData.swift** is the source of truth for user data, uses DataPersistence for local storage
- **AuthService.swift** handles Apple Sign In and local test accounts with profile switching
- **CloudService.swift** - Full Firebase Firestore integration for user profiles, calibration, runs, inventory
- Config files in `Ippo/Ippo/Config/` have placeholder values that will need tuning
- 106 pet images from AI_pets folder are now integrated
- Focus on structure and flow first, balance later
- **AppState** properly connects to AuthService for authentication state
- **Watch app** - ✅ Calibration FIXED! Now starts real workout session, collects sensor data, saves via WatchConnectivity → Phone → Firebase
- **HealthKit permissions** - If denied, Settings sheet guides users to Settings app to re-enable
- **Firebase** - ✅ FULLY INTEGRATED! Auth + Firestore working. See `docs/FIREBASE_SETUP.md` for reference.
- **Haptics** - All chase patterns implemented: start, speed up, slow down, maintain, segment success, chase success/fail, heartbeat, recovery

### Key File Locations

| System | Location |
|--------|----------|
| Auth | `Services/AuthService.swift` |
| Cloud Storage | `Services/CloudService.swift` |
| Data Persistence | `Services/DataPersistence.swift` |
| Watch Sync | `Services/WatchConnectivityService.swift` |
| RP Calculation | `Systems/Rewards/RPCalculator.swift` |
| Loot Drops | `Systems/Rewards/LootBoxSystem.swift` |
| Pet Logic | `Systems/PetSystem.swift` |
| Shop Logic | `Systems/ShopSystem.swift` |
| Upgrades | `Systems/UpgradeSystem.swift` |
| Achievements | `Systems/AchievementSystem.swift` |
| User Data | `Data/UserData.swift` |
| Game Definitions | `Data/GameData.swift` |

---

---

### January 5, 2026 - Expertise & Learning Roadmap

**User Context:** 18-year-old high school student heading to college, wants to build foundational expertise that will make Ippo successful and turn it into a thriving business.

**Key Question:** What ONE skill should they become an expert in to make this project thrive?

**Recommendation Given:** **Gamification / Behavioral Psychology / Game Design**

**Rationale:**
1. It's the core differentiator — there are thousands of running apps, but the engagement loop is what makes Ippo special
2. It's hard to outsource — you can hire developers, but the person who understands WHY users come back needs to be the founder
3. It's transferable — applies to any product, content creation, marketing, leadership
4. It compounds — every feature decision gets better with this knowledge

**Created:** `docs/gamification-expertise-roadmap.md` — A 16-week structured learning plan including:
- 16 essential books in priority order
- YouTube channels and content creators to follow
- Courses (Coursera Gamification, Octalysis Prime)
- Apps/games to play and analyze
- Weekly schedule template
- Practical exercises and milestone checkpoints

**Secondary Skills Recommended:**
- Exercise science basics (to make the IEI system meaningful)
- Product analytics (to measure if gamification is working)

**Expert Positioning:** "The Gamification of Fitness Guy" — combining game design + exercise science + running expertise is a rare, valuable niche.

---

### January 8, 2026 - IEI System Overhaul

**User Concern:** IEI system wasn't aligned with PRD. Zone ranges were wrong. Fake metrics were given same weight as real data. No honest documentation of what's real vs approximated.

**Issues Identified:**
1. **Zone ranges mismatched** - PRD said Z1: 0-44, Z2: 45-57, etc. but code had even 20-point zones
2. **Fake metrics weighted equally** - GCT and RRP are approximations/estimates but had same weight as real data
3. **No documentation of sensor reality** - No clear statement of what Apple Watch can vs. can't measure
4. **Calibration was skippable** - Users could run without calibration, using defaults

**Changes Made:**

1. **Updated IEI_System_PRD.md (v2.0):**
   - Added Section 2.1: Metric Availability on Apple Watch (REAL vs DERIVED vs ESTIMATED)
   - Changed weights to prioritize real data (Cadence: 0.40, VPP: 0.30 = 70% from real sources)
   - Reduced weights on fake metrics (GCT: 0.08, RRP: 0.02)
   - Standardized zones to even 20-point ranges for mathematical clarity
   - Added Section 12: Apple Watch Implementation Notes
   - Added Section 5.4: Cold Start Behavior

2. **Updated IEIConfig.swift:**
   - New weights: Cadence 0.40, VPP 0.30, HRD 0.15, GCT 0.08, SV 0.05, RRP 0.02

3. **Updated IEITypes.swift:**
   - Zone ranges now: Z1 (0-19), Z2 (20-39), Z3 (40-59), Z4 (60-79), Z5 (80-100)
   - Added `targetIEI` and `tolerance` properties to EffortZone

4. **Updated WatchStartView.swift:**
   - Calibration is now MANDATORY before first run
   - Removed "Start Run with defaults" option
   - Clear messaging about why calibration matters

5. **Created IEI_ARCHITECTURE.md:**
   - Complete technical documentation of how IEI works
   - Explains data flow from sensors to IEI output
   - Documents what's real vs fake
   - Includes testing checklist

**Sensor Reality Summary:**

| Metric | Reality |
|--------|---------|
| Cadence | REAL (CMPedometer) |
| Heart Rate | REAL (HealthKit) |
| VPP | DERIVED (accelerometer amplitude) |
| HRD | DERIVED (HR change rate) |
| Stride Variability | DERIVED (accelerometer variance) |
| GCT | ESTIMATED (approximated from cadence) |
| RRP | ESTIMATED (guessed from effort level) |

**User Preferences Clarified:**
- IEI must reflect REAL values quickly (1-3 seconds)
- Smoothing should not make zones hard to maintain
- PRD should be updated when specs are wrong (don't just implement incorrectly)
- All systems need comprehensive documentation

**Files Changed:**
- `docs/IEI_System_PRD.md` - Major revision (v2.0)
- `docs/IEI_ARCHITECTURE.md` - NEW FILE
- `Ippo/Ippo/Config/IEIConfig.swift` - New weights
- `Ippo/Ippo/Core/Types/IEITypes.swift` - Fixed zone ranges
- `IppoWatch Watch App/Views/WatchStartView.swift` - Forced calibration

---

### January 8, 2026 - IEI Calibration & Debug Encounter Trigger Fixes

**User Concern (TestFlight testing):** 
1. IEI showing 55 while walking with HR 100 - should be much lower
2. Debug encounter trigger button not appearing during runs
3. Bad calibration (only easy jog + walk) produced bad IEI values

**Root Causes Identified:**

1. **Default calibration ranges too narrow:**
   - Old defaults: cadence 100-150, VPP 0.6-1.2
   - Walking cadence is 60-80 spm, so it normalized incorrectly
   - A bad/incomplete calibration would create very narrow ranges

2. **IEI didn't handle "not running" state:**
   - Walking with low cadence wasn't forcing IEI toward 0
   - Even with 0 cadence contribution, other metrics could push IEI to 50+

3. **Tester mode not syncing to Watch:**
   - Profile sync wasn't happening reliably on app launch
   - Tester mode changes weren't triggering sync to Watch

**Fixes Implemented:**

1. **Widened default calibration ranges (IEITypes.swift):**
   - Cadence: 60-200 spm (was 100-150) - covers walking to sprinting
   - VPP: 0.3-2.0 g (was 0.6-1.2) - covers walking to max effort
   - GCT: 160-350 ms (was 240-320)
   - RRP: 15-55 bpm (was 20-40)
   - Now walking naturally produces IEI ~10-20, jogging ~30-50

2. **Added "not running" detection to IEIEngine:**
   - If cadence < 110 spm AND VPP < 0.3g, user is "not running"
   - When not running: IEI capped at 5, forced to Z1
   - This prevents walking from ever showing mid-range IEI

3. **Fixed tester mode sync:**
   - TesterMode now auto-syncs to Watch when enabled/disabled
   - iOS app syncs profile to Watch when coming to foreground
   - Watch requests sync when starting a run
   - Added "Sync Now" button in Watch debug help view
   - Better logging for debugging sync issues

4. **Added debug help view on Watch:**
   - When tester mode not detected, shows instructions
   - Explains how to enable tester mode (tap profile 7x on iPhone)
   - Has manual "Sync Now" button

**Files Changed:**
- `Ippo/Ippo/Core/Types/IEITypes.swift` - Wider default calibration ranges
- `IppoWatch Watch App/Core/Types/IEITypes.swift` - Matching changes
- `Ippo/Ippo/Engine/IEI/IEIEngine.swift` - Added "not running" detection
- `IppoWatch Watch App/Engine/IEI/IEIEngine.swift` - Already had it, verified
- `Ippo/Ippo/Services/AuthService.swift` - Auto-sync tester mode changes
- `Ippo/Ippo/Services/WatchConnectivityService.swift` - Better logging
- `IppoWatch Watch App/Services/WatchConnectivityService.swift` - Request sync on run start
- `IppoWatch Watch App/Views/WatchRunningView.swift` - Added debug help view
- `Ippo/Ippo/IppoApp.swift` - Sync profile when app becomes active

**To Enable Debug Encounter Trigger:**
1. On iPhone, go to Profile tab
2. Tap your profile picture 7 times quickly (within 2 seconds each)
3. You'll see a wrench icon appear - tester mode unlocked!
4. Go to Settings (gear icon) and toggle "Tester Mode" ON
5. Start a run on Watch - scroll down to find "Tester" tab
6. Button says "Trigger Encounter" - tap to force spawn a chase

---

### January 8, 2026 - Calibration Haptic Guidance

**User Concern:** Calibration has no haptic prompts telling the user what to do. User has to remember the phases and timing themselves.

**Fix Implemented:**

Added comprehensive haptic feedback during calibration:

1. **Phase-specific haptic patterns:**
   - **Easy Phase:** Two gentle taps - "take it easy"
   - **Jog Phase:** Three ascending taps - "pick up the pace"
   - **Sprint Phase:** Four strong urgent pulses - "GO GO GO!"
   - **Cooldown Phase:** Descending notification - "slow down"

2. **Sprint reminders:** During the 15-second sprint phase, additional reminder haptics every 3 seconds to encourage max effort

3. **Start/Complete haptics:** Distinct patterns for calibration start and successful completion

**Calibration Flow with Haptics:**
- Start → `start` + `success` haptic
- Phase 1 (Easy 30s) → double tap + full-screen "WALK SLOWLY" overlay
- Phase 2 (Jog 30s) → triple ascending tap + "JOG NORMALLY" overlay
- Phase 3 (Sprint 15s) → four urgent pulses + "RUN AS FAST AS YOU CAN!" overlay + reminder ticks every 3s
- Phase 4 (Cooldown 45s) → descending tap + "SLOW DOWN & RECOVER" overlay
- Complete → triple success haptic + "Calibration Complete!" screen

**Files Changed:**
- `IppoWatch Watch App/Config/HapticsConfig.swift` - Added 7 calibration-specific haptic patterns
- `IppoWatch Watch App/Utils/HapticsManager.swift` - Added calibration haptic methods
- `IppoWatch Watch App/Views/WatchCalibrationView.swift` - Triggers haptics on phase changes + sprint reminders

---

### January 8, 2026 - Tester Mode Access & Sheet Closing Fixes

**User Issues:**
1. No obvious way to enable tester mode
2. Settings sheets (like Calibration Data) close immediately when opened

**Fixes:**

1. **Added explicit "Enable Tester Mode" button in Settings:**
   - Now visible in Settings under "Developer" section when tester mode not yet unlocked
   - One tap to enable (no more hidden 7-tap method required)
   - Clear description: "Access debug features and encounter trigger"

2. **Fixed sheet closing bug:**
   - Removed sync call from button action (was triggering state update before sheet presented)
   - Added 0.5s delay before sync in CalibrationDataSheet to let sheet fully present first
   - Sync now happens in `.task` modifier with delay instead of immediately

**How to Enable Tester Mode Now:**
1. Open iPhone app → Profile tab → Settings (gear icon)
2. Scroll down to "Developer" section
3. Tap "Enable Tester Mode"
4. Done! Debug features now available

**Files Changed:**
- `Ippo/Ippo/UI/Views/ProfileTab.swift` - Added tester mode unlock button + fixed sheet sync timing

---

### January 9, 2026 - IEI Responsiveness + Calibration Validation

**User Issues Reported:**
1. IEI stayed at Zone 4 even when walking/stopped - too sluggish
2. Calibration not guided with real-time feedback
3. No validation that user is actually sprinting during sprint phase

**Root Causes & Fixes:**

#### 1. IEI Now Much More Responsive
**Problem:** The EMA smoothing (α = 0.5) made IEI too sluggish. Changes took 3+ seconds to reflect.

**Fix:** Simplified to minimal smoothing:
```swift
// OLD: α = 0.5 (sluggish, takes 3+ seconds)
// NEW: α = 0.8 (very responsive - 80% current, 20% previous)
let ieiFast = (0.8 * ieiRaw) + (0.2 * previousIEIRaw)

// IEI_stable slightly smoother for "hold zone" checks
let ieiStable = (0.5 * ieiRaw) + (0.5 * previousIEIRaw)
```

IEI now responds almost immediately to effort changes.

#### 2. Heartbeat = Chase Progress (Corrected per PRD)
**Clarification:** Per Real_Time_Chase_System_PRD Section 4.2:
> "It grows steadily faster as the user progresses through segments."
> "It is fastest near the final segment."

Heartbeat represents "getting closer to catching the creature" - it speeds up as you complete more segments, NOT based on effort zones.

#### 3. Calibration Real-Time Validation
**Problem:** Calibration only validated AFTER completion. User didn't know if they were doing it right.

**Fix:** Added real-time validation with visual feedback:
- **Easy phase:** Warns if going too fast (cadence > 130)
- **Jog phase:** Warns if too slow (< 120) or too fast (> 180)
- **Sprint phase:** Warns if not sprinting (cadence < 160) - "⚡ Push harder!"
- **Cooldown:** Warns if not slowing down

New `PhaseValidationStatus` enum shows:
- ✓ Perfect! (green) - meeting requirements
- ↑ Speed up! (orange) - too slow
- ↓ Slow down! (orange) - too fast
- ⚡ Push harder! (orange) - sprint needs more effort

**Files Changed:**
- `IppoWatch Watch App/Engine/IEI/IEIEngine.swift` - Simplified to minimal smoothing (α=0.8) for responsiveness
- `IppoWatch Watch App/Engine/Chase/ChaseEngine.swift` - Heartbeat = segment progress (per PRD)
- `IppoWatch Watch App/Engine/IEI/CalibrationManager.swift` - Real-time phase validation + PhaseValidationStatus
- `IppoWatch Watch App/Views/WatchCalibrationView.swift` - Shows validation feedback during calibration

---

### January 9, 2026 - Calibration Data Sheet Instant-Dismiss Bug (FINALLY FIXED)

**User Issue:** Clicking "View Calibration Data" in Settings would pop up the sheet, then it would immediately close. Happened every time. User reported this 4+ times across multiple sessions.

**Previous Fix Attempts That Didn't Work:**
1. Removed `@ObservedObject` from CalibrationDataSheet, used `@State` snapshots instead
2. Moved `.sheet` modifier from Section to List level
3. Removed sync calls from button action
4. Added delay before sync in sheet's onAppear

**Root Cause Analysis:**

The problem was a **nested sheet presentation instability** caused by SwiftUI's `@ObservedObject` re-render behavior:

```
ProfileTab (observes userData, testerMode, etc.)
  └── .sheet → SettingsSheet (observes userData, authService, testerMode, data)
                  └── .sheet → CalibrationDataSheet
```

When ANY observed object publishes a change:
1. `ProfileTab` re-renders
2. `SettingsSheet()` is **recreated as a new instance** (not the same view)
3. The new instance initializes with `@State showingCalibrationData = false`
4. SwiftUI sees the binding changed → dismisses the nested sheet

The nested `.sheet` modifier was too fragile for this view hierarchy with multiple observed objects.

**The Fix That Worked:**

Changed from `.sheet` to `.fullScreenCover`:

```swift
// BEFORE (unstable):
.sheet(isPresented: $showingCalibrationData) {
    CalibrationDataSheet()
}

// AFTER (stable):
.fullScreenCover(isPresented: $showingCalibrationData) {
    CalibrationDataSheet()
}
```

**Why `.fullScreenCover` Works:**
- Takes over the entire screen, disconnecting from parent view hierarchy
- More "heavyweight" presentation that's isolated from parent re-renders
- SwiftUI treats it as a separate presentation context
- Parent view re-renders don't propagate through to dismiss it

**Lesson Learned:**
When you have deeply nested sheets with observed objects at multiple levels, use `.fullScreenCover` instead of `.sheet` for the inner presentations. Sheets are sensitive to parent view re-renders; full screen covers are not.

**Files Changed:**
- `Ippo/Ippo/UI/Views/ProfileTab.swift` - Changed CalibrationDataSheet from `.sheet` to `.fullScreenCover`

---

### January 9, 2026 - Calibration Guardrails (Major Overhaul)

**User Issue:** Calibration data showed Cadence 0-50 spm, which is physiologically impossible for running and caused IEI to be permanently broken.

**Root Cause:** Calibration system had validation for effort INCREASE between phases, but no validation for ABSOLUTE minimum thresholds. A user could walk/stand during all phases and still "complete" calibration with useless values.

**Guardrails Added:**

#### 1. Absolute Minimum Thresholds
```swift
struct CalibrationGuardrails {
    // Sprint cadence MUST be at least 150 spm (you can't sprint slower)
    static let minCadenceMax: Double = 150
    // Easy cadence can't be above 100 spm (or you weren't going easy)
    static let maxCadenceMin: Double = 100
    // Must have at least 50 spm range between easy and sprint
    static let minCadenceRange: Double = 50
    
    // Sprint must produce at least 0.7g bounce
    static let minVPPMax: Double = 0.7
    // Must have at least 0.3g VPP range
    static let minVPPRange: Double = 0.3
}
```

#### 2. Valid Sample Counting
Now tracks how many seconds the user was ACTUALLY meeting requirements per phase:
- Easy phase: Need 10+ seconds of valid easy effort (cadence 50-130)
- Jog phase: Need 10+ seconds of valid jogging (cadence 120-180, VPP 0.4-1.2)
- Sprint phase: Need 5+ seconds of valid sprinting (cadence 160+, VPP 0.7+)
- Cooldown: Need 10+ seconds of valid cooldown (cadence 50-150)

#### 3. Profile Validation on Load
When calibration loads from storage, it's validated:
- If invalid (e.g., cadence max < 150), the stored data is CLEARED
- Falls back to defaults (wide ranges that work for any fitness level)

#### 4. Descriptive Failure Messages
Each failure now explains exactly what went wrong:
- "NOT ENOUGH SPRINTING! Got only 2 valid sprint samples, need 5."
- "Calibration produced invalid values (Cadence: 0-50 spm). Sprint cadence must reach at least 150 spm!"

**Result:** User CANNOT complete calibration without actually doing the required effort. Invalid stored calibrations are automatically cleared and replaced with defaults.

**Files Changed:**
- `IppoWatch Watch App/Engine/IEI/CalibrationManager.swift` - Complete guardrail overhaul

---

### January 9, 2026 - Comprehensive PRD Audit & IEI System Hardening

**User Request:** Deep audit of IEI_System_PRD.md and Real_Time_Chase_System_PRD.md to ensure all features, guardrails, and systems are properly implemented.

**Issues Found & Fixed:**

#### 1. IEI Weights Didn't Match PRD
**PRD Spec (Section 5.2):** Cadence=0.40, VPP=0.30, HRD=0.15, GCT=0.08, SV=0.05, RRP=0.02
**Was:** Cadence=0.35, VPP=0.25, GCT=0.15, HRD=0.15, SV=0.05, RRP=0.05
**Fixed:** Updated `IEIConfig.swift` to match PRD weights exactly.

#### 2. HR Zone Validation Missing in Calibration
**PRD Spec (Section 4A):** "Max effort accepted ONLY if Cadence↑, VPP↑, AND (HRD↑ OR HR enters Z4/Z5)"
**Was:** Only checked cadence↑, VPP↑, HRD↑
**Fixed:** Added HR zone validation - now checks if HR increased 20% or reached high zone during sprint.

#### 3. Stop-Go Stability Detection Missing
**PRD Spec (Section 3.1):** "Runner is stable (confirmed stride, not stop-go behavior)"
**Was:** Only checked zone eligibility
**Fixed:** Added `recentZones` tracking and `stableRunningSeconds` counter. Must be stable for 5+ seconds in Z2+ before encounters can trigger.

#### 4. Session Validity Tracking for Anti-Cheat
**PRD Spec (Section 8.2):** "Invalid runs → no XP, resources, RP, or crates"
**Was:** No session validity tracking
**Fixed:** Added `isSessionValid` flag to IEIEngine that detects:
- Flat HR with elevated metrics (watch off wrist)
- Long periods of inconsistent stride patterns
- Missing HR while supposedly running

#### 5. Short Dropout Tolerance
**PRD Spec (Section 5.3):** "If IEI slips outside band for ≤2s, does not immediately fail"
**Already Implemented:** `shortDropoutAllowance: 2` in ChaseConfig ✅

#### 6. Recovery Pause When Below Z2
**PRD Spec (Section 9.1):** "If user drops below Z2, recovery timer pauses"
**Already Implemented:** RecoveryManager handles this ✅

#### 7. Anti-Gaming Detection in Calibration
**New Addition:** Detect if user intentionally runs slow during sprint to game IEI zones.
- Sprint cadence must be 15%+ higher than jog cadence
- Easy pace must be lower than jog pace
- Sprint VPP must be higher than jog VPP
- Clear progression: easy < jog < sprint

**Files Changed:**
- `IppoWatch Watch App/Config/IEIConfig.swift` - PRD-correct weights (0.40/0.30/0.08/0.15/0.05/0.02)
- `IppoWatch Watch App/Engine/IEI/IEIEngine.swift` - Session validity tracking, anti-cheat detection
- `IppoWatch Watch App/Engine/IEI/CalibrationManager.swift` - HR zone validation, anti-gaming detection
- `IppoWatch Watch App/Engine/Chase/EncounterManager.swift` - Stop-go stability detection

**Key Calibration Guardrails Now in Place:**
1. **Physical Thresholds:** Sprint cadence must reach 150+ spm, easy can't exceed 100 spm
2. **HR Validation:** Sprint must show cardiovascular response (HRD↑ or HR increase)
3. **Phase Progression:** Easy < Jog < Sprint (can't fake by running same pace)
4. **Valid Sample Counts:** Must hit effort targets for minimum duration per phase
5. **Anti-Gaming Detection:** Catches intentional slow-sprinting to narrow zones
6. **Invalid Profile Clearing:** Bad stored calibrations auto-cleared on load

**Impact:** Calibration now has multiple layers of validation making it nearly impossible to game. Users who don't follow instructions get clear error messages explaining what went wrong.

---

### January 12, 2026 - Calibration UX Complete Overhaul

**User Issue:** Calibration on TestFlight behaved like a normal run instead of a guided calibration experience. No prompts, no haptics at phase changes, and progress bar filled based on time rather than user effort.

**Root Causes:**
1. **First phase overlay not showing** - `onChange` doesn't fire for initial values, so the first phase overlay never appeared
2. **Progress bar was time-based** - It filled regardless of whether user was following instructions
3. **Haptics not triggering at start** - Initial phase haptic wasn't being played

**Fixes Implemented:**

#### 1. First Phase Overlay Now Shows
Added explicit handling in `onChange(of: calibrationManager.calibrationState)` to show the first phase overlay when calibration starts:
- `hasShownInitialOverlay` flag prevents duplicate overlays
- Small delay (0.5s) allows workout to start before showing overlay
- Strong haptic + visual prompt for first phase

#### 2. Progress Bar Now Effort-Based
The progress bar ONLY fills when the user is actually following instructions:
- Tracks `validSamplesProgress` instead of elapsed time
- Shows real-time feedback: "3/10s valid" → "✓ Complete!"
- Progress bar turns gray when user is NOT meeting requirements
- Uses `CalibrationGuardrails` thresholds for each phase

#### 3. Published Valid Sample Counts
CalibrationManager now exposes valid sample counts for UI:
```swift
@Published private(set) var validEasySampleCount: Int = 0
@Published private(set) var validJogSampleCount: Int = 0
@Published private(set) var validSprintSampleCount: Int = 0
@Published private(set) var validCooldownSampleCount: Int = 0
```

#### 4. Longer Overlay Duration
Phase transition overlay now shows for 3 seconds (was 2.5) so users have time to read instructions.

**Calibration Flow (Now Working):**
1. User taps "Start Calibration"
2. **Strong haptic** + full-screen overlay: "WALK SLOWLY - 30 seconds"
3. Progress bar fills ONLY when cadence is in easy range (50-130 spm)
4. Real-time feedback: "✓ Perfect!" / "↓ Slow down!" / "↑ Speed up!"
5. Phase complete → **Next haptic** + new overlay: "JOG NORMALLY"
6. Repeat for each phase with appropriate effort requirements
7. Sprint phase: reminder haptics every 3 seconds
8. Completion → **Success haptic** + celebration screen

**Continuous Calibration (Already Implemented):**
- `addRunSample()` collects samples during normal runs
- `processRunEnd()` updates calibration profile at end of run
- Uses drift-controlled updates (max +15% expansion, -5% contraction per run)
- Rolling 10-run history for stable averages
- Automatically syncs to phone/Firebase

**Files Changed:**
- `IppoWatch Watch App/Views/WatchCalibrationView.swift` - Complete UI overhaul
- `IppoWatch Watch App/Engine/IEI/CalibrationManager.swift` - Exposed valid sample counts

---

*Document maintained by AI assistant. Last updated January 12, 2026 after calibration UX overhaul.*
