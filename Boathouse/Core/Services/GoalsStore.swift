import Foundation

/// UserDefaults-backed persistence for KayakingGoals
final class GoalsStore {
    static let shared = GoalsStore()

    private let defaults: UserDefaults
    private let goalsKey = "com.boathouse.kayakingGoals"
    private let completedKey = "com.boathouse.goalsCompleted"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// Whether the user has completed the goals setup flow
    var hasCompletedGoals: Bool {
        get { defaults.bool(forKey: completedKey) }
        set { defaults.set(newValue, forKey: completedKey) }
    }

    /// Load saved goals, or nil if none saved yet
    func load() -> KayakingGoals? {
        guard let data = defaults.data(forKey: goalsKey) else { return nil }
        return try? JSONDecoder().decode(KayakingGoals.self, from: data)
    }

    /// Save goals to UserDefaults
    func save(_ goals: KayakingGoals) {
        if let data = try? JSONEncoder().encode(goals) {
            defaults.set(data, forKey: goalsKey)
        }
        hasCompletedGoals = true
    }

    /// Clear all goals data (for testing / reset)
    func clear() {
        defaults.removeObject(forKey: goalsKey)
        defaults.removeObject(forKey: completedKey)
    }
}
