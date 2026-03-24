import Foundation

// MARK: - Race Service Protocol

protocol RaceServiceProtocol {
    func fetchActiveRaces() async throws -> [Race]
    func fetchRace(id: String) async throws -> Race
    func fetchUserEntries(userId: String) async throws -> [Entry]
    func fetchUserEntry(raceId: String, userId: String) async throws -> Entry?
    func enterRace(raceId: String, userId: String) async throws -> Entry
    func fetchLeaderboard(duration: RaceDuration, raceType: RaceType) async throws -> Leaderboard
    func fetchRaceLeaderboard(raceId: String) async throws -> Leaderboard
}

/// Service for race operations
final class RaceService: RaceServiceProtocol {
    static let shared = RaceService()

    private let networkClient: NetworkClientProtocol

    init(networkClient: NetworkClientProtocol = NetworkClient.shared) {
        self.networkClient = networkClient
    }

    func fetchActiveRaces() async throws -> [Race] {
        // TODO: Replace with actual API call
        let base = MockData.races
        return ensureAllDistances(
            races: base,
            for: RaceDuration.allCases,
            categories: RaceCategory.allCases
        )
    }

    /// Ensures every (duration, category, raceType) triple has at least one race.
    /// Missing combinations are filled with a placeholder race (entryCount == 0).
    func ensureAllDistances(races: [Race], for durations: [RaceDuration], categories: [RaceCategory]) -> [Race] {
        var result = races
        let now = Date()

        for duration in durations {
            for category in categories {
                for raceType in RaceType.allCases {
                    let exists = races.contains {
                        $0.duration == duration && $0.category == category && $0.type == raceType
                    }
                    guard !exists else { continue }

                    let start: Date
                    let end: Date
                    switch duration {
                    case .daily:
                        start = Calendar.current.startOfDay(for: now)
                        end   = Calendar.current.date(byAdding: .day, value: 1, to: start) ?? now
                    case .weekly:
                        start = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now
                        end   = Calendar.current.date(byAdding: .day, value: 7, to: now) ?? now
                    case .monthly:
                        start = Calendar.current.date(byAdding: .month, value: -1, to: now) ?? now
                        end   = Calendar.current.date(byAdding: .month, value: 1, to: now) ?? now
                    case .yearly:
                        start = Calendar.current.date(byAdding: .year, value: -1, to: now) ?? now
                        end   = Calendar.current.date(byAdding: .year, value: 1, to: now) ?? now
                    }

                    let placeholder = Race(
                        id: "placeholder-\(duration.rawValue)-\(category.rawValue)-\(raceType.rawValue)",
                        type: raceType,
                        duration: duration,
                        category: category,
                        startDate: start,
                        endDate: end,
                        entryCount: 0,
                        prizePool: 0,
                        status: .active,
                        createdAt: now
                    )
                    result.append(placeholder)
                }
            }
        }
        return result
    }

    func fetchRace(id: String) async throws -> Race {
        // TODO: Replace with actual API call
        guard let race = MockData.races.first(where: { $0.id == id }) else {
            throw RaceError.notFound
        }
        return race
    }

    func fetchUserEntries(userId: String) async throws -> [Entry] {
        // TODO: Replace with actual API call
        return MockData.entries.filter { $0.userId == userId }
    }

    func fetchUserEntry(raceId: String, userId: String) async throws -> Entry? {
        // TODO: Replace with actual API call
        guard var entry = MockData.entries.first(where: { $0.raceId == raceId && $0.userId == userId }) else {
            return nil
        }
        // Enrich with dynamically computed rank + score from leaderboard
        if let leaderboard = MockData.leaderboard(for: raceId),
           let lbEntry = leaderboard.entry(for: userId) {
            entry.rank = lbEntry.rank
            entry.score = lbEntry.score
        }
        return entry
    }

    func enterRace(raceId: String, userId: String) async throws -> Entry {
        // TODO: Replace with actual API call
        // This would:
        // 1. Verify user eligibility for the race category
        // 2. Charge the entry fee from wallet
        // 3. Create the entry record
        // 4. Update race entry count and prize pool

        let entry = Entry(
            id: UUID().uuidString,
            userId: userId,
            raceId: raceId,
            sessionId: nil,
            enteredAt: Date(),
            score: nil,
            rank: nil,
            status: .active,
            prizeWon: nil,
            transactionId: nil
        )

        return entry
    }

    func fetchLeaderboard(duration: RaceDuration, raceType: RaceType) async throws -> Leaderboard {
        // TODO: Replace with actual API call
        // Find the matching race and compute its leaderboard
        if let race = MockData.races.first(where: { $0.duration == duration && $0.type == raceType }),
           let lb = MockData.leaderboard(for: race.id) {
            return lb
        }
        throw RaceError.notFound
    }

    func fetchRaceLeaderboard(raceId: String) async throws -> Leaderboard {
        // TODO: Replace with actual API call
        guard let lb = MockData.leaderboard(for: raceId) else {
            throw RaceError.notFound
        }
        return lb
    }
}

// MARK: - Race Errors

enum RaceError: LocalizedError {
    case notFound
    case entryDeadlinePassed
    case insufficientBalance
    case notEligible
    case alreadyEntered

    var errorDescription: String? {
        switch self {
        case .notFound: return "Race not found"
        case .entryDeadlinePassed: return "Entry deadline has passed"
        case .insufficientBalance: return "Insufficient wallet balance"
        case .notEligible: return "Not eligible for this race category"
        case .alreadyEntered: return "Already entered this race"
        }
    }
}
