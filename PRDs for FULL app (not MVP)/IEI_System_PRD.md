# Product Requirements Document (PRD): Ippo Instantaneous Effort Index (IEI) System

## 1. PURPOSE AND CONTEXT

### 1.1 What is Ippo?

Ippo is an Apple Watch-based running game where real-world effort drives encounters, chases, challenges, rewards, XP, and progression. All real-time gameplay depends on one thing:

**Accurately detecting effort changes in real time.**

That is what the IEI is for.

### 1.2 Purpose of the Instantaneous Effort Index (IEI)

IEI = a 0-100 score updated every 1-2 seconds that reflects:

- True effort level
- Instant effort changes
- Sustained effort trends

IEI drives:

- Encounter triggers
- Chase difficulty
- Success/failure evaluation
- Reward scaling

---

IEI must be:

- Fast (detect changes in 1-2 seconds)
- Personalized (unique to each runner)
- Robust (anti-cheat, anti-manipulation)
- Stable (no jitter, no false spikes)
- Safe (use HR to detect unsafe behavior)

## 2. SENSOR INPUTS AND RAW METRICS

The Apple Watch samples all metrics at 1-50 Hz (depending on hardware & OS).
The IEI engine resamples & aggregates to 1-second windows.

### 2.1 Metric Availability on Apple Watch

**IMPORTANT:** Not all metrics are directly available from Apple Watch sensors. This section clarifies what is real vs. derived vs. estimated.

| Metric | Source | Availability | Notes |
| :-- | :-- | :-- | :-- |
| **Cadence (spm)** | CMPedometer | ✅ REAL | Direct from motion sensors, highly reliable |
| **Heart Rate (HR)** | HealthKit | ✅ REAL | Direct from optical sensor, ~1-3s delay |
| **VPP** | Accelerometer | 🟡 DERIVED | Calculated from vertical acceleration amplitude |
| **HRD** | Calculated | 🟡 DERIVED | Rate of change of HR (real signal, derived value) |
| **Stride Variability** | Accelerometer | 🟡 DERIVED | Calculated from acceleration variance |
| **GCT** | Approximated | ⚠️ ESTIMATED | Apple Watch cannot measure true GCT; approximated from cadence |
| **RRP** | Approximated | ⚠️ ESTIMATED | Not available real-time; estimated from effort level |

### 2.2 Metric Definitions

| Metric | Description | Why It Matters |
| :--: | :--: | :--: |
| Cadence (spm) | Steps per minute | Strong indicator of effort & transitions |
| Vertical Oscillation Power Proxy (VPP) | Wrist acceleration "bounce" amplitude | Strong predictor of surges, sprints |
| Ground Contact Time (GCT) | Estimated foot contact duration (ms) | Drops during high effort (approximated) |
| Heart Rate Derivative (HRD) | Rate of HR change per second | Detects rising/falling effort |
| Stride Variability (SV) | Step-to-step consistency | High at low effort, low at high effort |
| Respiratory Rate Proxy (RRP) | Breaths per minute estimate | Correlates with physiological strain |
| Heart Rate (HR) | Absolute bpm | Used for validation, safety, zone inference |

### 2.3 Secondary Derived Metrics

These are calculated from the primary metrics.

| Derived Metric | Calculation Concept | Purpose |
| :-- | :-- | :-- |
| Effort Trend Score | Weighted average of 1-second deltas in cadence, VPP, HRD | Detects increases/decreases in effort |
| Stride Power Proxy | VPP × Cadence | Approximates mechanical intensity |

## 3. HEART RATE ZONE INFERENCE LAYER

The system infers heart-rate zones automatically using:

### Inputs for Zone Estimation

- Age (user-provided)
- Gender (optional for more accurate models)
- Resting HR (computed automatically over time)
- Maximum observed HR during past sessions
- HR at calibration start (early baseline)
- HR behavior during calibration sprints

### HR Zones (Standardized for our use)

| Zone | % Estimated Max HR | Interpretation |
| :-- | :-- | :-- |
| Z1 | 50-60% | Very easy |
| Z2 | 60-70% | Easy / low effort |
| Z3 | 70-80% | Moderate effort |
| Z4 | 80-90% | Hard effort |
| Z5 | 90-100% | Maximal |

### How Zones Are Used

HR ZONE ≠ direct IEI input.

Instead, HR zones serve three supporting roles:

#### (1) Validate max effort during calibration

If the user hits Z4-Z5 during sprint → accept their "max effort" window.
If cadence/VPP rise but HR stays in Z2 → reject max window, use fallback.

#### (2) Set safety rules

If user stays in Z5 > 60 seconds → reduce chase difficulty automatically.

#### (3) Provide boundary sanity-checks for min/max ranges

Low HR + high metrics? → Possible watch misreading.
High HR + low metrics? → Fatigue distortion; use historical bests instead.

This layer increases calibration accuracy, reduces false positives, and improves safety.

## 4. CALIBRATION SYSTEM

Calibration is divided into two systems:

### A. Day-1 Bootstrapping Calibration

(Defines initial min/max ranges)

### B. Continuous Background Calibration

(Continuously refines those ranges over time)

**IMPORTANT: Day-1 Calibration is REQUIRED before the first real run.** Users cannot skip calibration—it is mandatory for accurate IEI tracking.

## 4A. DAY-1 CALIBRATION RUN — TECHNICAL DEFINITION

### Goal

Establish personalized baseline min/max values for all metrics using real data, not assumptions.

### Procedure

1. User performs a 2-minute guided run:
   - 30s very easy movement
   - 30s normal jog
   - 10-15s max safe sprint
   - 45s cooldown

2. The system collects ~120 seconds of sensor data.

3. For each metric:
   - Compute initial min/max using percentiles:
     - Min = 10th percentile
     - Max = 95th percentile

### Calibration UX Requirements

Each phase transition MUST include:

1. **Strong haptic feedback** to get user's attention
2. **Full-screen overlay** with clear instruction (e.g., "SPRINT NOW!" or "WALK SLOWLY")
3. **Phase duration** displayed prominently
4. **Progress bar** that fills ONLY when user is meeting effort requirements
5. **Real-time validation feedback** (e.g., "✓ Perfect!" or "↑ Speed up!")

Progress tracking per phase:
- Progress bar fills based on **valid samples**, NOT elapsed time
- A sample is "valid" only if the user's effort matches the phase requirements
- Users cannot complete a phase by standing still or going too slow/fast

Phase requirements:
| Phase | Duration | Valid Sample Criteria |
| :-- | :-- | :-- |
| Very Easy | 30s | Cadence 50-130 spm |
| Normal Jog | 30s | Cadence 120-180 spm, VPP 0.4-1.2g |
| Max Sprint | 15s | Cadence 160+ spm, VPP 0.7+g, HR responding |
| Cooldown | 45s | Cadence 50-150 spm |

Minimum valid samples required:
- Easy: 10 seconds
- Jog: 10 seconds
- Sprint: 5 seconds
- Cooldown: 10 seconds

### Fallback Rules

If (max - min) < minimum allowed range → expand automatically.

### Guardrails Table

| Metric | Min Allowed | Max Allowed | Required Min Range | Default Range |
| :-- | :-- | :-- | :-- | :-- |
| Cadence | 100 spm | 210 spm | 35 spm | 50 spm |
| VPP | 0.6 g | 1.8 g | 0.3 g | 0.6 g |
| GCT | 160 ms | 330 ms | 60 ms | 80 ms |
| HRD | -1.5 to +1.5 | Same | 0.8 | 1.2 |
| SV | 2-12% | Same | 3% | 6% |
| RRP | 18-55 | Same | 12 | 20 |

### Cross-Metric Validation (Critical)

Max effort is accepted ONLY if:

- Cadence ↑
- VPP ↑
- HRD ↑ or HR enters Z4/Z5

If not satisfied →
- → Reject max window
- → Use default max: min + default range

## 4B. CONTINUOUS CALIBRATION (ALWAYS ON)

Runs after every session.

### Flow

1. Collect 1-second averaged data.

2. Identify running segments (cadence ≥ 110 spm).

3. Compute per-run candidate min/max values:
   - min_run = 10th percentile
   - max_run = 95th percentile

4. Validate max_run using:
   - Cadence ↑
   - VPP ↑
   - HRD ↑ OR HR enters ≥ Zone 3

5. Update rolling window:
   - Store latest 10 accepted values
   - Current min = avg lowest 3
   - Current max = avg highest 3

### Drift Control

- Max expansion per run: +15%
- Max contraction per run: -5%
- If range collapses repeatedly → revert to historical bests
- Outlier spikes <10s ignored

### Fatigue & Environment Adjustment

If HR is unusually high for the effort metrics:
→ Weight historical max values more to avoid shrinking range artificially.

If metrics are unusually low:
→ Weight historical min values more.

## 5. IEI CALCULATION ENGINE

### 5.1 Normalization

For each metric M:
```
M_norm = (M_current - M_min) / (M_max - M_min)
Clamp to range [0.0-1.0]
```

This maps all metrics to a common 0-1 scale.

### 5.2 Weighted Sum (Primary IEI Score)

**Weight Distribution Philosophy:**

Weights are assigned based on metric reliability and uniqueness:
- **Real metrics** (Cadence, HR-derived) get higher weights
- **Derived metrics** (VPP, SV) get moderate weights based on signal uniqueness
- **Estimated/approximated metrics** (GCT, RRP) get lower weights since they provide redundant information

```
IEI_raw =
    (Cadence_norm × 0.40) +
    (VPP_norm × 0.30) +
    (HRD_norm × 0.15) +
    (GCT_norm × 0.08) +
    (SV_norm × 0.05) +
    (RRP_norm × 0.02)
```

| Metric | Weight | Rationale |
| :-- | :-- | :-- |
| Cadence | 0.40 | Real sensor data, highly responsive, primary effort indicator |
| VPP | 0.30 | Derived but unique signal, excellent for detecting surges |
| HRD | 0.15 | Real (calculated from real HR), good for effort trends |
| GCT | 0.08 | Approximated from cadence—provides confirming signal but partially redundant |
| SV | 0.05 | Derived from accelerometer, adds stability detection |
| RRP | 0.02 | Estimated only—minimal weight to avoid fake data skewing results |

Then convert to 0-100:
```
IEI_raw = IEI_raw × 100
```

### 5.3 Smoothing Layers

Two smoothed versions:
```
IEI_fast = 0.5 × IEI_raw + 0.5 × IEI_fast(previous)
IEI_stable = 0.2 × IEI_raw + 0.8 × IEI_stable(previous)
```

- **IEI_fast** reacts to sudden changes (effort surges). Converges to ~95% of new value in 2-3 seconds.
- **IEI_stable** is used for "hold steady" requirements. Converges to ~95% of new value in 8-10 seconds.

### 5.4 Cold Start Behavior

When a run begins, both IEI_fast and IEI_stable start at 0 and ramp up based on actual sensor data. This means:
- First 3-5 seconds show IEI climbing toward true value
- This is intentional—prevents false high readings before sensors stabilize
- After warmup, changes are detected in 1-2 seconds as required

## 6. EFFORT TREND ENGINE

Tracks rise/fall/stability of effort every second.

### Inputs

- ΔCadence_norm
- ΔVPP_norm
- ΔHRD_norm

(Each is the difference between this second and the previous one.)

### Effort Trend Calculation

```
Trend_score =
    (ΔCadence_norm × 0.50) +
    (ΔVPP_norm × 0.30) +
    (ΔHRD_norm × 0.20)
```

### Interpretation

| Trend Score | Meaning |
| :-- | :-- |
| > +0.15 | Rising effort |
| < -0.15 | Falling effort |
| Between -0.15 and +0.15 | Stable |

### Usage

- Early chase entry detection
- Detecting failed segments faster
- Reward/safety adjustments
- Encouraging or discouraging encounter triggers

This engine dramatically improves real-time responsiveness.

## 7. IEI ZONES (EFFORT BANDS)

Zones are evenly distributed across the 0-100 IEI scale for mathematical clarity and gameplay balance.

| Zone | IEI Range | Width | Description |
| :--: | :--: | :--: | :-- |
| 1 | 0-19 | 20 pts | Recovery / walk |
| 2 | 20-39 | 20 pts | Easy jog |
| 3 | 40-59 | 20 pts | Steady run |
| 4 | 60-79 | 20 pts | Hard effort |
| 5 | 80-100 | 21 pts | Sprint / max |

### Zone Design Rationale

- **Even distribution** ensures zones map naturally to the normalized 0-1 metric scale
- **20-point width** provides comfortable margins for maintaining zones during gameplay
- **Z3 (40-59)** is the primary "game zone" where most chases occur
- **Z1** covers true recovery; **Z5** requires genuine max effort

### Staying in Zones

With proper calibration:
- A runner at ~50% of their effort range lands in Z3
- A runner pushing ~75% lands in Z4
- A runner sprinting at ~90%+ lands in Z5

The 20-point zone width provides forgiveness—natural fluctuations of ±5-10 IEI points won't constantly push users out of their target zone.

Zones drive gameplay (chases, events, rewards).

## 8. SAFETY AND ANTI-CHEAT LOGIC

### 8.1 Safety

Conditions triggering automatic chase reduction:

- HR sustained in Zone 5 > 60 seconds
  → Cut chase length by 40%

- Sudden GCT increase + cadence collapse
  → Trigger fatigue mode

### 8.2 Anti-Cheat

Conditions marking run as invalid:

- Max effort window fails cross-validation
- HR stays flat while cadence/VPP spike
- GCT inconsistent with movement pattern
- Excessive noise or missing watch contact
- Long periods of "inconsistent stride patterns"

Invalid runs → no XP, resources, RP, or crates.

## 9. EXAMPLE CALCULATION (FOR DEV UNDERSTANDING)

### Given:

- Cadence_norm = 0.60
- VPP_norm = 0.50
- HRD_norm = 0.30
- GCT_norm = 0.40
- SV_norm = 0.70
- RRP_norm = 0.55

### Compute IEI_raw

```
IEI_raw =
    0.60 × 0.40 +
    0.50 × 0.30 +
    0.30 × 0.15 +
    0.40 × 0.08 +
    0.70 × 0.05 +
    0.55 × 0.02
= 0.24 + 0.15 + 0.045 + 0.032 + 0.035 + 0.011
= 0.513
```

IEI_raw × 100 = **51.3**

### Meaning

IEI ≈ 51 → **Zone 3 (Steady run)**

This runner is at moderate effort—right in the middle of the scale, which makes sense given metric values averaging around 0.5.

## 10. DEVELOPER REQUIREMENTS (FULL LIST)

### Data Pipeline

- Sample raw watch data at 1-50 Hz
- Aggregate to 1-second epochs
- Maintain rolling buffers for 10-second windows

### Effort Engine

- Compute normalized values
- Compute IEI_raw
- Maintain IEI_fast and IEI_stable
- Compute Effort Trend Score
- Provide real-time API for IEI_fast, IEI_stable, Trend_score, Zone

### Calibration

- Implement Day-1 calibration (MANDATORY before first run)
- Implement continuous background calibration
- Enforce cross-metric validation logic
- Enforce drift caps & default ranges

### Safety & Anti-Cheat

- HR zone tracking
- Safety auto-adjustments
- Invalid session detection
- Run-level reward eligibility flag

### Logging

Log:

- Raw metrics (summarized)
- Normalized metrics
- Trend scores
- Calibration decisions
- Invalid run reasons
- Safety events

## 11. SYSTEM INTEGRATION

The IEI engine outputs:

- IEI_fast → chase entry detection, surge moments
- IEI_stable → chase "hold steady" phases
- Trend_score → rising/falling logic
- Zone (1-5) → effort gates
- Validity flag → reward eligibility

Other systems consume these values but do not influence IEI computations.

## 12. APPLE WATCH IMPLEMENTATION NOTES

### Sensor Approximations

Since Apple Watch doesn't provide all metrics directly, the following approximations are used:

**GCT (Ground Contact Time):**
```
GCT_approx = 400 - (Cadence × 1.1)
Clamped to 160-330 ms
```
This inverse relationship (higher cadence = lower GCT) is physiologically accurate for running.

**RRP (Respiratory Rate Proxy):**
Estimated based on effort level indicators:
- High cadence (>170 spm) → ~40 bpm
- Moderate cadence (150-170 spm) → ~32 bpm
- Low cadence (<150 spm) → ~25 bpm

**VPP (Vertical Power Proxy):**
Calculated from accelerometer vertical axis amplitude:
```
VPP = max(vertical_accel) - min(vertical_accel) over 1-second window
Scaled to typical range 0.6-1.8g
```

**Stride Variability:**
Calculated from standard deviation of vertical acceleration:
```
SV = stddev(vertical_accel) × 10
Clamped to 2-12%
```

### Why These Approximations Work

The reduced weights on GCT (0.08) and RRP (0.02) ensure that approximated values don't dominate the calculation. The primary drivers—Cadence (0.40) and VPP (0.30)—are based on real sensor data and account for 70% of the IEI score.

---

*Last Updated: January 8, 2026*
*Version: 2.0 - Revised weights, zone ranges, and added sensor availability documentation*