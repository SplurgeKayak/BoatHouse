# Copilot Instructions — Boathouse iOS App

## Project Overview

Boathouse is an iOS app that tracks paddle race efforts and kayaking sessions.
It integrates with Strava and Garmin for activity data.
Accuracy and determinism matter more than abstractions.
Models are frequently shared between UI and tests.

## Environment

- **Language:** Swift 5.9+
- **IDE:** Xcode 15+ (Xcode 16.2 in CI)
- **Minimum target:** iOS 16+
- **Testing:** XCTest
- **CI:** GitHub Actions on macOS 15 runners
- **Project:** `Boathouse.xcodeproj`, scheme `Boathouse`

## Build & Test Commands

```bash
# Build
xcodebuild build \
  -project Boathouse.xcodeproj \
  -scheme Boathouse \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.2' \
  -configuration Debug \
  CODE_SIGNING_ALLOWED=NO

# Test
xcodebuild test \
  -project Boathouse.xcodeproj \
  -scheme Boathouse \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.2' \
  -configuration Debug \
  CODE_SIGNING_ALLOWED=NO
```

## Coding Rules

- Prefer value semantics (structs over classes where possible).
- Avoid force unwraps (`!`). Use `guard let`, `if let`, or nil coalescing.
- Respect `@MainActor` and `Sendable` for Swift concurrency.
- XCTest failures may indicate a wrong test, not wrong production code — investigate both.
- Do not refactor unless explicitly requested.
- Fix the smallest surface area possible.
- No architectural changes without explicit approval.

## Project Structure

```
Boathouse/
├── App/              # App lifecycle (AppState)
├── Configuration/    # AppConfig, environment settings
├── Core/
│   ├── Models/       # Data models (Race, User, Session, etc.)
│   ├── Services/     # Business logic (RaceService, SessionService, etc.)
│   ├── MockData/     # Test/preview data
│   └── Utilities/    # String helpers, etc.
├── Features/         # Feature modules
│   ├── Authentication/
│   ├── Home/
│   ├── Races/
│   ├── Goals/
│   ├── Entry/
│   ├── Wallet/
│   ├── Account/
│   ├── Stories/
│   └── Onboarding/
├── Networking/       # NetworkClient
├── UI/               # Shared UI components, styles, navigation
└── Resources/        # Assets, fonts, etc.

BoathouseTests/       # XCTest test files
```

## Key Domain Concepts

- **Session**: A recorded kayaking/paddling activity with GPS data and split times.
- **Race**: A competitive event with duration, category, and type. Users enter races and compete on leaderboards.
- **Entry**: A user's participation in a race, linked to a session.
- **Goal**: Personal targets for distance, speed, or frequency.
- **Leaderboard**: Ranked entries for a race, sorted by performance.
