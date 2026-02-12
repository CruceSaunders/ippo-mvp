# Real-Time Chase System

This document defines the universal chase engine that transforms the IEI's real-time effort signal into moment-to-moment interactive challenges. All future game mechanics (creatures, items, loot, XP, etc.) depend on this foundation.

## 1. Purpose & Relationship to IEI

The Chase System converts the Instantaneous Effort Index (IEI) into gameplay.

IEI measures:

- When effort is increasing
- When effort is decreasing
- When effort is being maintained

The Chase System uses that data to:

- Trigger encounters
- Generate personalized effort challenges
- Communicate instructions via haptics
- Give rewards for successful completion
- Maintain a variable-ratio reward loop
- Keep everything safe, fair, and physiologically appropriate

This section defines how chases work, not what the player is chasing.
Reward content and game theme will be defined afterward.

## 2. Effort Zones (Core Logic)

IEI is a personalized 0-100 effort score, calibrated per user by the IEI system.
Because IEI is already normalized to the user's own minimum and maximum, we can define fixed numeric ranges as relative "zones" that feel the same difficulty for every runner.

### 2.1 Zone Definitions

| Zone | IEI Range | Description | Used in Chases |
| :-- | :-- | :-- | :-- |
| Z1 | 0-19 | Walk / recovery | Recovery only |
| Z2 | 20-39 | Easy jog | Recovery target, easy segments |
| Z3 | 40-59 | Steady run | Common chase segments |
| Z4 | 60-79 | Hard run | Moderate-hard segments |
| Z5 | 80-100 | Max effort | Short, intense segments |

Why this matters:
A beginner and an elite athlete can both be in Z4, but their actual pace/HR/cadence are different. The IEI calibration ensures that "Z4" feels like similarly hard work for both.

### 2.2 IEI Signals Used

- **IEI_fast**: Used to detect entry into a target zone (did they speed up / slow down enough?).
- **IEI_stable**: Used to confirm maintenance of a target zone over time (are they holding it?).

### 2.3 On-Watch Glance

When a segment begins, the watch displays:

- Target Zone (e.g., "Zone 4")
- Current IEI (simple meter or number)
- Optional color band for clarity (e.g., Z2 = green, Z3 = yellow, etc.)

This UI is optional — all chases must be fully playable eyes-free via haptics alone.

## 3. Encounter System (How Chases Begin)

An encounter is the moment something appears for the runner to chase.

### 3.1 Encounter Eligibility

A chase can only begin when:

- Runner is in Z2 or higher
- Runner is stable (confirmed stride, not stop-go behavior)
- No active chase is running
- No recovery cooldown is active
- No safety flags are active (e.g., unsafe HR pattern, near-falls, very erratic motion, or IEI showing sustained extreme effort for too long)

If a safety issue is detected, encounters are temporarily suppressed until signals return to normal.

### 3.2 Variable-Ratio (VRR) Trigger Model

Every second, while eligible, the system checks whether to start a chase using a controlled VRR model:

- **Immediately after recovery ends**: Very low base chance (e.g., ~0.5% per second)
- **As time since last chase increases**: Chance ramps up gradually over time (e.g., up to ~3-4% per second)
- **Pity timer**: If no encounter has triggered after a maximum eligible window (e.g., 120-150 seconds of Z2+ running), a chase is forced.
- **Rarity-aware**: At encounter time, rarity is drawn according to its own probability table (see Section 6).

This model guarantees:

- Unpredictability
- Frequent interaction
- Occasional high-value spikes
- No long "dead zones" with nothing happening

The exact probability curve is tunable, but the behavior must always be: unpredictable but fair.

## 4. Haptic Communication System

This is the "language" of the running game.

### 4.1 Mandatory Haptic Signals

| Purpose | Pattern | Notes |
| :-- | :-- | :-- |
| Chase Start | Two strong taps | Immediately recognizable |
| Increase Effort | Three ascending taps | "Go up one zone" |
| Decrease Effort | Three descending taps | "Go down one zone" |
| Maintain Effort | Single short tap | "Hold this zone" (one-time cue) |
| Segment Success | Three light taps | Micro-reward |
| Chase Complete – Success | Long resonant pulse | Strong reward expectation cue |
| Chase Complete – Fail | Single dull tap | Gentle "missed" feedback |
| Reward Earned | Distinct short-long buzz | Paired with actual reward reveal |

### 4.2 Heartbeat Haptics (Immersion Layer)

During every chase:

- A heartbeat-like vibration runs continuously.
- It starts slower at chase beginning.
- It grows steadily faster as the user progresses through segments.
- It is fastest near the final segment.
- It stops instantly when the chase ends.

This creates tension, a sense of "closing in," and emotional engagement without requiring the user to look at the screen.

## 5. Segment System (Building a Chase)

A chase is a sequence of effort segments.

Each segment requires the runner to:

- Increase effort
- Decrease effort
- Maintain effort

The IEI determines whether the runner hits and holds the required zone.

### 5.1 Segment Types

**Increase Effort Segment**

- Instruction: raise effort into a higher target zone (e.g., Z2 → Z3 or Z3 → Z4).
- IEI_fast must enter the target zone within the grace window (see below).

**Decrease Effort Segment**

- Instruction: reduce effort into a lower target zone (e.g., Z4 → Z3, or Z3 → Z2).
- IEI_fast must drop into the new zone within the grace window.

**Maintain Effort Segment**

- Instruction: hold effort in the current zone.
- IEI_stable must remain inside the target band for the duration.

All three segment types use the same haptic language with different semantics.

### 5.2 Segment Duration Rules

Durations are tuned for physiological realism and must respect zone difficulty:

| Segment Type | Target Zone | Duration Range |
| :-- | :-- | :-- |
| Easy | Z2 | 10-60 sec (sustainable) |
| Moderate | Z3 | 10-45 sec |
| Hard | Z4 | 10-30 sec |
| Max | Z5 | 6-30 sec MAX |

- No segment is ever shorter than 6 seconds.
- No segment is ever longer than 60 seconds, and only Z2 segments can approach that length.
- Exact durations per segment are determined by rarity and chase design (see Section 6).

### 5.3 Zone Entry Grace & Tolerance

For each segment:

- **Entry Grace Period**: Runner has 3-5 seconds to move IEI_fast into the target zone.
- **Tolerance Band**: While holding, IEI_stable can fluctuate within a small band around the zone boundary (e.g., ±3 IEI points).
- **Short Dropouts**: If IEI slips just outside the band for ≤2 seconds, it does not immediately fail the segment.
- **Failure Condition (per segment)**: If IEI stays outside the target band for >2 seconds after entry, the segment is marked as failed.

### 5.4 Number of Segments per Chase

Chases contain:

- 2-8 segments, determined entirely by rarity (see Section 6).
- There is no separate "normal" vs "special" chase type — rarity drives everything.

## 6. Rarity System (Difficulty, Frequency, and Structure)

Rarity controls:

- How often the encounter type appears
- How many segments the chase has
- How many segments hit higher zones
- How long the chase tends to last
- How much cooldown is needed afterward
- The expected value of the reward bundle (actual content defined later)

### 6.1 Rarity Table

These are default targeting ranges; they can be tuned but structure should remain:

| Rarity | Approx Frequency | Segment Count | Difficulty Structure |
| :-- | :-- | :-- | :-- |
| Common | ~55% | 2-3 | Mostly Z2-Z3, light Z4 |
| Uncommon | ~25% | 3-4 | Z3-Z4, with one brief Z5 segment optional |
| Rare | ~12% | 4-6 | Multiple Z4 segments, 1 short Z5 |
| Epic | ~6% | 5-7 | Structured, multiple Z4/Z5 bursts |
| Legendary | ~2% | 6-8 | Carefully designed, short Z5 spikes only |

Rarity is chosen when an encounter triggers, then the chase is built within that rarity's band.

### 6.2 Legendary Encounter Frequency Goal

Design target:
An average runner (~30 minutes per run) should see one Legendary encounter every ~4-6 runs.

Assumptions:

- ~3-5 chases per 30-minute run
- ~12-25 chases over 4-6 runs
- A Legendary chance of ~2% per encounter leads to roughly one Legendary every 4-6 runs, on average.

Developers may adjust this during testing, but the goal is: Legendaries feel rare but not mythical.

## 7. Burnout & Safety System

This system ensures chases are challenging but not unsafe or demoralizing.

### 7.1 Z5 (Max Effort) Constraints

- Max duration for any Z5 segment: 30 seconds
- If two Z5 segments appear back-to-back in a chase: Each must be ≤10 seconds
- If the user repeatedly fails Z5 segments in a run: Future Z5 segments in that session are:
  - Shortened, or
  - Downgraded to Z4 segments

### 7.2 Z4 (Hard Effort) Constraints

- Typical duration: 10-30 seconds
- Rarely up to 40 seconds, and only in high-rarity chases
- Never more than two consecutive Z4 segments

### 7.3 Automatic Fatigue Detection

If the system observes patterns like:

- Repeated failure to enter target zones
- IEI plateauing below requested zone despite "increase effort" cues
- Very slow recovery from high zones

Then, for the remainder of the run or for a fixed window:

- Future segments use lower zones (e.g., Z3 instead of Z4, Z4 instead of Z5)
- Segment durations are shortened within their allowed ranges
- High-rarity chase patterns can be truncated (ending earlier with partial rewards)

### 7.4 Global Safety Overrides

If IEI and sensor data suggest:

- Sustained extreme effort beyond safe bounds
- Very erratic motion (possible trip/fall)
- Abnormal HR patterns (from IEI integration logic, not raw HR)

The system must:

- Immediately end or pause the chase
- Suppress new encounters for a short window
- Allow the user to continue running without pressure

## 8. Chase Structure (How a Full Chase Feels)

Every chase follows the same structural pattern:

1. Encounter Triggered
2. Chase Start haptic (two strong taps)
3. Segment 1 instruction (increase / decrease / maintain)
4. Heartbeat haptic begins
5. Segment 1 Success or Fail feedback
6. Segment 2 instruction
7. …
8. Final Segment Success or Fail
9. Chase Complete haptic (success or fail pattern)
10. Reward haptic (if any reward is granted)
11. Recovery phase begins

All effort demands are IEI-based and fully personalized.

### 8.1 Segment-Level Success and Failure

Per segment:

- **Success** = entered zone within grace period and stayed inside the tolerance band for the required time.
- **Failure** = did not enter the zone in time, or dropped outside the band for >2 seconds.

Partial segment success (e.g., hit zone late) can be tracked for tuning but ultimately each segment counts as success or fail when scoring the chase.

### 8.2 Chase-Level Success and Failure

Typical rules (tunable):

- If the user succeeds on most segments (e.g., ≥60-70%): Chase is marked as success.
- If success rate is below threshold: Chase is marked as fail.

Reward & scoring logic:

- **Success**:
  - Full reward bundle for that rarity.
  - Maximum contribution to whatever "chase score" the upper-level systems use.
- **Fail**:
  - Reduced (but non-zero) reward.
  - Smaller contribution to chase score.

There is never a "zero reward" chase for normal running behavior. Only confirmed manipulation/cheating (handled in IEI PRD) can fully void rewards.

## 9. Recovery System

Recovery is a deliberate part of the core loop. It:

- Protects the runner physiologically
- Smooths the emotional rhythm (from spike back to calm)
- Provides light, guaranteed rewards to keep the loop satisfying

### 9.1 Recovery Requirements

After each chase:

- The user must maintain Z2 effort (easy jog) for a set duration.
- Recovery timer is shown on the watch (optional glance).
- No new encounter can trigger during recovery.
- If the user drops below Z2 (walk or stop):
  - Recovery timer pauses or cancels.
  - Recovery reward may be reduced.

### 9.2 Recovery Duration by Rarity

| Rarity | Recovery Duration |
| :-- | :-- |
| Common | 20-30 sec |
| Uncommon | 25-35 sec |
| Rare | 30-45 sec |
| Epic | 40-60 sec |
| Legendary | 45-60 sec |

These ranges balance physical cooldown needs with pacing — even Legendary chases do not require multi-minute dead zones.

### 9.3 Recovery Rewards

At the end of a valid recovery phase:

- The user receives a small, guaranteed recovery reward (type and magnitude defined later).

Recovery rewards:

- Reinforce healthy pacing and cooldown behavior
- Encourage users to keep jogging, not stop, after a chase
- Keep the reward loop alive even between big spikes

## 10. Variable-Ratio Reinforcement Framework

This is the engagement backbone.

### 10.1 Behavioral Rules

- Encounters occur unpredictably (VRR-based, with pity timers).
- Rarities are unpredictable, within their global percentage targets.
- Segment patterns are unpredictable, within safety and burnout rules.
- Target chase success rate: roughly 70-85%.
- Common encounters feel quick and satisfying.
- Rare/Epic/Legendary encounters feel intense and meaningful.
- Every chase feels worthwhile, even if the user fails or only gets partial rewards.

### 10.2 Psychological Loop

The intended loop is:
Run → Encounter → Haptic Instruction → Effort Change → Heartbeat → Segment Success → Chase Complete → Reward → Recovery → Run…

This uses:

- IEI + personalization for fair challenge
- Haptics for eyes-free interaction
- VRR encounters + rarity for long-term engagement

Game content (e.g. creatures, items, currencies, cosmetics, progression) will later plug into this chase skeleton.

