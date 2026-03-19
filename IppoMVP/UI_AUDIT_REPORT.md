# Ippo MVP — UI Completeness & Error State Audit Report

**Date:** March 18, 2026  
**Auditor:** Swarm D (UI Completeness & Error State Auditor)  
**Scope:** IppoMVP/IppoMVP/UI/Views/, UI/Components/, ContentView, IppoMVPApp

---

## 1. STATE MATRIX

| View | No Pet / 0 Owned | All Lost | 0 Coins | Max Lv (30) | Hibernation | Active Boost | Pending Evo | Pending Run | Care Need | All Care Done | Offline | No Watch | Notif Denied |
|------|------------------|----------|---------|-------------|-------------|--------------|-------------|-------------|-----------|---------------|---------|---------|--------------|
| **HomeView** | PASS (noPetView) | PASS | PASS | PASS (Max Level) | PASS (banner) | PASS (banners) | PASS (fullScreenCover) | PASS (fullScreenCover) | PASS (MoodIndicator) | PASS | MISSING | MISSING | MISSING |
| **CollectionView** | PASS (empty sections) | PASS (lostPetsSection) | N/A | N/A | N/A | N/A | N/A | N/A | N/A | N/A | MISSING | MISSING | N/A |
| **PetDetailView** | N/A (requires pet) | N/A | N/A | PASS (Max Level) | N/A | N/A | N/A | N/A | N/A | N/A | MISSING | N/A | N/A |
| **ShopView** | N/A | N/A | PASS (disabled buttons) | N/A | N/A | N/A | N/A | N/A | N/A | N/A | MISSING | N/A | N/A |
| **ShopSheet** | N/A | N/A | PASS | N/A | N/A | N/A | N/A | N/A | N/A | N/A | MISSING | N/A | N/A |
| **PostRunSummaryView** | PASS (petHappySection optional) | PASS | N/A | N/A | N/A | N/A | N/A | N/A | N/A | N/A | MISSING | N/A | N/A |
| **EvolutionAnimationView** | N/A | N/A | N/A | N/A | N/A | N/A | N/A | N/A | N/A | N/A | N/A | N/A | N/A |
| **OnboardingFlow** | N/A | N/A | N/A | N/A | N/A | N/A | N/A | N/A | N/A | N/A | MISSING | PASS (watchSetupScreen) | PASS (permissionsScreen) |
| **LoginView** | N/A | N/A | N/A | N/A | N/A | N/A | N/A | N/A | N/A | N/A | MISSING | N/A | N/A |
| **ProfileView** | N/A | N/A | N/A | N/A | N/A | N/A | N/A | N/A | N/A | N/A | MISSING | N/A | N/A |
| **AdminDebugView** | PASS (No equipped pet) | N/A | N/A | N/A | PASS | PASS | N/A | N/A | N/A | N/A | N/A | N/A | N/A |
| **TutorialOverlayView** | N/A | N/A | N/A | N/A | N/A | N/A | N/A | N/A | N/A | N/A | N/A | N/A | N/A |

### State Handling Summary

- **No internet / offline:** No view explicitly handles offline state. Cloud sync, auth, and shop purchases could fail silently or show generic errors.
- **No Watch paired:** Only OnboardingFlow (watchSetupScreen) handles this. HomeView firstRunCTA mentions Watch but doesn’t check pairing; users can reach Home without a Watch.
- **Notification denied:** Only OnboardingFlow (permissionsScreen) handles this. No in-app reminder or re-prompt after denial.

---

## 2. NAVIGATION MAP

```
IppoMVPApp
├── !hasCompletedOnboarding → IppoCompleteOnboardingFlow (15 steps)
│   └── onComplete → ContentView
├── !isAuthenticated → LoginView
│   └── (auth success) → ContentView
└── ContentView (TabView)
    ├── Tab 0: HomeView
    │   ├── .sheet(showSettings) → ProfileView [DONE button ✓]
    │   ├── .fullScreenCover(showRunSummary) → PostRunSummaryView [Continue → dismiss ✓]
    │   └── .fullScreenCover(showEvolution) → EvolutionAnimationView [Tap to continue → dismiss ✓]
    ├── Tab 1: CollectionView
    │   └── .sheet(selectedPet) → PetDetailView [Done button ✓]
    │       └── Equip → dismiss() ✓
    └── Tab 2: ShopView (standalone tab, no sheet)
```

### Navigation Issues

| Issue | Location | Severity |
|-------|----------|----------|
| **ShopView has no dismiss** | ShopView is a tab, not a sheet — OK | None |
| **ShopSheet is unused** | ShopSheet exists but is never presented | Dead code |
| **ProfileView → DeleteAccountSheet** | DeleteAccountSheet has Cancel ✓ | None |
| **ProfileView → AdminDebugView** | NavigationLink, back via nav bar ✓ | None |
| **PostRunSummaryView** | No back button; only "Continue" — OK for fullScreenCover | None |
| **EvolutionAnimationView** | Tap to continue dismisses ✓ | None |
| **No dead ends** | All sheets/covers have dismiss paths | None |

---

## 3. TIMER & ANIMATION LIFECYCLE ISSUES

### Timers

| Location | Timer | Invalidated on disappear? | Risk |
|----------|-------|---------------------------|------|
| **HomeView** `startSleepAnimation()` | `Timer.scheduledTimer(6.0, repeats: true)` | ❌ NO | **BUG** — Timer never invalidated; leaks when view disappears during hibernation |
| **HomeView** `FloatingZ.startLoop()` | `Timer.scheduledTimer(floatDuration, repeats: true)` | ❌ NO | **BUG** — Same as above; each Z creates a repeating timer |
| **OnboardingFlow** `watchSetupScreen` | `watchPollTimer` (2.0s) | ✅ YES (onDisappear) | OK |
| **OnboardingFlow** `sprintDemoTimer` | 1.0s countdown | ⚠️ Invalidated in callback only | If user navigates away mid-demo, timer may keep firing until complete |
| **SprintEngine** (Watch) | countdownTimer, sprintTimer | Engine lifecycle | Not in UI scope |
| **EncounterManager** | checkTimer, recoveryTimer | Manager lifecycle | Not in UI scope |

### DispatchQueue.main.asyncAfter

| Location | Purpose | Risk |
|----------|---------|------|
| HomeView | Milestone toast (3s), floating XP (1s), care hint (4s), pet bounce, hearts | View could be gone; closures capture `self` implicitly — potential stale updates |
| HomeView `triggerPetBounce` | Multiple hops via asyncAfter | Rapid navigation could stack bounces |
| ShopView / ShopSheet | Purchase toast (1.5s) | Low risk; sheet/tab usually still visible |
| PostRunSummaryView | Pet reveal delay (1s) | Low risk; fullScreenCover |
| EvolutionAnimationView | Phase transitions | Sequential; low risk |
| TutorialOverlayView | Hint loop, step completion | If user leaves mid-tutorial, asyncAfter chain continues |
| AdminDebugView | Feedback toast (2s) | Low risk |
| PetEnvironmentView | `repeatForever` animations | No onDisappear; animations continue when view off-screen |

### Animation Stacking / Conflicts

- **HomeView:** `triggerPetBounce` uses multiple `asyncAfter`; rapid feed/water/pet could overlap bounces. `isBouncing` guards some but not all.
- **TutorialOverlayView:** `startHintLoop` recurses via `asyncAfter`; no cancellation when view disappears.
- **PetEnvironmentView:** `withAnimation(.linear.repeatForever)` and `withAnimation(.easeInOut.repeatForever)` — no `onDisappear` to stop them.

### Memory / Capture

- Timer closures use `{ _ in Task { @MainActor in ... } }` — weak self not used, but SwiftUI views are value types; risk is timer retention, not classic retain cycles.
- `FloatingZ` and `SleepingZzzOverlay` are child views; parent `HomeView` keeps them alive. When HomeView disappears, timers should be invalidated but currently are not.

---

## 4. SHOP COMPARISON: ShopView vs ShopSheet

| Aspect | ShopView | ShopSheet |
|--------|----------|-----------|
| **Used in app** | ✅ Yes — Tab 2 in ContentView | ❌ No — never presented |
| **Dismiss** | N/A (tab) | Done button ✓ |
| **Essentials** | food, water, foodPack, waterPack | Same |
| **Boosts** | xpBoost, encounterCharm, coinBoost | xpBoost, encounterCharm only |
| **Protection** | hibernation, streakFreeze | hibernation only |
| **Sections** | Essentials, Boosts, Protection | Essentials, Boosts, Special |
| **Coin balance** | Same | Same |
| **Purchase feedback** | SoundManager.play(.shopPurchase) | No sound |
| **Purchase toast** | 1.5s | 1.5s |

### Conclusion

- **ShopView** is the live shop (full catalog).
- **ShopSheet** is unused and has a smaller catalog (no coinBoost, no streakFreeze).
- **Recommendation:** Remove ShopSheet or repurpose it (e.g. quick-shop sheet from Home). If kept, align item list with ShopView and add purchase sound.

---

## 5. ACCESSIBILITY GAPS

### Elements with accessibilityLabel

- ProgressRing, StreakCounter, WeeklyProgressDots, EffortRing
- CelebrationModal (Continue, Celebration)
- EvolutionAnimationView (evolution description)

### Missing accessibilityLabel

| Element | Location | Suggestion |
|---------|----------|------------|
| Settings (gear) button | HomeView toolbar | `accessibilityLabel("Settings")` |
| Food/Water/Pet care tray | HomeView careTray | Label each: "Food, x\(count)", "Water, x\(count)", "Rub pet" |
| Equip button | PetDetailView | "Equip \(petName)" |
| Rescue button | LostPetRow | "Rescue \(petName) for \(cost) coins" |
| Shop buy buttons | ShopView/ShopSheet | "Buy \(itemName) for \(cost) coins" |
| Pet grid cells | PetGridCell | "\(petName), level \(level), \(equipped ? "equipped" : "")" |
| Undiscovered cells | UndiscoveredCell | "Undiscovered pet, hint: \(hintText)" |
| MoodIndicator | MoodIndicator | Uses label from `label`; consider `accessibilityHint` for tip |
| PetImageView | PetImageView | `accessibilityLabel(imageName)` or pet name when available |
| Tab bar items | ContentView | Default Label() provides some; verify VoiceOver |
| Login buttons | LoginView | SignInWithAppleButton has default; Google button needs label |
| Onboarding buttons | OnboardingFlow | "Get Started", "Continue", etc. — verify |
| Profile actions | ProfileView | "Sign Out", "Delete Account" — verify |

### Color Contrast

- AppColors use warm palette; no explicit contrast checks in code.
- Recommendation: Validate textPrimary/textSecondary/textTertiary on background/surface against WCAG 2.1 AA.

---

## 6. BUGS FOUND

| # | Bug | Location | Severity |
|---|-----|----------|----------|
| 1 | **Sleep timer never invalidated** | HomeView `startSleepAnimation()` | Medium — leak when leaving Home during hibernation |
| 2 | **FloatingZ timer never invalidated** | HomeView `FloatingZ.startLoop()` | Medium — 3 timers per hibernation view |
| 3 | **ShopSheet dead code** | ShopSheet.swift | Low — unused; maintenance burden |
| 4 | **Sprint demo timer not invalidated on disappear** | OnboardingFlow `vibrationsAndSprintsScreen` | Low — user can leave during demo |
| 6 | **No offline/network error UI** | ShopView, LoginView, ProfileView, Cloud sync | Medium — poor UX when offline |
| 7 | **No Watch-unpaired warning on Home** | HomeView | Low — firstRunCTA helps but doesn’t check pairing |
| 8 | **0 owned pets + all lost** | CollectionView | Edge case — ownedPetsSection empty, undiscoveredSection shows, lostPetsSection shows; "0/10" in header. No explicit "You have no pets" state. |
| 9 | **Milestone toast asyncAfter** | HomeView line 158–164 | Low — if view disappears, `userData.pendingMilestoneToast = nil` already run; toast overlay could briefly show on wrong tab |

---

## 7. CONFIDENCE

**Overall confidence: 82%**

- **High confidence:** State matrix for main views, navigation map, Shop comparison, timer locations.
- **Medium confidence:** Accessibility (manual VoiceOver testing not done), animation stacking under rapid interaction.
- **Lower confidence:** Exact behavior of 0-owned + all-lost edge case, real-world offline behavior, color contrast values.

---

## RECOMMENDATIONS (PRIORITY)

1. **High:** Invalidate sleep and FloatingZ timers in `onDisappear` (or use a shared timer store and cancel when not needed).
2. **High:** Add offline/network error handling for Shop, Login, and Cloud sync.
3. **Medium:** Remove or repurpose ShopSheet; align with ShopView if kept.
4. **Medium:** Add accessibilityLabel to primary interactive elements (care tray, shop, pet cells, toolbar).
5. **Low:** Invalidate sprint demo timer in OnboardingFlow `onDisappear` when leaving that step.
