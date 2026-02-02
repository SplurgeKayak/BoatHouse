import SwiftUI

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

    init() {
        // Default initialization
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
        // TODO: Check keychain for existing auth token
        isLoading = false
    }

    func login() async {
        guard isFormValid else {
            errorMessage = "Please enter a valid email and password"
            return
        }

        isLoading = true
        errorMessage = nil

        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        // For demo, just succeed with mock user
        await MainActor.run {
            AppState.shared?.currentUser = MockData.racerUser
            AppState.shared?.isAuthenticated = true
            isLoading = false
        }
    }

    func register(as userType: User.UserType) async {
        guard isFormValid else {
            errorMessage = "Please fill in all fields correctly"
            return
        }

        isLoading = true
        errorMessage = nil

        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        // For demo, succeed with mock user
        await MainActor.run {
            if userType == .racer {
                AppState.shared?.currentUser = MockData.racerUser
            } else {
                AppState.shared?.currentUser = MockData.spectatorUser
            }
            AppState.shared?.isAuthenticated = true
            AppState.shared?.showOnboarding = true
            isLoading = false
        }
    }

    func logout() async {
        AppState.shared?.logout()
    }

    func clearForm() {
        email = ""
        password = ""
        confirmPassword = ""
        errorMessage = nil
    }
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
