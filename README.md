# Racepace - Digital Canoe & Kayak Racing

A UK-based digital racing platform where users compete using their Strava canoe and kayaking activities for real prize money.

## Architecture Overview

### Technology Stack
- **SwiftUI** - Modern declarative UI framework
- **MVVM** - Model-View-ViewModel architecture pattern
- **iOS 17+** - Minimum deployment target
- **Async/Await** - Modern Swift concurrency
- **Firebase** - Backend services (recommended over CloudKit)

### Why Firebase over CloudKit?
1. **Real-time leaderboards** - Firestore's real-time listeners provide instant updates
2. **Complex queries** - Better support for filtering races by multiple criteria
3. **Server-side logic** - Cloud Functions for prize distribution and anti-cheat
4. **Custom auth** - Seamless integration with Strava OAuth
5. **Scalability** - Optimized for high-read scenarios

## Project Structure

```
Boathouse/
├── App/
│   ├── BoathouseApp.swift          # App entry point
│   └── AppState.swift              # Global app state
├── Core/
│   ├── Models/                     # Data models
│   │   ├── User.swift
│   │   ├── Race.swift
│   │   ├── Activity.swift
│   │   ├── Entry.swift
│   │   └── Wallet.swift
│   ├── Services/                   # Business logic services
│   │   ├── AuthService.swift
│   │   ├── StravaService.swift
│   │   ├── KeychainService.swift
│   │   ├── RaceEngine.swift
│   │   ├── LocationService.swift
│   │   └── ModerationService.swift
│   └── MockData/
│       └── MockData.swift          # Test/preview data
├── Features/
│   ├── Authentication/             # Login, register, Strava OAuth
│   ├── Home/                       # Activity feed, rankings
│   ├── Races/                      # Race listings, detail view
│   ├── Entry/                      # User's race entries
│   ├── Account/                    # Profile, settings
│   ├── Wallet/                     # Balance, payments
│   └── Onboarding/                 # New user flow
├── Networking/
│   └── NetworkClient.swift         # API client
├── UI/
│   ├── Navigation/                 # Tab bar, root view
│   ├── Styles/                     # Button styles, text fields
│   └── Components/                 # Reusable UI components
├── Configuration/
│   └── AppConfig.swift             # App configuration
└── Resources/
    └── Assets.xcassets             # Images, colors
```

## Key Features

### User Types
- **Spectator**: View-only access to races and leaderboards
- **Racer**: Full access with Strava connection and wallet

### Race Types
- Top Speed (highest max speed)
- Furthest Distance (longest distance)
- Fastest 1km (best 1km time)
- Fastest 5km (best 5km time)

### Race Durations
- Daily (£1.00 entry)
- Weekly (£4.99 entry)
- Monthly (£15.99 entry)

### Categories
- Junior Girls/Boys (U18)
- Women/Men U23
- Senior Women/Men (23+)
- Masters Women/Men (35+)

### Category Rules
- Juniors may race in higher age categories
- Women may race in men's categories
- Men may NOT race in women's categories
- No user may race in a lower age category

### Prize Distribution
- 99% of entry fees go to prize pool
- 1st Place: 75%
- 2nd Place: 20%
- 3rd Place: 5%
- Platform fee: 1%

## Setup Instructions

### 1. Strava API Configuration

1. Create a Strava API application at https://www.strava.com/settings/api
2. Set the callback domain to `boathouse://strava-callback`
3. Update credentials in `Configuration/AppConfig.swift`:
```swift
static let stravaClientId = "YOUR_CLIENT_ID"
static let stravaClientSecret = "YOUR_CLIENT_SECRET"
```

### 2. URL Scheme Configuration

Add to `Info.plist`:
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>boathouse</string>
        </array>
        <key>CFBundleURLName</key>
        <string>com.boathouse.app</string>
    </dict>
</array>
```

### 3. Apple Pay Configuration

1. Enable Apple Pay capability in Xcode
2. Register merchant ID in Apple Developer Portal
3. Update `merchantIdentifier` in `AppConfig.swift`

### 4. Firebase Setup (Backend)

1. Create Firebase project
2. Enable Authentication, Firestore, Cloud Functions
3. Add `GoogleService-Info.plist` to project
4. Deploy Cloud Functions for:
   - Race ending/prize distribution
   - Activity validation
   - Scheduled race creation

## Backend API Requirements (TODO)

The app requires a backend API with the following endpoints:

### Authentication
- `POST /auth/login` - Email/password login
- `POST /auth/register` - New user registration
- `POST /auth/logout` - Session termination
- `GET /auth/validate` - Session validation
- `POST /auth/reset-password` - Password reset

### Users
- `GET /users/:id` - Get user profile
- `PUT /users/:id` - Update user profile
- `PUT /users/:id/strava` - Update Strava connection

### Races
- `GET /races` - List active races (with filters)
- `GET /races/:id` - Get race details
- `GET /races/:id/leaderboard` - Get race leaderboard
- `POST /races/:id/enter` - Enter a race

### Entries
- `GET /users/:id/entries` - Get user's race entries
- `GET /entries/:id` - Get entry details

### Activities
- `GET /activities` - List activities feed
- `GET /users/:id/activities` - Get user's activities
- `POST /activities` - Import activity from Strava
- `POST /activities/:id/flag` - Flag an activity

### Wallet
- `POST /wallets` - Create wallet
- `GET /wallets/:id` - Get wallet
- `POST /wallets/:id/deposit` - Add funds
- `POST /wallets/:id/withdraw` - Withdraw funds
- `GET /wallets/:id/transactions` - Transaction history

### Moderation (Admin)
- `GET /moderation/flagged` - Get flagged activities
- `POST /moderation/review` - Review flagged activity

## Strava OAuth Flow

1. User taps "Connect Strava"
2. App opens Strava authorization URL in WebView
3. User logs in and grants permissions
4. Strava redirects to `boathouse://strava-callback?code=XXX`
5. App exchanges code for access/refresh tokens
6. Tokens stored securely in Keychain
7. App fetches athlete profile
8. User's age/gender updated for category eligibility

### OAuth Scopes Required
- `read` - Basic profile info
- `activity:read_all` - All activity data
- `profile:read_all` - Full profile access

### Token Refresh
- Access tokens expire after ~6 hours
- Refresh tokens used to obtain new access tokens
- Automatic refresh handled by `StravaService`

## Activity Eligibility Rules

An activity qualifies for races if:
1. Activity type is "Canoeing" or "Kayaking"
2. GPS data is present and verified
3. Start/end location is within UK boundaries
4. Activity timestamp falls within race time window
5. Activity status is "Verified" (not flagged/disqualified)

## Anti-Cheat & Moderation

### Community Flagging
- Users can flag suspicious activities
- After 3+ flags, activity requires admin review
- Flag reasons: Suspicious Speed, Motorized Assistance, Impossible Route, Fake Activity

### Moderation Decisions
- **Approve**: Clear flags, mark as verified
- **Disqualify**: Remove from races, refund entry fees
- **Request Info**: Contact user for explanation

### Allowed Conditions
- Natural stream flow
- Wind assistance
- Washes from other boats

### Prohibited
- Motorized assistance
- Any non-natural aids

## Testing

Mock data is available in `MockData.swift` for:
- User profiles (racer, spectator)
- Wallet and transactions
- Races and entries
- Activities
- Leaderboards

All previews use mock data for testing without backend.

## License

Proprietary - All rights reserved
