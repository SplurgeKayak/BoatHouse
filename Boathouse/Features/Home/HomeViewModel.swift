import SwiftUI
import Combine

/// ViewModel for the Home screen
final class HomeViewModel: ObservableObject {
    @Published var activities: [Activity] = []
    @Published var currentLeaderboard: Leaderboard?
    @Published var selectedDuration: RaceDuration = .weekly
    @Published var selectedRaceType: RaceType = .fastest1km
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let activityService: ActivityServiceProtocol
    private let raceService: RaceServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    init(
        activityService: ActivityServiceProtocol = ActivityService.shared,
        raceService: RaceServiceProtocol = RaceService.shared
    ) {
        self.activityService = activityService
        self.raceService = raceService
        setupBindings()
    }

    // MARK: - Filtered activities

    /// Activities filtered by time period and sorted by the selected distance metric.
    /// Time filters narrow the list; distance filters sort and exclude activities
    /// that lack the corresponding segment time.
    var filteredActivities: [Activity] {
        let calendar = Calendar.current
        let now = Date()

        // 1. Time-period filter
        let timeFiltered = activities.filter { activity in
            switch selectedDuration {
            case .daily:
                return calendar.isDateInToday(activity.startDate)
            case .weekly:
                return calendar.isDate(activity.startDate, equalTo: now, toGranularity: .weekOfYear)
            case .monthly:
                return calendar.isDate(activity.startDate, equalTo: now, toGranularity: .month)
            case .yearly:
                return calendar.isDate(activity.startDate, equalTo: now, toGranularity: .year)
            }
        }

        // 2. Distance sort (ascending = fastest first) with deterministic tiebreaker
        switch selectedRaceType {
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

        async let activitiesTask: Void = loadActivities()
        async let leaderboardTask: Void = loadLeaderboard()

        _ = await (activitiesTask, leaderboardTask)

        isLoading = false
    }

    func refresh() async {
        await loadInitialData()
    }

    private func loadActivities() async {
        do {
            activities = try await activityService.fetchFeedActivities(page: 1)
        } catch {
            errorMessage = "Failed to load activities"
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

// MARK: - Activity Service Protocol

protocol ActivityServiceProtocol {
    func fetchFeedActivities(page: Int) async throws -> [Activity]
    func fetchRecentActivities(limit: Int) async throws -> [Activity]
    func fetchUserActivities(userId: String, page: Int) async throws -> [Activity]
    func importStravaActivities() async throws -> [Activity]
    func flagActivity(activityId: String, reason: String) async throws
}

/// Service for activity operations
final class ActivityService: ActivityServiceProtocol {
    static let shared = ActivityService()

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

    func fetchFeedActivities(page: Int) async throws -> [Activity] {
        // TODO: Replace with actual API call
        // For now, return mock data
        return MockData.activities
    }

    func fetchRecentActivities(limit: Int) async throws -> [Activity] {
        // TODO: Replace with actual API call
        return Array(MockData.activities.prefix(limit))
    }

    func fetchUserActivities(userId: String, page: Int) async throws -> [Activity] {
        // TODO: Replace with actual API call
        return MockData.activities.filter { $0.userId == userId }
    }

    func importStravaActivities() async throws -> [Activity] {
        guard let accessToken = keychainService.retrieveToken(for: .stravaAccessToken) else {
            throw StravaError.notAuthenticated
        }

        let stravaActivities = try await stravaService.fetchActivities(
            accessToken: accessToken,
            after: nil,
            before: nil,
            page: 1
        )

        // Filter for canoe/kayak activities only
        let filteredActivities = stravaActivities.filter { $0.isCanoeOrKayak }

        // Get userId on MainActor before mapping
        let userId = await MainActor.run { AppState.shared?.currentUser?.id ?? "" }

        // TODO: Convert Strava activities to app activities and save to backend
        return filteredActivities.map { stravaActivity in
            mapStravaActivity(stravaActivity, userId: userId)
        }
    }

    func flagActivity(activityId: String, reason: String) async throws {
        // TODO: Implement API call to flag activity
    }

    private func mapStravaActivity(_ stravaActivity: StravaActivity, userId: String) -> Activity {
        let startCoord: Coordinate? = stravaActivity.startLatlng.map {
            Coordinate(latitude: $0[0], longitude: $0[1])
        }
        let endCoord: Coordinate? = stravaActivity.endLatlng.map {
            Coordinate(latitude: $0[0], longitude: $0[1])
        }

        let activityType: ActivityType = stravaActivity.type == "Kayaking" ? .kayaking : .canoeing

        return Activity(
            id: UUID().uuidString,
            stravaId: stravaActivity.id,
            userId: userId,
            name: stravaActivity.name,
            activityType: activityType,
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
            isUKActivity: isLocationInUK(startCoord),
            flagCount: 0,
            status: .pending,
            importedAt: Date()
        )
    }

    private func isLocationInUK(_ coordinate: Coordinate?) -> Bool {
        guard let coord = coordinate else { return false }

        // UK bounding box (approximate)
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
