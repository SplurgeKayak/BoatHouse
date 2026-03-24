import SwiftUI
import Combine

/// ViewModel for the Goals dashboard (State B of Home).
final class GoalsViewModel: ObservableObject {
    @Published var goals: [Goal] = []
    @Published var progress: [GoalProgress] = []
    @Published var isLoading = false

    private let store: GoalsStore
    private let sessionService: SessionServiceProtocol

    var hasGoals: Bool { !goals.isEmpty }

    init(
        store: GoalsStore = .shared,
        sessionService: SessionServiceProtocol = SessionService.shared
    ) {
        self.store = store
        self.sessionService = sessionService
    }

    @MainActor
    func loadGoals() async {
        isLoading = true
        defer { isLoading = false }

        goals = store.loadGoals()
        guard !goals.isEmpty else { return }

        // Fetch sessions to compute progress (lazy: only when goals exist)
        do {
            let sessions = try await sessionService.fetchFeedSessions(page: 1)
            progress = GoalProgressService.computeAllProgress(
                goals: goals,
                sessions: sessions
            )
        } catch {
            // Fall back to dummy data on error
            progress = goals.map { GoalProgressService.generateDummyProgress(for: $0) }
        }
    }

    /// Save new goals from entry form and reload.
    @MainActor
    func saveAndReload(_ newGoals: [Goal]) async {
        store.saveGoals(newGoals)
        await loadGoals()
    }
}
