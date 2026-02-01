import Foundation

/// HTTP methods
enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

/// Protocol for API endpoints
protocol Endpoint {
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String]? { get }
    var body: Data? { get }
    var queryItems: [URLQueryItem]? { get }
}

extension Endpoint {
    var headers: [String: String]? { nil }
    var body: Data? { nil }
    var queryItems: [URLQueryItem]? { nil }
}

/// Network error types
enum NetworkError: LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case serverError(Int)
    case unauthorized
    case networkUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .noData: return "No data received"
        case .decodingError: return "Failed to decode response"
        case .serverError(let code): return "Server error: \(code)"
        case .unauthorized: return "Unauthorized access"
        case .networkUnavailable: return "Network unavailable"
        }
    }
}

/// Protocol for network client
protocol NetworkClientProtocol {
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T
    func requestVoid(_ endpoint: Endpoint) async throws
}

/// Main network client for API requests
final class NetworkClient: NetworkClientProtocol {
    static let shared = NetworkClient()

    // TODO: Move to configuration
    private let baseURL = "https://api.boathouse.app/v1"
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        let request = try buildRequest(for: endpoint)
        let (data, response) = try await session.data(for: request)

        try validateResponse(response)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingError
        }
    }

    func requestVoid(_ endpoint: Endpoint) async throws {
        let request = try buildRequest(for: endpoint)
        let (_, response) = try await session.data(for: request)
        try validateResponse(response)
    }

    private func buildRequest(for endpoint: Endpoint) throws -> URLRequest {
        var components = URLComponents(string: baseURL + endpoint.path)

        if let queryItems = endpoint.queryItems {
            components?.queryItems = queryItems
        }

        guard let url = components?.url else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.httpBody = endpoint.body

        // Default headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // Custom headers
        endpoint.headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        return request
    }

    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.noData
        }

        switch httpResponse.statusCode {
        case 200...299:
            return
        case 401:
            throw NetworkError.unauthorized
        default:
            throw NetworkError.serverError(httpResponse.statusCode)
        }
    }
}
