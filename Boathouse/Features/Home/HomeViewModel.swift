import SwiftUI
import Combine

/// ViewModel for the Home screen
final class HomeViewModel: ObservableObject {
    @Published var sessions: [Session] = []
    @Published var currentLeaderboard: Leaderboard?
    @Published var selectedDuration: RaceDuration = .weekly
    @Published var selectedRaceType: RaceType = .fastest1km
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let sessionService: SessionServiceProtocol
    private let raceService: RaceServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    init(
        sessionService: SessionServiceProtocol = SessionService.shared,
        raceService: RaceServiceProtocol = RaceService.shared
    ) {
        self.sessionService = sessionService
        self.raceService = raceService
        setupBindings()
    }

    // MARK: - Filtered sessions

    /// Sessions filtered by time period and sorted by the selected distance metric.
    var filteredSessions: [Session] {
        Self.filterSessions(
            sessions: sessions,
            timeFilter: selectedDuration,
            distanceFilter: selectedRaceType,
            now: Date(),
            calendar: .current
        )
    }

    /// Pure function for filtering and sorting sessions.
    /// Testable independently of the ViewModel.
    static func filterSessions(
        sessions: [Session],
        timeFilter: RaceDuration,
        distanceFilter: RaceType,
        now: Date,
        calendar: Calendar
    ) -> [Session] {
        // 1. Time-period filter
        let timeFiltered = sessions.filter { session in
            switch timeFilter {
            case .daily:
                return calendar.isDateInToday(session.startDate)
            case .weekly:
                return calendar.isDate(session.startDate, equalTo: now, toGranularity: .weekOfYear)
            case .monthly:
                return calendar.isDate(session.startDate, equalTo: now, toGranularity: .month)
            case .yearly:
                return calendar.isDate(session.startDate, equalTo: now, toGranularity: .year)
            }
        }

        // 2. Distance filter + sort (ascending = fastest first) with deterministic tiebreaker
        switch distanceFilter {
        case .fastest1km:
            return timeFiltered
                .filter { $0.fastest1kmTime != nil }
                .sorted { a, b in
                    let at = a.fastest1kmTime ?? .infinity
                    let bt = b.fastest1kmTime ?? .infinity
                    return at != bt ? at < bt : a.id < b.id
                }
        case .fastest5km:
            return timeFiltered
                .filter { $0.fastest5kmTime != nil }
                .sorted { a, b in
                    let at = a.fastest5kmTime ?? .infinity
                    let bt = b.fastest5kmTime ?? .infinity
                    return at != bt ? at < bt : a.id < b.id
                }
        case .fastest10km:
            return timeFiltered
                .filter { $0.fastest10kmTime != nil }
                .sorted { a, b in
                    let at = a.fastest10kmTime ?? .infinity
                    let bt = b.fastest10kmTime ?? .infinity
                    return at != bt ? at < bt : a.id < b.id
                }
        default:
            return timeFiltered.sorted { $0.startDate > $1.startDate }
        }
    }

    // MARK: - Data loading

    private func setupBindings() {
        $selectedDuration
            .combineLatest($selectedRaceType)
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] _, _ in
                Task { @MainActor [weak self] in
                    await self?.loadLeaderboard()
                }
            }
            .store(in: &cancellables)
    }

    @MainActor
    func loadInitialData() async {
        isLoading = true

        async let sessionsTask: Void = loadSessions()
        async let leaderboardTask: Void = loadLeaderboard()

        _ = await (sessionsTask, leaderboardTask)

        isLoading = false
    }

    func refresh() async {
        await loadInitialData()
    }

    private func loadSessions() async {
        do {
            sessions = try await sessionService.fetchFeedSessions(page: 1)
        } catch {
            errorMessage = "Failed to load sessions"
        }
    }

    private func loadLeaderboard() async {
        do {
            currentLeaderboard = try await raceService.fetchLeaderboard(
                duration: selectedDuration,
                raceType: selectedRaceType
            )
        } catch {
            // Silently fail for leaderboard
        }
    }
}

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
