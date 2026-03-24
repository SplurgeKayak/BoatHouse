import Foundation

/// Lightweight goals model stored in UserDefaults
struct KayakingGoals: Codable, Equatable {
    /// Target time for fastest 1km (seconds), e.g. 240 = "4:00"
    var timeGoal1k: TimeInterval?
    /// Target time for fastest 5km (seconds)
    var timeGoal5k: TimeInterval?
    /// Target time for fastest 10km (seconds)
    var timeGoal10k: TimeInterval?
    /// Weekly distance goal in kilometres
    var distancePerWeekKm: Double?
    /// Ranking goals by race category (e.g. "seniorMen" → top-10)
    var rankingGoals: [String: Int]
    /// Target rank for fastest 1km (e.g. top 10)
    var rankTarget1km: Int?
    /// Target rank for fastest 5km
    var rankTarget5km: Int?
    /// Target rank for fastest 10km
    var rankTarget10km: Int?
    /// Target rank for total distance
    var rankTargetDistance: Int?

    init(
        timeGoal1k: TimeInterval? = nil,
        timeGoal5k: TimeInterval? = nil,
        timeGoal10k: TimeInterval? = nil,
        distancePerWeekKm: Double? = nil,
        rankingGoals: [String: Int] = [:],
        rankTarget1km: Int? = nil,
        rankTarget5km: Int? = nil,
        rankTarget10km: Int? = nil,
        rankTargetDistance: Int? = nil
    ) {
        self.timeGoal1k = timeGoal1k
        self.timeGoal5k = timeGoal5k
        self.timeGoal10k = timeGoal10k
        self.distancePerWeekKm = distancePerWeekKm
        self.rankingGoals = rankingGoals
        self.rankTarget1km = rankTarget1km
        self.rankTarget5km = rankTarget5km
        self.rankTarget10km = rankTarget10km
        self.rankTargetDistance = rankTargetDistance
    }

    // MARK: - Time string helpers

    /// Parse "M:SS" or "MM:SS" into seconds.
    /// Returns nil for invalid input.
    static func parseTimeString(_ string: String) -> TimeInterval? {
        let trimmed = string.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }

        let parts = trimmed.split(separator: ":")
        guard parts.count == 2 else { return nil }
        guard let minutes = Int(parts[0]), let seconds = Int(parts[1]) else { return nil }
        guard minutes >= 0, seconds >= 0, seconds < 60 else { return nil }
        let total = TimeInterval(minutes * 60 + seconds)
        guard total > 0 else { return nil }
        return total
    }

    /// Format seconds to "M:SS" string.
    static func formatTime(_ interval: TimeInterval) -> String {
        let totalSeconds = Int(interval)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    // MARK: - Validation

    /// At least one goal must be set
    var hasAnyGoal: Bool {
        timeGoal1k != nil ||
        timeGoal5k != nil ||
        timeGoal10k != nil ||
        distancePerWeekKm != nil ||
        !rankingGoals.isEmpty ||
        rankTarget1km != nil ||
        rankTarget5km != nil ||
        rankTarget10km != nil ||
        rankTargetDistance != nil
    }
}
