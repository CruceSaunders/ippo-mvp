# Firebase Setup Guide for Ippo MVP

**Status:** NOT STARTED - Complete these steps before building

This guide documents the Firebase setup for the MVP.

## Prerequisites

- Xcode project with Bundle ID: `com.cruce.IppoMVP`
- Apple Developer Account

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add Project"
3. Name it "IppoMVP" (or similar)
4. Disable Google Analytics (not needed for MVP)
5. Click "Create Project"

## Step 2: Add iOS App to Firebase

1. In Firebase Console, click "Add App" → iOS
2. Enter Bundle ID: `com.cruce.IppoMVP`
3. App nickname: `Ippo MVP iOS`
4. Download `GoogleService-Info.plist`
5. Add this file to your iOS app target in Xcode

**Note:** For the watchOS app, data syncs via WatchConnectivity from the iOS app. The watch app doesn't need direct Firebase access.

## Step 3: Add Firebase SDK

In Xcode:

1. File → Add Package Dependencies
2. Enter: `https://github.com/firebase/firebase-ios-sdk`
3. Select version: "Up to Next Major" from 10.0.0
4. Select these packages:
   - `FirebaseAuth`
   - `FirebaseFirestore`

5. Add packages to the iOS target only

## Step 4: Enable Firebase Services

### Authentication
1. Build → Authentication → Get Started
2. Sign-in method → Apple → Enable

### Firestore Database
1. Build → Firestore Database → Create database
2. Start in **test mode** for development
3. Location: `us-central` (or closest to users)

## Step 5: Security Rules

Update Firestore rules for production:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Step 6: Initialize Firebase in App

In your `IppoMVPApp.swift`:

```swift
import SwiftUI
import Firebase

@main
struct IppoMVPApp: App {
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

## Data Structure

### `/users/{userId}`
```json
{
  "profile": {
    "displayName": "string",
    "rp": 0,
    "xp": 0,
    "level": 1,
    "rank": "bronze_1",
    "coins": 500,
    "gems": 0,
    "currentStreak": 0,
    "equippedPetId": null,
    "createdAt": "timestamp",
    "lastRunDate": null
  },
  "abilities": {
    "abilityPoints": 0,
    "petPoints": 0,
    "unlockedPlayerAbilities": [],
    "petAbilityLevels": {}
  },
  "inventory": {
    "lootBoxes": { "common": 0, "uncommon": 0, "rare": 0, "epic": 0, "legendary": 0 }
  }
}
```

### `/users/{userId}/pets/{petInstanceId}`
```json
{
  "petDefinitionId": "pet_01",
  "evolutionStage": 1,
  "experience": 0,
  "mood": 7,
  "abilityLevel": 1,
  "isEquipped": false,
  "lastFedDate": null,
  "feedingsToday": 0,
  "caughtAt": "timestamp"
}
```

### `/users/{userId}/runs/{runId}`
```json
{
  "date": "timestamp",
  "durationSeconds": 1800,
  "sprintsCompleted": 4,
  "sprintsTotal": 5,
  "rpEarned": 120,
  "xpEarned": 180,
  "coinsEarned": 250,
  "petCaught": null,
  "lootBoxesEarned": ["common", "uncommon"]
}
```

## Cost Estimation

Firebase free tier (Spark plan) includes:
- 50K auth verifications/month
- 1 GB Firestore storage
- 10 GB transfer/month
- 20K writes/day
- 50K reads/day

For MVP testing with ~100-1000 users, free tier is sufficient.

## Troubleshooting

### "No GoogleService-Info.plist found"
- Ensure file is added to correct target membership in Xcode
- Check Build Phases → Copy Bundle Resources

### "Permission denied" errors
- Check Firestore security rules
- Ensure user is authenticated before database access

### Auth errors
- Verify Sign in with Apple is enabled in Firebase Console
- Check Apple Developer portal has correct Service ID configured
