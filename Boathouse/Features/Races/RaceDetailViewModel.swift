import SwiftUI

/// ViewModel for race detail screen
final class RaceDetailViewModel: ObservableObject {
    @Published var leaderboard: Leaderboard?
    @Published var isLoading: Bool = false
    @Published var isProcessing: Bool = false
    @Published var showingEntryConfirmation: Bool = false
    @Published var showingSuccess: Bool = false
    @Published var showingError: Bool = false
    @Published var errorMessage: String?
    @Published var fastestTimeFormatted: String = "—"

    private let raceService: RaceServiceProtocol
    private let walletService: WalletServiceProtocol

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
            var board = try await raceService.fetchRaceLeaderboard(raceId: raceId)
            // Deduplicate to one row per user, using each user's fastest time
            let raceType = board.entries.first?.raceType ?? .fastest1km
            let deduped = RaceEngine.shared.calculateRankingsDeduplicatedByUser(
                entries: board.entries.map { entry in
                    Entry(
                        id: entry.id,
                        userId: entry.userId,
                        raceId: raceId,
                        sessionId: entry.sessionId,
                        enteredAt: Date(),
                        score: entry.score,
                        rank: entry.rank,
                        status: .active,
                        prizeWon: nil,
                        transactionId: nil
                    )
                },
                raceType: raceType
            )
            // Rebuild leaderboard entries from deduplicated entries
            let dedupedEntries: [LeaderboardEntry] = deduped.compactMap { entry in
                guard let original = board.entries.first(where: { $0.id == entry.id }) else { return nil }
                return LeaderboardEntry(
                    id: original.id,
                    rank: entry.rank ?? original.rank,
                    userId: original.userId,
                    userName: original.userName,
                    userProfileURL: original.userProfileURL,
                    score: original.score,
                    sessionId: original.sessionId,
                    raceType: original.raceType,
                    isGPSVerified: original.isGPSVerified
                )
            }
            board.entries = dedupedEntries
            leaderboard = board
            fastestTimeFormatted = board.entries.first?.formattedScore ?? "—"
        } catch {
            errorMessage = "Failed to load leaderboard"
        }
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
