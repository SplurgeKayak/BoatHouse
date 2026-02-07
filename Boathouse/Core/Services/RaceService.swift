import Foundation

// MARK: - Race Service Protocol

protocol RaceServiceProtocol {
    func fetchActiveRaces() async throws -> [Race]
    func fetchRace(id: String) async throws -> Race
    func fetchUserEntries(userId: String) async throws -> [Entry]
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
        return MockData.races
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
        return MockData.leaderboard
    }

    func fetchRaceLeaderboard(raceId: String) async throws -> Leaderboard {
        // TODO: Replace with actual API call
        return MockData.leaderboard
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
