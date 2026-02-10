import SwiftUI

/// ViewModel for race detail screen
final class RaceDetailViewModel: ObservableObject {
    @Published var leaderboard: Leaderboard?
    @Published var userEntry: Entry?
    @Published var isLoading: Bool = false
    @Published var isProcessing: Bool = false
    @Published var showingEntryConfirmation: Bool = false
    @Published var showingSuccess: Bool = false
    @Published var showingError: Bool = false
    @Published var errorMessage: String?

    private let raceService: RaceServiceProtocol
    private let walletService: WalletServiceProtocol

    var isUserEntered: Bool { userEntry != nil }

    var leaderboardUpdatedAt: Date? { leaderboard?.updatedAt }

    /// The user's rank derived from the leaderboard (single source of truth).
    /// Falls back to `userEntry.rank` if leaderboard hasn't loaded yet.
    func userRank(userId: String) -> Int? {
        leaderboard?.rank(for: userId) ?? userEntry?.rank
    }

    /// The user's score derived from the leaderboard (single source of truth).
    func userScore(userId: String) -> Double? {
        leaderboard?.entry(for: userId)?.score ?? userEntry?.score
    }

    init(
        raceService: RaceServiceProtocol = RaceService.shared,
        walletService: WalletServiceProtocol = WalletService.shared
    ) {
        self.raceService = raceService
        self.walletService = walletService
    }

    @MainActor
    func loadLeaderboard(for raceId: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            leaderboard = try await raceService.fetchRaceLeaderboard(raceId: raceId)
        } catch {
            errorMessage = "Failed to load leaderboard"
        }
    }

    @MainActor
    func loadUserEntry(raceId: String, userId: String) async {
        do {
            userEntry = try await raceService.fetchUserEntry(raceId: raceId, userId: userId)
        } catch {
            // Silently fail — user just hasn't entered
        }

        // After loading entry, sync rank/score from the leaderboard
        // so the Your Position card always matches the leaderboard.
        syncUserEntryFromLeaderboard(userId: userId)
    }

    /// Keep userEntry in sync with the authoritative leaderboard ranking.
    @MainActor
    func syncUserEntryFromLeaderboard(userId: String) {
        guard userEntry != nil,
              let lbEntry = leaderboard?.entry(for: userId) else { return }
        userEntry?.rank = lbEntry.rank
        userEntry?.score = lbEntry.score
    }

    @MainActor
    func enterRace(raceId: String, userId: String) async {
        isProcessing = true
        defer { isProcessing = false }

        do {
            // Entry fee will be deducted from wallet via backend
            _ = try await raceService.enterRace(raceId: raceId, userId: userId)
            showingSuccess = true
        } catch let error as RaceError {
            errorMessage = error.localizedDescription
            showingError = true
        } catch {
            errorMessage = "Failed to enter race"
            showingError = true
        }
    }
}
