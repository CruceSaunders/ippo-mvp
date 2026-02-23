# Ippo UI Improvements -- Prioritized Action Items

*Synthesized from competitive research (Pokemon Go, Tamagotchi, Strava, Nike Run Club, Duolingo, Neko Atsume) and partial QA testing.*

---

## QA Findings (from Beru's partial testing)

- Onboarding screens 1-3 render correctly (Welcome, How It Works, Starter Pet Selection)
- Starter pet selection: orange border highlight works, Choose button correctly disables until selection
- Apple Sign-In blocks in iOS Simulator (expected -- requires real device)
- Build succeeds with 0 errors, 0 warnings after fixes
- Beru added a debug skip button for Sign-In in simulator testing

---

## Priority 1: High-Impact, Low-Effort (Do First)

### 1.1 Fix Typography Hierarchy
**Files:** `AppTypography.swift`
**What:** Add missing hero stat style, enforce consistent usage across all views
```swift
static let heroStat = Font.system(size: 48, weight: .bold, design: .rounded)
static let sectionTitle = Font.system(size: 22, weight: .semibold, design: .rounded)
```
**Where to apply:** PostRunSummaryView (make coins/XP HUGE), HomeView (make streak number bigger), ShopSheet (coin balance)

### 1.2 Add Consistent Card Styling ViewModifier
**Files:** New `UI/Design/CardStyle.swift`
**What:** Create a reusable `.cardStyle()` modifier with consistent padding, radius, shadow
```swift
.padding(16)
.background(AppColors.surface)
.cornerRadius(16)
.shadow(color: .black.opacity(0.06), radius: 8, y: 2)
```
**Where to apply:** Every card in HomeView, CollectionView, ShopSheet, ProfileView

### 1.3 Fix Spacing to 8pt Grid
**Files:** All views
**What:** Audit every spacing value and round to nearest 8pt multiple (8, 16, 24, 32)
**Current issues:** Mix of 6, 10, 12, 14, 20 values throughout

### 1.4 Add Debug Skip for Onboarding Sign-In
**Files:** `OnboardingFlow.swift`
**What:** Beru already did this on Mac Mini. Pull his changes and keep the debug-only skip button.

---

## Priority 2: Medium-Impact, Medium-Effort

### 2.1 Upgrade Post-Run Summary (Strava-inspired)
**Files:** `PostRunSummaryView.swift`
**Changes:**
- Make the primary stat (distance or duration) MASSIVE (48pt heroStat)
- Add counting animation to coins and XP numbers
- Add pet reaction section with bounce animation
- Add pet catch reveal with silhouette-to-color transition
- Bottom: "Share" button (placeholder for now -- share card feature)

### 2.2 Enhance Pet Idle Animations
**Files:** `HomeView.swift`
**Changes:**
- Add 3 more idle animation states: gentle side-to-side tilt, breathing scale (0.97-1.03), occasional "look around" rotation
- Randomly cycle between idle animations
- Pet should never feel static

### 2.3 Add Streak Calendar Widget to Home
**Files:** `HomeView.swift`
**Changes:**
- Below the boost banners, add a compact weekly streak calendar
- 7 dots (M T W T F S S), filled for active days
- Reuse the existing `WeeklyProgressDots` component from ProgressRing.swift

### 2.4 Improve Collection Grid Cells
**Files:** `CollectionView.swift`
**Changes:**
- Add subtle drop shadow to pet grid cells
- Add bond level indicator (small hearts or stars below name)
- Make undiscovered silhouettes darker/more mysterious
- Add shimmer animation on rare/legendary pet silhouettes

### 2.5 Add Personality Text to Pet Detail
**Files:** `PetDetailView.swift`, `PetTypes.swift`, `GameData.swift`
**Changes:**
- Add `personality` field to GamePetDefinition
- Show personality in PetDetailView below description
- Examples: "Energetic morning runner. Hates rain.", "Calm and nurturing. Loves sunsets."

---

## Priority 3: High-Impact, High-Effort (Do When Ready)

### 3.1 Living Home Screen Environment
**Files:** `HomeView.swift`, new `PetEnvironmentView.swift`
**Changes:**
- Replace plain `AppColors.surface` container with a gradient environment
- Time-of-day gradient: warm sunrise tones in AM, golden afternoon, cool evening
- Subtle parallax on device tilt (using `MotionManager`)
- Pet positioned "on ground" not floating in center

### 3.2 Tiered Celebration System
**Files:** `CelebrationModal.swift`, `HomeView.swift`
**Changes:**
- Small celebrations: inline toast notification (slide in from top, 2 seconds)
- Medium celebrations: card popup (center screen, confetti, 3 seconds)
- Large celebrations: existing fullscreen modal (pet catch, evolution)
- Map each event to the right tier

### 3.3 Instagram Share Card Generator
**Files:** New `ShareCardView.swift`, `PostRunSummaryView.swift`
**Changes:**
- SwiftUI view rendered as image (using `ImageRenderer`)
- Layout: pet image + run stats + streak + Ippo branding
- 9:16 for Stories, 1:1 for feed
- "Share" button on PostRunSummaryView

### 3.4 Autonomous Pet Behavior on Home Screen
**Files:** `HomeView.swift`
**Changes:**
- State machine: idle -> walking -> playing -> sleeping -> looking_at_user
- Random transitions every 5-15 seconds
- Different animations per state (offset, rotation, scale)
- Pet "notices" when app opens (bounce + hearts on first appear)

---

## Files to Change (Summary)

| File | Priority | Changes |
|------|----------|---------|
| `AppTypography.swift` | P1 | Add heroStat, enforce hierarchy |
| `HomeView.swift` | P1-P3 | Spacing, animations, environment, streak calendar |
| `PostRunSummaryView.swift` | P2 | Hero stat, counting animations, share button |
| `CollectionView.swift` | P2 | Card shadows, bond indicators, silhouette polish |
| `PetDetailView.swift` | P2 | Personality text, spacing |
| `ShopSheet.swift` | P1 | Card styling, spacing |
| `CelebrationModal.swift` | P3 | Tiered celebration tiers |
| `ProfileView.swift` | P1 | Card styling, spacing |
| New `CardStyle.swift` | P1 | Reusable card modifier |
| New `ShareCardView.swift` | P3 | Instagram share card |
| New `PetEnvironmentView.swift` | P3 | Living home background |

---

*Implementation order: P1 items first (can be done in ~1-2 hours), then P2 (another 1-2 hours), then P3 (longer-term polish).*
