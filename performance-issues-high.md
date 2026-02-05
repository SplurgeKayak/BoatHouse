# High Priority Performance Issues

Noticeable performance impact to users. Fix in next sprint.

---

## 1. StravaOAuthViewModel - Missing @MainActor on State Updates

**File:** `Boathouse/Features/Authentication/StravaOAuthViewModel.swift`
**Lines:** 67, 87

### Current Issue
`@Published` properties modified in async context without MainActor guarantee.

### Current Code
```swift
func handleOAuthCallback(url: URL) async {
    showWebAuth = false  // Direct update without MainActor!
    isLoading = true     // Direct update without MainActor!

    do {
        // async work...
    }

    isLoading = false  // Direct update without MainActor!
}
```

### Impact
- Race condition: view may read state during update
- Potential UI inconsistency
- SwiftUI warnings in console
- Possible crash on iOS 17+

### Recommended Fix
```swift
@MainActor
func handleOAuthCallback(url: URL) async {
    showWebAuth = false
    isLoading = true

    do {
        // async work...
    }

    isLoading = false
}
```

---

## 2. RacesViewModel - Computed Property Recalculates Every Access

**File:** `Boathouse/Features/Races/RacesViewModel.swift`
**Lines:** 16-34

### Current Issue
`filteredRaces` filters entire array on every property access.

### Current Code
```swift
var filteredRaces: [Race] {
    races.filter { race in  // O(n) on EVERY access
        var matches = true
        if let duration = selectedDuration {
            matches = matches && race.duration == duration
        }
        if let type = selectedRaceType {
            matches = matches && race.type == type
        }
        // ... more conditions
        return matches
    }
}
```

### Impact
- SwiftUI calls this multiple times per render cycle
- With 100 races: 300+ filter operations per second during scroll
- Choppy scrolling
- High CPU usage

### Recommended Fix
```swift
@Published private(set) var filteredRaces: [Race] = []

private var cancellables = Set<AnyCancellable>()

init() {
    Publishers.CombineLatest3($races, $selectedDuration, $selectedRaceType)
        .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
        .map { races, duration, type in
            races.filter { race in
                // filtering logic
            }
        }
        .assign(to: &$filteredRaces)
}
```

---

## 3. HomeViewModel - Redundant Task Wrapper in Combine Sink

**File:** `Boathouse/Features/Home/HomeViewModel.swift`
**Lines:** 31-34

### Current Issue
Creating Task with @MainActor inside Combine sink adds unnecessary overhead.

### Current Code
```swift
$selectedDuration
    .combineLatest($selectedRaceType)
    .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
    .sink { [weak self] _, _ in
        Task { @MainActor [weak self] in  // Unnecessary Task creation!
            await self?.loadLeaderboard()
        }
    }
    .store(in: &cancellables)
```

### Impact
- Extra Task allocation per filter change
- Potential thread-hopping overhead
- Memory churn

### Recommended Fix
```swift
$selectedDuration
    .combineLatest($selectedRaceType)
    .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
    .sink { [weak self] _, _ in
        guard let self else { return }
        Task {
            await self.loadLeaderboard()
        }
    }
    .store(in: &cancellables)
```

---

## 4. NetworkClient - No URLSession Caching Configuration

**File:** `Boathouse/Networking/NetworkClient.swift`
**Line:** 62

### Current Issue
Uses `.shared` URLSession without cache configuration.

### Current Code
```swift
let (data, response) = try await URLSession.shared.data(for: request)
```

### Impact
- No HTTP caching (ETag, Cache-Control ignored)
- Repeated identical requests hit network
- Slower perceived performance
- Higher data usage

### Recommended Fix
```swift
private static let session: URLSession = {
    let config = URLSessionConfiguration.default
    config.urlCache = URLCache(
        memoryCapacity: 10_000_000,  // 10 MB
        diskCapacity: 50_000_000,    // 50 MB
        diskPath: "network_cache"
    )
    config.requestCachePolicy = .returnCacheDataElseLoad
    return URLSession(configuration: config)
}()

func get<T: Decodable>(_ endpoint: String) async throws -> T {
    let (data, response) = try await Self.session.data(for: request)
    // ...
}
```

---

## 5. NetworkClient - JSONDecoder Created Per Request

**File:** `Boathouse/Networking/NetworkClient.swift`
**Lines:** 72-74

### Current Issue
New JSONDecoder instance created for every request.

### Current Code
```swift
func get<T: Decodable>(_ endpoint: String) async throws -> T {
    // ...
    let decoder = JSONDecoder()  // New instance every time!
    decoder.dateDecodingStrategy = .iso8601
    return try decoder.decode(T.self, from: data)
}
```

### Impact
- JSONDecoder is moderately expensive to create
- 10+ requests = 10+ decoder instances
- Memory churn during API-heavy operations

### Recommended Fix
```swift
private static let decoder: JSONDecoder = {
    let d = JSONDecoder()
    d.dateDecodingStrategy = .iso8601
    return d
}()

func get<T: Decodable>(_ endpoint: String) async throws -> T {
    // ...
    return try Self.decoder.decode(T.self, from: data)
}
```

---

## 6. Race.swift - NumberFormatter in Computed Properties

**File:** `Boathouse/Core/Models/Race.swift`
**Lines:** 32-46, 66-81

### Current Issue
Three separate NumberFormatter instances created in computed properties.

### Current Code
```swift
var formattedPrizePool: String {
    let formatter = NumberFormatter()  // Created every access!
    formatter.numberStyle = .currency
    // ...
}

var formattedEntryFee: String {
    let formatter = NumberFormatter()  // Created every access!
    // ...
}

func formattedPrize(for position: Int) -> String {
    let formatter = NumberFormatter()  // Created every call!
    // ...
}
```

### Impact
- Race list with 20 items = 60+ formatter instances
- Each formatter takes ~0.5ms to create
- 30ms+ wasted per list render

### Recommended Fix
Use shared CurrencyFormatter utility (see Critical issues).

---

## 7. User.swift - Expensive Age Calculation

**File:** `Boathouse/Core/Models/User.swift`
**Lines:** 36-41

### Current Issue
`Date()` and `Calendar.current` accessed on every property read.

### Current Code
```swift
var age: Int? {
    guard let dob = dateOfBirth else { return nil }
    let calendar = Calendar.current  // Accessed every call
    let ageComponents = calendar.dateComponents([.year], from: dob, to: Date())  // New Date()!
    return ageComponents.year
}
```

### Impact
- `eligibleCategories` calls `age`, which creates Date() and accesses Calendar
- Multiple Date allocations per user
- Affects category filtering performance

### Recommended Fix
```swift
func age(relativeTo referenceDate: Date = Date()) -> Int? {
    guard let dob = dateOfBirth else { return nil }
    return Calendar.current.dateComponents([.year], from: dob, to: referenceDate).year
}

// Or cache age when user is loaded
private(set) var cachedAge: Int?

mutating func updateCachedAge() {
    cachedAge = age()
}
```

---

## 8. EntryViewModel - Redundant Computed Property Filtering

**File:** `Boathouse/Features/Entry/EntryViewModel.swift`
**Lines:** 12-18

### Current Issue
Two computed properties independently filter the entire entries array.

### Current Code
```swift
var activeEntries: [Entry] {
    entries.filter { $0.status == .active }  // Filter #1
}

var completedEntries: [Entry] {
    entries.filter { $0.status != .active }  // Filter #2
}
```

### Impact
- O(2n) filtering on every access
- Both called during view render
- Unnecessary work

### Recommended Fix
```swift
@Published private(set) var activeEntries: [Entry] = []
@Published private(set) var completedEntries: [Entry] = []

private func updateFilteredEntries() {
    var active: [Entry] = []
    var completed: [Entry] = []

    for entry in entries {
        if entry.status == .active {
            active.append(entry)
        } else {
            completed.append(entry)
        }
    }

    activeEntries = active
    completedEntries = completed
}
```

---

## 9. EntryViewModel - Linear Search for Race Lookup

**File:** `Boathouse/Features/Entry/EntryViewModel.swift`
**Lines:** 42-44

### Current Issue
O(n) search for every entry's race.

### Current Code
```swift
func getRace(for entry: Entry) -> Race? {
    races.first { $0.id == entry.raceId }  // O(n) search!
}
```

### Impact
- With 50 entries and 100 races: 5000 comparisons
- Called for every entry row render
- Significant lag with large datasets

### Recommended Fix
```swift
private var racesById: [String: Race] = [:]

private func updateRacesById() {
    racesById = Dictionary(uniqueKeysWithValues: races.map { ($0.id, $0) })
}

func getRace(for entry: Entry) -> Race? {
    racesById[entry.raceId]  // O(1) lookup!
}
```

---

## 10. HomeView - Unkeyed ForEach Loops

**File:** `Boathouse/Features/Home/HomeView.swift`
**Lines:** 70-72, 109-114

### Current Issue
ForEach without explicit stable IDs can cause incorrect view recycling.

### Current Code
```swift
// Recent activities
ForEach(viewModel.recentActivities) { activity in
    RecentActivityCard(activity: activity)
}

// Activity feed
LazyVStack(spacing: 16) {
    ForEach(viewModel.activities) { activity in
        ActivityCard(activity: activity)
    }
}
```

### Impact
- If Activity IDs change, wrong views may be reused
- Potential UI glitches during updates
- SwiftUI may rebuild more views than necessary

### Recommended Fix
Ensure Activity has stable Identifiable conformance:
```swift
struct Activity: Identifiable {
    let id: String  // Must be truly unique and stable
}
```

---

## 11. StravaService - JSONDecoder Per Request

**File:** `Boathouse/Core/Services/StravaService.swift`
**Lines:** 127-128, 146-147

### Current Issue
New JSONDecoder created for each Strava API response.

### Current Code
```swift
func fetchActivities(...) async throws -> [StravaActivity] {
    // ...
    let decoder = JSONDecoder()  // New instance!
    decoder.dateDecodingStrategy = .iso8601
    return try decoder.decode([StravaActivity].self, from: data)
}
```

### Impact
- Multiple decoder allocations during activity sync
- Memory churn during bulk imports

### Recommended Fix
```swift
private static let decoder: JSONDecoder = {
    let d = JSONDecoder()
    d.dateDecodingStrategy = .iso8601
    return d
}()
```

---

## 12. StravaService - No HTTP Caching

**File:** `Boathouse/Core/Services/StravaService.swift`
**Lines:** 74-90, 92-130

### Current Issue
Direct network calls without HTTP cache headers.

### Impact
- Repeated identical API calls hit Strava servers
- Slower data loading
- May hit Strava rate limits faster

### Recommended Fix
Configure URLSession with caching and respect Cache-Control headers from Strava API.

---

## 13. RaceDetailView - Expensive Prefix Filtering

**File:** `Boathouse/Features/Races/RaceDetailView.swift`
**Lines:** 183-188

### Current Issue
Array prefix and last element check on every render.

### Current Code
```swift
ForEach(leaderboard.entries.prefix(10)) { entry in
    LeaderboardRow(entry: entry)
    if entry.id != leaderboard.entries.prefix(10).last?.id {  // Recomputes prefix!
        Divider()
    }
}
```

### Impact
- `.prefix(10)` called twice per iteration
- `.last` computed for each row
- O(n) work becomes O(n²)

### Recommended Fix
```swift
let topEntries = Array(leaderboard.entries.prefix(10))

ForEach(Array(topEntries.enumerated()), id: \.element.id) { index, entry in
    LeaderboardRow(entry: entry)
    if index < topEntries.count - 1 {
        Divider()
    }
}
```

---

## 14. LeaderboardView - AsyncImage Without Caching

**File:** `Boathouse/Features/Home/LeaderboardView.swift`
**Lines:** 56-75

### Current Issue
AsyncImage in list rows without image caching.

### Current Code
```swift
ForEach(leaderboard.entries) { entry in
    HStack {
        AsyncImage(url: entry.avatarURL) { phase in
            // ...
        }
    }
}
```

### Impact
- Images re-fetched on every scroll
- Network bandwidth waste
- Visible loading states during scroll

### Recommended Fix
Use a caching image library or implement custom cache:
```swift
// Option 1: Use URLCache
// Option 2: Use a library like Kingfisher or SDWebImage
// Option 3: Implement custom image cache with NSCache
```

---

## 15. Wallet.swift - DateFormatter in formattedDate

**File:** `Boathouse/Core/Models/Wallet.swift`
**Lines:** 67-72

### Current Issue
New DateFormatter for every transaction date format.

### Current Code
```swift
var formattedDate: String {
    let formatter = DateFormatter()  // Expensive!
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter.string(from: createdAt)
}
```

### Impact
- Transaction list = many formatter instances
- DateFormatter even more expensive than NumberFormatter
- Significant lag with transaction history

### Recommended Fix
```swift
enum DateFormatters {
    static let mediumDateTime: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()
}

var formattedDate: String {
    DateFormatters.mediumDateTime.string(from: createdAt)
}
```

---

## 16. AuthService - Missing Response Caching

**File:** `Boathouse/Core/Services/AuthService.swift`
**Lines:** 27-36, 38-47

### Current Issue
No caching for user session validation.

### Impact
- Repeated session checks hit network
- Slower app responsiveness
- Unnecessary API calls

### Recommended Fix
Implement token validation cache with 5-10 minute TTL.

---

## 17. WalletService - Transaction Caching Missing

**File:** `Boathouse/Features/Wallet/WalletService.swift`
**Lines:** 76-79

### Current Issue
`getTransactions` fetches from network every time.

### Current Code
```swift
func getTransactions(walletId: String, page: Int) async throws -> [WalletTransaction] {
    // TODO: Implement API call
    return MockData.transactions  // No caching!
}
```

### Impact
- Transaction history reloads on every view appear
- Unnecessary network requests
- Slower perceived performance

### Recommended Fix
```swift
private var transactionCache: [String: (transactions: [WalletTransaction], timestamp: Date)] = [:]

func getTransactions(walletId: String, page: Int) async throws -> [WalletTransaction] {
    let cacheKey = "\(walletId)-\(page)"

    if let cached = transactionCache[cacheKey],
       Date().timeIntervalSince(cached.timestamp) < 300 {  // 5 min TTL
        return cached.transactions
    }

    let transactions = try await networkClient.get("/wallets/\(walletId)/transactions?page=\(page)")
    transactionCache[cacheKey] = (transactions, Date())
    return transactions
}
```

---

## 18. StoryFeedViewModel - Double Sorting in updateStories

**File:** `Boathouse/Features/Stories/StoryFeedViewModel.swift`
**Lines:** 75, 93-96

### Current Issue
Activities sorted twice - once per user, once globally.

### Current Code
```swift
for (userId, userActivities) in groupedByUser {
    let unseenActivities = seenStore.unseenActivities(from: userActivities)
        .sorted { $0.startDate > $1.startDate }  // Sort #1

    // create story...
}

stories = newStories.sorted {  // Sort #2
    ($0.unseenActivities.first?.startDate ?? .distantPast) >
    ($1.unseenActivities.first?.startDate ?? .distantPast)
}
```

### Impact
- Two O(n log n) sorts on every update
- CPU waste with large activity feeds

### Recommended Fix
```swift
// Sort once with composite key
stories = newStories
    .map { story -> (story: AthleteStory, date: Date) in
        (story, story.unseenActivities.first?.startDate ?? .distantPast)
    }
    .sorted { $0.date > $1.date }
    .map { $0.story }
```

---

## 19. AccountViewModel - Repeated AppState Access

**File:** `Boathouse/Features/Account/AccountViewModel.swift`
**Lines:** 25, 28, 30

### Current Issue
Reads deeply nested optional path multiple times in same function.

### Current Code
```swift
@MainActor
func toggleAutoPayout() async {
    guard let walletId = AppState.shared?.currentUser?.wallet?.id else { return }

    do {
        let newValue = !(AppState.shared?.currentUser?.wallet?.autoPayoutEnabled ?? false)
        // ...
        AppState.shared?.currentUser?.wallet?.autoPayoutEnabled = newValue
    }
}
```

### Impact
- Same optional chain evaluated 3 times
- Potential race condition if AppState modified between reads
- Verbose and error-prone

### Recommended Fix
```swift
@MainActor
func toggleAutoPayout() async {
    guard let wallet = AppState.shared?.currentUser?.wallet else { return }

    do {
        let newValue = !wallet.autoPayoutEnabled
        try await walletService.updateAutoPayoutSetting(walletId: wallet.id, enabled: newValue)
        AppState.shared?.currentUser?.wallet?.autoPayoutEnabled = newValue
    }
}
```
