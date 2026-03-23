import Foundation
import CoreLocation

// ─────────────────────────────────────────────────────────────────────
// MockData — programmatically generated mock data
//
// Athletes: 6 Garmin-connected racers
//   Billy Butler, Jon, Farley, Andy (logged-in), Tom, Stuart
//
// Sessions: 3 per week × 52 weeks = 156 per athlete = 936 total
//   Days 1, 3, 5 of each week, spread backwards from today.
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

    // MARK: - Athlete Specs

    private struct AthleteSpec {
        let name: String
        let userId: String
        let stravaId: Int
        let basePaceSecPerKm: Double
        let paceVariance: Double
        let best1kTarget: TimeInterval
        let best5kTarget: TimeInterval
        let best10kTarget: TimeInterval
    }

    private static let athleteSpecs: [AthleteSpec] = [
        AthleteSpec(name: "Billy Butler", userId: "billy-001",  stravaId: 10000001, basePaceSecPerKm: 250, paceVariance: 8,  best1kTarget: 252,  best5kTarget: 1785, best10kTarget: 3885),
        AthleteSpec(name: "Jon",          userId: "jon-001",    stravaId: 10000002, basePaceSecPerKm: 258, paceVariance: 9,  best1kTarget: 268,  best5kTarget: 1860, best10kTarget: 4020),
        AthleteSpec(name: "Farley",       userId: "farley-001", stravaId: 10000003, basePaceSecPerKm: 272, paceVariance: 11, best1kTarget: 290,  best5kTarget: 2040, best10kTarget: 4380),
        AthleteSpec(name: "Andy",         userId: "andy-001",   stravaId: 10000004, basePaceSecPerKm: 275, paceVariance: 12, best1kTarget: 295,  best5kTarget: 2100, best10kTarget: 4500),
        AthleteSpec(name: "Tom",          userId: "tom-001",    stravaId: 10000005, basePaceSecPerKm: 278, paceVariance: 12, best1kTarget: 300,  best5kTarget: 2145, best10kTarget: 4590),
        AthleteSpec(name: "Stuart",       userId: "stuart-001", stravaId: 10000006, basePaceSecPerKm: 310, paceVariance: 15, best1kTarget: 355,  best5kTarget: 2390, best10kTarget: 6355),
    ]

    private static let bankNames = ["HSBC", "Barclays", "Lloyds", "NatWest", "Santander"]

    // MARK: - Users (6)

    static let users: [User] = {
        var rng = SeededRNG(seed: 42)

        return athleteSpecs.map { spec in
            let balanceCents = Int(rng.next() % 11501) + 500
            let nameParts = spec.name.components(separatedBy: " ")
            let firstName = nameParts.first ?? spec.name
            let lastName = nameParts.dropFirst().joined(separator: " ")

            return User(
                id: spec.userId,
                email: "\(spec.name.lowercased().replacingOccurrences(of: " ", with: "."))@example.com",
                displayName: spec.name,
                userType: .racer,
                garminConnection: GarminConnection(
                    athleteId: spec.stravaId,
                    accessToken: "mock_access_\(spec.userId)",
                    refreshToken: "mock_refresh_\(spec.userId)",
                    expiresAt: Date().addingTimeInterval(21600),
                    athleteProfile: StravaAthleteProfile(
                        id: spec.stravaId,
                        firstName: firstName,
                        lastName: lastName,
                        profileImageURL: nil,
                        city: "London",
                        country: "United Kingdom",
                        sex: "M",
                        dateOfBirth: nil
                    )
                ),
                wallet: Wallet(
                    id: "wallet-\(spec.userId)",
                    userId: spec.userId,
                    balance: Decimal(balanceCents) / 100,
                    autoPayoutEnabled: false,
                    payoutDetails: PayoutDetails(
                        bankName: bankNames[Int(rng.next() % UInt64(bankNames.count))],
                        accountNumberLast4: String(format: "%04d", Int(rng.next() % 9000) + 1000),
                        sortCode: String(format: "%02d-%02d-%02d",
                                         Int(rng.next() % 90) + 10,
                                         Int(rng.next() % 90) + 10,
                                         Int(rng.next() % 90) + 10),
                        isVerified: true
                    ),
                    createdAt: Date().addingTimeInterval(-86400 * Double(Int(rng.next() % 335) + 30)),
                    updatedAt: Date()
                ),
                dateOfBirth: nil,
                gender: nil,
                profileImageURL: nil,
                createdAt: Date().addingTimeInterval(-86400 * Double(Int(rng.next() % 340) + 60)),
                updatedAt: Date()
            )
        }
    }()

    // MARK: - Convenience Aliases

    /// Andy — the logged-in racer user
    static let racerUser: User = users[3]

    /// Spectator user — no Garmin, no wallet
    static let spectatorUser: User = {
        User(
            id: "user-spectator",
            email: "spectator@example.com",
            displayName: "Guest",
            userType: .spectator,
            garminConnection: nil,
            wallet: nil,
            dateOfBirth: nil,
            gender: nil,
            profileImageURL: nil,
            createdAt: Date().addingTimeInterval(-86400 * 14),
            updatedAt: Date()
        )
    }()

    // MARK: - Sessions (936 = 6 athletes x 156 sessions)

    static let sessions: [Session] = {
        var rng = SeededRNG(seed: 1337)
        let result = athleteSpecs.flatMap { spec in
            generateSessions(for: spec, rng: &rng)
        }
        .sorted { $0.startDate > $1.startDate }

        #if DEBUG
        verifyMockData(sessions: result)
        #endif

        return result
    }()

    private static let sessionDistancesKm: [Double] = [3.0, 5.0, 7.0, 8.0, 10.0, 12.0, 15.0]

    private static let sessionNames: [String] = [
        "Easy Paddle", "Intervals", "Race Simulation", "Recovery Paddle", "Technique Session",
    ]

    private static let sessionTypes: [SessionType] = [.kayaking, .canoeing]

    private static func generateSessions<RNG: RandomNumberGenerator>(
        for spec: AthleteSpec,
        rng: inout RNG
    ) -> [Session] {
        var sessions: [Session] = []
        let dayOffsets = [1, 3, 5]

        for weekIndex in 0..<52 {
            for (dayIndex, dayOffset) in dayOffsets.enumerated() {
                let secondsAgo = Double((weekIndex * 7 + dayOffset) * 86400)
                let startDate = Date().addingTimeInterval(-secondsAgo)

                let sessionIndex = weekIndex * 3 + dayIndex

                // Distance
                let distKm = sessionDistancesKm[Int(rng.next() % UInt64(sessionDistancesKm.count))]
                let distance = distKm * 1000.0

                // Session type
                let sessionType = sessionTypes[Int(rng.next() % UInt64(sessionTypes.count))]

                // Session name
                let name = sessionNames[Int(rng.next() % UInt64(sessionNames.count))]

                // Pace (s/km): basePace +/- variance, clamped to 200 s/km minimum
                let varianceFactor = 2.0 * (Double(rng.next()) / Double(UInt64.max)) - 1.0
                let pace = max(200.0, spec.basePaceSecPerKm + spec.paceVariance * varianceFactor)

                // Times
                let movingTime = pace * distKm
                let elapsedTime = movingTime * 1.05

                // Speed (m/s)
                let averageSpeed = 1000.0 / pace
                let maxSpeed = averageSpeed * 1.15

                // Near-PR session approximately every 8th session
                let isNearPR = sessionIndex % 8 == 0

                // Fastest 1km segment time
                let fastest1km: TimeInterval?
                if distKm >= 1.0 {
                    let noise = Double(rng.next()) / Double(UInt64.max)
                    if isNearPR {
                        fastest1km = spec.best1kTarget * (1.0 + noise * 0.03)
                    } else {
                        fastest1km = min(spec.best1kTarget * (1.0 + noise * 0.1), pace)
                    }
                } else {
                    fastest1km = nil
                }

                // Fastest 5km segment time
                let fastest5km: TimeInterval?
                if distKm >= 5.0 {
                    let noise = Double(rng.next()) / Double(UInt64.max)
                    if isNearPR {
                        fastest5km = spec.best5kTarget * (1.0 + noise * 0.03)
                    } else {
                        fastest5km = min(spec.best5kTarget * (1.0 + noise * 0.1), pace * 5.0)
                    }
                } else {
                    fastest5km = nil
                }

                // Fastest 10km segment time
                let fastest10km: TimeInterval?
                if distKm >= 10.0 {
                    let noise = Double(rng.next()) / Double(UInt64.max)
                    if isNearPR {
                        fastest10km = spec.best10kTarget * (1.0 + noise * 0.03)
                    } else {
                        fastest10km = min(spec.best10kTarget * (1.0 + noise * 0.1), pace * 10.0)
                    }
                } else {
                    fastest10km = nil
                }

                let sessionId = "\(spec.userId)-session-\(String(format: "%03d", sessionIndex + 1))"
                let stravaId = spec.stravaId * 1000 + sessionIndex + 1

                sessions.append(Session(
                    id: sessionId,
                    stravaId: stravaId,
                    userId: spec.userId,
                    name: name,
                    sessionType: sessionType,
                    startDate: startDate,
                    elapsedTime: elapsedTime,
                    movingTime: movingTime,
                    distance: distance,
                    maxSpeed: maxSpeed,
                    averageSpeed: averageSpeed,
                    startLocation: nil,
                    endLocation: nil,
                    polyline: nil,
                    isGPSVerified: true,
                    isUKSession: true,
                    flagCount: 0,
                    status: .verified,
                    importedAt: startDate.addingTimeInterval(3600),
                    fastest1kmTime: fastest1km,
                    fastest5kmTime: fastest5km,
                    fastest10kmTime: fastest10km
                ))
            }
        }

        return sessions
    }

    // MARK: - Wallet (convenience)

    static let wallet: Wallet = {
        users[3].wallet!   // Andy's wallet
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
                type: .fastest1km,
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
                type: .fastest5km,
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
                category: .seniorMen,
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
        let lbData: [(userId: String, name: String, score: Double)] = [
            ("billy-001",  "Billy Butler", 22.4),
            ("jon-001",    "Jon",          21.8),
            ("andy-001",   "Andy",         20.5),
            ("farley-001", "Farley",       19.2),
            ("tom-001",    "Tom",          17.3),
        ]

        return Leaderboard(
            id: "leaderboard-001",
            raceId: "race-002",
            entries: lbData.enumerated().map { i, item in
                LeaderboardEntry(
                    id: "lb-\(String(format: "%03d", i + 1))",
                    rank: i + 1,
                    userId: item.userId,
                    userName: item.name,
                    userProfileURL: nil,
                    score: item.score,
                    sessionId: sessions.first { $0.userId == item.userId }?.id,
                    raceType: .fastest1km
                )
            },
            updatedAt: Date()
        )
    }()

    // MARK: - Debug Verification

    #if DEBUG
    private static func verifyMockData(sessions: [Session]) {
        assert(sessions.count == 936,
               "MockData: expected 936 sessions, got \(sessions.count)")

        for spec in athleteSpecs {
            let uSessions = sessions.filter { $0.userId == spec.userId }
            assert(uSessions.count == 156,
                   "MockData: \(spec.userId) has \(uSessions.count) sessions, expected 156")
        }
    }
    #endif
}
