import SwiftUI
import AuthenticationServices

/// ViewModel for Strava OAuth2 authentication flow
@MainActor
final class StravaOAuthViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage: String?
    @Published var showWebAuth = false
    @Published var authorizationURL: URL?
    @Published var isConnected = false

    private let stravaService: StravaServiceProtocol
    private let keychainService: KeychainServiceProtocol

    // OAuth Configuration
    private let clientId = StravaConfig.clientId
    private let redirectURI = StravaConfig.redirectURI
    private let scope = "read,activity:read_all,profile:read_all"

    init(
        stravaService: StravaServiceProtocol = StravaService.shared,
        keychainService: KeychainServiceProtocol = KeychainService.shared
    ) {
        self.stravaService = stravaService
        self.keychainService = keychainService
    }

    /// Constructs the Strava authorization URL
    var stravaAuthURL: URL? {
        var components = URLComponents(string: "https://www.strava.com/oauth/authorize")
        components?.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "approval_prompt", value: "auto"),
            URLQueryItem(name: "scope", value: scope)
        ]
        return components?.url
    }

    func startOAuthFlow() {
        guard let url = stravaAuthURL else {
            showError(message: "Failed to construct authorization URL")
            return
        }

        authorizationURL = url
        showWebAuth = true
    }

    func cancelOAuth() {
        showWebAuth = false
        authorizationURL = nil
        isLoading = false
    }

    /// Handles the OAuth callback with authorization code
    func handleOAuthCallback(url: URL) async {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
            showError(message: "Invalid callback URL")
            return
        }

        showWebAuth = false
        isLoading = true

        do {
            let tokenResponse = try await stravaService.exchangeCodeForToken(code: code)

            keychainService.saveToken(tokenResponse.accessToken, for: .stravaAccessToken)
            keychainService.saveToken(tokenResponse.refreshToken, for: .stravaRefreshToken)

            let athlete = try await stravaService.fetchAthleteProfile(accessToken: tokenResponse.accessToken)

            await updateUserWithStravaConnection(
                tokenResponse: tokenResponse,
                athlete: athlete
            )

            isConnected = true
        } catch {
            showError(message: "Failed to connect Strava account: \(error.localizedDescription)")
        }

        isLoading = false
    }

    /// Refreshes the Strava access token if expired
    func refreshTokenIfNeeded() async throws {
        guard let refreshToken = keychainService.retrieveToken(for: .stravaRefreshToken) else {
            throw StravaError.notAuthenticated
        }

        let tokenResponse = try await stravaService.refreshAccessToken(refreshToken: refreshToken)

        keychainService.saveToken(tokenResponse.accessToken, for: .stravaAccessToken)
        keychainService.saveToken(tokenResponse.refreshToken, for: .stravaRefreshToken)
    }

    func disconnect() async {
        isLoading = true

        if let accessToken = keychainService.retrieveToken(for: .stravaAccessToken) {
            try? await stravaService.deauthorize(accessToken: accessToken)
        }

        keychainService.deleteToken(for: .stravaAccessToken)
        keychainService.deleteToken(for: .stravaRefreshToken)

        await MainActor.run {
            AppState.shared?.currentUser?.stravaConnection = nil
        }

        isConnected = false
        isLoading = false
    }

    private func showError(message: String) {
        errorMessage = message
        showError = true
    }

    private func updateUserWithStravaConnection(
        tokenResponse: StravaTokenResponse,
        athlete: StravaAthleteProfile
    ) async {
        let connection = StravaConnection(
            athleteId: athlete.id,
            accessToken: tokenResponse.accessToken,
            refreshToken: tokenResponse.refreshToken,
            expiresAt: Date(timeIntervalSince1970: TimeInterval(tokenResponse.expiresAt)),
            athleteProfile: athlete
        )

        await MainActor.run {
            AppState.shared?.currentUser?.stravaConnection = connection
            if let dob = athlete.dateOfBirth {
                AppState.shared?.currentUser?.dateOfBirth = dob
            }
            if let sex = athlete.sex {
                AppState.shared?.currentUser?.gender = sex == "M" ? .male : .female
            }
        }

        // TODO: Sync connection to backend
    }
}

// MARK: - Strava Configuration

enum StravaConfig {
    // TODO: Move to secure configuration / environment variables
    static let clientId = "YOUR_STRAVA_CLIENT_ID"
    static let clientSecret = "YOUR_STRAVA_CLIENT_SECRET"
    static let redirectURI = "boathouse://strava-callback"
    static let baseURL = "https://www.strava.com/api/v3"
    static let authURL = "https://www.strava.com/oauth"
}

// MARK: - Strava API Models

struct StravaTokenResponse: Codable {
    let tokenType: String
    let expiresAt: Int
    let expiresIn: Int
    let refreshToken: String
    let accessToken: String
    let athlete: StravaAthleteResponse?

    enum CodingKeys: String, CodingKey {
        case tokenType = "token_type"
        case expiresAt = "expires_at"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
        case accessToken = "access_token"
        case athlete
    }
}

struct StravaAthleteResponse: Codable {
    let id: Int
    let firstname: String
    let lastname: String
    let profile: String?
    let city: String?
    let country: String?
    let sex: String?
}

enum StravaError: LocalizedError {
    case notAuthenticated
    case tokenExpired
    case rateLimited
    case networkError
    case invalidResponse
    case deauthorizationFailed

    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "Not connected to Strava"
        case .tokenExpired: return "Strava session expired"
        case .rateLimited: return "Too many requests. Please wait"
        case .networkError: return "Network error"
        case .invalidResponse: return "Invalid response from Strava"
        case .deauthorizationFailed: return "Failed to disconnect Strava"
        }
    }
}
