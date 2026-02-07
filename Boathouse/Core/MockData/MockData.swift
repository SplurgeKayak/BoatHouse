import Foundation
import CoreLocation

/// Mock data for previews and testing
enum MockData {

    // MARK: - Users

    static var racerUser: User {
        User(
            id: "user-001",
            email: "james.wilson@example.com",
            displayName: "James Wilson",
            userType: .racer,
            stravaConnection: StravaConnection(
                athleteId: 12345678,
                accessToken: "mock_access_token_001",
                refreshToken: "mock_refresh_token_001",
                expiresAt: Date().addingTimeInterval(21600),
                athleteProfile: StravaAthleteProfile(
                    id: 12345678,
                    firstName: "James",
                    lastName: "Wilson",
                    profileImageURL: nil,
                    city: "London",
                    country: "United Kingdom",
                    sex: "M",
                    dateOfBirth: Calendar.current.date(from: DateComponents(year: 1995, month: 3, day: 15))
                )
            ),
            wallet: Wallet(
                id: "wallet-001",
                userId: "user-001",
                balance: 47.50,
                autoPayoutEnabled: false,
                payoutDetails: PayoutDetails(
                    bankName: "HSBC",
                    accountNumberLast4: "1234",
                    sortCode: "40-47-84",
                    isVerified: true
                ),
                createdAt: Date().addingTimeInterval(-86400 * 120),
                updatedAt: Date()
            ),
            dateOfBirth: Calendar.current.date(from: DateComponents(year: 1995, month: 3, day: 15)),
            gender: .male,
            profileImageURL: nil,
            createdAt: Date().addingTimeInterval(-86400 * 120),
            updatedAt: Date()
        )
    }

    static var spectatorUser: User {
        User(
            id: "user-006",
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
    }

    // MARK: - Wallet

    static var wallet: Wallet {
        Wallet(
            id: "wallet-001",
            userId: "user-001",
            balance: 47.50,
            autoPayoutEnabled: false,
            payoutDetails: PayoutDetails(
                bankName: "HSBC",
                accountNumberLast4: "1234",
                sortCode: "40-47-84",
                isVerified: true
            ),
            createdAt: Date().addingTimeInterval(-86400 * 120),
            updatedAt: Date()
        )
    }

    // MARK: - Transactions

    static var transactions: [WalletTransaction] {
        [
            WalletTransaction(
                id: "txn-001",
                walletId: "wallet-001",
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
                walletId: "wallet-001",
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
                walletId: "wallet-001",
                type: .prize,
                amount: 35.25,
                description: "2nd Place - Weekly Fastest 1km",
                status: .completed,
                relatedRaceId: "race-010",
                relatedEntryId: "entry-010",
                createdAt: Date().addingTimeInterval(-86400 * 2)
            )
        ]
    }

    // MARK: - Races

    static var races: [Race] {
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
            )
        ]
    }

    // MARK: - Sessions (formerly Activities)
    //
    // Date spread (assuming today ≈ 2026-02-07):
    //   Today:      sessions 001, 004, 006, 007, 009, 010
    //   This week:  sessions 002, 003, 005, 008, 011
    //   This year:  sessions 012, 013 (last month / earlier)

    static var sessions: [Session] {
        let thamesStart = Coordinate(latitude: 51.4615, longitude: -0.3015)
        let thamesEnd = Coordinate(latitude: 51.4812, longitude: -0.2734)
        let leeValleyStart = Coordinate(latitude: 51.5742, longitude: -0.0356)
        let leeValleyEnd = Coordinate(latitude: 51.5621, longitude: -0.0412)
        let grandUnionStart = Coordinate(latitude: 51.5312, longitude: -0.4521)
        let grandUnionEnd = Coordinate(latitude: 51.6234, longitude: -0.5012)
        let lakeDStart = Coordinate(latitude: 54.4609, longitude: -3.0886)
        let lakeDEnd = Coordinate(latitude: 54.4712, longitude: -3.0734)
        let severnStart = Coordinate(latitude: 52.1936, longitude: -2.2216)
        let severnEnd = Coordinate(latitude: 52.2012, longitude: -2.2134)
        let camStart = Coordinate(latitude: 52.2053, longitude: 0.1218)
        let camEnd = Coordinate(latitude: 52.2112, longitude: 0.1156)
        let lochStart = Coordinate(latitude: 56.4112, longitude: -5.4721)
        let lochEnd = Coordinate(latitude: 56.4234, longitude: -5.4612)

        return [
            // ── User 001 – James Wilson ───────────────────────
            Session(
                id: "session-001",
                stravaId: 10000001,
                userId: "user-001",
                name: "Morning Thames Paddle",
                sessionType: .kayaking,
                startDate: Date().addingTimeInterval(-3600 * 4),
                elapsedTime: 3845,
                movingTime: 3602,
                distance: 8750.5,
                maxSpeed: 4.8,
                averageSpeed: 2.43,
                startLocation: thamesStart,
                endLocation: thamesEnd,
                polyline: PolylineCodec.generateRoute(from: thamesStart, to: thamesEnd, pointCount: 35),
                isGPSVerified: true,
                isUKSession: true,
                flagCount: 0,
                status: .verified,
                importedAt: Date().addingTimeInterval(-3600 * 3),
                fastest1kmTime: 245,
                fastest5kmTime: 1280
            ),
            Session(
                id: "session-002",
                stravaId: 10000002,
                userId: "user-001",
                name: "Evening Sprint Session",
                sessionType: .canoeing,
                startDate: Date().addingTimeInterval(-86400),
                elapsedTime: 2456,
                movingTime: 2312,
                distance: 5890.2,
                maxSpeed: 5.2,
                averageSpeed: 2.55,
                startLocation: leeValleyStart,
                endLocation: leeValleyEnd,
                polyline: PolylineCodec.generateRoute(from: leeValleyStart, to: leeValleyEnd, pointCount: 28),
                isGPSVerified: true,
                isUKSession: true,
                flagCount: 0,
                status: .verified,
                importedAt: Date().addingTimeInterval(-86400 + 3600),
                fastest1kmTime: 230,
                fastest5kmTime: 1210
            ),
            Session(
                id: "session-003",
                stravaId: 10000003,
                userId: "user-001",
                name: "Long Distance Challenge",
                sessionType: .kayaking,
                startDate: Date().addingTimeInterval(-86400 * 2),
                elapsedTime: 10845,
                movingTime: 9876,
                distance: 25420.8,
                maxSpeed: 4.1,
                averageSpeed: 2.57,
                startLocation: grandUnionStart,
                endLocation: grandUnionEnd,
                polyline: PolylineCodec.generateRoute(from: grandUnionStart, to: grandUnionEnd, pointCount: 55),
                isGPSVerified: true,
                isUKSession: true,
                flagCount: 0,
                status: .verified,
                importedAt: Date().addingTimeInterval(-86400 * 2 + 7200),
                fastest1kmTime: 235,
                fastest5kmTime: 1190,
                fastest10kmTime: 2420
            ),

            // ── User 002 – Sarah Chen ────────────────────────
            Session(
                id: "session-004",
                stravaId: 10000004,
                userId: "user-002",
                name: "Lake District Adventure",
                sessionType: .kayaking,
                startDate: Date().addingTimeInterval(-3600 * 2),
                elapsedTime: 5400,
                movingTime: 5100,
                distance: 12500.0,
                maxSpeed: 5.5,
                averageSpeed: 2.45,
                startLocation: lakeDStart,
                endLocation: lakeDEnd,
                polyline: PolylineCodec.generateRoute(from: lakeDStart, to: lakeDEnd, pointCount: 40),
                isGPSVerified: true,
                isUKSession: true,
                flagCount: 0,
                status: .verified,
                importedAt: Date().addingTimeInterval(-3600),
                fastest1kmTime: 220,
                fastest5kmTime: 1150,
                fastest10kmTime: 2350
            ),
            Session(
                id: "session-005",
                stravaId: 10000005,
                userId: "user-002",
                name: "Quick Morning Row",
                sessionType: .rowing,
                startDate: Date().addingTimeInterval(-86400 * 0.5),
                elapsedTime: 1800,
                movingTime: 1720,
                distance: 4200.0,
                maxSpeed: 4.2,
                averageSpeed: 2.44,
                startLocation: nil,
                endLocation: nil,
                polyline: PolylineCodec.generateLoopRoute(
                    center: CLLocationCoordinate2D(latitude: 51.508, longitude: -0.076),
                    radiusDegrees: 0.005,
                    pointCount: 25
                ),
                isGPSVerified: true,
                isUKSession: true,
                flagCount: 0,
                status: .verified,
                importedAt: Date().addingTimeInterval(-3600 * 10),
                fastest1kmTime: 248
            ),
            // Sarah's session from last month (for year filter testing)
            Session(
                id: "session-012",
                stravaId: 10000012,
                userId: "user-002",
                name: "New Year Resolution Paddle",
                sessionType: .kayaking,
                startDate: Date().addingTimeInterval(-86400 * 14),
                elapsedTime: 6000,
                movingTime: 5700,
                distance: 14200.0,
                maxSpeed: 5.0,
                averageSpeed: 2.49,
                startLocation: lakeDStart,
                endLocation: lakeDEnd,
                polyline: PolylineCodec.generateRoute(from: lakeDStart, to: lakeDEnd, pointCount: 45),
                isGPSVerified: true,
                isUKSession: true,
                flagCount: 0,
                status: .verified,
                importedAt: Date().addingTimeInterval(-86400 * 13),
                fastest1kmTime: 242,
                fastest5kmTime: 1240,
                fastest10kmTime: 2480
            ),

            // ── User 003 – Mike Johnson ──────────────────────
            Session(
                id: "session-006",
                stravaId: 10000006,
                userId: "user-003",
                name: "River Severn Exploration",
                sessionType: .canoeing,
                startDate: Date().addingTimeInterval(-3600 * 6),
                elapsedTime: 7200,
                movingTime: 6800,
                distance: 15800.0,
                maxSpeed: 4.8,
                averageSpeed: 2.32,
                startLocation: severnStart,
                endLocation: severnEnd,
                polyline: PolylineCodec.generateRoute(from: severnStart, to: severnEnd, pointCount: 50),
                isGPSVerified: true,
                isUKSession: true,
                flagCount: 0,
                status: .verified,
                importedAt: Date().addingTimeInterval(-3600 * 5),
                fastest1kmTime: 258,
                fastest5kmTime: 1320,
                fastest10kmTime: 2680
            ),
            Session(
                id: "session-007",
                stravaId: 10000007,
                userId: "user-003",
                name: "Sprint Training",
                sessionType: .kayaking,
                startDate: Date().addingTimeInterval(-3600 * 8),
                elapsedTime: 2700,
                movingTime: 2600,
                distance: 6500.0,
                maxSpeed: 5.8,
                averageSpeed: 2.5,
                startLocation: nil,
                endLocation: nil,
                polyline: PolylineCodec.generateLoopRoute(
                    center: CLLocationCoordinate2D(latitude: 52.19, longitude: -2.22),
                    radiusDegrees: 0.006,
                    pointCount: 30
                ),
                isGPSVerified: true,
                isUKSession: true,
                flagCount: 0,
                status: .verified,
                importedAt: Date().addingTimeInterval(-3600 * 7),
                fastest1kmTime: 225,
                fastest5kmTime: 1170
            ),
            Session(
                id: "session-008",
                stravaId: 10000008,
                userId: "user-003",
                name: "Endurance Session",
                sessionType: .kayaking,
                startDate: Date().addingTimeInterval(-86400 * 1.5),
                elapsedTime: 10800,
                movingTime: 10200,
                distance: 28000.0,
                maxSpeed: 4.5,
                averageSpeed: 2.74,
                startLocation: nil,
                endLocation: nil,
                polyline: PolylineCodec.generateLoopRoute(
                    center: CLLocationCoordinate2D(latitude: 51.50, longitude: -0.10),
                    radiusDegrees: 0.015,
                    pointCount: 60
                ),
                isGPSVerified: true,
                isUKSession: true,
                flagCount: 0,
                status: .verified,
                importedAt: Date().addingTimeInterval(-86400),
                fastest1kmTime: 218,
                fastest5kmTime: 1110,
                fastest10kmTime: 2260
            ),

            // ── User 004 – Emma Davis ────────────────────────
            Session(
                id: "session-009",
                stravaId: 10000009,
                userId: "user-004",
                name: "Cambridge River Tour",
                sessionType: .rowing,
                startDate: Date().addingTimeInterval(-3600 * 1),
                elapsedTime: 3600,
                movingTime: 3400,
                distance: 8200.0,
                maxSpeed: 4.3,
                averageSpeed: 2.41,
                startLocation: camStart,
                endLocation: camEnd,
                polyline: PolylineCodec.generateRoute(from: camStart, to: camEnd, pointCount: 30),
                isGPSVerified: true,
                isUKSession: true,
                flagCount: 0,
                status: .verified,
                importedAt: Date().addingTimeInterval(-1800),
                fastest1kmTime: 250,
                fastest5kmTime: 1290
            ),
            // Emma's session from early January (for year filter testing)
            Session(
                id: "session-013",
                stravaId: 10000013,
                userId: "user-004",
                name: "Winter Solstice Row",
                sessionType: .rowing,
                startDate: Date().addingTimeInterval(-86400 * 35),
                elapsedTime: 7800,
                movingTime: 7400,
                distance: 18200.0,
                maxSpeed: 4.6,
                averageSpeed: 2.46,
                startLocation: camStart,
                endLocation: camEnd,
                polyline: PolylineCodec.generateRoute(from: camStart, to: camEnd, pointCount: 48),
                isGPSVerified: true,
                isUKSession: true,
                flagCount: 0,
                status: .verified,
                importedAt: Date().addingTimeInterval(-86400 * 34),
                fastest1kmTime: 255,
                fastest5kmTime: 1300,
                fastest10kmTime: 2620
            ),

            // ── User 005 – Tom Roberts ───────────────────────
            Session(
                id: "session-010",
                stravaId: 10000010,
                userId: "user-005",
                name: "Scottish Loch Paddle",
                sessionType: .kayaking,
                startDate: Date().addingTimeInterval(-3600 * 3),
                elapsedTime: 4800,
                movingTime: 4500,
                distance: 11200.0,
                maxSpeed: 4.9,
                averageSpeed: 2.49,
                startLocation: lochStart,
                endLocation: lochEnd,
                polyline: PolylineCodec.generateRoute(from: lochStart, to: lochEnd, pointCount: 38),
                isGPSVerified: true,
                isUKSession: true,
                flagCount: 0,
                status: .verified,
                importedAt: Date().addingTimeInterval(-3600 * 2),
                fastest1kmTime: 238,
                fastest5kmTime: 1220,
                fastest10kmTime: 2500
            ),
            Session(
                id: "session-011",
                stravaId: 10000011,
                userId: "user-005",
                name: "Evening Cooldown",
                sessionType: .canoeing,
                startDate: Date().addingTimeInterval(-86400),
                elapsedTime: 2400,
                movingTime: 2200,
                distance: 5100.0,
                maxSpeed: 3.8,
                averageSpeed: 2.32,
                startLocation: nil,
                endLocation: nil,
                polyline: PolylineCodec.generateLoopRoute(
                    center: CLLocationCoordinate2D(latitude: 56.41, longitude: -5.47),
                    radiusDegrees: 0.005,
                    pointCount: 25
                ),
                isGPSVerified: true,
                isUKSession: true,
                flagCount: 0,
                status: .verified,
                importedAt: Date().addingTimeInterval(-86400 + 3600),
                fastest1kmTime: 260,
                fastest5kmTime: 1350
            )
        ]
    }

    // MARK: - Entries

    static var entries: [Entry] {
        [
            Entry(
                id: "entry-001",
                userId: "user-001",
                raceId: "race-002",
                sessionId: "session-001",
                enteredAt: Date().addingTimeInterval(-86400 * 2),
                score: 17.28,
                rank: 5,
                status: .active,
                prizeWon: nil,
                transactionId: "txn-002"
            ),
            Entry(
                id: "entry-002",
                userId: "user-001",
                raceId: "race-001",
                sessionId: "session-002",
                enteredAt: Date().addingTimeInterval(-3600 * 6),
                score: 18.72,
                rank: 3,
                status: .active,
                prizeWon: nil,
                transactionId: nil
            )
        ]
    }

    // MARK: - Leaderboard

    static var leaderboard: Leaderboard {
        Leaderboard(
            id: "leaderboard-001",
            raceId: "race-002",
            entries: [
                LeaderboardEntry(
                    id: "lb-001",
                    rank: 1,
                    userId: "user-010",
                    userName: "David Henderson",
                    userProfileURL: nil,
                    score: 22.4,
                    sessionId: "session-ext-001",
                    raceType: .topSpeed
                ),
                LeaderboardEntry(
                    id: "lb-002",
                    rank: 2,
                    userId: "user-011",
                    userName: "Michael Roberts",
                    userProfileURL: nil,
                    score: 21.8,
                    sessionId: "session-ext-002",
                    raceType: .topSpeed
                ),
                LeaderboardEntry(
                    id: "lb-003",
                    rank: 3,
                    userId: "user-012",
                    userName: "Christopher Lee",
                    userProfileURL: nil,
                    score: 20.5,
                    sessionId: "session-ext-003",
                    raceType: .topSpeed
                ),
                LeaderboardEntry(
                    id: "lb-004",
                    rank: 4,
                    userId: "user-013",
                    userName: "Daniel Wright",
                    userProfileURL: nil,
                    score: 19.2,
                    sessionId: "session-ext-004",
                    raceType: .topSpeed
                ),
                LeaderboardEntry(
                    id: "lb-005",
                    rank: 5,
                    userId: "user-001",
                    userName: "James Wilson",
                    userProfileURL: nil,
                    score: 17.28,
                    sessionId: "session-001",
                    raceType: .topSpeed
                )
            ],
            updatedAt: Date()
        )
    }
}
