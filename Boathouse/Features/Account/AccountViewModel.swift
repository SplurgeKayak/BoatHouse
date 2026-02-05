import SwiftUI

/// ViewModel for Account screen
final class AccountViewModel: ObservableObject {
    @Published var showingStravaOAuth: Bool = false
    @Published var showingWalletSetup: Bool = false
    @Published var showingTransactionHistory: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let stravaOAuthViewModel = StravaOAuthViewModel()
    private let walletService: WalletServiceProtocol

    init(walletService: WalletServiceProtocol = WalletService.shared) {
        self.walletService = walletService
    }

    @MainActor
    func disconnectStrava() async {
        await stravaOAuthViewModel.disconnect()
    }

    @MainActor
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
