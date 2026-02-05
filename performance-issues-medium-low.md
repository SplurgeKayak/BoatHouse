# Medium & Low Priority Performance Issues

Best practices and micro-optimizations. Address in backlog.

---

## Medium Priority Issues

### 1. Missing Hashable Conformance on Models

**Files:** Multiple
**Impact:** Medium

Models used in Sets or as dictionary keys should conform to Hashable.

| File | Struct | Line |
|------|--------|------|
| User.swift | User | 4 |
| Activity.swift | Activity | 5 |
| Entry.swift | LeaderboardEntry | 57 |
| Wallet.swift | PayoutDetails | 26 |

**Recommended Fix:**
```swift
struct User: Identifiable, Codable, Equatable, Hashable {
    // Hashable auto-synthesized from Equatable properties
}
```

---

### 2. Activity.swift - String Formatting Computed Properties

**File:** `Boathouse/Core/Models/Activity.swift`
**Lines:** 40-62

Multiple String formatting operations on every access.

```swift
var formattedDistance: String {
    String(format: "%.2f km", distanceKm)
}

var formattedDuration: String {
    // Complex time formatting logic
}
```

**Recommendation:** Memoize formatted strings or move to lazy properties.

---

### 3. User.swift - Date() in Token Validity Checks

**File:** `Boathouse/Core/Models/User.swift`
**Lines:** 89-95

```swift
var isValid: Bool {
    Date() < expiresAt  // New Date() every call
}

var needsRefresh: Bool {
    Date().addingTimeInterval(300) >= expiresAt  // New Date() every call
}
```

**Recommendation:** Accept reference date parameter or use method instead of property.

---

### 4. StoriesStripView - Filtering in View Body

**File:** `Boathouse/Features/Stories/StoriesStripView.swift`
**Line:** 16

```swift
ForEach(stories.filter { $0.unseenCount > 0 }) { story in
    // ...
}
```

**Recommendation:** Pre-filter in ViewModel.

---

### 5. StoryViewerView - Array Creation in ForEach

**File:** `Boathouse/Features/Stories/StoryViewerView.swift`
**Lines:** 29-36

```swift
ForEach(Array(activities.enumerated()), id: \.element.id) { index, activity in
    // Creates new array every render
}
```

**Recommendation:** Use `.indices` or `indexed()` extension.

---

### 6. StoryViewerView - DispatchQueue in View

**File:** `Boathouse/Features/Stories/StoryViewerView.swift`
**Line:** 189

```swift
DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
    dismissViewer()
}
```

**Recommendation:** Use `.task` modifier with proper cancellation:
```swift
.task {
    try? await Task.sleep(nanoseconds: 2_000_000_000)
    dismissViewer()
}
```

---

### 7. Race.swift - Date() in Computed Properties

**File:** `Boathouse/Core/Models/Race.swift`
**Lines:** 24-29

```swift
var canEnter: Bool {
    status == .active && Date() < entryDeadline
}

var timeRemaining: TimeInterval {
    endDate.timeIntervalSince(Date())
}
```

**Recommendation:** Accept reference date or move to methods.

---

### 8. LocationService - Inefficient String Index Traversal

**File:** `Boathouse/Core/Services/LocationService.swift`
**Lines:** 86-132

String indices are O(n) in Swift. Polyline decoding repeatedly uses `.index(after:)`.

**Recommendation:** Convert to Array<Character> for O(1) indexing:
```swift
let chars = Array(polyline)
var index = 0
while index < chars.count {
    // O(1) access via chars[index]
}
```

---

### 9. SeenActivityStore - Repeated JSONEncoder/Decoder

**File:** `Boathouse/Features/Stories/SeenActivityStore.swift`
**Lines:** 50-55, 59

```swift
try? JSONDecoder().decode(Set<String>.self, from: data)
try? JSONEncoder().encode(seenActivityIDs)
```

**Recommendation:** Use static cached instances.

---

### 10. MockData.swift - Static Properties Recomputed

**File:** `Boathouse/Core/MockData/MockData.swift`
**Lines:** Multiple

Static computed properties with Date() are recomputed on every access:
```swift
static var racerUser: User {
    User(
        createdAt: Date().addingTimeInterval(-86400 * 120),  // New Date!
        updatedAt: Date()
    )
}
```

**Recommendation:** Use `static let` with lazy initialization.

---

### 11. AccountView - Binding Creation in View Body

**File:** `Boathouse/Features/Account/AccountView.swift`
**Lines:** 148-151

```swift
Toggle(..., isOn: Binding(
    get: { ... },
    set: { ... }
))
```

**Recommendation:** Move Binding to computed property or use @State.

---

### 12. RaceDetailView - Prize Calculation in View

**File:** `Boathouse/Features/Races/RaceDetailView.swift`
**Line:** 99

```swift
let prizes = race.calculatePrizes()  // In computed property
```

**Recommendation:** Cache in ViewModel or use @State.

---

### 13. RacesView - ScrollView + LazyVStack Redundancy

**File:** `Boathouse/Features/Races/RacesView.swift`
**Lines:** 85-97

Combining ScrollView with LazyVStack is less efficient than List.

**Recommendation:** Use List for better performance:
```swift
List(viewModel.filteredRaces) { race in
    NavigationLink(value: race) {
        RaceCard(race: race)
    }
}
.listStyle(.plain)
```

---

### 14. TransactionHistoryView - DateFormatter Per Row

**File:** `Boathouse/Features/Wallet/TransactionHistoryView.swift`
**Lines:** 78-87, 133-137

Multiple DateFormatter instances created during list rendering.

**Recommendation:** Use shared formatters.

---

### 15. StravaOAuthViewModel - URL Rebuilt Every Access

**File:** `Boathouse/Features/Authentication/StravaOAuthViewModel.swift`
**Lines:** 30-40

```swift
var stravaAuthURL: URL? {
    var components = URLComponents(...)  // Built every access
    components?.queryItems = [...]
    return components?.url
}
```

**Recommendation:** Use lazy property:
```swift
private(set) lazy var stravaAuthURL: URL? = {
    var components = URLComponents(...)
    // ...
    return components?.url
}()
```

---

### 16. RaceDetailViewModel - No Task Cancellation

**File:** `Boathouse/Features/Races/RaceDetailViewModel.swift`

Network requests not cancellable when view dismisses.

**Recommendation:** Store Task references and cancel in deinit:
```swift
private var loadTask: Task<Void, Never>?

deinit {
    loadTask?.cancel()
}

func loadLeaderboard() {
    loadTask?.cancel()
    loadTask = Task {
        // ...
    }
}
```

---

### 17. StoryFeedViewModel - Inefficient Publisher Subscription

**File:** `Boathouse/Features/Stories/StoryFeedViewModel.swift`
**Lines:** 57-61

```swift
seenStore.$seenActivityIDs
    .sink { [weak self] _ in
        self?.objectWillChange.send()  // Manual invalidation
    }
```

**Recommendation:** Remove redundant objectWillChange, use @Published properly.

---

### 18. AuthService - JSONEncoder Created Per Request

**File:** `Boathouse/Core/Services/AuthService.swift`
**Lines:** 118, 120, 126

**Recommendation:** Cache static JSONEncoder instance.

---

### 19. NetworkClient - Missing Request Deduplication

**File:** `Boathouse/Networking/NetworkClient.swift`
**Lines:** 66-81

Identical concurrent requests aren't deduplicated.

**Recommendation:** Implement in-flight request cache:
```swift
private var inFlightRequests: [String: Task<Data, Error>] = [:]

func get<T>(_ endpoint: String) async throws -> T {
    let key = endpoint

    if let existing = inFlightRequests[key] {
        return try await decode(existing.value)
    }

    let task = Task { try await fetchData(endpoint) }
    inFlightRequests[key] = task
    defer { inFlightRequests[key] = nil }

    return try await decode(task.value)
}
```

---

### 20. KeychainService - Delete Before Insert

**File:** `Boathouse/Core/Services/KeychainService.swift`
**Line:** 29

Unnecessary deletion before adding new token.

**Recommendation:** Update existing item if present.

---

## Low Priority Issues

### 21. Color Arrays in Computed Properties

**Files:** StoryBubbleView.swift (101-108), StoryViewerView.swift (162-164)

```swift
private var avatarBackgroundColor: Color {
    let colors: [Color] = [.blue, .purple, ...]  // Array created every access
}
```

**Recommendation:** Extract to static constant.

---

### 22. Entry.swift - String Format in formattedScore

**File:** `Boathouse/Core/Models/Entry.swift`
**Lines:** 67-77

String formatting on every access.

**Recommendation:** Cache or memoize.

---

### 23. Coordinate Uses Double Comparison

**File:** `Boathouse/Core/Models/Activity.swift`
**Lines:** 100-107

Double-based Equatable can have floating-point precision issues.

**Recommendation:** Consider epsilon comparison for edge cases.

---

### 24. Wallet.swift - String Manipulation in formattedSortCode

**File:** `Boathouse/Core/Models/Wallet.swift`
**Lines:** 36-41

```swift
var formattedSortCode: String {
    let digits = sortCode.filter { $0.isNumber }
    // String index manipulation
}
```

**Recommendation:** Cache formatted sortCode.

---

### 25. RaceEngine - Redundant Rank Reassignment

**File:** `Boathouse/Core/Services/RaceEngine.swift`
**Lines:** 51-55

Creates new Entry with rank modification.

**Recommendation:** Use separate Ranking wrapper or modify in place.

---

### 26. LocationService - Redundant First/Last Check

**File:** `Boathouse/Core/Services/LocationService.swift`
**Lines:** 67-78

Always checks first and last points in addition to sampling.

**Recommendation:** Remove explicit check if included in sampling.

---

### 27. KeychainService - Silent Error Handling

**File:** `Boathouse/Core/Services/KeychainService.swift`
**Lines:** 41-43

Errors printed but not propagated.

**Recommendation:** Return Result type or throw errors.

---

### 28. NetworkClient - Missing Error Details

**File:** `Boathouse/Networking/NetworkClient.swift`
**Lines:** 76-80

Decoding errors lose specific details.

**Recommendation:** Wrap in custom error with context.

---

### 29. AuthViewModel - String Mutations in clearForm

**File:** `Boathouse/Features/Authentication/AuthViewModel.swift`
**Lines:** 86-90

Three separate @Published updates instead of batched.

**Recommendation:** Batch updates or use transaction.

---

### 30. StravaService - String URL Construction

**File:** `Boathouse/Core/Services/StravaService.swift`
**Lines:** 24, 51, 75, 114, 133, 152

Force-unwrapped URL construction.

**Recommendation:** Use proper URL validation or throwing errors.

---

## Implementation Notes

For Medium priority issues:
- Group related fixes together (all formatter caching in one PR)
- Test performance before/after with Instruments
- No functionality changes needed

For Low priority issues:
- Address during normal refactoring
- Don't prioritize over feature work
- Good for new team member onboarding tasks
