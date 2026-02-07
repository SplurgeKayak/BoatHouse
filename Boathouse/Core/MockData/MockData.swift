import Foundation
import CoreLocation

// ─────────────────────────────────────────────────────────────────────
// MockData — programmatically generated mock data
//
// Users:  15 total, distributed 4/4/4/3 across demographic groups:
//   Group 1 — Under-18 Men:     4 users  (user-001 … user-004)
//   Group 2 — Under-18 Women:   4 users  (user-005 … user-008)
//   Group 3 — Senior Men (18+): 4 users  (user-009 … user-012)
//   Group 4 — Senior Women(18+):3 users  (user-013 … user-015)
//
// Sessions: 25 per user = 375 total
//   Time-bucket guarantees (per user, ≥1 each):
//     Bucket A: within last 24 hours       ("today / last day")
//     Bucket B: 1–7 days ago               ("this week")
//     Bucket C: 8–30 days ago              ("this month")
//     Bucket D: 31–365 days ago            ("this year")
//   Remaining 21 sessions spread randomly across A–D.
//
// All sessions: .kayaking or .canoeing only, every session has a
// polyline route on a UK river, distance 1–35 km, realistic speeds,
// consistent elapsed/moving times.
//
// RNG: Deterministic SplitMix64 (seed 42 for users, 1337 for
// sessions) — stable across runs and previews.
// ─────────────────────────────────────────────────────────────────────

enum MockData {

    // MARK: - Deterministic Seeded RNG (SplitMix64)

    struct SeededRNG: RandomNumberGenerator {
        private var state: UInt64
        init(seed: UInt64) { state = seed }
        mutating func next() -> UInt64 {
            state &+= 0x9E3779B97F4A7C15
            var z = state
            z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
            z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
            return z ^ (z >> 31)
        }
    }

    // MARK: - UK River Routes

    private struct RiverRoute {
        let name: String
        let start: Coordinate
        let end: Coordinate
    }

    private static let riverRoutes: [RiverRoute] = [
        RiverRoute(name: "Thames",         start: Coordinate(latitude: 51.4615, longitude: -0.3015), end: Coordinate(latitude: 51.4812, longitude: -0.2734)),
        RiverRoute(name: "Lee Valley",     start: Coordinate(latitude: 51.5742, longitude: -0.0356), end: Coordinate(latitude: 51.5621, longitude: -0.0412)),
        RiverRoute(name: "Grand Union",    start: Coordinate(latitude: 51.5312, longitude: -0.4521), end: Coordinate(latitude: 51.6234, longitude: -0.5012)),
        RiverRoute(name: "Lake District",  start: Coordinate(latitude: 54.4609, longitude: -3.0886), end: Coordinate(latitude: 54.4712, longitude: -3.0734)),
        RiverRoute(name: "River Severn",   start: Coordinate(latitude: 52.1936, longitude: -2.2216), end: Coordinate(latitude: 52.2012, longitude: -2.2134)),
        RiverRoute(name: "River Cam",      start: Coordinate(latitude: 52.2053, longitude:  0.1218), end: Coordinate(latitude: 52.2112, longitude:  0.1156)),
        RiverRoute(name: "Loch Awe",       start: Coordinate(latitude: 56.4112, longitude: -5.4721), end: Coordinate(latitude: 56.4234, longitude: -5.4612)),
        RiverRoute(name: "River Wye",      start: Coordinate(latitude: 51.8420, longitude: -2.6480), end: Coordinate(latitude: 51.8560, longitude: -2.6320)),
        RiverRoute(name: "River Trent",    start: Coordinate(latitude: 52.9489, longitude: -1.1528), end: Coordinate(latitude: 52.9612, longitude: -1.1367)),
        RiverRoute(name: "Norfolk Broads", start: Coordinate(latitude: 52.6234, longitude:  1.5612), end: Coordinate(latitude: 52.6378, longitude:  1.5834)),
    ]

    // MARK: - User Profile Specs

    private struct UserSpec {
        let firstName: String
        let lastName: String
        let gender: User.Gender
        let yearOfBirth: Int
        let monthOfBirth: Int
        let dayOfBirth: Int
    }

    // Ordered by group: U18M(4), U18W(4), SM(4), SW(3)
    private static let userSpecs: [UserSpec] = [
        // Group 1: Under-18 Men (4)
        UserSpec(firstName: "Ethan",     lastName: "Parker",   gender: .male,   yearOfBirth: 2009, monthOfBirth: 5,  dayOfBirth: 12),
        UserSpec(firstName: "Noah",      lastName: "Taylor",   gender: .male,   yearOfBirth: 2009, monthOfBirth: 8,  dayOfBirth: 23),
        UserSpec(firstName: "Oliver",    lastName: "Brown",    gender: .male,   yearOfBirth: 2010, monthOfBirth: 1,  dayOfBirth: 7),
        UserSpec(firstName: "Liam",      lastName: "Hughes",   gender: .male,   yearOfBirth: 2010, monthOfBirth: 11, dayOfBirth: 30),
        // Group 2: Under-18 Women (4)
        UserSpec(firstName: "Sophie",    lastName: "Clarke",   gender: .female, yearOfBirth: 2009, monthOfBirth: 3,  dayOfBirth: 18),
        UserSpec(firstName: "Mia",       lastName: "Williams", gender: .female, yearOfBirth: 2009, monthOfBirth: 9,  dayOfBirth: 5),
        UserSpec(firstName: "Isabella",  lastName: "Jones",    gender: .female, yearOfBirth: 2010, monthOfBirth: 4,  dayOfBirth: 14),
        UserSpec(firstName: "Charlotte", lastName: "Davies",   gender: .female, yearOfBirth: 2010, monthOfBirth: 7,  dayOfBirth: 22),
        // Group 3: Senior Men 18+ (4)
        UserSpec(firstName: "James",     lastName: "Wilson",   gender: .male,   yearOfBirth: 1995, monthOfBirth: 3,  dayOfBirth: 15),
        UserSpec(firstName: "Daniel",    lastName: "Thompson", gender: .male,   yearOfBirth: 1992, monthOfBirth: 6,  dayOfBirth: 10),
        UserSpec(firstName: "Ryan",      lastName: "Mitchell", gender: .male,   yearOfBirth: 1998, monthOfBirth: 12, dayOfBirth: 1),
        UserSpec(firstName: "Matthew",   lastName: "Evans",    gender: .male,   yearOfBirth: 2002, monthOfBirth: 2,  dayOfBirth: 28),
        // Group 4: Senior Women 18+ (3)
        UserSpec(firstName: "Emily",     lastName: "Roberts",  gender: .female, yearOfBirth: 1997, monthOfBirth: 10, dayOfBirth: 8),
        UserSpec(firstName: "Sarah",     lastName: "Chen",     gender: .female, yearOfBirth: 1993, monthOfBirth: 4,  dayOfBirth: 20),
        UserSpec(firstName: "Hannah",    lastName: "Cooper",   gender: .female, yearOfBirth: 2000, monthOfBirth: 8,  dayOfBirth: 15),
    ]

    // MARK: - Session Name Templates

    private static let sessionPrefixes = [
        "Morning", "Evening", "Early", "Late", "Weekend",
        "Sunrise", "Sunset", "Midday", "Dawn", "Dusk",
    ]

    private static let sessionActivities = [
        "Paddle", "Sprint", "Cruise", "Time Trial", "Endurance Run",
        "Interval Session", "Recovery Paddle", "Speed Test", "Long Distance",
        "Exploration", "Training", "Circuit", "Tempo Session", "Threshold Test",
        "Steady State",
    ]

    private static let cities = [
        "London", "Manchester", "Edinburgh", "Bristol", "Birmingham",
        "Leeds", "Liverpool", "Cambridge", "Oxford", "Cardiff",
        "Glasgow", "Bath", "York", "Norwich", "Nottingham",
    ]

    private static let bankNames = ["HSBC", "Barclays", "Lloyds", "NatWest", "Santander"]

    // MARK: - Users (15)

    static let users: [User] = {
        var rng = SeededRNG(seed: 42)
        let cal = Calendar.current

        return userSpecs.enumerated().map { index, spec in
            let userId = String(format: "user-%03d", index + 1)
            let dob = cal.date(from: DateComponents(
                year: spec.yearOfBirth, month: spec.monthOfBirth, day: spec.dayOfBirth
            ))!
            let stravaId = 10000000 + index + 1
            let balanceCents = Int.random(in: 500...12000, using: &rng)

            return User(
                id: userId,
                email: "\(spec.firstName.lowercased()).\(spec.lastName.lowercased())@example.com",
                displayName: "\(spec.firstName) \(spec.lastName)",
                userType: .racer,
                stravaConnection: StravaConnection(
                    athleteId: stravaId,
                    accessToken: "mock_access_\(String(format: "%03d", index + 1))",
                    refreshToken: "mock_refresh_\(String(format: "%03d", index + 1))",
                    expiresAt: Date().addingTimeInterval(21600),
                    athleteProfile: StravaAthleteProfile(
                        id: stravaId,
                        firstName: spec.firstName,
                        lastName: spec.lastName,
                        profileImageURL: nil,
                        city: cities[index],
                        country: "United Kingdom",
                        sex: spec.gender == .male ? "M" : "F",
                        dateOfBirth: dob
                    )
                ),
                wallet: Wallet(
                    id: "wallet-\(String(format: "%03d", index + 1))",
                    userId: userId,
                    balance: Decimal(balanceCents) / 100,
                    autoPayoutEnabled: false,
                    payoutDetails: PayoutDetails(
                        bankName: bankNames[index % bankNames.count],
                        accountNumberLast4: String(format: "%04d", Int.random(in: 1000...9999, using: &rng)),
                        sortCode: String(format: "%02d-%02d-%02d",
                                         Int.random(in: 10...99, using: &rng),
                                         Int.random(in: 10...99, using: &rng),
                                         Int.random(in: 10...99, using: &rng)),
                        isVerified: true
                    ),
                    createdAt: Date().addingTimeInterval(-86400 * Double.random(in: 30...365, using: &rng)),
                    updatedAt: Date()
                ),
                dateOfBirth: dob,
                gender: spec.gender,
                profileImageURL: nil,
                createdAt: Date().addingTimeInterval(-86400 * Double.random(in: 60...400, using: &rng)),
                updatedAt: Date()
            )
        }
    }()

    // MARK: - Convenience Aliases

    /// James Wilson (Senior Men) — used by ContentView and AuthViewModel
    static let racerUser: User = users[8]

    /// Spectator user — no Strava, no wallet
    static let spectatorUser: User = {
        User(
            id: "user-spectator",
            email: "spectator@example.com",
            displayName: "Alex Viewer",
            userType: .spectator,
            stravaConnection: nil,
            wallet: nil,
            dateOfBirth: nil,
            gender: nil,
            profileImageURL: nil,
            createdAt: Date().addingTimeInterval(-86400 * 14),
            updatedAt: Date()
        )
    }()

    // MARK: - Sessions (375 = 15 users x 25 sessions)

    static let sessions: [Session] = {
        var rng = SeededRNG(seed: 1337)
        let result = users.flatMap { user in
            generateSessions(for: user, rng: &rng)
        }

        #if DEBUG
        verifyMockData(sessions: result)
        #endif

        return result
    }()

    /// Generate 25 sessions for a user with guaranteed time-bucket coverage.
    static func generateSessions<RNG: RandomNumberGenerator>(
        for user: User,
        rng: inout RNG
    ) -> [Session] {
        let userIndex = Int(user.id.suffix(3))!

        // Time bucket ranges (seconds ago from now):
        //   A: 0–24h, B: 1d–7d, C: 8d–30d, D: 31d–365d
        let bucketRanges: [(min: Double, max: Double)] = [
            (60,            86400),
            (86400,         86400 * 7),
            (86400 * 8,     86400 * 30),
            (86400 * 31,    86400 * 365),
        ]

        var sessions: [Session] = []

        for sessionIndex in 0..<25 {
            // First 4 sessions guarantee one per bucket; rest are random
            let bucketIndex = sessionIndex < 4
                ? sessionIndex
                : Int.random(in: 0...3, using: &rng)

            let range = bucketRanges[bucketIndex]
            let secondsAgo = Double.random(in: range.min...range.max, using: &rng)
            let startDate = Date().addingTimeInterval(-secondsAgo)

            // Route
            let route = randomRoute(rng: &rng)

            // Distance: 1,000–35,000 m
            let distance = Double.random(in: 1000...35000, using: &rng)

            // Speeds (m/s)
            let averageSpeed = Double.random(in: 1.8...3.8, using: &rng)
            let maxSpeed = min(averageSpeed + Double.random(in: 0.4...2.0, using: &rng), 6.5)

            // Times (consistent: movingTime ≈ distance/averageSpeed, elapsedTime ≥ movingTime)
            let movingTime = (distance / averageSpeed) * Double.random(in: 0.97...1.03, using: &rng)
            let elapsedTime = movingTime * Double.random(in: 1.02...1.15, using: &rng)

            // Session type: kayaking or canoeing only
            let sessionType: SessionType = Bool.random(using: &rng) ? .kayaking : .canoeing

            // Segment times — fastest segment is quicker than overall average
            let fastest1km: TimeInterval? = distance >= 1000
                ? 1000 / (averageSpeed * Double.random(in: 1.3...1.9, using: &rng))
                : nil
            let fastest5km: TimeInterval? = distance >= 5000
                ? 5000 / (averageSpeed * Double.random(in: 1.2...1.6, using: &rng))
                : nil
            let fastest10km: TimeInterval? = distance >= 10000
                ? 10000 / (averageSpeed * Double.random(in: 1.2...1.5, using: &rng))
                : nil

            // Polyline (point count scales with distance, 20–60 points)
            let pointCount = max(20, min(60, Int(distance / 500)))
            let polyline = PolylineCodec.generateRoute(
                from: route.start, to: route.end, pointCount: pointCount
            )

            // Session name
            let prefix = sessionPrefixes[Int.random(in: 0..<sessionPrefixes.count, using: &rng)]
            let activity = sessionActivities[Int.random(in: 0..<sessionActivities.count, using: &rng)]

            let sessionId = String(format: "session-%03d-%03d", userIndex, sessionIndex + 1)
            let stravaId = 20000000 + (userIndex - 1) * 25 + sessionIndex + 1

            sessions.append(Session(
                id: sessionId,
                stravaId: stravaId,
                userId: user.id,
                name: "\(prefix) \(activity)",
                sessionType: sessionType,
                startDate: startDate,
                elapsedTime: elapsedTime,
                movingTime: movingTime,
                distance: distance,
                maxSpeed: maxSpeed,
                averageSpeed: averageSpeed,
                startLocation: route.start,
                endLocation: route.end,
                polyline: polyline,
                isGPSVerified: true,
                isUKSession: true,
                flagCount: 0,
                status: .verified,
                importedAt: startDate.addingTimeInterval(Double.random(in: 600...7200, using: &rng)),
                fastest1kmTime: fastest1km,
                fastest5kmTime: fastest5km,
                fastest10kmTime: fastest10km
            ))
        }

        return sessions
    }

    /// Select a random UK river route for polyline generation.
    static func randomRoute<RNG: RandomNumberGenerator>(
        rng: inout RNG
    ) -> (name: String, start: Coordinate, end: Coordinate) {
        let r = riverRoutes[Int.random(in: 0..<riverRoutes.count, using: &rng)]
        return (r.name, r.start, r.end)
    }

    // MARK: - Wallet (convenience)

    static let wallet: Wallet = {
        users[8].wallet!   // James Wilson's wallet
    }()

    // MARK: - Transactions

    static let transactions: [WalletTransaction] = {
        let wId = wallet.id
        return [
            WalletTransaction(
                id: "txn-001",
                walletId: wId,
                type: .deposit,
                amount: 50.00,
                description: "Added funds via Apple Pay",
                status: .completed,
                relatedRaceId: nil,
                relatedEntryId: nil,
                createdAt: Date().addingTimeInterval(-86400 * 7)
            ),
            WalletTransaction(
                id: "txn-002",
                walletId: wId,
                type: .entryFee,
                amount: 4.99,
                description: "Weekly Top Speed - Senior Men",
                status: .completed,
                relatedRaceId: "race-001",
                relatedEntryId: "entry-001",
                createdAt: Date().addingTimeInterval(-86400 * 5)
            ),
            WalletTransaction(
                id: "txn-003",
                walletId: wId,
                type: .prize,
                amount: 35.25,
                description: "2nd Place - Weekly Fastest 1km",
                status: .completed,
                relatedRaceId: "race-010",
                relatedEntryId: "entry-010",
                createdAt: Date().addingTimeInterval(-86400 * 2)
            ),
        ]
    }()

    // MARK: - Races

    static let races: [Race] = {
        [
            Race(
                id: "race-001",
                type: .topSpeed,
                duration: .daily,
                category: .seniorMen,
                startDate: Calendar.current.startOfDay(for: Date()),
                endDate: Calendar.current.startOfDay(for: Date()).addingTimeInterval(86400),
                entryCount: 34,
                prizePool: 34.00,
                status: .active,
                createdAt: Calendar.current.startOfDay(for: Date())
            ),
            Race(
                id: "race-002",
                type: .furthestDistance,
                duration: .weekly,
                category: .seniorMen,
                startDate: Date().addingTimeInterval(-86400 * 3),
                endDate: Date().addingTimeInterval(86400 * 4),
                entryCount: 89,
                prizePool: 444.11,
                status: .active,
                createdAt: Date().addingTimeInterval(-86400 * 3)
            ),
            Race(
                id: "race-003",
                type: .fastest1km,
                duration: .monthly,
                category: .seniorWomen,
                startDate: Date().addingTimeInterval(-86400 * 15),
                endDate: Date().addingTimeInterval(86400 * 15),
                entryCount: 145,
                prizePool: 2318.55,
                status: .active,
                createdAt: Date().addingTimeInterval(-86400 * 15)
            ),
            Race(
                id: "race-004",
                type: .fastest5km,
                duration: .weekly,
                category: .mastersMen,
                startDate: Date().addingTimeInterval(-86400 * 3),
                endDate: Date().addingTimeInterval(86400 * 4),
                entryCount: 42,
                prizePool: 209.58,
                status: .active,
                createdAt: Date().addingTimeInterval(-86400 * 3)
            ),
        ]
    }()

    // MARK: - Entries

    static let entries: [Entry] = {
        let uId = racerUser.id
        return [
            Entry(
                id: "entry-001",
                userId: uId,
                raceId: "race-002",
                sessionId: sessions.first { $0.userId == uId }?.id,
                enteredAt: Date().addingTimeInterval(-86400 * 2),
                score: 17.28,
                rank: 5,
                status: .active,
                prizeWon: nil,
                transactionId: "txn-002"
            ),
            Entry(
                id: "entry-002",
                userId: uId,
                raceId: "race-001",
                sessionId: sessions.filter({ $0.userId == uId }).dropFirst().first?.id,
                enteredAt: Date().addingTimeInterval(-3600 * 6),
                score: 18.72,
                rank: 3,
                status: .active,
                prizeWon: nil,
                transactionId: nil
            ),
        ]
    }()

    // MARK: - Leaderboard

    static let leaderboard: Leaderboard = {
        // Pick 5 users from different groups for a diverse leaderboard
        let lbUsers: [(user: User, score: Double)] = [
            (users[9],  22.4),  // Daniel Thompson — Senior Men
            (users[4],  21.8),  // Sophie Clarke — U18 Women
            (users[8],  20.5),  // James Wilson — Senior Men
            (users[12], 19.2),  // Emily Roberts — Senior Women
            (users[0],  17.3),  // Ethan Parker — U18 Men
        ]

        return Leaderboard(
            id: "leaderboard-001",
            raceId: "race-002",
            entries: lbUsers.enumerated().map { i, item in
                LeaderboardEntry(
                    id: "lb-\(String(format: "%03d", i + 1))",
                    rank: i + 1,
                    userId: item.user.id,
                    userName: item.user.displayName,
                    userProfileURL: nil,
                    score: item.score,
                    sessionId: sessions.first { $0.userId == item.user.id }?.id,
                    raceType: .topSpeed
                )
            },
            updatedAt: Date()
        )
    }()

    // MARK: - Debug Verification

    #if DEBUG
    private static func verifyMockData(sessions: [Session]) {
        assert(MockData.users.count == 15,
               "MockData: expected 15 users, got \(MockData.users.count)")
        assert(sessions.count == 375,
               "MockData: expected 375 sessions, got \(sessions.count)")

        let now = Date()
        for user in MockData.users {
            let uSessions = sessions.filter { $0.userId == user.id }
            assert(uSessions.count == 25,
                   "MockData: \(user.id) has \(uSessions.count) sessions, expected 25")

            let hasA = uSessions.contains { now.timeIntervalSince($0.startDate) <= 86400 }
            let hasB = uSessions.contains {
                let d = now.timeIntervalSince($0.startDate)
                return d > 86400 && d <= 86400 * 7
            }
            let hasC = uSessions.contains {
                let d = now.timeIntervalSince($0.startDate)
                return d > 86400 * 7 && d <= 86400 * 30
            }
            let hasD = uSessions.contains {
                let d = now.timeIntervalSince($0.startDate)
                return d > 86400 * 30 && d <= 86400 * 365
            }

            assert(hasA, "MockData: \(user.id) missing 'last day' session")
            assert(hasB, "MockData: \(user.id) missing 'last week' session")
            assert(hasC, "MockData: \(user.id) missing 'last month' session")
            assert(hasD, "MockData: \(user.id) missing 'last year' session")
        }
    }
    #endif
}
