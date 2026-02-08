import Foundation

/// Computes progress for goals against session data, and generates dummy data for empty states.
enum GoalProgressService {

    // MARK: - Progress Computation

    /// Compute progress for a single goal against real session data.
    static func computeProgress(
        for goal: Goal,
        sessions: [Session],
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> GoalProgress {
        let relevant = sessions.filter { $0.sessionType == goal.activityType || $0.sessionType == .canoeing }

        let bestTime: TimeInterval? = {
            switch goal.category {
            case .fastest1km:  return relevant.compactMap(\.fastest1kmTime).min()
            case .fastest5km:  return relevant.compactMap(\.fastest5kmTime).min()
            case .fastest10km: return relevant.compactMap(\.fastest10kmTime).min()
            case .weeklyDistance: return nil
            }
        }()

        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: now) ?? now
        let recentSessions = relevant.filter { $0.startDate >= thirtyDaysAgo }

        let avgTime: TimeInterval? = {
            let times: [TimeInterval]
            switch goal.category {
            case .fastest1km:  times = recentSessions.compactMap(\.fastest1kmTime)
            case .fastest5km:  times = recentSessions.compactMap(\.fastest5kmTime)
            case .fastest10km: times = recentSessions.compactMap(\.fastest10kmTime)
            case .weeklyDistance: return nil
            }
            guard !times.isEmpty else { return nil }
            return times.reduce(0, +) / Double(times.count)
        }()

        return GoalProgress(
            goal: goal,
            currentBestTime: bestTime,
            averageTime30Days: avgTime,
            sessionsCount: recentSessions.count,
            isDummyData: false
        )
    }

    /// Compute progress for all goals; fills in dummy data where real data is missing.
    static func computeAllProgress(
        goals: [Goal],
        sessions: [Session],
        now: Date = Date()
    ) -> [GoalProgress] {
        goals.map { goal in
            let real = computeProgress(for: goal, sessions: sessions, now: now)
            if real.currentBestTime != nil {
                return real
            }
            return generateDummyProgress(for: goal)
        }
    }

    // MARK: - Dummy Data Generation

    /// Generate deterministic dummy progress when there's no real activity data.
    /// Seed is based on goal.id so data is stable across launches.
    static func generateDummyProgress(for goal: Goal) -> GoalProgress {
        // Deterministic seed from goal id
        let hash = goal.id.utf8.reduce(UInt64(0)) { ($0 &* 31) &+ UInt64($1) }
        var rng = MockData.SeededRNG(seed: hash)

        let target = goal.targetTime
        // Best time: 85–115% of target (sometimes beating it, sometimes not)
        let bestFactor = Double.random(in: 0.88...1.12, using: &rng)
        let bestTime = target * bestFactor

        // Average: 5–20% slower than best
        let avgFactor = Double.random(in: 1.05...1.20, using: &rng)
        let avgTime = bestTime * avgFactor

        let sessionCount = Int.random(in: 3...12, using: &rng)

        return GoalProgress(
            goal: goal,
            currentBestTime: bestTime,
            averageTime30Days: avgTime,
            sessionsCount: sessionCount,
            isDummyData: true
        )
    }
}
