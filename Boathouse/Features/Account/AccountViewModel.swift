import SwiftUI

/// ViewModel for Account screen
@MainActor
final class AccountViewModel: ObservableObject {
    @Published var showingStravaOAuth = false
    @Published var showingWalletSetup = false
    @Published var showingTransactionHistory = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let stravaOAuthViewModel = StravaOAuthViewModel()
    private let walletService: WalletServiceProtocol

    nonisolated init(walletService: WalletServiceProtocol = WalletService.shared) {
        self.walletService = walletService
    }

    func disconnectStrava() async {
        await stravaOAuthViewModel.disconnect()
    }

    func toggleAutoPayout() async {
        guard let walletId = AppState.shared?.currentUser?.wallet?.id else { return }

        do {
            let newValue = !(AppState.shared?.currentUser?.wallet?.autoPayoutEnabled ?? false)
            try await walletService.updateAutoPayoutSetting(walletId: walletId, enabled: newValue)
            AppState.shared?.currentUser?.wallet?.autoPayoutEnabled = newValue
        } catch {
            errorMessage = "Failed to update setting"
        }
    }
}
