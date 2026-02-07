import Foundation

// MARK: - Session Service Protocol

protocol SessionServiceProtocol {
    func fetchFeedSessions(page: Int) async throws -> [Session]
    func fetchRecentSessions(limit: Int) async throws -> [Session]
    func fetchUserSessions(userId: String, page: Int) async throws -> [Session]
    func importStravaSessions() async throws -> [Session]
    func flagSession(sessionId: String, reason: String) async throws
}

/// Service for session operations
final class SessionService: SessionServiceProtocol {
    static let shared = SessionService()

    private let networkClient: NetworkClientProtocol
    private let stravaService: StravaServiceProtocol
    private let keychainService: KeychainServiceProtocol

    init(
        networkClient: NetworkClientProtocol = NetworkClient.shared,
        stravaService: StravaServiceProtocol = StravaService.shared,
        keychainService: KeychainServiceProtocol = KeychainService.shared
    ) {
        self.networkClient = networkClient
        self.stravaService = stravaService
        self.keychainService = keychainService
    }

    func fetchFeedSessions(page: Int) async throws -> [Session] {
        // TODO: Replace with actual API call
        return MockData.sessions
    }

    func fetchRecentSessions(limit: Int) async throws -> [Session] {
        // TODO: Replace with actual API call
        return Array(MockData.sessions.prefix(limit))
    }

    func fetchUserSessions(userId: String, page: Int) async throws -> [Session] {
        // TODO: Replace with actual API call
        return MockData.sessions.filter { $0.userId == userId }
    }

    func importStravaSessions() async throws -> [Session] {
        guard let accessToken = keychainService.retrieveToken(for: .stravaAccessToken) else {
            throw StravaError.notAuthenticated
        }

        let stravaActivities = try await stravaService.fetchActivities(
            accessToken: accessToken,
            after: nil,
            before: nil,
            page: 1
        )

        // Filter for canoe/kayak sessions only
        let filteredActivities = stravaActivities.filter { $0.isCanoeOrKayak }

        let userId = await MainActor.run { AppState.shared?.currentUser?.id ?? "" }

        return filteredActivities.map { stravaActivity in
            mapStravaSession(stravaActivity, userId: userId)
        }
    }

    func flagSession(sessionId: String, reason: String) async throws {
        // TODO: Implement API call to flag session
    }

    private func mapStravaSession(_ stravaActivity: StravaActivity, userId: String) -> Session {
        let startCoord: Coordinate? = stravaActivity.startLatlng.map {
            Coordinate(latitude: $0[0], longitude: $0[1])
        }
        let endCoord: Coordinate? = stravaActivity.endLatlng.map {
            Coordinate(latitude: $0[0], longitude: $0[1])
        }

        let sessionType: SessionType = stravaActivity.type == "Kayaking" ? .kayaking : .canoeing

        return Session(
            id: UUID().uuidString,
            stravaId: stravaActivity.id,
            userId: userId,
            name: stravaActivity.name,
            sessionType: sessionType,
            startDate: stravaActivity.startDate,
            elapsedTime: TimeInterval(stravaActivity.elapsedTime),
            movingTime: TimeInterval(stravaActivity.movingTime),
            distance: stravaActivity.distance,
            maxSpeed: stravaActivity.maxSpeed,
            averageSpeed: stravaActivity.averageSpeed,
            startLocation: startCoord,
            endLocation: endCoord,
            polyline: stravaActivity.map?.summaryPolyline,
            isGPSVerified: stravaActivity.startLatlng != nil,
            isUKSession: isLocationInUK(startCoord),
            flagCount: 0,
            status: .pending,
            importedAt: Date()
        )
    }

    private func isLocationInUK(_ coordinate: Coordinate?) -> Bool {
        guard let coord = coordinate else { return false }

        let ukBounds = (
            minLat: 49.8,
            maxLat: 60.9,
            minLon: -8.2,
            maxLon: 1.8
        )

        return coord.latitude >= ukBounds.minLat &&
               coord.latitude <= ukBounds.maxLat &&
               coord.longitude >= ukBounds.minLon &&
               coord.longitude <= ukBounds.maxLon
    }
}
