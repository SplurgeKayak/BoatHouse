import Foundation

/// ViewModel for Garmin connection management
final class GarminOAuthViewModel: ObservableObject {
    private let keychainService: KeychainServiceProtocol

    init(keychainService: KeychainServiceProtocol = KeychainService.shared) {
        self.keychainService = keychainService
    }

    func disconnect() async {
        keychainService.deleteToken(for: .garminAccessToken)
        keychainService.deleteToken(for: .garminRefreshToken)

        await MainActor.run {
            AppState.shared?.currentUser?.garminConnection = nil
        }
    }
}
