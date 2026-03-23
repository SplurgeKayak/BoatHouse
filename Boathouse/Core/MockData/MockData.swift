import Foundation
import CoreLocation

// ─────────────────────────────────────────────────────────────────────
// MockData — programmatically generated mock data
//
// Athletes: 56 (6 benchmark racers + 50 additional)
//   Benchmarks: Billy Butler, Jon Ogrady, Tom Daniels,
//               Andy Daniels (logged-in), Farley Wright, Stuart Bennett
//
// Sessions: 3 per week × 52 weeks = 156 per athlete = 8736 total
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
        let best2kTarget: TimeInterval    // best 2 km rep time (seconds)
        let best300mTarget: TimeInterval  // best 300 m rep time (seconds)
        let location: Coordinate?         // athlete's home water coordinates
    }

    // MARK: - Benchmark Athletes (6)

    private static let benchmarkSpecs: [AthleteSpec] = [
        AthleteSpec(name: "Billy Butler",   userId: "billy-001",   stravaId: 10000001, basePaceSecPerKm: 243, paceVariance: 8,  best1kTarget: 243, best5kTarget: 1625, best10kTarget: 3371, best2kTarget: 422, best300mTarget: 70.0,  location: Coordinate(latitude: 52.370, longitude:  4.900)),
        AthleteSpec(name: "Jon Ogrady",     userId: "jon-001",     stravaId: 10000002, basePaceSecPerKm: 255, paceVariance: 9,  best1kTarget: 255, best5kTarget: 1706, best10kTarget: 3540, best2kTarget: 443, best300mTarget: 73.5,  location: Coordinate(latitude: 53.400, longitude: -2.990)),
        AthleteSpec(name: "Tom Daniels",    userId: "tom-001",     stravaId: 10000005, basePaceSecPerKm: 279, paceVariance: 12, best1kTarget: 279, best5kTarget: 1869, best10kTarget: 3877, best2kTarget: 485, best300mTarget: 80.5,  location: Coordinate(latitude: 51.410, longitude: -0.300)),
        AthleteSpec(name: "Andy Daniels",   userId: "andy-001",    stravaId: 10000004, basePaceSecPerKm: 282, paceVariance: 12, best1kTarget: 282, best5kTarget: 1885, best10kTarget: 3910, best2kTarget: 490, best300mTarget: 81.2,  location: Coordinate(latitude: 52.950, longitude: -1.150)),
        AthleteSpec(name: "Farley Wright",  userId: "farley-001",  stravaId: 10000003, basePaceSecPerKm: 316, paceVariance: 11, best1kTarget: 316, best5kTarget: 2113, best10kTarget: 4382, best2kTarget: 549, best300mTarget: 91.0,  location: Coordinate(latitude: 50.720, longitude: -3.530)),
        AthleteSpec(name: "Stuart Bennett", userId: "stuart-001",  stravaId: 10000006, basePaceSecPerKm: 365, paceVariance: 15, best1kTarget: 365, best5kTarget: 2438, best10kTarget: 5057, best2kTarget: 633, best300mTarget: 105.0, location: Coordinate(latitude: 51.450, longitude: -0.970)),
    ]

    // MARK: - Venue Coordinates (20 UK cities, cycled for additional athletes)

    private static let venueCoordinates: [Coordinate] = [
        Coordinate(latitude: 52.9500, longitude: -1.1500), // Nottingham
        Coordinate(latitude: 51.4500, longitude: -0.9700), // Reading
        Coordinate(latitude: 50.7200, longitude: -3.5300), // Exeter
        Coordinate(latitude: 51.4100, longitude: -0.3000), // Kingston upon Thames
        Coordinate(latitude: 53.4000, longitude: -2.9900), // Liverpool
        Coordinate(latitude: 53.4800, longitude: -2.2400), // Manchester
        Coordinate(latitude: 51.4550, longitude: -2.5900), // Bristol
        Coordinate(latitude: 53.8000, longitude: -1.5500), // Leeds
        Coordinate(latitude: 53.3800, longitude: -1.4700), // Sheffield
        Coordinate(latitude: 51.4800, longitude: -3.1800), // Cardiff
        Coordinate(latitude: 55.9500, longitude: -3.1900), // Edinburgh
        Coordinate(latitude: 55.8600, longitude: -4.2600), // Glasgow
        Coordinate(latitude: 51.7500, longitude: -1.2600), // Oxford
        Coordinate(latitude: 52.2000, longitude:  0.1200), // Cambridge
        Coordinate(latitude: 52.6300, longitude:  1.3000), // Norwich
        Coordinate(latitude: 50.3800, longitude: -4.1400), // Plymouth
        Coordinate(latitude: 50.8200, longitude: -0.1400), // Brighton
        Coordinate(latitude: 50.9000, longitude: -1.4000), // Southampton
        Coordinate(latitude: 54.9700, longitude: -1.6200), // Newcastle
        Coordinate(latitude: 51.3800, longitude: -2.3600), // Bath
    ]

    private static let venueCities: [String] = [
        "Nottingham", "Reading", "Exeter", "Kingston upon Thames", "Liverpool",
        "Manchester", "Bristol", "Leeds", "Sheffield", "Cardiff",
        "Edinburgh", "Glasgow", "Oxford", "Cambridge", "Norwich",
        "Plymouth", "Brighton", "Southampton", "Newcastle", "Bath",
    ]

    // MARK: - Additional Athletes (50)

    private static let additionalAthleteNames: [(name: String, userId: String)] = [
        ("James Weir",        "james-weir"),
        ("Rachel Cawthorn",   "rachel-cawthorn"),
        ("Luca Ferretti",     "luca-ferretti"),
        ("Sophie Mallinson",  "sophie-mallinson"),
        ("Harry Aldous",      "harry-aldous"),
        ("Emma Spence",       "emma-spence"),
        ("Oliver Rowe",       "oliver-rowe"),
        ("Charlotte Baines",  "charlotte-baines"),
        ("Ethan Croft",       "ethan-croft"),
        ("Isabelle Dunn",     "isabelle-dunn"),
        ("Noah Hartley",      "noah-hartley"),
        ("Amelia Cross",      "amelia-cross"),
        ("Finn Gallagher",    "finn-gallagher"),
        ("Grace Thornton",    "grace-thornton"),
        ("Callum Brady",      "callum-brady"),
        ("Megan Sutherland",  "megan-sutherland"),
        ("Rhys Davies",       "rhys-davies"),
        ("Hannah Perry",      "hannah-perry"),
        ("Connor Walsh",      "connor-walsh"),
        ("Lucy Morton",       "lucy-morton"),
        ("Aaron Chambers",    "aaron-chambers"),
        ("Bethany Doyle",     "bethany-doyle"),
        ("Jack Simmons",      "jack-simmons"),
        ("Chloe Griffiths",   "chloe-griffiths"),
        ("Ryan Fletcher",     "ryan-fletcher"),
        ("Natalie Webb",      "natalie-webb"),
        ("Sam Holt",          "sam-holt"),
        ("Zoe Atkinson",      "zoe-atkinson"),
        ("Luke Patterson",    "luke-patterson"),
        ("Amy Nolan",         "amy-nolan"),
        ("Ben Walters",       "ben-walters"),
        ("Katie Hughes",      "katie-hughes"),
        ("Josh Blackwood",    "josh-blackwood"),
        ("Ellie Savage",      "ellie-savage"),
        ("Marcus Cole",       "marcus-cole"),
        ("Freya Jennings",    "freya-jennings"),
        ("Dylan Marsh",       "dylan-marsh"),
        ("Poppy Lawson",      "poppy-lawson"),
        ("Jamie Saunders",    "jamie-saunders"),
        ("Niamh Byrne",       "niamh-byrne"),
        ("Kieran Lang",       "kieran-lang"),
        ("Rosie Caldwell",    "rosie-caldwell"),
        ("Toby Prentice",     "toby-prentice"),
        ("Amber Scott",       "amber-scott"),
        ("Liam Donnelly",     "liam-donnelly"),
        ("Sophia Lane",       "sophia-lane"),
        ("Alex Garner",       "alex-garner"),
        ("Molly Farrow",      "molly-farrow"),
        ("Owen Castle",       "owen-castle"),
        ("Tara Leigh",        "tara-leigh"),
    ]

    private static let additionalSpecs: [AthleteSpec] = {
        (0..<50).map { i in
            let nameInfo = additionalAthleteNames[i]
            let factor = 1.05 + Double(i) * (0.45 / 49.0)
            let venueIndex = i % 20
            return AthleteSpec(
                name: nameInfo.name,
                userId: nameInfo.userId,
                stravaId: 10000007 + i,
                basePaceSecPerKm: 243.0 * factor,
                paceVariance: 10.0,
                best1kTarget: (243.0  * factor).rounded(),
                best5kTarget: (1625.0 * factor).rounded(),
                best10kTarget: (3371.0 * factor).rounded(),
                best2kTarget: (422.0  * factor).rounded(),
                best300mTarget: 70.0 * factor,
                location: venueCoordinates[venueIndex]
            )
        }
    }()

    // MARK: - All Athletes (56 = 6 benchmarks + 50 additional)

    private static let athleteSpecs: [AthleteSpec] = benchmarkSpecs + additionalSpecs

    // MARK: - City / Country Lookup

    private static func cityName(for location: Coordinate?) -> String {
        guard let location = location else { return "London" }
        for (i, coord) in venueCoordinates.enumerated() {
            if coord.latitude == location.latitude && coord.longitude == location.longitude {
                return venueCities[i]
            }
        }
        return "Amsterdam"
    }

    private static let bankNames = ["HSBC", "Barclays", "Lloyds", "NatWest", "Santander"]

    // MARK: - Users (56)

    static let users: [User] = {
        var rng = SeededRNG(seed: 42)

        return athleteSpecs.map { spec in
            let balanceCents = Int(rng.next() % 11501) + 500
            let nameParts = spec.name.components(separatedBy: " ")
            let firstName = nameParts.first ?? spec.name
            let lastName = nameParts.dropFirst().joined(separator: " ")
            let city = cityName(for: spec.location)
            let country = spec.userId == "billy-001" ? "Netherlands" : "United Kingdom"

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
                        city: city,
                        country: country,
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

    /// Andy Daniels — the logged-in racer user (index 3)
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

    // MARK: - Sessions (8736 = 56 athletes x 156 sessions)

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

    // [weekIndex % 5][dayIndex 0,1,2]
    private static let sessionTypeSchedule: [[String]] = [
        ["5k_single",       "intervals_15x4",  "10k_long"],
        ["intervals_5x2km", "intervals_300m",   "5k_single"],
        ["10k_long",        "intervals_15x4",   "intervals_5x2km"],
        ["intervals_300m",  "5k_single",        "10k_long"],
        ["intervals_15x4",  "intervals_5x2km",  "intervals_300m"],
    ]

    private static func generateSessions<RNG: RandomNumberGenerator>(
        for spec: AthleteSpec,
        rng: inout RNG
    ) -> [Session] {
        var sessions: [Session] = []
        let dayOffsets = [1, 3, 5]
        let isBilly = spec.userId == "billy-001"

        var firstIntervals15x4Done  = false
        var firstIntervals5x2kmDone = false
        var firstIntervals300mDone  = false

        for weekIndex in 0..<52 {
            for (dayIndex, dayOffset) in dayOffsets.enumerated() {
                let secondsAgo = Double((weekIndex * 7 + dayOffset) * 86400)
                let startDate = Date().addingTimeInterval(-secondsAgo)

                let sessionIndex = weekIndex * 3 + dayIndex
                let sessionId = "\(spec.userId)-session-\(String(format: "%03d", sessionIndex + 1))"
                let stravaId = spec.stravaId * 1000 + sessionIndex + 1

                let typeKey = sessionTypeSchedule[weekIndex % 5][dayIndex]

                var name: String = ""
                var distance: Double = 0
                var movingTime: Double = 0
                var fastest1km: TimeInterval? = nil
                var fastest5km: TimeInterval? = nil
                var fastest10km: TimeInterval? = nil

                switch typeKey {
                case "5k_single":
                    name = "5k Single Effort"
                    distance = 5000.0
                    movingTime = spec.best5kTarget + (Double(rng.next()) / Double(UInt64.max)) * (spec.best5kTarget * 0.30)
                    fastest5km = movingTime
                    fastest1km = movingTime / 5.0
                    fastest10km = nil

                case "intervals_15x4":
                    name = "15 × 4-min Intervals"
                    distance = 15000.0
                    movingTime = 3600.0
                    let f1k: Double
                    if isBilly && !firstIntervals15x4Done {
                        f1k = 243.0
                        firstIntervals15x4Done = true
                    } else {
                        f1k = spec.best1kTarget + (Double(rng.next()) / Double(UInt64.max)) * (spec.best1kTarget * 0.30)
                    }
                    fastest1km = f1k
                    fastest5km = f1k * 5.0
                    fastest10km = nil

                case "10k_long":
                    name = "10k Long Paddle"
                    distance = 10000.0
                    movingTime = spec.best10kTarget + (Double(rng.next()) / Double(UInt64.max)) * (spec.best10kTarget * 0.30)
                    fastest10km = movingTime
                    fastest5km = movingTime / 2.0
                    fastest1km = movingTime / 10.0

                case "intervals_5x2km":
                    name = "5 × 2km Intervals"
                    distance = 10000.0
                    let repTime: Double
                    if isBilly && !firstIntervals5x2kmDone {
                        repTime = 422.0
                        firstIntervals5x2kmDone = true
                    } else {
                        repTime = spec.best2kTarget + (Double(rng.next()) / Double(UInt64.max)) * (spec.best2kTarget * 0.30)
                    }
                    movingTime = 5.0 * repTime          // 5 reps × repTime
                    fastest5km = movingTime / 2.0       // first 5 km proxy (half of 10 km total)
                    fastest1km = movingTime / 10.0      // proportional 1 km pace from 10 km total
                    fastest10km = nil

                case "intervals_300m":
                    name = "300m × 20 Intervals"
                    distance = 6000.0 // 20 reps × 300 m
                    let repTime: Double
                    if isBilly && !firstIntervals300mDone {
                        repTime = 70.0
                        firstIntervals300mDone = true
                    } else {
                        repTime = spec.best300mTarget + (Double(rng.next()) / Double(UInt64.max)) * (spec.best300mTarget * 0.30)
                    }
                    movingTime = 20.0 * repTime
                    // Extrapolated 1 km pace from 300 m rep time (repTime / 0.3 km)
                    fastest1km = repTime / 0.3
                    fastest5km = nil
                    fastest10km = nil

                default:
                    continue
                }

                let averageSpeed = distance / movingTime
                let maxSpeed = averageSpeed * 1.15
                let elapsedTime = movingTime * 1.05

                sessions.append(Session(
                    id: sessionId,
                    stravaId: stravaId,
                    userId: spec.userId,
                    name: name,
                    sessionType: .kayaking,
                    startDate: startDate,
                    elapsedTime: elapsedTime,
                    movingTime: movingTime,
                    distance: distance,
                    maxSpeed: maxSpeed,
                    averageSpeed: averageSpeed,
                    startLocation: spec.location,
                    endLocation: spec.location,
                    polyline: nil,
                    isGPSVerified: true,
                    isUKSession: !isBilly,
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
            ("billy-001",  "Billy Butler",   26.0),
            ("jon-001",    "Jon Ogrady",     24.8),
            ("tom-001",    "Tom Daniels",    21.5),
            ("andy-001",   "Andy Daniels",   21.1),
            ("farley-001", "Farley Wright",  16.8),
            ("stuart-001", "Stuart Bennett", 14.0),
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
        assert(sessions.count == 8736,
               "MockData: expected 8736 sessions, got \(sessions.count)")

        for spec in athleteSpecs {
            let uSessions = sessions.filter { $0.userId == spec.userId }
            assert(uSessions.count == 156,
                   "MockData: \(spec.userId) has \(uSessions.count) sessions, expected 156")
        }
    }
    #endif
}
