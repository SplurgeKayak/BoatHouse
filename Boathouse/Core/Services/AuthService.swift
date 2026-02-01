import Foundation

/// Protocol for authentication service
protocol AuthServiceProtocol {
    func login(email: String, password: String) async throws -> User
    func register(email: String, password: String, userType: User.UserType) async throws -> User
    func logout() async throws
    func validateSession(token: String, userId: String) async throws -> User
    func resetPassword(email: String) async throws
}

/// Service handling user authentication
final class AuthService: AuthServiceProtocol {
    static let shared = AuthService()

    private let networkClient: NetworkClientProtocol
    private let keychainService: KeychainServiceProtocol

    init(
        networkClient: NetworkClientProtocol = NetworkClient.shared,
        keychainService: KeychainServiceProtocol = KeychainService.shared
    ) {
        self.networkClient = networkClient
        self.keychainService = keychainService
    }

    func login(email: String, password: String) async throws -> User {
        // TODO: Replace with actual API call
        let endpoint = AuthEndpoint.login(email: email, password: password)
        let response: AuthResponse = try await networkClient.request(endpoint)

        keychainService.saveToken(response.token, for: .authToken)
        keychainService.saveToken(response.user.id, for: .userId)

        return response.user
    }

    func register(email: String, password: String, userType: User.UserType) async throws -> User {
        // TODO: Replace with actual API call
        let endpoint = AuthEndpoint.register(email: email, password: password, userType: userType)
        let response: AuthResponse = try await networkClient.request(endpoint)

        keychainService.saveToken(response.token, for: .authToken)
        keychainService.saveToken(response.user.id, for: .userId)

        return response.user
    }

    func logout() async throws {
        guard let token = keychainService.retrieveToken(for: .authToken) else { return }

        // TODO: Replace with actual API call
        let endpoint = AuthEndpoint.logout(token: token)
        try await networkClient.requestVoid(endpoint)
    }

    func validateSession(token: String, userId: String) async throws -> User {
        // TODO: Replace with actual API call
        let endpoint = AuthEndpoint.validateSession(token: token)
        let response: AuthResponse = try await networkClient.request(endpoint)
        return response.user
    }

    func resetPassword(email: String) async throws {
        // TODO: Replace with actual API call
        let endpoint = AuthEndpoint.resetPassword(email: email)
        try await networkClient.requestVoid(endpoint)
    }
}

// MARK: - Auth API Models

struct AuthResponse: Codable {
    let token: String
    let user: User
}

// MARK: - Auth Endpoints

enum AuthEndpoint: Endpoint {
    case login(email: String, password: String)
    case register(email: String, password: String, userType: User.UserType)
    case logout(token: String)
    case validateSession(token: String)
    case resetPassword(email: String)

    var path: String {
        switch self {
        case .login: return "/auth/login"
        case .register: return "/auth/register"
        case .logout: return "/auth/logout"
        case .validateSession: return "/auth/validate"
        case .resetPassword: return "/auth/reset-password"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .login, .register, .logout, .resetPassword:
            return .post
        case .validateSession:
            return .get
        }
    }

    var headers: [String: String]? {
        switch self {
        case .logout(let token), .validateSession(let token):
            return ["Authorization": "Bearer \(token)"]
        default:
            return nil
        }
    }

    var body: Data? {
        switch self {
        case .login(let email, let password):
            return try? JSONEncoder().encode(["email": email, "password": password])
        case .register(let email, let password, let userType):
            return try? JSONEncoder().encode([
                "email": email,
                "password": password,
                "userType": userType.rawValue
            ])
        case .resetPassword(let email):
            return try? JSONEncoder().encode(["email": email])
        default:
            return nil
        }
    }
}
