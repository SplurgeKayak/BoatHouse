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
            leaderboard = try await raceService.fetchRaceLeaderboard(raceId: raceId)
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
