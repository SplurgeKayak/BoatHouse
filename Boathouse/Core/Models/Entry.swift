import Foundation

/// Entry model representing a user's race entry
struct Entry: Identifiable, Codable, Equatable {
    let id: String
    let userId: String
    let raceId: String
    let sessionId: String?
    let enteredAt: Date
    var score: Double?
    var rank: Int?
    var status: EntryStatus
    var prizeWon: Decimal?
    var transactionId: String?

    enum CodingKeys: String, CodingKey {
        case id, userId, raceId
        case sessionId = "activityId"
        case enteredAt, score, rank, status, prizeWon, transactionId
    }

    var hasSession: Bool {
        sessionId != nil
    }

    var isWinner: Bool {
        guard let rank = rank else { return false }
        return rank <= 3 && prizeWon != nil
    }

    var formattedScore: String {
        guard let score = score else { return "—" }
        return String(format: "%.2f", score)
    }

    var formattedPrize: String? {
        guard let prize = prizeWon else { return nil }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "GBP"
        formatter.currencySymbol = "£"
        return formatter.string(from: prize as NSDecimalNumber)
    }
}

enum EntryStatus: String, Codable {
    case active
    case completed
    case disqualified
    case refunded

    var displayName: String {
        switch self {
        case .active: return "Active"
        case .completed: return "Completed"
        case .disqualified: return "Disqualified"
        case .refunded: return "Refunded"
        }
    }
}

/// Leaderboard entry for race rankings
struct LeaderboardEntry: Identifiable, Codable, Equatable {
    let id: String
    let rank: Int
    let userId: String
    let userName: String
    let userProfileURL: URL?
    let score: Double
    let sessionId: String?
    let raceType: RaceType

    enum CodingKeys: String, CodingKey {
        case id, rank, userId, userName, userProfileURL, score
        case sessionId = "activityId"
        case raceType
    }

    var formattedScore: String {
        switch raceType {
        case .topSpeed:
            return String(format: "%.1f km/h", score)
        case .furthestDistance:
            return String(format: "%.2f km", score)
        case .fastest1km, .fastest5km, .fastest10km:
            let minutes = Int(score) / 60
            let seconds = Int(score) % 60
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    var medalColor: String? {
        switch rank {
        case 1: return "gold"
        case 2: return "silver"
        case 3: return "bronze"
        default: return nil
        }
    }
}

/// Complete leaderboard for a race
struct Leaderboard: Identifiable, Codable {
    let id: String
    let raceId: String
    var entries: [LeaderboardEntry]
    let updatedAt: Date

    var topThree: [LeaderboardEntry] {
        Array(entries.prefix(3))
    }

    func entry(for userId: String) -> LeaderboardEntry? {
        entries.first { $0.userId == userId }
    }

    func rank(for userId: String) -> Int? {
        entry(for: userId)?.rank
    }
}
