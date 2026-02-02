import Foundation

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

    static var transactions: [Transaction] {
        [
            Transaction(
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
            Transaction(
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
            Transaction(
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

    // MARK: - Activities

    static var activities: [Activity] {
        [
            Activity(
                id: "activity-001",
                stravaId: 10000001,
                userId: "user-001",
                name: "Morning Thames Paddle",
                activityType: .kayaking,
                startDate: Date().addingTimeInterval(-3600 * 4),
                elapsedTime: 3845,
                movingTime: 3602,
                distance: 8750.5,
                maxSpeed: 4.8,
                averageSpeed: 2.43,
                startLocation: Coordinate(latitude: 51.4615, longitude: -0.3015),
                endLocation: Coordinate(latitude: 51.4812, longitude: -0.2734),
                polyline: nil,
                isGPSVerified: true,
                isUKActivity: true,
                flagCount: 0,
                status: .verified,
                importedAt: Date().addingTimeInterval(-3600 * 3)
            ),
            Activity(
                id: "activity-002",
                stravaId: 10000002,
                userId: "user-001",
                name: "Evening Sprint Session",
                activityType: .canoeing,
                startDate: Date().addingTimeInterval(-86400),
                elapsedTime: 2456,
                movingTime: 2312,
                distance: 5890.2,
                maxSpeed: 5.2,
                averageSpeed: 2.55,
                startLocation: Coordinate(latitude: 51.5742, longitude: -0.0356),
                endLocation: Coordinate(latitude: 51.5621, longitude: -0.0412),
                polyline: nil,
                isGPSVerified: true,
                isUKActivity: true,
                flagCount: 0,
                status: .verified,
                importedAt: Date().addingTimeInterval(-86400 + 3600)
            ),
            Activity(
                id: "activity-003",
                stravaId: 10000003,
                userId: "user-001",
                name: "Long Distance Challenge",
                activityType: .kayaking,
                startDate: Date().addingTimeInterval(-86400 * 2),
                elapsedTime: 10845,
                movingTime: 9876,
                distance: 25420.8,
                maxSpeed: 4.1,
                averageSpeed: 2.57,
                startLocation: Coordinate(latitude: 51.5312, longitude: -0.4521),
                endLocation: Coordinate(latitude: 51.6234, longitude: -0.5012),
                polyline: nil,
                isGPSVerified: true,
                isUKActivity: true,
                flagCount: 0,
                status: .verified,
                importedAt: Date().addingTimeInterval(-86400 * 2 + 7200)
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
                activityId: "activity-001",
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
                activityId: "activity-002",
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
                    activityId: "activity-ext-001",
                    raceType: .topSpeed
                ),
                LeaderboardEntry(
                    id: "lb-002",
                    rank: 2,
                    userId: "user-011",
                    userName: "Michael Roberts",
                    userProfileURL: nil,
                    score: 21.8,
                    activityId: "activity-ext-002",
                    raceType: .topSpeed
                ),
                LeaderboardEntry(
                    id: "lb-003",
                    rank: 3,
                    userId: "user-012",
                    userName: "Christopher Lee",
                    userProfileURL: nil,
                    score: 20.5,
                    activityId: "activity-ext-003",
                    raceType: .topSpeed
                ),
                LeaderboardEntry(
                    id: "lb-004",
                    rank: 4,
                    userId: "user-013",
                    userName: "Daniel Wright",
                    userProfileURL: nil,
                    score: 19.2,
                    activityId: "activity-ext-004",
                    raceType: .topSpeed
                ),
                LeaderboardEntry(
                    id: "lb-005",
                    rank: 5,
                    userId: "user-001",
                    userName: "James Wilson",
                    userProfileURL: nil,
                    score: 17.28,
                    activityId: "activity-001",
                    raceType: .topSpeed
                )
            ],
            updatedAt: Date()
        )
    }
}
