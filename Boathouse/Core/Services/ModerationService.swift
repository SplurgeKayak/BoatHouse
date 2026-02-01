import Foundation

/// Protocol for moderation operations
protocol ModerationServiceProtocol {
    func flagActivity(activityId: String, userId: String, reason: FlagReason) async throws
    func reviewActivity(activityId: String, decision: ModerationDecision) async throws
    func getFlaggedActivities() async throws -> [FlaggedActivity]
}

/// Service for activity moderation and anti-cheat
final class ModerationService: ModerationServiceProtocol {
    static let shared = ModerationService()

    private let networkClient: NetworkClientProtocol

    // Threshold for requiring admin review
    static let reviewThreshold = 3

    init(networkClient: NetworkClientProtocol = NetworkClient.shared) {
        self.networkClient = networkClient
    }

    func flagActivity(activityId: String, userId: String, reason: FlagReason) async throws {
        // TODO: Replace with actual API call
        // POST /moderation/flag
        // Body: { activityId, userId, reason }

        // Server should:
        // 1. Check if user has already flagged this activity
        // 2. Increment flag count
        // 3. If flag count >= 3, mark for review
    }

    func reviewActivity(activityId: String, decision: ModerationDecision) async throws {
        // TODO: Replace with actual API call
        // POST /moderation/review (admin only)
        // Body: { activityId, decision, notes }

        // Server should:
        // 1. Update activity status based on decision
        // 2. If disqualified:
        //    - Remove from any active race entries
        //    - Refund entry fees
        // 3. If approved, clear flags and mark as verified
    }

    func getFlaggedActivities() async throws -> [FlaggedActivity] {
        // TODO: Replace with actual API call
        // GET /moderation/flagged (admin only)
        return []
    }

    /// Check if an activity should be reviewed
    func requiresReview(flagCount: Int) -> Bool {
        flagCount >= Self.reviewThreshold
    }
}

// MARK: - Supporting Types

enum FlagReason: String, Codable, CaseIterable {
    case suspiciousSpeed = "suspicious_speed"
    case motorizedAssistance = "motorized_assistance"
    case impossibleRoute = "impossible_route"
    case fakeActivity = "fake_activity"
    case other = "other"

    var displayName: String {
        switch self {
        case .suspiciousSpeed: return "Suspicious Speed"
        case .motorizedAssistance: return "Motorized Assistance"
        case .impossibleRoute: return "Impossible Route"
        case .fakeActivity: return "Fake Activity"
        case .other: return "Other"
        }
    }
}

enum ModerationDecision: String, Codable {
    case approve
    case disqualify
    case requireMoreInfo

    var displayName: String {
        switch self {
        case .approve: return "Approve"
        case .disqualify: return "Disqualify"
        case .requireMoreInfo: return "Request More Info"
        }
    }
}

struct FlaggedActivity: Identifiable, Codable {
    let id: String
    let activityId: String
    let userId: String
    let userName: String
    let flagCount: Int
    let reasons: [FlagReason]
    let activityDetails: Activity
    let createdAt: Date

    var needsReview: Bool {
        flagCount >= ModerationService.reviewThreshold
    }
}

struct Flag: Identifiable, Codable {
    let id: String
    let activityId: String
    let flaggedByUserId: String
    let reason: FlagReason
    let notes: String?
    let createdAt: Date
}
