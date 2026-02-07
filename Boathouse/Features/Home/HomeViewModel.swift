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
