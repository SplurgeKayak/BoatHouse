import SwiftUI
import Combine

/// ViewModel for the Races screen
final class RacesViewModel: ObservableObject {
    @Published var races: [Race] = []
    @Published var selectedDuration: RaceDuration?
    @Published var selectedRaceType: RaceType?
    @Published var selectedCategory: RaceCategory?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let raceService: RaceServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    var filteredRaces: [Race] {
        races.filter { race in
            var matches = true

            if let duration = selectedDuration {
                matches = matches && race.duration == duration
            }

            if let type = selectedRaceType {
                matches = matches && race.type == type
            }

            if let category = selectedCategory {
                matches = matches && race.category == category
            }

            return matches
        }
    }

    init(raceService: RaceServiceProtocol = RaceService.shared) {
        self.raceService = raceService
    }

    @MainActor
    func loadRaces() async {
        isLoading = true
        defer { isLoading = false }

        do {
            races = try await raceService.fetchActiveRaces()
        } catch {
            errorMessage = "Failed to load races"
        }
    }
}

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
