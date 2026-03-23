import SwiftUI

/// Pure helpers for computing goal progress from a list of sessions.
/// Andy's userId is "andy-001".
enum GoalProgressCalculator {

    enum Status {
        case aheadOfGoal
        case onTrack
        case needsImprovement
        case noData

        var label: String {
            switch self {
            case .aheadOfGoal:      return "Ahead of goal"
            case .onTrack:          return "On track"
            case .needsImprovement: return "Needs improvement"
            case .noData:           return "No data"
            }
        }

        var color: Color {
            switch self {
            case .aheadOfGoal:      return .green
            case .onTrack:          return .orange
            case .needsImprovement: return .red
            case .noData:           return .secondary
            }
        }
    }

    // MARK: - Best-time extractors

    static func best1k(from sessions: [Session]) -> TimeInterval? {
        sessions.compactMap(\.fastest1kmTime).min()
    }

    static func best5k(from sessions: [Session]) -> TimeInterval? {
        sessions.compactMap(\.fastest5kmTime).min()
    }

    static func best10k(from sessions: [Session]) -> TimeInterval? {
        sessions.compactMap(\.fastest10kmTime).min()
    }

    // MARK: - Status

    /// Returns a status comparing best time vs goal.
    /// Lower time = better for paddling.
    static func status(goal: TimeInterval, best: TimeInterval?) -> Status {
        guard let best = best else { return .noData }
        let ratio = best / goal   // < 1 means faster than goal
        switch ratio {
        case ..<0.98:     return .aheadOfGoal      // > 2 % faster
        case 0.98..<1.05: return .onTrack          // within 5 %
        default:          return .needsImprovement
        }
    }
}
