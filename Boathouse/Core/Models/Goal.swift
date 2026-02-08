import Foundation

/// Individual goal with identity, category, and target time.
struct Goal: Identifiable, Codable, Equatable {
    let id: String
    var activityType: SessionType
    var category: GoalCategory
    var targetTime: TimeInterval
    var createdDate: Date
    var linkedStravaCategory: String?

    init(
        id: String = UUID().uuidString,
        activityType: SessionType = .kayaking,
        category: GoalCategory,
        targetTime: TimeInterval,
        createdDate: Date = Date(),
        linkedStravaCategory: String? = nil
    ) {
        self.id = id
        self.activityType = activityType
        self.category = category
        self.targetTime = targetTime
        self.createdDate = createdDate
        self.linkedStravaCategory = linkedStravaCategory
    }

    /// Format target time as "M:SS"
    var formattedTarget: String {
        KayakingGoals.formatTime(targetTime)
    }
}

// MARK: - Goal Category

enum GoalCategory: String, Codable, CaseIterable, Identifiable {
    case fastest1km = "fastest_1km"
    case fastest5km = "fastest_5km"
    case fastest10km = "fastest_10km"
    case weeklyDistance = "weekly_distance"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .fastest1km: return "1km"
        case .fastest5km: return "5km"
        case .fastest10km: return "10km"
        case .weeklyDistance: return "Weekly Distance"
        }
    }

    var fullName: String {
        switch self {
        case .fastest1km: return "Fastest 1km"
        case .fastest5km: return "Fastest 5km"
        case .fastest10km: return "Fastest 10km"
        case .weeklyDistance: return "Weekly Distance"
        }
    }

    var icon: String {
        switch self {
        case .fastest1km: return "1.circle.fill"
        case .fastest5km: return "5.circle.fill"
        case .fastest10km: return "10.circle.fill"
        case .weeklyDistance: return "arrow.left.and.right"
        }
    }

    /// Corresponding RaceType for filtering
    var raceType: RaceType? {
        switch self {
        case .fastest1km: return .fastest1km
        case .fastest5km: return .fastest5km
        case .fastest10km: return .fastest10km
        case .weeklyDistance: return nil
        }
    }

    /// Time-based goal categories (not distance)
    static var timeCategories: [GoalCategory] {
        [.fastest1km, .fastest5km, .fastest10km]
    }
}

// MARK: - Goal Progress

/// Computed progress for a single goal against activity data.
struct GoalProgress: Identifiable {
    let goal: Goal
    var currentBestTime: TimeInterval?
    var averageTime30Days: TimeInterval?
    var sessionsCount: Int
    var isDummyData: Bool

    var id: String { goal.id }

    /// 0..1 fraction of how close best time is to target (1.0 = met or exceeded)
    var progressFraction: Double {
        guard let best = currentBestTime, goal.targetTime > 0 else { return 0 }
        // For time goals: lower is better. If best ≤ target → 1.0
        return min(goal.targetTime / best, 1.0)
    }

    /// Whether the goal has been met (best time ≤ target)
    var isGoalMet: Bool {
        guard let best = currentBestTime else { return false }
        return best <= goal.targetTime
    }

    var formattedBest: String? {
        guard let best = currentBestTime else { return nil }
        return KayakingGoals.formatTime(best)
    }

    var formattedAverage: String? {
        guard let avg = averageTime30Days else { return nil }
        return KayakingGoals.formatTime(avg)
    }
}
