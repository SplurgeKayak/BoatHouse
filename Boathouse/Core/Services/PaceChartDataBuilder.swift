import Foundation

extension GoalProgressCalculator {

    /// Extracts per-session pace data points for the chart, sorted oldest → newest.
    static func dataPoints(for distance: GoalDistance, from sessions: [Session]) -> [RacePerformanceDataPoint] {
        sessions
            .compactMap { s -> RacePerformanceDataPoint? in
                let pace: TimeInterval?
                switch distance {
                case .oneKm:  pace = s.fastest1kmTime           // already seconds/km for 1 km
                case .fiveKm: pace = s.fastest5kmTime.map { $0 / 5 }   // total time → pace/km
                case .tenKm:  pace = s.fastest10kmTime.map { $0 / 10 }
                }
                guard let p = pace else { return nil }
                return RacePerformanceDataPoint(id: s.id, date: s.startDate, pacePerKm: p)
            }
            .sorted { $0.date < $1.date }
    }

    /// Goal pace (seconds/km) for the selected distance.
    static func goalPace(for distance: GoalDistance, goals: KayakingGoals) -> TimeInterval? {
        switch distance {
        case .oneKm:  return goals.timeGoal1k
        case .fiveKm: return goals.timeGoal5k.map { $0 / 5 }
        case .tenKm:  return goals.timeGoal10k.map { $0 / 10 }
        }
    }

    /// Simple linear regression over pace values.
    /// Returns (slope, intercept) such that predicted pace at index x = slope * x + intercept.
    static func linearRegression(points: [RacePerformanceDataPoint]) -> (slope: Double, intercept: Double)? {
        let n = Double(points.count)
        guard n >= 2 else { return nil }
        let xs = (0..<points.count).map { Double($0) }
        let ys = points.map { $0.pacePerKm }
        let xMean = xs.reduce(0, +) / n
        let yMean = ys.reduce(0, +) / n
        let ssxx = xs.map { ($0 - xMean) * ($0 - xMean) }.reduce(0, +)
        let ssxy = zip(xs, ys).map { ($0 - xMean) * ($1 - yMean) }.reduce(0, +)
        guard ssxx != 0 else { return nil }
        let slope = ssxy / ssxx
        let intercept = yMean - slope * xMean
        return (slope, intercept)
    }
}
