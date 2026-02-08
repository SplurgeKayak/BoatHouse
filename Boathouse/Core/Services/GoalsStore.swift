import Foundation

/// UserDefaults-backed persistence for goals
final class GoalsStore {
    static let shared = GoalsStore()

    private let defaults: UserDefaults
    private let goalsKey = "com.boathouse.kayakingGoals"
    private let completedKey = "com.boathouse.goalsCompleted"
    private let goalsArrayKey = "com.boathouse.goals"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// Whether the user has completed the goals setup flow
    var hasCompletedGoals: Bool {
        get { defaults.bool(forKey: completedKey) }
        set { defaults.set(newValue, forKey: completedKey) }
    }

    // MARK: - Goal Array (New)

    /// Load saved goals array
    func loadGoals() -> [Goal] {
        guard let data = defaults.data(forKey: goalsArrayKey) else {
            // Migration: convert old KayakingGoals to Goal array
            return migrateFromLegacy()
        }
        return (try? JSONDecoder().decode([Goal].self, from: data)) ?? []
    }

    /// Save goals array
    func saveGoals(_ goals: [Goal]) {
        if let data = try? JSONEncoder().encode(goals) {
            defaults.set(data, forKey: goalsArrayKey)
        }
        if !goals.isEmpty {
            hasCompletedGoals = true
        }
    }

    // MARK: - Legacy KayakingGoals (backward compat)

    /// Load saved legacy goals, or nil if none saved yet
    func load() -> KayakingGoals? {
        guard let data = defaults.data(forKey: goalsKey) else { return nil }
        return try? JSONDecoder().decode(KayakingGoals.self, from: data)
    }

    /// Save legacy goals to UserDefaults
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
        defaults.removeObject(forKey: goalsArrayKey)
    }

    // MARK: - Migration

    /// Convert old flat KayakingGoals into Goal array
    private func migrateFromLegacy() -> [Goal] {
        guard let legacy = load() else { return [] }
        var goals: [Goal] = []

        if let t = legacy.timeGoal1k {
            goals.append(Goal(category: .fastest1km, targetTime: t))
        }
        if let t = legacy.timeGoal5k {
            goals.append(Goal(category: .fastest5km, targetTime: t))
        }
        if let t = legacy.timeGoal10k {
            goals.append(Goal(category: .fastest10km, targetTime: t))
        }

        // Persist migrated goals so migration only runs once
        if !goals.isEmpty {
            saveGoals(goals)
        }

        return goals
    }
}
