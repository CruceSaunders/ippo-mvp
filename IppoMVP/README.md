# Ippo MVP

A fartlek-style running game for iOS and watchOS with pet collection and progression.

## Project Setup

### Prerequisites

- Xcode 15.0+
- iOS 16.0+ / watchOS 9.0+
- Apple Developer Account (for TestFlight/device testing)

### Creating the Xcode Project

1. **Open Xcode** → File → New → Project

2. **Select iOS App**
   - Product Name: `IppoMVP`
   - Team: Select your team
   - Organization Identifier: `com.cruce`
   - Bundle Identifier: `com.cruce.IppoMVP`
   - Interface: SwiftUI
   - Language: Swift

3. **Add Watch App Target**
   - File → New → Target
   - Select "watchOS App"
   - Product Name: `IppoMVPWatch Watch App`
   - Bundle Identifier: `com.cruce.IppoMVP.watchkitapp`
   - Include Watch App: YES

4. **Add Files to Project**
   - Drag the `IppoMVP` folder contents into the iOS target
   - Drag the `IppoMVPWatch Watch App` folder contents into the watchOS target

5. **Configure Capabilities** (for iOS target):
   - Sign in with Apple
   - HealthKit
   - App Groups: `group.cruce.ippomvp.shared`

6. **Configure Capabilities** (for watchOS target):
   - HealthKit
   - App Groups: `group.cruce.ippomvp.shared`

7. **Add Info.plist Keys** (both targets):
   ```xml
   <key>NSHealthShareUsageDescription</key>
   <string>Ippo reads your heart rate and workout data to validate sprints during runs.</string>
   <key>NSHealthUpdateUsageDescription</key>
   <string>Ippo saves your workout sessions to track your running progress.</string>
   <key>NSMotionUsageDescription</key>
   <string>Ippo uses motion data to detect your running cadence.</string>
   ```

### Firebase Setup (Post-Build)

Follow the instructions in `/MVP_Firebase_Setup.md`:
1. Create Firebase project
2. Add iOS app to Firebase
3. Download `GoogleService-Info.plist`
4. Add Firebase SDK packages
5. Enable Apple Sign-In authentication

## Architecture

```
IppoMVP/
├── Config/          # All tunable parameters
├── Core/Types/      # Data models and enums
├── Data/            # GameData (10 pets), UserData
├── Engine/          # Sprint validation, encounter triggering
├── Services/        # Persistence, Watch connectivity
├── Systems/         # Pet, Abilities, Rewards, LootBox
├── UI/              # Design system, Components, Views
└── Utils/           # Haptics, Logging

IppoMVPWatch Watch App/
├── Engine/          # Watch-specific run manager
├── Views/           # Start, Running, Sprint, Summary
├── Services/        # Watch connectivity
├── Data/            # Simplified pet data
└── Utils/           # Watch haptics
```

## Key Features

### The 10 Pets
1. **Ember** - +15% RP on short sprints
2. **Splash** - +10% passive XP
3. **Sprout** - +20% evolution XP
4. **Zephyr** - +10% encounter chance
5. **Pebble** - -15% mood decay
6. **Spark** - +25% loot box coins
7. **Shadow** - +5% catch rate
8. **Frost** - +50% feeding XP
9. **Blaze** - +30% RP on long sprints
10. **Luna** - +5% to all bonuses

### Sprint System
- Duration: 30-45 seconds (random)
- Validation: HR increase (50%), Cadence (35%), HR derivative (15%)
- Pass threshold: 60% total score

### Pet Evolution
- 10 stages per pet (Baby → Elder)
- XP from feeding (3x/day), running, completing sprints
- Ability effectiveness scales with evolution stage

### Ability Tree
- Player abilities: RP, XP, Coin boosts + special abilities
- Pet abilities: 5 upgrade levels per pet
- Points earned from level ups and pet evolutions

## Testing

### Simulator Testing
1. Select `IppoMVP` scheme → iPhone simulator → Run
2. Select `IppoMVPWatch Watch App` scheme → Watch simulator → Run

### Debug Features
In DEBUG builds, go to Profile → Settings → "Load Test Data" to populate sample data.

## Version History

- v2.0 (Jan 2026): Complete MVP with 10 pets, ability trees, simplified sprint system
