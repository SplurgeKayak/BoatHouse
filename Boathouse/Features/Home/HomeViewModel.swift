import SwiftUI
import Combine

/// ViewModel for the Home screen
@MainActor
final class HomeViewModel: ObservableObject {
    @Published var activities: [Activity] = []
    @Published var recentActivities: [Activity] = []
    @Published var currentLeaderboard: Leaderboard?
    @Published var selectedDuration: RaceDuration = .daily
    @Published var selectedRaceType: RaceType = .topSpeed
    @Published var isLoading = false
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

    private func setupBindings() {
        $selectedDuration
            .combineLatest($selectedRaceType)
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] _, _ in
                Task {
                    await self?.loadLeaderboard()
                }
            }
            .store(in: &cancellables)
    }

    func loadInitialData() async {
        isLoading = true

        async let activitiesTask = loadActivities()
        async let recentTask = loadRecentActivities()
        async let leaderboardTask = loadLeaderboard()

        _ = await (activitiesTask, recentTask, leaderboardTask)

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

    private func loadRecentActivities() async {
        do {
            recentActivities = try await activityService.fetchRecentActivities(limit: 10)
        } catch {
            // Silently fail for recent activities
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
