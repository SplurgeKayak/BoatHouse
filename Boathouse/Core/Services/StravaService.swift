import Foundation

/// Protocol for Strava API service
protocol StravaServiceProtocol {
    func exchangeCodeForToken(code: String) async throws -> StravaTokenResponse
    func refreshAccessToken(refreshToken: String) async throws -> StravaTokenResponse
    func fetchAthleteProfile(accessToken: String) async throws -> StravaAthleteProfile
    func fetchActivities(accessToken: String, after: Date?, before: Date?, page: Int) async throws -> [StravaActivity]
    func fetchActivity(accessToken: String, activityId: Int) async throws -> StravaActivityDetail
    func deauthorize(accessToken: String) async throws
}

/// Service for Strava API interactions
final class StravaService: StravaServiceProtocol {
    static let shared = StravaService()

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func exchangeCodeForToken(code: String) async throws -> StravaTokenResponse {
        var request = URLRequest(url: URL(string: "\(StravaConfig.authURL)/token")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "client_id": StravaConfig.clientId,
            "client_secret": StravaConfig.clientSecret,
            "code": code,
            "grant_type": "authorization_code"
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw StravaError.networkError
        }

        guard httpResponse.statusCode == 200 else {
            throw mapStravaError(statusCode: httpResponse.statusCode)
        }

        return try JSONDecoder().decode(StravaTokenResponse.self, from: data)
    }

    func refreshAccessToken(refreshToken: String) async throws -> StravaTokenResponse {
        var request = URLRequest(url: URL(string: "\(StravaConfig.authURL)/token")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "client_id": StravaConfig.clientId,
            "client_secret": StravaConfig.clientSecret,
            "refresh_token": refreshToken,
            "grant_type": "refresh_token"
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw StravaError.tokenExpired
        }

        return try JSONDecoder().decode(StravaTokenResponse.self, from: data)
    }

    func fetchAthleteProfile(accessToken: String) async throws -> StravaAthleteProfile {
        var request = URLRequest(url: URL(string: "\(StravaConfig.baseURL)/athlete")!)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw StravaError.networkError
        }

        guard httpResponse.statusCode == 200 else {
            throw mapStravaError(statusCode: httpResponse.statusCode)
        }

        let athleteResponse = try JSONDecoder().decode(StravaAthleteResponse.self, from: data)
        return mapAthleteResponse(athleteResponse)
    }

    func fetchActivities(
        accessToken: String,
        after: Date? = nil,
        before: Date? = nil,
        page: Int = 1
    ) async throws -> [StravaActivity] {
        var components = URLComponents(string: "\(StravaConfig.baseURL)/athlete/activities")!
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "per_page", value: "50")
        ]

        if let after = after {
            queryItems.append(URLQueryItem(name: "after", value: "\(Int(after.timeIntervalSince1970))"))
        }

        if let before = before {
            queryItems.append(URLQueryItem(name: "before", value: "\(Int(before.timeIntervalSince1970))"))
        }

        components.queryItems = queryItems

        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw StravaError.networkError
        }

        guard httpResponse.statusCode == 200 else {
            throw mapStravaError(statusCode: httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([StravaActivity].self, from: data)
    }

    func fetchActivity(accessToken: String, activityId: Int) async throws -> StravaActivityDetail {
        var request = URLRequest(url: URL(string: "\(StravaConfig.baseURL)/activities/\(activityId)")!)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw StravaError.networkError
        }

        guard httpResponse.statusCode == 200 else {
            throw mapStravaError(statusCode: httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(StravaActivityDetail.self, from: data)
    }

    func deauthorize(accessToken: String) async throws {
        var request = URLRequest(url: URL(string: "\(StravaConfig.authURL)/deauthorize")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (_, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw StravaError.deauthorizationFailed
        }
    }

    private func mapStravaError(statusCode: Int) -> StravaError {
        switch statusCode {
        case 401: return .tokenExpired
        case 429: return .rateLimited
        default: return .invalidResponse
        }
    }

    private func mapAthleteResponse(_ response: StravaAthleteResponse) -> StravaAthleteProfile {
        StravaAthleteProfile(
            id: response.id,
            firstName: response.firstname,
            lastName: response.lastname,
            profileImageURL: response.profile.flatMap { URL(string: $0) },
            city: response.city,
            country: response.country,
            sex: response.sex,
            dateOfBirth: nil // Strava API doesn't expose DOB directly
        )
    }
}

// MARK: - Strava Activity Models

struct StravaActivity: Codable, Identifiable {
    let id: Int
    let name: String
    let type: String
    let sportType: String?
    let startDate: Date
    let startDateLocal: Date
    let elapsedTime: Int
    let movingTime: Int
    let distance: Double
    let maxSpeed: Double?
    let averageSpeed: Double?
    let startLatlng: [Double]?
    let endLatlng: [Double]?
    let map: StravaMap?

    enum CodingKeys: String, CodingKey {
        case id, name, type, distance, map
        case sportType = "sport_type"
        case startDate = "start_date"
        case startDateLocal = "start_date_local"
        case elapsedTime = "elapsed_time"
        case movingTime = "moving_time"
        case maxSpeed = "max_speed"
        case averageSpeed = "average_speed"
        case startLatlng = "start_latlng"
        case endLatlng = "end_latlng"
    }

    var isCanoeOrKayak: Bool {
        let canoeTypes = ["Canoeing", "Kayaking"]
        return canoeTypes.contains(type) || (sportType.map { canoeTypes.contains($0) } ?? false)
    }
}

struct StravaActivityDetail: Codable {
    let id: Int
    let name: String
    let type: String
    let sportType: String?
    let startDate: Date
    let startDateLocal: Date
    let elapsedTime: Int
    let movingTime: Int
    let distance: Double
    let maxSpeed: Double?
    let averageSpeed: Double?
    let startLatlng: [Double]?
    let endLatlng: [Double]?
    let map: StravaMap?
    let deviceName: String?
    let hasHeartrate: Bool?
    let segmentEfforts: [StravaSegmentEffort]?

    enum CodingKeys: String, CodingKey {
        case id, name, type, distance, map
        case sportType = "sport_type"
        case startDate = "start_date"
        case startDateLocal = "start_date_local"
        case elapsedTime = "elapsed_time"
        case movingTime = "moving_time"
        case maxSpeed = "max_speed"
        case averageSpeed = "average_speed"
        case startLatlng = "start_latlng"
        case endLatlng = "end_latlng"
        case deviceName = "device_name"
        case hasHeartrate = "has_heartrate"
        case segmentEfforts = "segment_efforts"
    }
}

struct StravaMap: Codable {
    let id: String
    let polyline: String?
    let summaryPolyline: String?

    enum CodingKeys: String, CodingKey {
        case id, polyline
        case summaryPolyline = "summary_polyline"
    }
}

struct StravaSegmentEffort: Codable {
    let id: Int
    let name: String
    let elapsedTime: Int
    let movingTime: Int
    let distance: Double

    enum CodingKeys: String, CodingKey {
        case id, name, distance
        case elapsedTime = "elapsed_time"
        case movingTime = "moving_time"
    }
}
