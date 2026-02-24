# Ippo v3 -- Complete App Specification

## 1. App Overview

**What it is:** A Tamagotchi-meets-Pokemon-Go running app for iOS and watchOS.

**Target audience:** Ages 16-30, leaning female. Runners who want a fun, gamified reason to keep running.

**Core value prop:** Run with your Apple Watch, catch cute fantasy pets during sprints, care for them daily, and watch them evolve through 10 stages. Neglect them and they run away.

**Platforms:** iOS 17+ (iPhone), watchOS 10+ (Apple Watch)

**Tech stack:** SwiftUI, HealthKit, WatchConnectivity, Firebase Auth (Apple Sign-In), Firebase Firestore, local notifications via UNUserNotificationCenter

---

## 2. Design Principles

- **Warm and inviting:** Cream/amber natural color palette, not dark/techy
- **Pets feel alive:** Bounce animations, heart particles, mood indicators -- pets are the center of every screen
- **Clean and professional:** No "vibe-coded" feel. Consistent spacing, typography, corner radii
- **Minimal friction:** Onboarding in 60-90 seconds. Daily care in under 2 minutes. No walls of text.
- **Addictive loop:** Run -> catch -> care -> evolve -> repeat. Every action feeds the next.

### Color Palette

| Token | Hex | Usage |
|---|---|---|
| background | #FFF8F0 | Main app background (warm cream) |
| surface | #FFF1E6 | Cards, elevated surfaces |
| surfaceElevated | #FFE8D6 | Modals, sheets |
| textPrimary | #2D2A26 | Main text (warm dark brown) |
| textSecondary | #6B6560 | Secondary text |
| textTertiary | #A39E98 | Placeholder text |
| accent | #E88D5A | Primary accent (warm amber/orange) |
| accentSoft | #F5C89A | Soft accent for backgrounds |
| success | #6BBF6B | Positive actions |
| warning | #E8B44A | Low food warnings |
| danger | #D96B6B | Pet sad, runaway |
| coins | #D4A843 | Coin currency |
| xp | #7BB8E0 | XP bar |
| petHappy | #8BC68B | Happy mood |
| petNeutral | #E8C86B | Content mood |
| petSad | #D98B8B | Sad mood |

### Typography

- Primary font: SF Rounded (system)
- Headers: Bold, 22-28pt
- Body: Regular, 16pt
- Captions: Regular, 13pt
- Pet names: Semibold, 20pt

### Corner Radii

- Cards: 16pt
- Buttons: 12pt
- Pet image container: 24pt
- Tab bar: standard (0)

---

## 3. Complete Feature List

### Implemented Features

| Feature | Status | Notes |
|---|---|---|
| 8-screen onboarding flow | DONE | Welcome, how-it-works, starter pick, sign-in, age, health, notifications, ready |
| Home screen with equipped pet | DONE | Large pet image, name, stage, mood, XP bar, care buttons, coins, streak |
| Pet care: feed, water, pet | DONE | Once/day each, consumes inventory, gives XP, shows hearts + bounce |
| Collection screen (3-column grid) | DONE | Owned pets, undiscovered silhouettes with hints, lost pets |
| Pet detail view | DONE | Large image, stats, XP progress, evolution timeline, equip button |
| Shop (7 items) | DONE | Food, water, food pack, water pack, XP boost, encounter boost, hibernation |
| Coin economy | DONE | Earn from running (1/min) + sprints (8-12) + catches (25). Spend in shop. |
| XP and evolution (10 stages) | DONE | Cumulative XP thresholds, mood multipliers, auto stage-up |
| Evolution celebration modal | DONE | "EVOLVING!" fullscreen with confetti when pet stages up |
| Pet catch celebration | DONE | "NEW FRIEND!" fullscreen modal |
| Mood system (happy/content/sad) | DONE | Based on: ran recently + fed today + petted today |
| Pet runaway and rescue | DONE | 14 days sad + 14 days no interaction = lost. Rescue for coins. |
| Hibernation | DONE | 7-day freeze on mood decay and runaway timers |
| Streak system | DONE | Increments on any daily interaction, resets on missed day |
| Local notifications | DONE | Daily care reminders (2-5pm), run reminders (3 days), runaway warnings |
| Post-run summary | DONE | Stats (duration, distance, sprints), coins/XP earned, pet catch reveal |
| Watch sprint/encounter engine | DONE | HR + cadence validation, probability-based encounters, haptic feedback |
| Watch running screen | DONE | Time, HR, distance, pace, sprints, recovery indicator |
| Watch sprint screen | DONE | "SPRINT!" countdown with progress ring |
| Watch summary screen | DONE | Stats + coins + pet catch indicator |
| Apple Sign-In + Firebase Auth | DONE | Sign in, sign out, delete account |
| Cloud sync (Firestore) | DONE | Profile, pets, inventory, run history |
| Profile/settings | DONE | Stats, sign out, delete account, debug panel |
| Warm natural color palette | DONE | Applied across all views |
| Pet image asset catalog | DONE | 30 imagesets (3 pets x 10 stages) |

### Placeholder/Incomplete Features

| Feature | Status | Notes |
|---|---|---|
| Evolution stage images | PLACEHOLDER | All 10 stages use Stage 1 image. Real evolution art needed. |
| Pet idle/happy video animations | NOT STARTED | Using programmatic bounce + heart particles instead |
| 7 catchable pet art | NOT STARTED | Only 3 starters have art (Lumira, Mossworth, Dewdrop) |
| Watch pet display on scroll | PARTIAL | Code exists but no real pet images in Watch assets |
| Pet catch silhouette on Watch | PARTIAL | Shows text "New friend caught!" but no silhouette image |

---

## 4. User Experience Flows

### Flow 1: First-Time Onboarding

```
Welcome -> How It Works (3 items) -> Choose Starter (3 pets)
-> Create Account (Apple Sign-In) -> Age Input (for max HR)
-> HealthKit Permission -> Notification Permission -> Ready!
```

1. User opens app for the first time
2. Sees warm welcome screen with pawprint icon and "Welcome to Ippo"
3. Swipes through 3 how-it-works items (Watch + sprint, catch pets, care for pets)
4. Chooses one of 3 starter pets: Lumira (fox), Mossworth (hedgehog), Dewdrop (dragon)
5. Signs in with Apple
6. Enters age (14-65 picker, calculates max HR via 220-age)
7. Grants HealthKit permission ("Continue" button)
8. Grants notification permission ("Allow Notifications" button)
9. Sees ready screen with chosen pet: "[Pet name] is excited to meet you!"
10. Taps "Let's Go!" -- navigates to Home screen with pet equipped

### Flow 2: Daily Care Loop (1-2 minutes)

```
Notification -> Open App -> See Pet -> Feed/Water/Pet -> Happy Animation -> Close
```

1. User receives push notification: "Lumira is hungry! Come feed them before they get sad."
2. Opens app, lands on Home screen
3. Sees equipped pet with current mood indicator (leaf icon)
4. Taps "Feed" button (if has food in inventory)
5. Pet bounces (scale to 1.12x), floating hearts animate upward
6. XP bar ticks up slightly (+5 XP)
7. Mood indicator may improve
8. Optionally taps "Water" and "Pet" buttons for more XP
9. Closes app. Total interaction: ~60 seconds.

### Flow 3: Run Loop (15-20 minutes active)

```
Watch: Start Run -> Sprint Encounter -> Sprint -> Result -> Continue -> End Run
Phone: Post-Run Summary -> Pet Reveal (if caught) -> Back to Home
```

**On Watch:**
1. Opens Watch app, sees "IPPO" branding and Start button
2. Taps Start Run -- workout session begins
3. Running screen shows: time, HR, distance, pace, sprints count
4. After 60-180 seconds, Watch vibrates (3 strong pulses) -- encounter!
5. Sprint screen appears: "SPRINT!" with countdown timer
6. User sprints for 30-45 seconds
7. Sprint validated: HR must reach Zone 4 (>80% max HR)
8. Result overlay: "+10 coins, +20 XP" (or "New friend caught!" if lucky)
9. 45-second recovery period
10. Repeat encounters 3-4 times per run
11. User taps Stop, sees summary: duration, distance, sprints, coins, XP

**On Phone (after run):**
1. Opens iPhone app
2. Post-run summary appears as fullscreen modal
3. Shows run stats and rewards
4. If pet was caught: dramatic reveal with "YOU CAUGHT A NEW FRIEND!" + confetti
5. Taps Continue to return to Home screen
6. New pet appears in Collection

### Flow 4: Pet Collection Browsing

1. Taps "Collection" tab (grid icon)
2. Sees 3-column grid of owned pets (with images, names, stages)
3. Equipped pet has orange border
4. Below owned pets: "Undiscovered" section with question marks and hint text
5. Below that: "Lost Pets" section (if any ran away) with rescue buttons
6. Taps any owned pet to see PetDetailView
7. In detail view: sees large image, description, mood, XP progress, evolution timeline
8. Can equip/unequip pet

### Flow 5: Shop Purchasing

1. From Collection screen, taps "Shop" button
2. Shop sheet slides up
3. Coin balance shown at top
4. Three sections: Essentials (food, water, packs), Boosts (XP, encounter), Special (hibernation)
5. Each item shows icon, name, description, cost
6. Taps buy button -- coins deducted, inventory updated
7. Green toast appears: "Bought Food!"
8. Buy button greys out if insufficient coins

### Flow 6: Evolution Experience

1. Pet accumulates XP from running, sprints, and daily care
2. When XP crosses a stage threshold (e.g., 200 for Stage 2), evolution triggers
3. Fullscreen celebration modal appears: "EVOLVING! Lumira is growing up!"
4. Shows new stage number and name: "Stage 2 -- Sprout"
5. Confetti animation
6. User taps Continue
7. Pet image updates to new stage (currently same placeholder)
8. Evolution timeline in PetDetailView updates with new checkmark

### Flow 7: Pet Runaway and Rescue

1. If mood stays Sad for 14+ days AND no interaction for 14+ days:
2. Pet moves to "Lost Pets" section in Collection
3. Pet appears greyed out with "Ran away..." text
4. Rescue button shows coin cost (50-300 based on stage)
5. User taps Rescue, coins are spent
6. Pet returns at Sad mood, no XP loss
7. User can re-equip and start caring again

---

## 5. UI Component Inventory

### iOS Screens

#### HomeView (Tab 1)
- **Top bar:** Coin count (circle icon + number), streak (flame icon + number), settings gear button
- **Pet section:** Pet name (22pt bold), stage + mood row, large pet image in rounded container (38% screen height), pet bounce animation (continuous gentle float)
- **XP section:** XPProgressBar component showing progress to next stage
- **Care buttons:** 3 buttons (Feed, Water, Pet) in HStack with icons, labels, inventory counts
- **Boost banners:** XP boost with timer, hibernation status
- **Empty state:** "No pet equipped" with pawprint icon
- **Modals:** Settings sheet, post-run summary fullscreen, evolution celebration fullscreen
- **Animations:** Pet idle float (1.5s ease-in-out loop), happy bounce (spring to 1.12x on care), floating hearts (6 hearts, mixed sizes, fade upward)

#### CollectionView (Tab 2)
- **Header:** "My Pets" title with count, "Shop" button (orange capsule)
- **Owned grid:** LazyVGrid 3 columns, PetGridCell (image, name, stage, orange border if equipped)
- **Undiscovered grid:** Same grid, question marks, hint text
- **Lost pets:** HStack rows with greyed image, name, "Ran away..." text, Rescue button with coin cost
- **Modals:** ShopSheet, PetDetailView

#### PetDetailView (sheet)
- **Pet image:** Large in rounded container (250pt)
- **Info:** Name (24pt bold), description, mood indicator, stage
- **XP bar:** Progress to next stage
- **Evolution timeline:** 10 dots with connecting lines, checkmarks for completed, larger dot for current
- **Actions:** Equip button or "Currently Equipped" badge, caught date

#### OnboardingFlow (8 screens)
- **Layout:** TabView with page style, progress bar at top
- **Screen 1:** Pawprint icon, title, subtitle, "Get Started" button
- **Screen 2:** 3 how-it-works items with SF Symbol icons
- **Screen 3:** 3 starter pet cards in HStack, tap to select with orange border
- **Screen 4:** Apple Sign-In button, display name
- **Screen 5:** Age picker (wheel style), max HR display
- **Screen 6:** Health access with heart icon, "Continue" button
- **Screen 7:** Notification with bell icon, "Allow Notifications" button
- **Screen 8:** Selected pet preview, "[Pet name] is excited to meet you!", "Let's Go!" button

#### PostRunSummaryView (fullscreen)
- **Header:** "Run Complete!" with checkmark
- **Stats:** Duration, distance, sprints in 3-column grid
- **Rewards:** Coins and XP earned
- **Pet section:** Equipped pet happy message or pet catch reveal with animation
- **Continue button**

#### ShopSheet (sheet)
- **Coin balance** at top
- **3 sections:** Essentials, Boosts, Special
- **Item rows:** Icon, name, description, buy button with cost
- **Purchase toast:** Green notification at bottom

#### ProfileView (sheet)
- **Profile header:** Avatar, display name, username
- **Stats list:** Total runs, sprints, distance, streak, pets, level
- **Account actions:** Sign out, delete account
- **Debug section:** (DEBUG only) Load test data, add coins/XP

#### LoginView
- **Logo:** Circular gradient with running figure
- **Title:** "Ippo" + "Run. Catch. Grow."
- **Apple Sign-In** button
- **Terms** text at bottom

### Watch Screens

#### WatchStartView
- "IPPO" title, orange branding
- Start button (circular with play icon)
- Health access prompt if needed

#### WatchRunningView
- Large timer at top
- HR, distance, pace, calories, sprints
- Recovery countdown indicator
- Sprint result overlay (success/failure/catch)

#### WatchSprintView
- "SPRINT!" header
- Progress ring countdown
- HR display
- Encouragement text

#### WatchSummaryView
- "RUN COMPLETE" header
- Stats grid: distance, pace, HR, calories, sprints, coins
- Pet catch indicator
- Done button

### Reusable Components

#### PetImageView
- Displays pet image from asset catalog
- Fallback: circle with pawprint if image not found
- Parameters: imageName, size

#### CelebrationModal
- Fullscreen overlay with confetti particles
- Icon circle with gradient
- Title, subtitle, stats
- Continue button
- Presets: petCaught, levelUp, evolution, streakMilestone

#### XPProgressBar
- Horizontal bar with gradient fill
- Current/target XP text
- Label for next stage name

#### MoodIndicator
- Leaf icon (filled/outline based on mood)
- Text label: Happy/Content/Sad
- Color-coded capsule background

#### ProgressRing
- Circular progress ring (Apple Fitness style)
- Animated fill, overflow support
- Center label options

#### StreakCounter
- Flame icon with gradient
- Day count + "day streak" label
- Pulsing animation when active

---

## 6. Game Loop Interconnections

```
                    +---> Coins ---> Shop ---> Food/Water/Boosts
                    |                              |
  Run on Watch -----+---> XP -----> Evolution     |
                    |                    ^         |
                    +---> Pet Catch      |         |
                                        |         v
                              Mood Multiplier <-- Daily Care (Feed/Water/Pet)
                                   |
                                   v
                            XP Gain Rate
                                   |
                           Low mood? ---> Sad Days ---> Runaway
                                                          |
                                                    Rescue (Coins)
```

**The virtuous cycle:**
1. Running earns coins + XP
2. Coins buy food/water for daily care
3. Daily care keeps mood Happy (1.0x XP multiplier)
4. Happy mood means faster evolution
5. Evolution is the primary reward and motivator
6. Not running = no coins = can't buy care items = pet gets sad = slower XP = eventual runaway

**Retention hooks:**
- Daily notification for care (Tamagotchi-style guilt)
- Streak counter (Duolingo-style loss aversion)
- Evolution stages (long-term progression goal)
- Undiscovered pet silhouettes (collection completionism)
- Runaway threat (consequence for abandonment)

---

## 7. Economy Reference

### Coin Income

| Source | Amount | Notes |
|---|---|---|
| Running | 1 coin/minute | Base income |
| Sprint | 8-12 coins | Random per successful sprint |
| Pet catch | 25 coins | Bonus for catching new pet |

Typical 15-min run: ~15 + ~30-36 = ~50 coins

### Shop Prices

| Item | Cost | Effect |
|---|---|---|
| Food (1x) | 3 coins | Feed pet once |
| Water (1x) | 2 coins | Water pet once |
| Food Pack (5x) | 12 coins | 5 feedings |
| Water Pack (5x) | 8 coins | 5 waterings |
| XP Boost | 40 coins | +30% XP for 2 hours |
| Encounter Boost | 60 coins | +50% catch rate, 1 run |
| Hibernation | 80 coins | 7-day freeze on mood/runaway |

### XP Thresholds (Cumulative)

| Stage | Name | XP Required |
|---|---|---|
| 1 | Newborn | 0 |
| 2 | Sprout | 200 |
| 3 | Seedling | 500 |
| 4 | Bloom | 1,000 |
| 5 | Juvenile | 1,800 |
| 6 | Adolescent | 3,000 |
| 7 | Young | 4,500 |
| 8 | Mature | 6,500 |
| 9 | Prime | 9,000 |
| 10 | Elder | 12,000 |

### XP Sources

| Source | XP | Frequency |
|---|---|---|
| Running | 5 XP/min | During runs |
| Sprint | 15-25 XP | Per successful sprint |
| Feeding | 5 XP | Once/day |
| Watering | 5 XP | Once/day |
| Petting | 2 XP | Once/day |

### Mood Multipliers

| Mood | Multiplier | Conditions |
|---|---|---|
| Happy (3) | 1.0x | Ran recently + fed today + petted today |
| Content (2) | 0.85x | Missing one care action |
| Sad (1) | 0.6x | Missing multiple care actions |

### Catch Rates

- Base: 8% per successful sprint
- With encounter boost: 12%
- Pity timer: guaranteed catch after 15 dry sprints
- Starter pet: chosen during onboarding (free)

### Sprint Timing

- Sprint duration: 30-45 seconds (random)
- Recovery period: 45 seconds after sprint
- Time between encounters: 60-180 seconds (probability increases)
- Warmup before first encounter: 60 seconds

### Runaway Conditions

- 14 consecutive sad days + 14 days no interaction = runaway
- Rescue costs: Stage 1-3 = 50, Stage 4-6 = 100, Stage 7-9 = 200, Stage 10 = 300

---

## 8. Pet Roster

### Starters (chosen during onboarding)

| ID | Name | Art Style | Description | Has Art |
|---|---|---|---|---|
| pet_01 | Lumira | Fennec fox, chibi sticker | A gentle spirit that glows brighter as it grows | YES (all stages placeholder) |
| pet_02 | Mossworth | Leaf hedgehog with bow tie | A mossy friend who loves the shade of old trees | YES (all stages placeholder) |
| pet_03 | Dewdrop | Teal sea dragon | A little sea dragon who dreams of the deep | YES (all stages placeholder) |

### Catchable (caught during runs)

| ID | Name | Description | Has Art |
|---|---|---|---|
| pet_04 | Cinders | A tiny flame that never burns, only warms | NO |
| pet_05 | Breezling | A little cloud that rides the wind | NO |
| pet_06 | Pebblet | A sturdy little rock with a heart of gold | NO |
| pet_07 | Bloomsy | A flower bud waiting for the right moment to bloom | NO |
| pet_08 | Starkit | A fragment of a falling star, still sparkling | NO |
| pet_09 | Duskfawn | A shy creature that appears at sunset | NO |
| pet_10 | Coralette | A tiny shell humming with the sound of the sea | NO |

---

## 9. Known Gaps and Limitations

1. **Evolution images are placeholders** -- all 10 stages show the same Stage 1 image for all 3 starters
2. **No video animations** -- using programmatic bounce + heart particles instead of idle/happy videos
3. **7 catchable pets have no art** -- will show pawprint fallback if caught
4. **Watch pet display** -- code exists but no pet images in Watch asset catalog
5. **Pet catch silhouette on Watch** -- shows text only, no silhouette image
6. **No sound effects** -- entire app is silent
7. **No social features** -- no friends, groups, or leaderboards
8. **No real-money purchases** -- coins are the only currency, earned only from running
9. **Starter pet name mismatch** -- plan says "Puddlejoy" but code uses "Dewdrop" (intentional rename)

---

## 9.1 Future Considerations

1. **Exportable pet cards** -- Let users generate a shareable card image (pet art, name, stage, stats, XP) that they can save to camera roll or share to Instagram Stories / social media. Great for organic virality -- users flex their evolved pets and drive awareness.

---

## 10. QA Test Checklist

### Onboarding
- [ ] Welcome screen renders with pawprint icon and correct text
- [ ] How It Works shows 3 items with correct SF Symbols
- [ ] Starter pet selection: 3 pets displayed, tap highlights with orange border
- [ ] Choose button disabled until pet selected
- [ ] Apple Sign-In screen shows button and error handling
- [ ] Age picker works (14-65 range), shows estimated max HR
- [ ] HealthKit permission screen has "Continue" (not "Allow")
- [ ] Notification permission screen shows correctly
- [ ] Ready screen shows selected pet name and image
- [ ] "Let's Go!" completes onboarding and shows Home

### Home Screen
- [ ] Coins display with circle icon
- [ ] Streak counter shows with flame icon (hidden if 0)
- [ ] Settings gear opens ProfileView sheet
- [ ] Pet name displays (22pt bold rounded)
- [ ] Stage number and name display
- [ ] Mood indicator (leaf icon, colored capsule)
- [ ] Pet image displays in rounded container
- [ ] Pet has idle bounce animation
- [ ] XP progress bar shows correct fill and labels
- [ ] Feed button shows food count, works when available
- [ ] Water button shows water count, works when available
- [ ] Pet button works (no inventory cost)
- [ ] Care buttons show hearts + bounce animation
- [ ] Care buttons grey out after daily use
- [ ] Care buttons grey out when inventory is 0
- [ ] XP boost banner shows when active with timer
- [ ] Hibernation banner shows when active
- [ ] No-pet state shows pawprint and message
- [ ] Post-run summary modal presents when pending

### Collection Screen
- [ ] "My Pets" header with count
- [ ] Shop button (orange capsule)
- [ ] 3-column grid of owned pets
- [ ] Pet cells show image, name, stage
- [ ] Equipped pet has orange border
- [ ] Tapping pet opens PetDetailView
- [ ] Undiscovered section shows "???" with hint text
- [ ] Lost pets section shows (if any lost)
- [ ] Rescue button shows correct coin cost
- [ ] Rescue works when coins sufficient

### Pet Detail
- [ ] Large pet image in rounded container
- [ ] Name, description, mood, stage display correctly
- [ ] XP progress bar correct
- [ ] Evolution timeline shows 10 dots with checkmarks
- [ ] Equip button works
- [ ] Done button dismisses

### Shop
- [ ] Coin balance at top
- [ ] 3 sections: Essentials, Boosts, Special
- [ ] All 7 items display with correct icons, names, descriptions, costs
- [ ] Buy works when coins sufficient
- [ ] Buy disabled when coins insufficient
- [ ] Purchase toast appears
- [ ] Done button dismisses

### Profile/Settings
- [ ] Display name and username shown
- [ ] Stats: runs, sprints, distance, streak, pets, level
- [ ] Sign out works with confirmation
- [ ] Delete account works with confirmation
- [ ] Version footer shows

### Celebrations/Animations
- [ ] Evolution modal triggers on stage-up
- [ ] Evolution modal shows pet name, stage, stage name
- [ ] Pet catch modal works
- [ ] Confetti particles animate
- [ ] Continue button dismisses

### Watch
- [ ] Start screen shows branding and Start button
- [ ] Running screen shows time, HR, distance, pace, sprints
- [ ] Sprint screen shows "SPRINT!" and countdown
- [ ] Sprint result overlay shows coins/XP
- [ ] Pet catch shows "New friend caught!"
- [ ] Summary shows all stats and Done button

---

*Last updated: February 23, 2026*
