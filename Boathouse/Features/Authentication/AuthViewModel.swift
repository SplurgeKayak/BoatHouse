import SwiftUI
import AuthenticationServices

/// ViewModel handling authentication flows for email and Strava OAuth
@MainActor
final class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingStravaOAuth = false
    @Published var authMode: AuthMode = .login

    enum AuthMode {
        case login
        case register
    }

    private let authService: AuthServiceProtocol
    private let keychainService: KeychainServiceProtocol

    init(
        authService: AuthServiceProtocol = AuthService.shared,
        keychainService: KeychainServiceProtocol = KeychainService.shared
    ) {
        self.authService = authService
        self.keychainService = keychainService
    }

    var isFormValid: Bool {
        guard !email.isEmpty, !password.isEmpty else { return false }
        guard email.contains("@") else { return false }

        if authMode == .register {
            return password == confirmPassword && password.count >= 8
        }

        return true
    }

    func checkAuthState() async {
        guard let token = keychainService.retrieveToken(for: .authToken),
              let userId = keychainService.retrieveToken(for: .userId) else {
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let user = try await authService.validateSession(token: token, userId: userId)
            await updateAppState(user: user)
        } catch {
            keychainService.deleteToken(for: .authToken)
            keychainService.deleteToken(for: .userId)
        }
    }

    func login() async {
        guard isFormValid else {
            errorMessage = "Please enter a valid email and password"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let user = try await authService.login(email: email, password: password)
            await updateAppState(user: user)
        } catch let error as AuthError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "An unexpected error occurred"
        }

        isLoading = false
    }

    func register(as userType: User.UserType) async {
        guard isFormValid else {
            errorMessage = "Please fill in all fields correctly"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let user = try await authService.register(
                email: email,
                password: password,
                userType: userType
            )
            await updateAppState(user: user, showOnboarding: true)
        } catch let error as AuthError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "An unexpected error occurred"
        }

        isLoading = false
    }

    func logout() async {
        do {
            try await authService.logout()
        } catch {
            // Continue with local logout even if server logout fails
        }

        keychainService.deleteToken(for: .authToken)
        keychainService.deleteToken(for: .userId)
        keychainService.deleteToken(for: .stravaAccessToken)
        keychainService.deleteToken(for: .stravaRefreshToken)

        await MainActor.run {
            AppState.shared?.logout()
        }
    }

    func clearForm() {
        email = ""
        password = ""
        confirmPassword = ""
        errorMessage = nil
    }

    private func updateAppState(user: User, showOnboarding: Bool = false) async {
        await MainActor.run {
            AppState.shared?.currentUser = user
            AppState.shared?.isAuthenticated = true
            AppState.shared?.showOnboarding = showOnboarding
            AppState.shared?.isLoading = false
        }
    }
}

extension AppState {
    static var shared: AppState?
}

enum AuthError: LocalizedError {
    case invalidCredentials
    case emailAlreadyInUse
    case weakPassword
    case networkError
    case serverError
    case sessionExpired

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password"
        case .emailAlreadyInUse:
            return "This email is already registered"
        case .weakPassword:
            return "Password must be at least 8 characters"
        case .networkError:
            return "Please check your internet connection"
        case .serverError:
            return "Server error. Please try again later"
        case .sessionExpired:
            return "Your session has expired. Please log in again"
        }
    }
}
