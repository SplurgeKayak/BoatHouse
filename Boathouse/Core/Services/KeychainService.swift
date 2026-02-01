import Foundation
import Security

/// Protocol for keychain operations
protocol KeychainServiceProtocol {
    func saveToken(_ token: String, for key: KeychainKey)
    func retrieveToken(for key: KeychainKey) -> String?
    func deleteToken(for key: KeychainKey)
    func deleteAll()
}

/// Keychain storage keys
enum KeychainKey: String {
    case authToken = "com.boathouse.authToken"
    case userId = "com.boathouse.userId"
    case stravaAccessToken = "com.boathouse.stravaAccessToken"
    case stravaRefreshToken = "com.boathouse.stravaRefreshToken"
}

/// Service for secure keychain storage
final class KeychainService: KeychainServiceProtocol {
    static let shared = KeychainService()

    private let serviceName = "com.boathouse.app"

    func saveToken(_ token: String, for key: KeychainKey) {
        guard let data = token.data(using: .utf8) else { return }

        deleteToken(for: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key.rawValue,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        if status != errSecSuccess {
            print("Keychain save error: \(status)")
        }
    }

    func retrieveToken(for key: KeychainKey) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            return nil
        }

        return token
    }

    func deleteToken(for key: KeychainKey) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key.rawValue
        ]

        SecItemDelete(query as CFDictionary)
    }

    func deleteAll() {
        KeychainKey.allCases.forEach { deleteToken(for: $0) }
    }
}

extension KeychainKey: CaseIterable {}
