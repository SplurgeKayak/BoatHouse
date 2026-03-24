import SwiftUI
import Combine

/// ViewModel for the Home screen
@MainActor
final class HomeViewModel: ObservableObject {
    @Published var sessions: [Session] = []
    @Published var currentLeaderboard: Leaderboard?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var feedItems: [FeedItem] = []
    @Published var followedUserIds: Set<String> = {
        let saved = UserDefaults.standard.stringArray(forKey: "followedUserIds") ?? []
        return Set(saved)
    }()
    @Published var newsUnavailable: Bool = false

    private let sessionService: SessionServiceProtocol
    private let raceService: RaceServiceProtocol
    private let newsService: ExternalNewsServiceProtocol

    init(
        sessionService: SessionServiceProtocol = SessionService.shared,
        raceService: RaceServiceProtocol = RaceService.shared,
        newsService: ExternalNewsServiceProtocol = MockExternalNewsService()
    ) {
        self.sessionService = sessionService
        self.raceService = raceService
        self.newsService = newsService
    }

    // MARK: - Chronological feed

    /// All sessions sorted newest first, with no filtering.
    var chronologicalSessions: [Session] {
        sessions.sorted { $0.startDate > $1.startDate }
    }

    // MARK: - User helpers

    /// Returns the display name for a userId, falling back to the raw ID.
    func userName(for userId: String) -> String {
        Self.displayName(for: userId)
    }

    /// Returns the profile image URL for a userId, if available.
    func userAvatarURL(for userId: String) -> URL? {
        Self.avatarURL(for: userId)
    }

    /// Returns the display name for a userId, falling back to the raw ID.
    static func displayName(for userId: String) -> String {
        MockData.users.first(where: { $0.id == userId })?.displayName ?? userId
    }

    /// Returns the profile image URL for a userId, if available.
    static func avatarURL(for userId: String) -> URL? {
        MockData.users.first(where: { $0.id == userId })?.profileImageURL
    }

    /// Returns all userIds whose eligible categories include the given category.
    static func usersInCategory(_ category: RaceCategory) -> [String] {
        MockData.users
            .filter { $0.eligibleCategories.contains(category) }
            .map(\.id)
    }

    // MARK: - Filtered sessions (kept for backward compatibility with tests)

    /// Pure function for filtering and sorting sessions.
    /// Testable independently of the ViewModel.
    static func filterSessions(
        sessions: [Session],
        timeFilter: RaceDuration,
        distanceFilter: RaceType,
        categoryFilter: RaceCategory? = nil,
        currentUserCategory: RaceCategory? = nil,
        now: Date,
        calendar: Calendar
    ) -> [Session] {
        // 1. Time-period filter
        var timeFiltered = sessions.filter { session in
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

        // 2. Category filter — applies selected category (or current user's if set)
        let effectiveCategory = categoryFilter ?? currentUserCategory
        if let category = effectiveCategory {
            let categoryUserIds = Set(usersInCategory(category))
            timeFiltered = timeFiltered.filter { categoryUserIds.contains($0.userId) }
        }

        // 3. Distance filter + sort (ascending = fastest first) with deterministic tiebreaker
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
        }
    }

    // MARK: - Follow/Unfollow

    func toggleFollow(userId: String) {
        if followedUserIds.contains(userId) {
            followedUserIds.remove(userId)
        } else {
            followedUserIds.insert(userId)
        }
        UserDefaults.standard.set(Array(followedUserIds), forKey: "followedUserIds")
        rebuildFeed(sessions: sessions, newsItems: feedItems.compactMap {
            if case .news(let n) = $0 { return n } else { return nil }
        })
    }

    // MARK: - Feed building

    private func rebuildFeed(sessions: [Session], newsItems: [ExternalNewsItem]) {
        let sortedSessions = sessions.sorted { $0.startDate > $1.startDate }
        let followedSessions = sortedSessions.filter { followedUserIds.contains($0.userId) }
        let otherSessions = sortedSessions.filter { !followedUserIds.contains($0.userId) }

        var result: [FeedItem] = []

        // Followed users' sessions first
        for session in followedSessions {
            result.append(.session(session, userName: userName(for: session.userId), userAvatarURL: userAvatarURL(for: session.userId)))
        }

        // Interleave news every ~3 non-followed session cards
        var newsQueue = newsItems.sorted { $0.publishedAt > $1.publishedAt }
        var sessionBuffer: [FeedItem] = otherSessions.map {
            .session($0, userName: userName(for: $0.userId), userAvatarURL: userAvatarURL(for: $0.userId))
        }

        var idx = 0
        while !sessionBuffer.isEmpty {
            result.append(sessionBuffer.removeFirst())
            idx += 1
            if idx % 3 == 0, !newsQueue.isEmpty {
                result.append(.news(newsQueue.removeFirst()))
            }
        }
        // Append any remaining news
        for item in newsQueue {
            result.append(.news(item))
        }

        feedItems = result
    }

    // MARK: - Data loading

    @MainActor
    func loadInitialData() async {
        isLoading = true

        async let sessionsTask: Void = loadSessions()
        async let leaderboardTask: Void = loadLeaderboard()
        async let newsTask = newsService.fetchNews()

        let fetchedNews = await newsTask
        _ = await (sessionsTask, leaderboardTask)

        newsUnavailable = fetchedNews.isEmpty
        rebuildFeed(sessions: sessions, newsItems: fetchedNews)

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
                duration: .weekly,
                raceType: .fastest1km
            )
        } catch {
            // Silently fail for leaderboard
        }
    }
}
