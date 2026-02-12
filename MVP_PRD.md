# Ippo MVP - Complete Product Requirements Document

**Version:** 2.0  
**Last Updated:** January 20, 2026  
**Purpose:** One-shot build guide for the Ippo MVP - a simplified fartlek-based running game  
**Target:** AI-assisted development with minimal human intervention

---

## Executive Summary

This document specifies **Ippo MVP** - a streamlined running gamification app built around **fartlek-style sprint intervals** and **collectible pets with growth systems**.

### MVP Core Philosophy

| Aspect | Design |
|--------|--------|
| Pets | **10 unique pets** (not hundreds) |
| Pet Types | **None** - all pets are equal, differentiated by abilities |
| Catch Rate | **Very rare** after first 3 pets - makes catching special |
| Growth | **10 micro-evolutions** per pet - watch them grow from baby to adult |
| Abilities | **Ability Tree** for player and pets - deep progression |
| Focus | Level up pets, upgrade abilities, earn RP - catching is secondary |

### Why 10 Pets?

1. **Art constraints** - Can't afford hundreds of custom pet designs
2. **Each pet is special** - Rare catches feel meaningful
3. **Deep progression** - 10 evolution stages × 10 pets = 100 visuals
4. **Focus on care** - You grow attached to your pets over time

---

## Table of Contents

1. [Product Vision](#1-product-vision)
2. [Core Gameplay Loop](#2-core-gameplay-loop)
3. [Technical Architecture](#3-technical-architecture)
4. [Sprint Detection & Validation System](#4-sprint-detection--validation-system)
5. [Pet Encounter System](#5-pet-encounter-system)
6. [The 10 Pets](#6-the-10-pets)
7. [Pet Evolution System](#7-pet-evolution-system)
8. [Ability Tree System](#8-ability-tree-system)
9. [Reward System](#9-reward-system)
10. [Progression System](#10-progression-system)
11. [Economy & Currencies](#11-economy--currencies)
12. [iOS App Specifications](#12-ios-app-specifications)
13. [watchOS App Specifications](#13-watchos-app-specifications)
14. [Data Architecture](#14-data-architecture)
15. [Haptic Feedback System](#15-haptic-feedback-system)
16. [UI/UX Design System](#16-uiux-design-system)
17. [Authentication & Backend](#17-authentication--backend)
18. [Implementation Checklist](#18-implementation-checklist)

---

## 1. Product Vision

### The Problem

Running is boring for most people. Traditional running apps track metrics but don't make running fun.

### The MVP Solution

**Turn running into a fartlek game with rare pet catches and deep pet growth.**

- You run, random sprints trigger
- Sprint successfully to earn rewards
- **Rarely**, you catch a new pet (this is special!)
- Focus on **growing your pets** through 10 evolution stages
- Unlock **abilities** in a visual skill tree
- Watch your little babies become powerful adults

### Core Value Proposition

**"Catch rare pets. Grow them from babies. Watch them evolve."**

### What Makes This Special

| Traditional Pet Games | Ippo MVP |
|----------------------|----------|
| Catch hundreds of creatures | Catch 10 rare, special pets |
| Pets are static | Pets evolve through 10 stages |
| Catching is frequent | Catching is rare and meaningful |
| Shallow progression | Deep ability trees |

---

## 2. Core Gameplay Loop

### Primary Loop (During Runs)

```
┌─────────────────────────────────────────────────────────────────┐
│  ① RUN NORMALLY                                                  │
│  User jogs at their comfortable pace                            │
└─────────────────────────┬───────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│  ② SPRINT TRIGGERS (Random)                                      │
│  Probability increases over time                                │
│  Pity timer guarantees sprint after 3 minutes                   │
└─────────────────────────┬───────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│  ③ SPRINT (30-45 seconds)                                        │
│  Strong vibration signals START                                 │
│  User sprints hard                                              │
│  Strong vibration signals END                                   │
└─────────────────────────┬───────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│  ④ VALIDATION & REWARD                                           │
│  Sprint validated → Earn RP, XP, coins, loot box               │
│  RARE: Pet encounter! (See catch rate system)                   │
│  Sprint failed → No reward                                      │
└─────────────────────────┬───────────────────────────────────────┘
                          │
                          ▼
                    [LOOP BACK TO ①]
```

### Secondary Loop (Between Runs)

```
┌─────────────────────────────────────────────────────────────────┐
│  ⑤ PET CARE & GROWTH                                             │
│  - Feed pets daily (up to 3x)                                   │
│  - Watch evolution progress                                     │
│  - Pets grow through 10 stages                                  │
└─────────────────────────┬───────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│  ⑥ ABILITY TREE                                                  │
│  - Spend Ability Points on player upgrades                      │
│  - Spend Pet Points on pet abilities                            │
│  - Visual tree you can zoom/pan                                 │
└─────────────────────────┬───────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│  ⑦ PROGRESSION                                                   │
│  - Track rank (RP)                                              │
│  - Open loot boxes                                              │
│  - View stats                                                   │
└─────────────────────────────────────────────────────────────────┘
```

### Reward Distribution

| Reward | Source | Frequency |
|--------|--------|-----------|
| RP | Every validated sprint | Common |
| XP | Every validated sprint | Common |
| Coins | Every validated sprint | Common |
| Loot Boxes | Most validated sprints | Common |
| **New Pet** | See catch rate system | **Very Rare** |

---

## 3. Technical Architecture

### Platform Requirements

| Platform | Minimum | Recommended |
|----------|---------|-------------|
| iOS | 16.0+ | Latest |
| watchOS | 9.0+ | Latest |
| Apple Watch | Series 4+ | Series 6+ |

### App Identifiers

| Identifier | Value |
|------------|-------|
| iOS Bundle ID | `com.cruce.IppoMVP` |
| watchOS Bundle ID | `com.cruce.IppoMVP.watchkitapp` |
| App Group | `group.cruce.ippomvp.shared` |

### Codebase Structure

```
IppoMVP/
├── IppoMVP/                           # iOS App
│   ├── Config/
│   │   ├── SprintConfig.swift
│   │   ├── EncounterConfig.swift
│   │   ├── PetConfig.swift            # Pet catch rates, evolution
│   │   ├── AbilityConfig.swift        # Ability tree configuration
│   │   └── RewardsConfig.swift
│   │
│   ├── Core/Types/
│   │   ├── SprintTypes.swift
│   │   ├── PetTypes.swift             # 10 pets, 10 evolutions each
│   │   ├── AbilityTypes.swift         # Ability tree types
│   │   ├── RewardTypes.swift
│   │   └── PlayerTypes.swift
│   │
│   ├── Data/
│   │   ├── GameData.swift             # 10 pet definitions
│   │   ├── AbilityTreeData.swift      # Ability tree structure
│   │   └── UserData.swift
│   │
│   ├── Engine/
│   │   ├── Sprint/
│   │   │   ├── SprintEngine.swift
│   │   │   └── SprintValidator.swift
│   │   ├── Encounter/
│   │   │   └── EncounterManager.swift
│   │   └── RunSession/
│   │       └── RunSessionManager.swift
│   │
│   ├── Systems/
│   │   ├── PetSystem.swift            # Feeding, evolution, abilities
│   │   ├── AbilityTreeSystem.swift    # Ability unlocking
│   │   ├── RewardsSystem.swift
│   │   └── LootBoxSystem.swift
│   │
│   ├── UI/
│   │   ├── Design/
│   │   │   ├── AppColors.swift
│   │   │   ├── AppTypography.swift
│   │   │   └── AppSpacing.swift
│   │   ├── Components/
│   │   │   └── AbilityTreeView/       # Zoomable ability tree
│   │   └── Views/
│   │
│   ├── Services/
│   │   ├── AuthService.swift
│   │   ├── CloudService.swift
│   │   ├── DataPersistence.swift
│   │   └── WatchConnectivityService.swift
│   │
│   └── Utils/
│       ├── HapticsManager.swift
│       └── TelemetryLogger.swift
│
└── IppoMVPWatch Watch App/            # watchOS App
    ├── Engine/
    ├── Views/
    ├── Services/
    └── Utils/
```

---

## 4. Sprint Detection & Validation System

### Sprint Validation

The system uses **three signals** to validate a sprint:

| Signal | Weight | Threshold |
|--------|--------|-----------|
| HR Response | 50% | ≥20 BPM increase, reaches Z4-5 |
| Cadence | 35% | ≥15% increase, peak ≥160 SPM |
| HR Derivative | 15% | ≥3 BPM/sec in first 10 seconds |

**Total score ≥60% = VALID sprint**

### Configuration (SprintConfig.swift)

```swift
struct SprintConfig: Sendable {
    static let shared = SprintConfig()
    
    // Sprint Duration
    let minSprintDuration: TimeInterval = 30.0
    let maxSprintDuration: TimeInterval = 45.0
    
    // Heart Rate Validation
    let minHRIncreaseRequired: Int = 20
    let targetHRZone: Int = 4
    let minTimeInTargetZone: Double = 0.70
    
    // Cadence Validation
    let minCadenceIncreasePercent: Double = 0.15
    let minPeakCadence: Int = 160
    
    // HRD Validation
    let minHRDerrivative: Double = 3.0
    let hrdMeasurementWindow: TimeInterval = 10.0
    
    // Overall
    let validationThreshold: Double = 60.0
    let hrWeight: Double = 0.50
    let cadenceWeight: Double = 0.35
    let hrdWeight: Double = 0.15
    
    // Recovery
    let recoveryDuration: TimeInterval = 45.0
}
```

---

## 5. Pet Encounter System

### Core Philosophy

**Pets are RARE.** Catching a new pet should feel like a special event. The focus of gameplay is on:
1. Growing and evolving your existing pets
2. Upgrading abilities
3. Earning RP and climbing ranks

**Catching is secondary.** Average: ~1 new pet every 10 runs after the first 3.

### Catch Rate System

The catch rate depends on **how many pets you already own**:

| Pets Owned | Catch Probability per Sprint | Average Runs Between Catches |
|------------|------------------------------|------------------------------|
| 0 (First Run) | **100%** (Guaranteed) | 1 run |
| 1 | 15% | ~5 runs |
| 2 | 8% | ~10 runs |
| 3+ | 3% | ~20 runs |

### How It Works

```swift
func shouldCatchPet(petsOwned: Int, sprintValidated: Bool) -> Bool {
    guard sprintValidated else { return false }
    
    let catchRate: Double
    switch petsOwned {
    case 0:
        catchRate = 1.00  // First pet guaranteed
    case 1:
        catchRate = 0.15  // ~5 runs average
    case 2:
        catchRate = 0.08  // ~10 runs average
    default:
        catchRate = 0.03  // ~20 runs average
    }
    
    return Double.random(in: 0...1) < catchRate
}
```

### Pet Selection (When Catch Occurs)

When a catch triggers, select a random pet the user doesn't own:

```swift
func selectPetToCatch(ownedPetIds: Set<String>) -> GamePetDefinition? {
    let unownedPets = GameData.shared.allPets.filter { !ownedPetIds.contains($0.id) }
    return unownedPets.randomElement()
}
```

### First Run Experience

On the user's very first run:
1. After first validated sprint
2. **Guaranteed pet catch** - Dramatic reveal animation
3. Pet arrives as a baby (Evolution Stage 1)
4. Tutorial explains feeding and growth

### Configuration (PetConfig.swift)

```swift
struct PetConfig: Sendable {
    static let shared = PetConfig()
    
    // Catch rates by pets owned
    let catchRates: [Int: Double] = [
        0: 1.00,   // First pet: 100%
        1: 0.15,   // Second pet: 15% per sprint (~5 runs)
        2: 0.08,   // Third pet: 8% per sprint (~10 runs)
        // 3+: 3% (default)
    ]
    
    let defaultCatchRate: Double = 0.03  // ~20 runs average for 4th+ pet
    
    // Evolution
    let evolutionStages: Int = 10
    let xpPerEvolution: [Int] = [0, 100, 250, 500, 1000, 2000, 4000, 7000, 12000, 20000]
    
    // Feeding
    let maxFeedingsPerDay: Int = 3
    let xpPerFeeding: Int = 25
    let moodBoostPerFeeding: Int = 1
}
```

---

## 6. The 10 Pets

### Overview

All 10 pets are equal in base power. They differ only in:
1. **Appearance** (10 evolution stages each)
2. **Unique Ability** (each pet has a special ability)
3. **Personality** (flavor text, animations)

### Pet Definitions

| ID | Name | Unique Ability | Description |
|----|------|----------------|-------------|
| `pet_01` | **Ember** | **Ignite** - +15% RP on sprints under 35 seconds | A fiery spirit that burns brightest in short bursts |
| `pet_02` | **Splash** | **Flow** - +10% passive XP during runs | A water creature that rewards steady effort |
| `pet_03` | **Sprout** | **Growth** - +20% evolution XP gains | A plant being that helps all pets grow faster |
| `pet_04` | **Zephyr** | **Tailwind** - +10% encounter chance | An air spirit that attracts more sprint opportunities |
| `pet_05` | **Pebble** | **Fortitude** - -15% mood decay when inactive | A stone creature that stays content longer |
| `pet_06` | **Spark** | **Energize** - +25% coins from loot boxes | An electric being that amplifies rewards |
| `pet_07` | **Shadow** | **Stealth** - +5% catch rate for new pets | A dark creature that helps find others |
| `pet_08` | **Frost** | **Preserve** - Feeding gives +50% XP | An ice spirit that maximizes care rewards |
| `pet_09` | **Blaze** | **Intensity** - +30% RP on sprints over 40 seconds | A fire creature that rewards sustained effort |
| `pet_10` | **Luna** | **Blessing** - +5% to ALL other pet bonuses | A celestial being that enhances everything |

### Pet Data Structure

```swift
struct GamePetDefinition: Identifiable, Codable {
    let id: String                    // "pet_01"
    let name: String                  // "Ember"
    let description: String           // "A fiery spirit..."
    let abilityName: String           // "Ignite"
    let abilityDescription: String    // "+15% RP on sprints under 35 seconds"
    let evolutionImageNames: [String] // 10 image names for each stage
}

struct OwnedPet: Identifiable, Codable {
    let id: String                    // UUID
    let petDefinitionId: String       // "pet_01"
    var evolutionStage: Int           // 1-10
    var experience: Int               // XP toward next evolution
    var mood: Int                     // 1-10
    var lastFedDate: Date?
    var feedingsToday: Int
    var isEquipped: Bool
    var abilityLevel: Int             // 1-5 (upgradeable in ability tree)
    
    var definition: GamePetDefinition? {
        GameData.shared.pet(byId: petDefinitionId)
    }
    
    var currentImageName: String {
        definition?.evolutionImageNames[evolutionStage - 1] ?? ""
    }
}
```

### Pet Images (100 Total)

Each pet has 10 evolution stage images:

```
Assets/
├── Pets/
│   ├── pet_01_ember/
│   │   ├── ember_stage_01.png    # Baby
│   │   ├── ember_stage_02.png
│   │   ├── ember_stage_03.png
│   │   ├── ember_stage_04.png
│   │   ├── ember_stage_05.png    # Juvenile
│   │   ├── ember_stage_06.png
│   │   ├── ember_stage_07.png
│   │   ├── ember_stage_08.png
│   │   ├── ember_stage_09.png
│   │   └── ember_stage_10.png    # Adult
│   ├── pet_02_splash/
│   │   └── ... (10 stages)
│   └── ... (8 more pets)
```

---

## 7. Pet Evolution System

### Evolution Stages

Each pet goes through 10 stages, visually transforming from baby to adult:

| Stage | Name | XP Required | Visual |
|-------|------|-------------|--------|
| 1 | Newborn | 0 | Tiny baby, simple design |
| 2 | Infant | 100 | Slightly larger |
| 3 | Toddler | 250 | More defined features |
| 4 | Child | 500 | Starting to show personality |
| 5 | Youth | 1,000 | Half-grown, recognizable |
| 6 | Adolescent | 2,000 | Nearly full size |
| 7 | Young Adult | 4,000 | Full size, basic details |
| 8 | Adult | 7,000 | Full details |
| 9 | Mature | 12,000 | Enhanced features |
| 10 | Elder | 20,000 | Final form, special effects |

### XP Sources

| Activity | XP Earned |
|----------|-----------|
| Feeding (3x/day max) | 25 XP each |
| Running with pet equipped | 10 XP per minute |
| Completing a sprint (with pet equipped) | 50 XP |

### Evolution Bonuses

As pets evolve, their ability gets stronger:

| Evolution Stage | Ability Effectiveness |
|-----------------|----------------------|
| 1-3 | 50% |
| 4-6 | 75% |
| 7-9 | 100% |
| 10 | 125% |

**Example:** Ember's "Ignite" ability (+15% RP on short sprints)
- Stage 1-3: +7.5% RP
- Stage 4-6: +11.25% RP
- Stage 7-9: +15% RP
- Stage 10: +18.75% RP

### Evolution Animation

When a pet reaches enough XP:

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│                     ✨ EVOLUTION! ✨                            │
│                                                                 │
│              [Stage 4 Image] → [Stage 5 Image]                 │
│                                                                 │
│                  Ember evolved to Youth!                        │
│                                                                 │
│              Ignite ability increased to 75%!                   │
│                                                                 │
│                      [ Continue ]                               │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 8. Ability Tree System

### Overview

The Ability Tree is a **visual skill tree** where players spend points to unlock permanent upgrades. It has two sections:

1. **Player Abilities** - Affect the player (RP gains, sprint bonuses, etc.)
2. **Pet Abilities** - Enhance each pet's unique ability

### Ability Tree UI

The tree should be:
- **Zoomable** - Pinch to zoom in/out
- **Pannable** - Drag to navigate
- **Visual** - Nodes connected by lines showing prerequisites
- **Beautiful** - Each node has an icon and glow effect when unlocked

```
┌─────────────────────────────────────────────────────────────────┐
│  Ability Tree                                    AP: 5  PP: 3   │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────┬─────────┐                                         │
│  │ Player  │  Pets   │  ← Tab selector                         │
│  └─────────┴─────────┘                                         │
│                                                                 │
│  [PLAYER TAB - Zoomable Tree]                                   │
│                                                                 │
│                    ┌───────┐                                    │
│                    │ START │                                    │
│                    └───┬───┘                                    │
│                        │                                        │
│              ┌─────────┼─────────┐                              │
│              │         │         │                              │
│          ┌───▼───┐ ┌───▼───┐ ┌───▼───┐                         │
│          │ RP I  │ │ XP I  │ │Coin I │                         │
│          │ +5%   │ │ +5%   │ │ +5%   │                         │
│          └───┬───┘ └───┬───┘ └───┬───┘                         │
│              │         │         │                              │
│          ┌───▼───┐ ┌───▼───┐ ┌───▼───┐                         │
│          │ RP II │ │ XP II │ │Coin II│                         │
│          │ +10%  │ │ +10%  │ │ +10%  │                         │
│          └───┬───┘ └───┬───┘ └───┬───┘                         │
│              │         │         │                              │
│              └─────────┼─────────┘                              │
│                        │                                        │
│                    ┌───▼───┐                                    │
│                    │SPRINT │                                    │
│                    │MASTER │                                    │
│                    │ +15%  │                                    │
│                    └───────┘                                    │
│                                                                 │
│  [Tap a node to see details and unlock]                         │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Ability Points (AP) - Player Abilities

Earned through:
- Level ups (1 AP per level)
- Major achievements (varies)
- First pet catch (1 AP bonus)

### Pet Points (PP) - Pet Abilities

Earned through:
- Each pet evolution (1 PP at stages 3, 6, 9, 10)
- Running milestones (every 50km total)

### Player Ability Tree Nodes

```swift
struct PlayerAbilityTree {
    static let nodes: [AbilityNode] = [
        // TIER 1 - Starting branches (choose your path)
        AbilityNode(
            id: "rp_1",
            name: "RP Boost I",
            description: "+5% RP from all sources",
            tier: 1,
            cost: 1,
            effect: .rpBonus(0.05),
            prerequisites: []
        ),
        AbilityNode(
            id: "xp_1",
            name: "XP Boost I",
            description: "+5% XP from all sources",
            tier: 1,
            cost: 1,
            effect: .xpBonus(0.05),
            prerequisites: []
        ),
        AbilityNode(
            id: "coin_1",
            name: "Coin Boost I",
            description: "+5% coins from all sources",
            tier: 1,
            cost: 1,
            effect: .coinBonus(0.05),
            prerequisites: []
        ),
        
        // TIER 2 - Improved versions
        AbilityNode(
            id: "rp_2",
            name: "RP Boost II",
            description: "+10% RP from all sources",
            tier: 2,
            cost: 2,
            effect: .rpBonus(0.10),
            prerequisites: ["rp_1"]
        ),
        AbilityNode(
            id: "xp_2",
            name: "XP Boost II",
            description: "+10% XP from all sources",
            tier: 2,
            cost: 2,
            effect: .xpBonus(0.10),
            prerequisites: ["xp_1"]
        ),
        AbilityNode(
            id: "coin_2",
            name: "Coin Boost II",
            description: "+10% coins from all sources",
            tier: 2,
            cost: 2,
            effect: .coinBonus(0.10),
            prerequisites: ["coin_1"]
        ),
        
        // TIER 3 - Specialized
        AbilityNode(
            id: "sprint_master",
            name: "Sprint Master",
            description: "+15% to all sprint rewards",
            tier: 3,
            cost: 3,
            effect: .sprintBonus(0.15),
            prerequisites: ["rp_2", "xp_2", "coin_2"]
        ),
        AbilityNode(
            id: "pet_lover",
            name: "Pet Lover",
            description: "+25% pet evolution XP",
            tier: 3,
            cost: 3,
            effect: .petXpBonus(0.25),
            prerequisites: ["xp_2"]
        ),
        AbilityNode(
            id: "lucky_runner",
            name: "Lucky Runner",
            description: "+2% pet catch rate",
            tier: 3,
            cost: 3,
            effect: .catchRateBonus(0.02),
            prerequisites: ["rp_2"]
        ),
        
        // TIER 4 - Powerful
        AbilityNode(
            id: "passive_income",
            name: "Passive Income",
            description: "+50% passive rewards while running",
            tier: 4,
            cost: 4,
            effect: .passiveBonus(0.50),
            prerequisites: ["sprint_master"]
        ),
        AbilityNode(
            id: "evolution_accelerator",
            name: "Evolution Accelerator",
            description: "-20% XP needed for pet evolution",
            tier: 4,
            cost: 4,
            effect: .evolutionDiscount(0.20),
            prerequisites: ["pet_lover"]
        ),
        
        // TIER 5 - Ultimate
        AbilityNode(
            id: "champion",
            name: "Champion",
            description: "+25% RP, +25% XP, +25% Coins",
            tier: 5,
            cost: 5,
            effect: .allBonus(0.25),
            prerequisites: ["passive_income", "evolution_accelerator"]
        ),
    ]
}
```

### Pet Ability Tree

Each pet's unique ability can be upgraded 5 times:

| Level | Effect Multiplier | PP Cost |
|-------|-------------------|---------|
| 1 | 100% (base) | Free |
| 2 | 125% | 2 PP |
| 3 | 150% | 3 PP |
| 4 | 175% | 4 PP |
| 5 | 200% | 5 PP |

**Example - Ember's Ignite:**
- Level 1: +15% RP on short sprints
- Level 2: +18.75% RP
- Level 3: +22.5% RP
- Level 4: +26.25% RP
- Level 5: +30% RP

```
┌─────────────────────────────────────────────────────────────────┐
│  Pet Abilities                                       PP: 3      │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Select a pet to upgrade:                                       │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │  🔥 Ember (Stage 5)                                         ││
│  │  Ignite - +15% RP on sprints under 35s                      ││
│  │                                                             ││
│  │  Level: ★★☆☆☆ (2/5)                                        ││
│  │  Current Effect: +18.75%                                    ││
│  │                                                             ││
│  │  [ Upgrade to Level 3 - 3 PP ]                              ││
│  │  Next Effect: +22.5%                                        ││
│  └─────────────────────────────────────────────────────────────┘│
│                                                                 │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │  💧 Splash (Stage 3)                                        ││
│  │  Flow - +10% passive XP during runs                         ││
│  │                                                             ││
│  │  Level: ★☆☆☆☆ (1/5)                                        ││
│  │  Current Effect: +10%                                       ││
│  │                                                             ││
│  │  [ Upgrade to Level 2 - 2 PP ]                              ││
│  │  Next Effect: +12.5%                                        ││
│  └─────────────────────────────────────────────────────────────┘│
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Ability Data Types

```swift
enum AbilityEffect: Codable {
    case rpBonus(Double)
    case xpBonus(Double)
    case coinBonus(Double)
    case sprintBonus(Double)
    case petXpBonus(Double)
    case catchRateBonus(Double)
    case passiveBonus(Double)
    case evolutionDiscount(Double)
    case allBonus(Double)
}

struct AbilityNode: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let tier: Int
    let cost: Int
    let effect: AbilityEffect
    let prerequisites: [String]
    let iconName: String
    
    // Position in tree (for rendering)
    let treeX: Double
    let treeY: Double
}

// User's unlocked abilities
struct UserAbilities: Codable {
    var abilityPoints: Int
    var petPoints: Int
    var unlockedPlayerAbilities: Set<String>
    var petAbilityLevels: [String: Int]  // petId -> level
}
```

---

## 9. Reward System

### Sprint Rewards (Every Validated Sprint)

| Reward | Amount | Notes |
|--------|--------|-------|
| RP | 15-25 | Base, before bonuses |
| XP | 30-50 | Base, before bonuses |
| Coins | 40-80 | Base, before bonuses |
| Loot Box | 70% chance | Random rarity |
| **Pet Catch** | See catch rates | Very rare |

### Loot Box Contents

| Rarity | Probability | Contents |
|--------|-------------|----------|
| Common | 55% | 50-100 coins |
| Uncommon | 25% | 100-200 coins, 5-10 gems |
| Rare | 12% | 200-400 coins, 10-25 gems |
| Epic | 6% | 400-800 coins, 25-50 gems |
| Legendary | 2% | 800-1500 coins, 50-100 gems |

### Passive Rewards (While Running)

| Reward | Per Minute |
|--------|------------|
| RP | 1-2 |
| XP | 2-4 |
| Coins | 0 |

### Pet Catch Reward

When a pet is caught:

```swift
struct PetCatchReward {
    let petDefinition: GamePetDefinition
    let bonusCoins: Int = 500
    let bonusRP: Int = 100
    let bonusXP: Int = 200
    let bonusAP: Int = 1  // First pet only
}
```

---

## 10. Progression System

### Rank System (RP)

| Rank | RP Required |
|------|-------------|
| Bronze I | 0 |
| Bronze II | 500 |
| Bronze III | 1,000 |
| Silver I | 2,000 |
| Silver II | 3,500 |
| Silver III | 5,500 |
| Gold I | 8,000 |
| Gold II | 11,000 |
| Gold III | 15,000 |
| Platinum | 20,000 |
| Diamond | 30,000 |
| Champion | 50,000 |

### Player Level (XP)

| Level Range | XP per Level | AP Earned |
|-------------|--------------|-----------|
| 1-10 | 100 | 1 per level |
| 11-20 | 200 | 1 per level |
| 21-30 | 400 | 1 per level |
| 31-40 | 800 | 1 per level |
| 41-50 | 1600 | 1 per level |

### Streak System

| Streak Days | Bonus |
|-------------|-------|
| 1-3 | +5% all rewards |
| 4-7 | +10% all rewards |
| 8-14 | +15% all rewards |
| 15+ | +20% all rewards |

---

## 11. Economy & Currencies

### Currencies

| Currency | Source | Sink |
|----------|--------|------|
| Coins | Sprints, loot boxes | Shop items |
| Gems | Loot boxes (rare) | Premium items |
| AP | Level ups, achievements | Player ability tree |
| PP | Pet evolutions, milestones | Pet ability upgrades |

### Shop System

MVP shop offers:
- **Pet Food** - Extra feeding beyond 3/day (100 coins)
- **XP Boost** - +50% XP for 1 hour (500 coins)
- **Loot Boxes** - Various rarities (gems)

---

## 12. iOS App Specifications

### Tab Structure

```
┌────────┬──────┬──────────┬──────┬─────────┐
│  Home  │ Pets │ Abilities│ Shop │ Profile │
└────────┴──────┴──────────┴──────┴─────────┘
   🏠       🐾       ⚡        🛒      👤
```

### Tab 1: Home

```
┌─────────────────────────────────────────────────────────────────┐
│  Welcome, [Name]                               💰 1,234  💎 15  │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │  👑 SILVER II                           2,450 RP          │ │
│  │  ━━━━━━━━━━━━━━━━░░░░░░  550 to Silver III               │ │
│  │  🔥 5 day streak (+10% rewards)          Level 8          │ │
│  └───────────────────────────────────────────────────────────┘ │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │           [ START RUN ON WATCH ]                          │ │
│  │           1 pet equipped                                  │ │
│  └───────────────────────────────────────────────────────────┘ │
│                                                                 │
│  Your Pets (3/10)                                     See All   │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                      │
│  │  🔥 Ember │  │ 💧Splash │  │ 🌱Sprout │                      │
│  │  Stage 5  │  │ Stage 3  │  │ Stage 2  │                      │
│  │  ★ Equip  │  │          │  │          │                      │
│  └──────────┘  └──────────┘  └──────────┘                      │
│                                                                 │
│  Undiscovered: 7 pets remain...                                 │
│                                                                 │
│  Recent Runs                                           See All  │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │  Today              ⚡ 4 sprints   ★ +180 RP              │ │
│  │  32 min             No new pets                           │ │
│  └───────────────────────────────────────────────────────────┘ │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Tab 2: Pets

```
┌─────────────────────────────────────────────────────────────────┐
│  My Pets                                                3/10    │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Equipped                                                       │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │  ┌──────────┐                                             │ │
│  │  │   🔥     │  Ember • Youth (Stage 5)                   │ │
│  │  │  Ember   │  Ignite: +11.25% RP on short sprints       │ │
│  │  │ Stage 5  │  1,234 / 2,000 XP to Adolescent            │ │
│  │  │   😊     │  ━━━━━━━━░░░░░                             │ │
│  │  └──────────┘  [ Feed 🍖 ] [ Unequip ]                   │ │
│  └───────────────────────────────────────────────────────────┘ │
│                                                                 │
│  Collection                                                     │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                      │
│  │   🔥     │  │   💧     │  │   🌱     │                      │
│  │  Ember   │  │  Splash  │  │  Sprout  │                      │
│  │ Stage 5  │  │ Stage 3  │  │ Stage 2  │                      │
│  │ ★ Equip  │  │          │  │          │                      │
│  └──────────┘  └──────────┘  └──────────┘                      │
│                                                                 │
│  Undiscovered (7)                                               │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐        │
│  │   ???    │  │   ???    │  │   ???    │  │   ???    │        │
│  │  Zephyr  │  │  Pebble  │  │  Spark   │  │  Shadow  │        │
│  │          │  │          │  │          │  │          │        │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘        │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                      │
│  │   ???    │  │   ???    │  │   ???    │                      │
│  │  Frost   │  │  Blaze   │  │   Luna   │                      │
│  │          │  │          │  │          │                      │
│  └──────────┘  └──────────┘  └──────────┘                      │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Tab 3: Abilities (Ability Tree)

```
┌─────────────────────────────────────────────────────────────────┐
│  Ability Tree                                    AP: 5  PP: 3   │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────┬─────────────┐                                 │
│  │   Player    │    Pets     │  ← Segment Control              │
│  └─────────────┴─────────────┘                                 │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │                                                           │ │
│  │           [ZOOMABLE, PANNABLE TREE VIEW]                  │ │
│  │                                                           │ │
│  │                    ┌─────┐                                │ │
│  │                    │START│                                │ │
│  │                    └──┬──┘                                │ │
│  │           ┌──────────┼──────────┐                         │ │
│  │        ┌──▼──┐    ┌──▼──┐    ┌──▼──┐                      │ │
│  │        │RP I │    │XP I │    │$$ I │                      │ │
│  │        │ ✓   │    │     │    │     │                      │ │
│  │        └──┬──┘    └─────┘    └─────┘                      │ │
│  │        ┌──▼──┐                                            │ │
│  │        │RP II│                                            │ │
│  │        │     │                                            │ │
│  │        └─────┘                                            │ │
│  │                                                           │ │
│  │  Pinch to zoom • Drag to pan                              │ │
│  │                                                           │ │
│  └───────────────────────────────────────────────────────────┘ │
│                                                                 │
│  Selected: RP Boost II                                          │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │  +10% RP from all sources                                 │ │
│  │  Requires: RP Boost I (✓)                                 │ │
│  │  Cost: 2 AP                                               │ │
│  │                               [ Unlock - 2 AP ]           │ │
│  └───────────────────────────────────────────────────────────┘ │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Tab 4: Shop

```
┌─────────────────────────────────────────────────────────────────┐
│  Shop                                            💰 1,234  💎 15│
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Pet Care                                                       │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │  🍖 Pet Food                                              │ │
│  │  Extra feeding for any pet                                │ │
│  │                                        💰 100   [ Buy ]   │ │
│  └───────────────────────────────────────────────────────────┘ │
│                                                                 │
│  Boosts                                                         │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │  ⚡ XP Boost (1 hour)                                      │ │
│  │  +50% XP from all sources                                 │ │
│  │                                        💰 500   [ Buy ]   │ │
│  └───────────────────────────────────────────────────────────┘ │
│                                                                 │
│  Loot Boxes                                                     │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐             │
│  │  📦 Basic   │  │ 📦 Premium  │  │ 📦 Ultimate │             │
│  │             │  │     ✨      │  │     ⭐      │             │
│  │  💎 50     │  │   💎 200   │  │   💎 500   │             │
│  │  [ Buy ]    │  │  [ Buy ]    │  │  [ Buy ]    │             │
│  └─────────────┘  └─────────────┘  └─────────────┘             │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Tab 5: Profile

```
┌─────────────────────────────────────────────────────────────────┐
│  Profile                                                   ⚙️   │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │     ┌───────┐    John Doe                                 │ │
│  │     │  JD   │    Level 8 • Silver II                      │ │
│  │     └───────┘    🔥 5 day streak                          │ │
│  └───────────────────────────────────────────────────────────┘ │
│                                                                 │
│  Stats                                                          │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐        │
│  │   23     │  │   67     │  │   3/10   │  │  2,450   │        │
│  │   Runs   │  │ Sprints  │  │   Pets   │  │    RP    │        │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘        │
│                                                                 │
│  Ability Points: 5 AP remaining                                 │
│  Pet Points: 3 PP remaining                                     │
│                                                                 │
│  Run History                                           See All  │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │  Today           4 sprints   32 min   +180 RP             │ │
│  │  Yesterday       3 sprints   25 min   +145 RP             │ │
│  └───────────────────────────────────────────────────────────┘ │
│                                                                 │
│  Settings                                                       │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │  Notifications                                        >   │ │
│  │  Health Permissions                                   >   │ │
│  │  Privacy                                              >   │ │
│  │  Help & Support                                       >   │ │
│  └───────────────────────────────────────────────────────────┘ │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │                    [ Sign Out ]                           │ │
│  └───────────────────────────────────────────────────────────┘ │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Pet Catch Animation

When a pet is caught (RARE event):

```
Stage 1: Full-screen celebration
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│                     ✨ NEW PET CAUGHT! ✨                       │
│                                                                 │
│                   [Silhouette with glow]                        │
│                                                                 │
│                      [ Tap to Reveal ]                          │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘

Stage 2: Reveal with fireworks
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│                        🎉 🎉 🎉                                │
│                                                                 │
│                    ┌─────────────┐                              │
│                    │     🌬️     │                              │
│                    │   Zephyr   │                              │
│                    │  (Baby)    │                              │
│                    └─────────────┘                              │
│                                                                 │
│             "An air spirit that attracts more                   │
│              sprint opportunities!"                             │
│                                                                 │
│           Tailwind: +10% encounter chance                       │
│                                                                 │
│                 +500 Coins • +100 RP • +200 XP                 │
│                                                                 │
│                      [ Continue ]                               │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 13. watchOS App Specifications

### Watch App Flow

```
Start View → Running View ↔ Sprint View → [Pet Catch?] → Summary View
```

### Watch Screens

**Start View:**
```
┌─────────────────────┐
│        IPPO         │
│                     │
│    ┌───────────┐    │
│    │  ▶ START  │    │
│    │    RUN    │    │
│    └───────────┘    │
│                     │
│    🔥 Ember (Lv.5)  │
│    equipped         │
│                     │
└─────────────────────┘
```

**Running View:**
```
┌─────────────────────┐
│  00:12:34           │
│                     │
│  ♥ 142  ⚡ 158      │
│                     │
│  Sprints: 2 ✓       │
│                     │
│  [ Pause ]  [ End ] │
│                     │
└─────────────────────┘
```

**Sprint View:**
```
┌─────────────────────┐
│                     │
│   🏃 SPRINT NOW!    │
│                     │
│  ━━━━━━━━━░░░░░░   │
│                     │
│      0:23           │
│                     │
└─────────────────────┘
```

**Pet Catch View (Rare!):**
```
┌─────────────────────┐
│                     │
│   ✨ NEW PET! ✨    │
│                     │
│      🌬️ Zephyr     │
│       (Baby)        │
│                     │
│   See on iPhone!    │
│                     │
└─────────────────────┘
```

**Summary View:**
```
┌─────────────────────┐
│     COMPLETE ✓      │
│                     │
│   28:45             │
│   Sprints: 3/3 ✓    │
│   RP: +180          │
│                     │
│    ┌───────────┐    │
│    │   Done    │    │
│    └───────────┘    │
└─────────────────────┘
```

---

## 14. Data Architecture

### GameData.swift

```swift
@MainActor
final class GameData {
    static let shared = GameData()
    
    let allPets: [GamePetDefinition] = [
        GamePetDefinition(
            id: "pet_01",
            name: "Ember",
            description: "A fiery spirit that burns brightest in short bursts",
            abilityName: "Ignite",
            abilityDescription: "+15% RP on sprints under 35 seconds",
            evolutionImageNames: [
                "ember_stage_01", "ember_stage_02", "ember_stage_03",
                "ember_stage_04", "ember_stage_05", "ember_stage_06",
                "ember_stage_07", "ember_stage_08", "ember_stage_09",
                "ember_stage_10"
            ]
        ),
        // ... 9 more pets
    ]
    
    func pet(byId id: String) -> GamePetDefinition? {
        allPets.first { $0.id == id }
    }
}
```

### UserData.swift

```swift
@MainActor
final class UserData: ObservableObject {
    static let shared = UserData()
    
    @Published var profile: PlayerProfile
    @Published var ownedPets: [OwnedPet]
    @Published var abilities: UserAbilities
    @Published var lootBoxes: [LootBox]
    @Published var coins: Int
    @Published var gems: Int
    @Published var runHistory: [CompletedRun]
    @Published var currentStreak: Int
}

struct PlayerProfile: Codable {
    var id: String
    var displayName: String
    var rp: Int
    var xp: Int
    var level: Int
    var rank: Rank
    var equippedPetId: String?  // Only 1 pet equipped
    var totalRuns: Int
    var totalSprints: Int
}

struct UserAbilities: Codable {
    var abilityPoints: Int       // Spend on player tree
    var petPoints: Int           // Spend on pet upgrades
    var unlockedPlayerAbilities: Set<String>
    var petAbilityLevels: [String: Int]  // petId -> level (1-5)
}
```

### Firebase Structure

```
users/{userId}/
    profile/
        displayName, rp, xp, level, rank, equippedPetId
        
    abilities/
        abilityPoints: Int
        petPoints: Int
        unlockedPlayerAbilities: [String]
        petAbilityLevels: {petId: Int}
        
    inventory/
        coins, gems, lootBoxes
        
users/{userId}/pets/{petId}/
    petDefinitionId, evolutionStage, experience, mood
    lastFedDate, feedingsToday, isEquipped, abilityLevel
    
users/{userId}/runs/{runId}/
    date, durationSeconds, sprintsCompleted, rpEarned
    petCaught: String?  // null or pet ID
```

---

## 15. Haptic Feedback System

### Haptic Patterns

| Event | Pattern |
|-------|---------|
| Sprint Start | 3 strong pulses |
| Sprint End | 3 strong pulses |
| Last 5 seconds | Light tick each second |
| Sprint Success | `.success` |
| Sprint Failed | `.failure` |
| **PET CAUGHT** | Special celebration pattern |

### Pet Catch Haptics

```swift
func playPetCaughtCelebration() {
    let device = WKInterfaceDevice.current()
    
    // Dramatic buildup
    for i in 0..<5 {
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.1) {
            device.play(.notification)
        }
    }
    
    // Big celebration
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
        device.play(.success)
    }
}
```

---

## 16. UI/UX Design System

### Color Palette

```swift
struct AppColors {
    // Backgrounds
    static let background = Color(hex: "#0C0C12")
    static let surface = Color(hex: "#1A1A24")
    static let surfaceElevated = Color(hex: "#222230")
    
    // Text
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "#B4B4C4")
    static let textTertiary = Color(hex: "#6B6B7B")
    
    // Brand
    static let brandPrimary = Color(hex: "#00E5FF")
    static let brandSecondary = Color(hex: "#7C3AED")
    
    // Semantic
    static let success = Color(hex: "#22C55E")
    static let warning = Color(hex: "#F59E0B")
    static let danger = Color(hex: "#EF4444")
    
    // Currencies
    static let gold = Color(hex: "#FFD700")
    static let gems = Color(hex: "#E879F9")
    
    // Loot Box Rarity
    static let rarityCommon = Color(hex: "#9CA3AF")
    static let rarityUncommon = Color(hex: "#22C55E")
    static let rarityRare = Color(hex: "#3B82F6")
    static let rarityEpic = Color(hex: "#A855F7")
    static let rarityLegendary = Color(hex: "#F97316")
    
    // Pet-specific (each pet has an accent color)
    static let ember = Color(hex: "#EF4444")      // Red
    static let splash = Color(hex: "#3B82F6")     // Blue
    static let sprout = Color(hex: "#22C55E")     // Green
    static let zephyr = Color(hex: "#A5F3FC")     // Cyan
    static let pebble = Color(hex: "#A8A29E")     // Stone
    static let spark = Color(hex: "#FBBF24")      // Yellow
    static let shadow = Color(hex: "#6366F1")     // Indigo
    static let frost = Color(hex: "#67E8F9")      // Ice blue
    static let blaze = Color(hex: "#F97316")      // Orange
    static let luna = Color(hex: "#E879F9")       // Pink
}
```

### Spacing

```swift
struct AppSpacing {
    static let xxxs: CGFloat = 2
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 6
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let xxxl: CGFloat = 48
    
    static let screenPadding: CGFloat = 20
    static let cardPadding: CGFloat = 16
    static let radiusSm: CGFloat = 8
    static let radiusMd: CGFloat = 12
    static let radiusLg: CGFloat = 16
}
```

---

## 17. Authentication & Backend

### Apple Sign-In

Standard implementation - see original PRD Section 15.

### Firebase Setup

- Authentication (Apple provider)
- Firestore (database)

---

## 18. Implementation Checklist

### Phase 1: Foundation (Week 1)

- [ ] Project setup (iOS + watchOS)
- [ ] Firebase configuration
- [ ] Design system (colors, spacing, typography)
- [ ] GameData.swift with 10 pet definitions
- [ ] UserData.swift with all properties
- [ ] Type files (Pet, Ability, Sprint, Reward, Player)
- [ ] Authentication flow

### Phase 2: Watch Core (Week 1-2)

- [ ] SensorBridge.swift
- [ ] SprintEngine.swift
- [ ] SprintValidator.swift
- [ ] EncounterManager.swift (with catch rate logic)
- [ ] HapticsManager.swift (including pet catch celebration)
- [ ] Watch UI (Start, Running, Sprint, Pet Catch, Summary)

### Phase 3: Pet System (Week 2)

- [ ] PetSystem.swift (feeding, evolution, XP)
- [ ] Evolution stage calculations
- [ ] Pet ability effectiveness by stage
- [ ] Pet detail view
- [ ] Pet catch animation (full-screen celebration)
- [ ] First run tutorial (guaranteed pet)

### Phase 4: Ability Tree (Week 2-3)

- [ ] AbilityTreeData.swift (node definitions)
- [ ] AbilityTreeSystem.swift (unlocking logic)
- [ ] AbilityTreeView (zoomable, pannable)
- [ ] Player abilities tab
- [ ] Pet abilities tab
- [ ] Effect calculations

### Phase 5: iOS UI (Week 3)

- [ ] Tab navigation (5 tabs)
- [ ] Home tab
- [ ] Pets tab (collection + detail)
- [ ] Abilities tab (tree view)
- [ ] Shop tab
- [ ] Profile tab

### Phase 6: Integration (Week 3-4)

- [ ] WatchConnectivity sync
- [ ] CloudService (Firebase)
- [ ] Cross-device testing

### Phase 7: Polish (Week 4)

- [ ] All loading states
- [ ] All error states
- [ ] All empty states
- [ ] Evolution animations
- [ ] Pet catch animations
- [ ] Ability unlock animations
- [ ] Bug fixes

---

## Appendix A: All 10 Pets

```swift
let allPets: [GamePetDefinition] = [
    GamePetDefinition(
        id: "pet_01",
        name: "Ember",
        description: "A fiery spirit that burns brightest in short bursts",
        abilityName: "Ignite",
        abilityDescription: "+15% RP on sprints under 35 seconds",
        evolutionImageNames: ["ember_stage_01", ..., "ember_stage_10"]
    ),
    GamePetDefinition(
        id: "pet_02",
        name: "Splash",
        description: "A water creature that rewards steady effort",
        abilityName: "Flow",
        abilityDescription: "+10% passive XP during runs",
        evolutionImageNames: ["splash_stage_01", ..., "splash_stage_10"]
    ),
    GamePetDefinition(
        id: "pet_03",
        name: "Sprout",
        description: "A plant being that helps all pets grow faster",
        abilityName: "Growth",
        abilityDescription: "+20% evolution XP gains",
        evolutionImageNames: ["sprout_stage_01", ..., "sprout_stage_10"]
    ),
    GamePetDefinition(
        id: "pet_04",
        name: "Zephyr",
        description: "An air spirit that attracts more sprint opportunities",
        abilityName: "Tailwind",
        abilityDescription: "+10% encounter chance",
        evolutionImageNames: ["zephyr_stage_01", ..., "zephyr_stage_10"]
    ),
    GamePetDefinition(
        id: "pet_05",
        name: "Pebble",
        description: "A stone creature that stays content longer",
        abilityName: "Fortitude",
        abilityDescription: "-15% mood decay when inactive",
        evolutionImageNames: ["pebble_stage_01", ..., "pebble_stage_10"]
    ),
    GamePetDefinition(
        id: "pet_06",
        name: "Spark",
        description: "An electric being that amplifies rewards",
        abilityName: "Energize",
        abilityDescription: "+25% coins from loot boxes",
        evolutionImageNames: ["spark_stage_01", ..., "spark_stage_10"]
    ),
    GamePetDefinition(
        id: "pet_07",
        name: "Shadow",
        description: "A dark creature that helps find others",
        abilityName: "Stealth",
        abilityDescription: "+5% catch rate for new pets",
        evolutionImageNames: ["shadow_stage_01", ..., "shadow_stage_10"]
    ),
    GamePetDefinition(
        id: "pet_08",
        name: "Frost",
        description: "An ice spirit that maximizes care rewards",
        abilityName: "Preserve",
        abilityDescription: "Feeding gives +50% XP",
        evolutionImageNames: ["frost_stage_01", ..., "frost_stage_10"]
    ),
    GamePetDefinition(
        id: "pet_09",
        name: "Blaze",
        description: "A fire creature that rewards sustained effort",
        abilityName: "Intensity",
        abilityDescription: "+30% RP on sprints over 40 seconds",
        evolutionImageNames: ["blaze_stage_01", ..., "blaze_stage_10"]
    ),
    GamePetDefinition(
        id: "pet_10",
        name: "Luna",
        description: "A celestial being that enhances everything",
        abilityName: "Blessing",
        abilityDescription: "+5% to ALL other pet bonuses",
        evolutionImageNames: ["luna_stage_01", ..., "luna_stage_10"]
    ),
]
```

---

## Appendix B: Complete Player Ability Tree

```
                          ┌─────────┐
                          │  START  │
                          └────┬────┘
                               │
           ┌───────────────────┼───────────────────┐
           │                   │                   │
      ┌────▼────┐        ┌────▼────┐        ┌────▼────┐
      │  RP I   │        │  XP I   │        │ Coin I  │
      │  +5%    │        │  +5%    │        │  +5%    │
      │  1 AP   │        │  1 AP   │        │  1 AP   │
      └────┬────┘        └────┬────┘        └────┬────┘
           │                   │                   │
      ┌────▼────┐        ┌────▼────┐        ┌────▼────┐
      │  RP II  │        │  XP II  │        │ Coin II │
      │  +10%   │        │  +10%   │        │  +10%   │
      │  2 AP   │        │  2 AP   │        │  2 AP   │
      └────┬────┘        └────┬────┘        └────┬────┘
           │                   │                   │
      ┌────▼────┐        ┌────▼────┐              │
      │ Lucky   │        │  Pet    │              │
      │ Runner  │        │ Lover   │              │
      │  +2%    │        │  +25%   │              │
      │ catch   │        │ pet XP  │              │
      │  3 AP   │        │  3 AP   │              │
      └────┬────┘        └────┬────┘              │
           │                   │                   │
           └───────────────────┼───────────────────┘
                               │
                          ┌────▼────┐
                          │ Sprint  │
                          │ Master  │
                          │  +15%   │
                          │  3 AP   │
                          └────┬────┘
                               │
                ┌──────────────┼──────────────┐
                │              │              │
           ┌────▼────┐   ┌────▼────┐   ┌────▼────┐
           │ Passive │   │ Evolve  │   │ Loot    │
           │ Income  │   │ Accel.  │   │ Luck    │
           │  +50%   │   │  -20%   │   │  +15%   │
           │ passive │   │ evo XP  │   │ rare    │
           │  4 AP   │   │  4 AP   │   │  4 AP   │
           └────┬────┘   └────┬────┘   └────┬────┘
                │              │              │
                └──────────────┼──────────────┘
                               │
                          ┌────▼────┐
                          │CHAMPION │
                          │  +25%   │
                          │   ALL   │
                          │  5 AP   │
                          └─────────┘
```

**Total AP to unlock all: 36 AP**
**Max player level in MVP: 50 (gives 50 AP)**

---

*This PRD v2.0 specifies the complete Ippo MVP with 10 rare pets, evolution stages, and ability trees. Build based on this document.*

**Document Version:** 2.0  
**Created:** January 20, 2026
