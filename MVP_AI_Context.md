# AI Context Document for Ippo MVP

**Last Updated:** January 20, 2026  
**Purpose:** Provide persistent context for AI assistants building the Ippo MVP.

---

## CRITICAL: This is the MVP, NOT the Full Product

This project is a **simplified MVP** of the larger Ippo app. The full product has:
- Complex IEI (Instantaneous Effort Index) system with 6 metrics
- Multi-zone chase sequences (Z2-Z5 target zones)
- Dynamic segment evaluation
- Continuous calibration

**The MVP simplifies to:**
- Binary sprint detection (sprint or don't sprint)
- HR + cadence validation only
- Fixed 30-45 second sprint duration
- Simple fartlek-style gameplay

**DO NOT** implement the complex IEI system. Build exactly what's in `MVP_PRD.md`.

---

## 1. Project Overview

**Ippo MVP** is a fartlek-style running game where:
1. User runs at normal pace
2. Random sprint prompts trigger (strong vibration)
3. User sprints for 30-45 seconds
4. Another vibration signals sprint end
5. If sprint validated → reward (pet or loot box)
6. Repeat

### Why This MVP Exists

The full IEI system proved difficult to debug and calibrate. This MVP:
- Reduces complexity = fewer bugs
- Uses well-understood fartlek methodology
- Has simpler validation = easier troubleshooting
- Can ship faster for market testing

---

## 2. Reference Documents

| Document | Purpose | How to Use |
|----------|---------|------------|
| `MVP_PRD.md` | **PRIMARY BUILD SPEC** | Follow exactly |
| `brainlift.md` | Domain knowledge, research | Background context only |
| `idea.md` | Product vision | Understand the "why" |
| `prd.md` | Full product PRD | **REFERENCE ONLY** - don't build this |
| `UIPRD1.md` | Full UI spec | Design guidance (simplified for MVP) |

**Rule:** When in doubt, `MVP_PRD.md` is the source of truth.

---

## 3. About the User

- **Coding Experience:** Very limited. Learning through AI-assisted development.
- **Tools:** Cursor IDE, Xcode (relatively new to both)
- **Goal:** Get MVP to market quickly for testing and feedback

### How to Interact

1. **Be proactive** - Suggest improvements, catch issues early
2. **Be thorough** - Every feature needs complete UI (loading, error, empty states)
3. **Be practical** - Don't over-engineer, this is an MVP
4. **Ask clarifying questions** - Rather than assume on ambiguous requests
5. **Update this document** - Log decisions, learnings, issues resolved

### User Preferences

- **Agentically complete tasks** - Do everything before reporting back
- **No high-level fluff** - Give actual code, not "here's how you could..."
- **Be terse** - Get to the point
- **Professional quality** - Not a shabby MVP, but a polished simple product
- **No half-finished work** - Every screen complete with all states

---

## 4. Technical Architecture

### App Identifiers

| Identifier | Value |
|------------|-------|
| iOS Bundle ID | `com.cruce.IppoMVP` |
| watchOS Bundle ID | `com.cruce.IppoMVP.watchkitapp` |
| App Group | `group.cruce.ippomvp.shared` |

### Codebase Structure

```
IppoMVP/
├── Config/                 # All tunables
│   ├── SprintConfig.swift
│   ├── EncounterConfig.swift
│   └── RewardsConfig.swift
├── Core/Types/            # Shared data types
│   ├── SprintTypes.swift
│   ├── PetTypes.swift
│   ├── RewardTypes.swift
│   └── PlayerTypes.swift
├── Data/
│   ├── GameData.swift     # Static pet definitions (10 pets)
│   └── UserData.swift     # Per-user dynamic data
├── Engine/
│   ├── Sprint/
│   │   ├── SprintEngine.swift
│   │   └── SprintValidator.swift
│   ├── Encounter/
│   │   └── EncounterManager.swift
│   └── RunSession/
│       └── RunSessionManager.swift
├── Services/
│   ├── AuthService.swift
│   ├── CloudService.swift
│   ├── DataPersistence.swift
│   └── WatchConnectivityService.swift
├── Systems/
│   ├── PetSystem.swift
│   ├── AbilityTreeSystem.swift
│   ├── RewardsSystem.swift
│   └── LootBoxSystem.swift
├── UI/
│   ├── Design/
│   │   ├── AppColors.swift
│   │   ├── AppTypography.swift
│   │   └── AppSpacing.swift
│   ├── Components/
│   └── Views/
└── Utils/
    ├── HapticsManager.swift
    └── TelemetryLogger.swift
```

---

## 5. Key Systems Summary

### Sprint Validation (NOT Complex IEI)

The MVP uses simple sprint validation:

| Signal | Weight | What to Check |
|--------|--------|---------------|
| HR Response | 50% | ≥20 BPM increase, reaches Z4-5, stays elevated |
| Cadence | 35% | ≥15% increase, peak ≥160 SPM |
| HR Derivative | 15% | ≥3 BPM/sec rise in first 10 seconds |

**Total ≥60% = VALID sprint**

### Pet System (10 Pets Only)

- 10 unique pets (not 106)
- No pet types - all pets are equal except for unique abilities
- 10 evolution stages per pet (baby → adult)
- Rare catches make each pet feel special

### Catch Rate System

| Pets Owned | Catch Rate per Sprint |
|------------|----------------------|
| 0 | 100% (first pet guaranteed) |
| 1 | 15% (~5 runs average) |
| 2 | 8% (~10 runs average) |
| 3+ | 3% (~20 runs average) |

### Ability Tree

- **Player Abilities:** Unlocked with AP (from level ups)
- **Pet Abilities:** Upgraded with PP (from pet evolutions)
- Visual tree UI with zoom/pan

---

## 6. What's Different from Full Product

| Full Product | MVP |
|--------------|-----|
| Complex IEI (6 metrics) | Simple sprint detection (HR + cadence) |
| Multi-zone chases (Z2-Z5) | Binary sprint only |
| 106 pets with 6 types | 10 pets, no types |
| Calibration required | No calibration needed |
| Dynamic difficulty | Fixed 30-45 second sprints |

---

## 7. Development Milestones

| Date | Milestone |
|------|-----------|
| Jan 20, 2026 | MVP PRD created |
| Jan 20, 2026 | MVP_AI_CONTEXT.md created |
| | (Add milestones as development progresses) |

---

## 8. Decisions Log

*Record important decisions made during development:*

### January 20, 2026 - MVP Simplification

**Decision:** Simplify IEI system to binary sprint detection.

**Rationale:** The complex IEI system had persistent bugs that were difficult to diagnose. The MVP needs to ship quickly for market validation. Sprint detection with HR/cadence is simpler and proven.

**Impact:** 
- No calibration required
- No multi-zone segments
- Validation is straightforward: did they sprint or not?

### January 20, 2026 - 10 Pets Only

**Decision:** Reduce from 106 pets to 10 pets.

**Rationale:** Can't afford hundreds of custom pet designs. 10 pets with 10 evolution stages each = 100 total images, which is manageable.

**Impact:**
- Each pet feels special (rare to catch)
- Deep progression through evolution
- Ability tree provides additional depth

---

## 9. Known Considerations

### Must Have for MVP
- [ ] Sprint detection (HR + cadence validation)
- [ ] Strong haptic feedback (unmistakable signals)
- [ ] 10 pets with evolution stages
- [ ] Ability tree (player + pet)
- [ ] Basic reward system (RP, XP, coins, loot boxes)
- [ ] Apple Sign-In
- [ ] Firebase sync

### Can Defer
- Complex IEI zones (use simple sprint detection)
- Leaderboards (mock data acceptable)
- Social features
- In-app purchases (can add after launch)
- Sound effects

### Watch Out For
- Sprint validation false positives (user didn't actually sprint)
- Sprint validation false negatives (user sprinted but wasn't credited)
- Haptic timing (must be strong and clear)
- Watch ↔ Phone sync reliability

---

## 10. Quality Standards

When building or reviewing any feature:

1. **Does it compile?** ✅
2. **Does the logic work?** ✅
3. **Does UI exist?** ✅
4. **Is UI professional?** ✅
5. **All states handled?** (loading, empty, error, success) ✅
6. **Would you ship this?** ✅

**No half-finished work.** Every feature should be complete before moving on.

---

## 11. Files Quick Reference

| System | Location |
|--------|----------|
| Sprint Engine | `Engine/Sprint/SprintEngine.swift` |
| Sprint Validator | `Engine/Sprint/SprintValidator.swift` |
| Encounter Manager | `Engine/Encounter/EncounterManager.swift` |
| Pet System | `Systems/PetSystem.swift` |
| Ability Tree | `Systems/AbilityTreeSystem.swift` |
| User Data | `Data/UserData.swift` |
| Game Data (10 pets) | `Data/GameData.swift` |
| Auth | `Services/AuthService.swift` |
| Cloud Sync | `Services/CloudService.swift` |
| Watch Sync | `Services/WatchConnectivityService.swift` |

---

## 12. Communication with AI

When making requests:
- "Build this feature" = Backend + Frontend + All states + Polish
- "Is this working?" = Compile + Logic + UI + UX + Ship-ready?
- "Review this" = Full audit of all touchpoints

**Default assumption:** User wants production-quality work, just simplified scope.

---

*This document should be updated after every significant session. Log decisions, resolved issues, and learnings here.*
