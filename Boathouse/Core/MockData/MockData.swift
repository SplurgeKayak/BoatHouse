import Foundation

/// Mock data for previews and testing
enum MockData {

    // MARK: - Users

    static let users: [User] = [
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
                athleteProfile: MockStravaData.athletes[0]
            ),
            wallet: wallets[0],
            dateOfBirth: Calendar.current.date(from: DateComponents(year: 1995, month: 3, day: 15)),
            gender: .male,
            profileImageURL: URL(string: "https://example.com/james.jpg"),
            createdAt: Date().addingTimeInterval(-86400 * 120),
            updatedAt: Date()
        ),
        User(
            id: "user-002",
            email: "emma.thompson@example.com",
            displayName: "Emma Thompson",
            userType: .racer,
            stravaConnection: StravaConnection(
                athleteId: 23456789,
                accessToken: "mock_access_token_002",
                refreshToken: "mock_refresh_token_002",
                expiresAt: Date().addingTimeInterval(21600),
                athleteProfile: MockStravaData.athletes[1]
            ),
            wallet: wallets[1],
            dateOfBirth: Calendar.current.date(from: DateComponents(year: 1998, month: 7, day: 22)),
            gender: .female,
            profileImageURL: nil,
            createdAt: Date().addingTimeInterval(-86400 * 90),
            updatedAt: Date()
        ),
        User(
            id: "user-003",
            email: "oliver.brown@example.com",
            displayName: "Oliver Brown",
            userType: .racer,
            stravaConnection: StravaConnection(
                athleteId: 34567890,
                accessToken: "mock_access_token_003",
                refreshToken: "mock_refresh_token_003",
                expiresAt: Date().addingTimeInterval(21600),
                athleteProfile: MockStravaData.athletes[2]
            ),
            wallet: wallets[2],
            dateOfBirth: Calendar.current.date(from: DateComponents(year: 1988, month: 11, day: 8)),
            gender: .male,
            profileImageURL: nil,
            createdAt: Date().addingTimeInterval(-86400 * 200),
            updatedAt: Date()
        ),
        User(
            id: "user-004",
            email: "sophie.davies@example.com",
            displayName: "Sophie Davies",
            userType: .racer,
            stravaConnection: StravaConnection(
                athleteId: 45678901,
                accessToken: "mock_access_token_004",
                refreshToken: "mock_refresh_token_004",
                expiresAt: Date().addingTimeInterval(21600),
                athleteProfile: MockStravaData.athletes[3]
            ),
            wallet: wallets[3],
            dateOfBirth: Calendar.current.date(from: DateComponents(year: 2007, month: 5, day: 30)),
            gender: .female,
            profileImageURL: nil,
            createdAt: Date().addingTimeInterval(-86400 * 45),
            updatedAt: Date()
        ),
        User(
            id: "user-005",
            email: "william.taylor@example.com",
            displayName: "William Taylor",
            userType: .racer,
            stravaConnection: StravaConnection(
                athleteId: 56789012,
                accessToken: "mock_access_token_005",
                refreshToken: "mock_refresh_token_005",
                expiresAt: Date().addingTimeInterval(21600),
                athleteProfile: MockStravaData.athletes[4]
            ),
            wallet: wallets[4],
            dateOfBirth: Calendar.current.date(from: DateComponents(year: 1985, month: 9, day: 12)),
            gender: .male,
            profileImageURL: nil,
            createdAt: Date().addingTimeInterval(-86400 * 365),
            updatedAt: Date()
        ),
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
    ]

    static var racerUser: User { users[0] }
    static var spectatorUser: User { users[5] }

    // MARK: - Wallets

    static let wallets: [Wallet] = [
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
        ),
        Wallet(
            id: "wallet-002",
            userId: "user-002",
            balance: 123.75,
            autoPayoutEnabled: true,
            payoutDetails: PayoutDetails(
                bankName: "Barclays",
                accountNumberLast4: "5678",
                sortCode: "20-32-45",
                isVerified: true
            ),
            createdAt: Date().addingTimeInterval(-86400 * 90),
            updatedAt: Date()
        ),
        Wallet(
            id: "wallet-003",
            userId: "user-003",
            balance: 89.25,
            autoPayoutEnabled: false,
            payoutDetails: PayoutDetails(
                bankName: "Lloyds",
                accountNumberLast4: "9012",
                sortCode: "30-12-67",
                isVerified: true
            ),
            createdAt: Date().addingTimeInterval(-86400 * 200),
            updatedAt: Date()
        ),
        Wallet(
            id: "wallet-004",
            userId: "user-004",
            balance: 15.00,
            autoPayoutEnabled: false,
            payoutDetails: nil,
            createdAt: Date().addingTimeInterval(-86400 * 45),
            updatedAt: Date()
        ),
        Wallet(
            id: "wallet-005",
            userId: "user-005",
            balance: 256.80,
            autoPayoutEnabled: true,
            payoutDetails: PayoutDetails(
                bankName: "NatWest",
                accountNumberLast4: "3456",
                sortCode: "60-14-28",
                isVerified: true
            ),
            createdAt: Date().addingTimeInterval(-86400 * 365),
            updatedAt: Date()
        )
    ]

    static var wallet: Wallet { wallets[0] }

    // MARK: - Transactions

    static let transactions: [Transaction] = [
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
            type: .entryFee,
            amount: 1.00,
            description: "Daily Furthest Distance - Senior Men",
            status: .completed,
            relatedRaceId: "race-002",
            relatedEntryId: "entry-002",
            createdAt: Date().addingTimeInterval(-86400 * 3)
        ),
        Transaction(
            id: "txn-004",
            walletId: "wallet-001",
            type: .prize,
            amount: 35.25,
            description: "2nd Place - Weekly Fastest 1km",
            status: .completed,
            relatedRaceId: "race-010",
            relatedEntryId: "entry-010",
            createdAt: Date().addingTimeInterval(-86400 * 2)
        ),
        Transaction(
            id: "txn-005",
            walletId: "wallet-001",
            type: .entryFee,
            amount: 15.99,
            description: "Monthly Top Speed - Senior Men",
            status: .completed,
            relatedRaceId: "race-003",
            relatedEntryId: "entry-003",
            createdAt: Date().addingTimeInterval(-86400)
        ),
        Transaction(
            id: "txn-006",
            walletId: "wallet-001",
            type: .prize,
            amount: 156.75,
            description: "1st Place - Weekly Furthest Distance",
            status: .completed,
            relatedRaceId: "race-011",
            relatedEntryId: "entry-011",
            createdAt: Date().addingTimeInterval(-3600 * 12)
        ),
        Transaction(
            id: "txn-007",
            walletId: "wallet-001",
            type: .withdrawal,
            amount: 100.00,
            description: "Withdrawal to bank account",
            status: .completed,
            relatedRaceId: nil,
            relatedEntryId: nil,
            createdAt: Date().addingTimeInterval(-3600 * 6)
        )
    ]

    // MARK: - Races

    static let races: [Race] = [
        // Daily Races
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
            duration: .daily,
            category: .seniorMen,
            startDate: Calendar.current.startOfDay(for: Date()),
            endDate: Calendar.current.startOfDay(for: Date()).addingTimeInterval(86400),
            entryCount: 28,
            prizePool: 28.00,
            status: .active,
            createdAt: Calendar.current.startOfDay(for: Date())
        ),
        Race(
            id: "race-003",
            type: .fastest1km,
            duration: .daily,
            category: .seniorWomen,
            startDate: Calendar.current.startOfDay(for: Date()),
            endDate: Calendar.current.startOfDay(for: Date()).addingTimeInterval(86400),
            entryCount: 19,
            prizePool: 19.00,
            status: .active,
            createdAt: Calendar.current.startOfDay(for: Date())
        ),
        Race(
            id: "race-004",
            type: .fastest5km,
            duration: .daily,
            category: .juniorBoys,
            startDate: Calendar.current.startOfDay(for: Date()),
            endDate: Calendar.current.startOfDay(for: Date()).addingTimeInterval(86400),
            entryCount: 12,
            prizePool: 12.00,
            status: .active,
            createdAt: Calendar.current.startOfDay(for: Date())
        ),

        // Weekly Races
        Race(
            id: "race-005",
            type: .topSpeed,
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
            id: "race-006",
            type: .furthestDistance,
            duration: .weekly,
            category: .seniorWomen,
            startDate: Date().addingTimeInterval(-86400 * 3),
            endDate: Date().addingTimeInterval(86400 * 4),
            entryCount: 56,
            prizePool: 279.44,
            status: .active,
            createdAt: Date().addingTimeInterval(-86400 * 3)
        ),
        Race(
            id: "race-007",
            type: .fastest1km,
            duration: .weekly,
            category: .mastersMen,
            startDate: Date().addingTimeInterval(-86400 * 3),
            endDate: Date().addingTimeInterval(86400 * 4),
            entryCount: 42,
            prizePool: 209.58,
            status: .active,
            createdAt: Date().addingTimeInterval(-86400 * 3)
        ),
        Race(
            id: "race-008",
            type: .fastest5km,
            duration: .weekly,
            category: .juniorGirls,
            startDate: Date().addingTimeInterval(-86400 * 3),
            endDate: Date().addingTimeInterval(86400 * 4),
            entryCount: 23,
            prizePool: 114.77,
            status: .active,
            createdAt: Date().addingTimeInterval(-86400 * 3)
        ),

        // Monthly Races
        Race(
            id: "race-009",
            type: .topSpeed,
            duration: .monthly,
            category: .seniorMen,
            startDate: Date().addingTimeInterval(-86400 * 15),
            endDate: Date().addingTimeInterval(86400 * 15),
            entryCount: 234,
            prizePool: 3741.66,
            status: .active,
            createdAt: Date().addingTimeInterval(-86400 * 15)
        ),
        Race(
            id: "race-010",
            type: .furthestDistance,
            duration: .monthly,
            category: .seniorMen,
            startDate: Date().addingTimeInterval(-86400 * 15),
            endDate: Date().addingTimeInterval(86400 * 15),
            entryCount: 198,
            prizePool: 3166.02,
            status: .active,
            createdAt: Date().addingTimeInterval(-86400 * 15)
        ),
        Race(
            id: "race-011",
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
            id: "race-012",
            type: .fastest5km,
            duration: .monthly,
            category: .mastersMen,
            startDate: Date().addingTimeInterval(-86400 * 15),
            endDate: Date().addingTimeInterval(86400 * 15),
            entryCount: 87,
            prizePool: 1391.13,
            status: .active,
            createdAt: Date().addingTimeInterval(-86400 * 15)
        ),

        // Additional categories
        Race(
            id: "race-013",
            type: .topSpeed,
            duration: .daily,
            category: .womenU23,
            startDate: Calendar.current.startOfDay(for: Date()),
            endDate: Calendar.current.startOfDay(for: Date()).addingTimeInterval(86400),
            entryCount: 15,
            prizePool: 15.00,
            status: .active,
            createdAt: Calendar.current.startOfDay(for: Date())
        ),
        Race(
            id: "race-014",
            type: .furthestDistance,
            duration: .weekly,
            category: .menU23,
            startDate: Date().addingTimeInterval(-86400 * 3),
            endDate: Date().addingTimeInterval(86400 * 4),
            entryCount: 67,
            prizePool: 334.33,
            status: .active,
            createdAt: Date().addingTimeInterval(-86400 * 3)
        ),
        Race(
            id: "race-015",
            type: .fastest1km,
            duration: .monthly,
            category: .mastersWomen,
            startDate: Date().addingTimeInterval(-86400 * 15),
            endDate: Date().addingTimeInterval(86400 * 15),
            entryCount: 54,
            prizePool: 863.46,
            status: .active,
            createdAt: Date().addingTimeInterval(-86400 * 15)
        )
    ]

    // MARK: - Activities

    static var activities: [Activity] {
        MockStravaData.convertToAppActivities()
    }

    // MARK: - Entries

    static let entries: [Entry] = [
        Entry(
            id: "entry-001",
            userId: "user-001",
            raceId: "race-005",
            activityId: "activity-10000001",
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
            activityId: "activity-10000002",
            enteredAt: Date().addingTimeInterval(-3600 * 6),
            score: 18.72,
            rank: 3,
            status: .active,
            prizeWon: nil,
            transactionId: "txn-003"
        ),
        Entry(
            id: "entry-003",
            userId: "user-001",
            raceId: "race-009",
            activityId: "activity-10000003",
            enteredAt: Date().addingTimeInterval(-86400 * 10),
            score: 14.76,
            rank: 12,
            status: .active,
            prizeWon: nil,
            transactionId: "txn-005"
        ),
        Entry(
            id: "entry-004",
            userId: "user-002",
            raceId: "race-006",
            activityId: "activity-10000004",
            enteredAt: Date().addingTimeInterval(-86400 * 2),
            score: 9.87,
            rank: 2,
            status: .active,
            prizeWon: nil,
            transactionId: nil
        ),
        Entry(
            id: "entry-005",
            userId: "user-002",
            raceId: "race-011",
            activityId: "activity-10000005",
            enteredAt: Date().addingTimeInterval(-86400 * 8),
            score: 245,
            rank: 1,
            status: .active,
            prizeWon: nil,
            transactionId: nil
        ),
        Entry(
            id: "entry-006",
            userId: "user-003",
            raceId: "race-007",
            activityId: "activity-10000006",
            enteredAt: Date().addingTimeInterval(-86400),
            score: 228,
            rank: 4,
            status: .active,
            prizeWon: nil,
            transactionId: nil
        ),
        Entry(
            id: "entry-007",
            userId: "user-004",
            raceId: "race-008",
            activityId: "activity-10000008",
            enteredAt: Date().addingTimeInterval(-86400 * 2),
            score: 1234,
            rank: 6,
            status: .active,
            prizeWon: nil,
            transactionId: nil
        ),
        Entry(
            id: "entry-008",
            userId: "user-005",
            raceId: "race-012",
            activityId: "activity-10000010",
            enteredAt: Date().addingTimeInterval(-86400 * 5),
            score: 1156,
            rank: 1,
            status: .active,
            prizeWon: nil,
            transactionId: nil
        )
    ]

    // MARK: - Leaderboards

    static let leaderboard = Leaderboard(
        id: "leaderboard-001",
        raceId: "race-005",
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
                activityId: "activity-10000001",
                raceType: .topSpeed
            ),
            LeaderboardEntry(
                id: "lb-006",
                rank: 6,
                userId: "user-014",
                userName: "Thomas Clark",
                userProfileURL: nil,
                score: 16.9,
                activityId: "activity-ext-005",
                raceType: .topSpeed
            ),
            LeaderboardEntry(
                id: "lb-007",
                rank: 7,
                userId: "user-015",
                userName: "Andrew Hall",
                userProfileURL: nil,
                score: 16.5,
                activityId: "activity-ext-006",
                raceType: .topSpeed
            ),
            LeaderboardEntry(
                id: "lb-008",
                rank: 8,
                userId: "user-016",
                userName: "Matthew Young",
                userProfileURL: nil,
                score: 15.8,
                activityId: "activity-ext-007",
                raceType: .topSpeed
            ),
            LeaderboardEntry(
                id: "lb-009",
                rank: 9,
                userId: "user-017",
                userName: "Joseph King",
                userProfileURL: nil,
                score: 15.2,
                activityId: "activity-ext-008",
                raceType: .topSpeed
            ),
            LeaderboardEntry(
                id: "lb-010",
                rank: 10,
                userId: "user-018",
                userName: "Richard Scott",
                userProfileURL: nil,
                score: 14.9,
                activityId: "activity-ext-009",
                raceType: .topSpeed
            )
        ],
        updatedAt: Date()
    )

    static func leaderboardForRace(_ raceType: RaceType) -> Leaderboard {
        let entries: [LeaderboardEntry]

        switch raceType {
        case .topSpeed:
            entries = (1...10).map { rank in
                LeaderboardEntry(
                    id: "lb-speed-\(rank)",
                    rank: rank,
                    userId: "user-\(100 + rank)",
                    userName: speedLeaderNames[rank - 1],
                    userProfileURL: nil,
                    score: 22.5 - Double(rank) * 0.7,
                    activityId: "activity-speed-\(rank)",
                    raceType: .topSpeed
                )
            }
        case .furthestDistance:
            entries = (1...10).map { rank in
                LeaderboardEntry(
                    id: "lb-dist-\(rank)",
                    rank: rank,
                    userId: "user-\(200 + rank)",
                    userName: distanceLeaderNames[rank - 1],
                    userProfileURL: nil,
                    score: 28.5 - Double(rank) * 1.2,
                    activityId: "activity-dist-\(rank)",
                    raceType: .furthestDistance
                )
            }
        case .fastest1km:
            entries = (1...10).map { rank in
                LeaderboardEntry(
                    id: "lb-1km-\(rank)",
                    rank: rank,
                    userId: "user-\(300 + rank)",
                    userName: time1kmLeaderNames[rank - 1],
                    userProfileURL: nil,
                    score: 210 + Double(rank) * 12,
                    activityId: "activity-1km-\(rank)",
                    raceType: .fastest1km
                )
            }
        case .fastest5km:
            entries = (1...10).map { rank in
                LeaderboardEntry(
                    id: "lb-5km-\(rank)",
                    rank: rank,
                    userId: "user-\(400 + rank)",
                    userName: time5kmLeaderNames[rank - 1],
                    userProfileURL: nil,
                    score: 1080 + Double(rank) * 45,
                    activityId: "activity-5km-\(rank)",
                    raceType: .fastest5km
                )
            }
        }

        return Leaderboard(
            id: "leaderboard-\(raceType.rawValue)",
            raceId: "race-\(raceType.rawValue)",
            entries: entries,
            updatedAt: Date()
        )
    }

    private static let speedLeaderNames = [
        "David Henderson", "Michael Roberts", "Christopher Lee",
        "Daniel Wright", "James Wilson", "Thomas Clark",
        "Andrew Hall", "Matthew Young", "Joseph King", "Richard Scott"
    ]

    private static let distanceLeaderNames = [
        "Sarah Mitchell", "Emily Johnson", "Rachel Adams",
        "Laura White", "Hannah Green", "Jessica Brown",
        "Sophie Turner", "Charlotte Evans", "Amy Walker", "Olivia Harris"
    ]

    private static let time1kmLeaderNames = [
        "Ryan Phillips", "Nathan Campbell", "Jack Murphy",
        "Luke Anderson", "Ben Morgan", "Sam Bailey",
        "Alex Cooper", "Charlie Reed", "Harry Price", "Oscar Russell"
    ]

    private static let time5kmLeaderNames = [
        "Mark Thompson", "Steven Edwards", "Peter Collins",
        "Ian Stewart", "Brian Foster", "Kevin Patterson",
        "Paul Jenkins", "Gary Hughes", "Neil Barnes", "Simon Wood"
    ]
}
