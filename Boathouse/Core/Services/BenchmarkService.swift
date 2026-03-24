import Foundation

/// Derives category benchmark paces from all-sessions mock data.
/// Replace with a real API call when the backend is ready.
/// - TODO: Replace MockData usage with a real SessionService async call.
enum BenchmarkService {

    /// Returns the average pace/km for the given category and distance,
    /// computed from all sessions filtered by the matching user category.
    static func categoryBenchmark(
        for distance: GoalDistance,
        category: RaceCategory,
        allSessions: [Session],
        allUsers: [User]
    ) -> CategoryBenchmark? {
        // Build a userId → category map
        let userCategoryMap: [String: RaceCategory] = Dictionary(
            uniqueKeysWithValues: allUsers.compactMap { user -> (String, RaceCategory)? in
                guard let cat = user.raceCategory else { return nil }
                return (user.id, cat)
            }
        )

        let categorySessions = allSessions.filter {
            userCategoryMap[$0.userId] == category
        }

        let paces: [TimeInterval] = categorySessions.compactMap { s in
            switch distance {
            case .oneKm:  return s.fastest1kmTime
            case .fiveKm: return s.fastest5kmTime.map { $0 / 5 }
            case .tenKm:  return s.fastest10kmTime.map { $0 / 10 }
            }
        }

        guard !paces.isEmpty else { return nil }
        let avg = paces.reduce(0, +) / TimeInterval(paces.count)
        return CategoryBenchmark(categoryName: category.displayName, averagePacePerKm: avg)
    }
}
