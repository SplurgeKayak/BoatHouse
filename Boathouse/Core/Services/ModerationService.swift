import Foundation

/// Protocol for moderation operations
protocol ModerationServiceProtocol {
    func flagSession(sessionId: String, userId: String, reason: FlagReason) async throws
    func reviewSession(sessionId: String, decision: ModerationDecision) async throws
    func getFlaggedSessions() async throws -> [FlaggedSession]
}

/// Service for session moderation and anti-cheat
final class ModerationService: ModerationServiceProtocol {
    static let shared = ModerationService()

    private let networkClient: NetworkClientProtocol

    static let reviewThreshold = 3

    init(networkClient: NetworkClientProtocol = NetworkClient.shared) {
        self.networkClient = networkClient
    }

    func flagSession(sessionId: String, userId: String, reason: FlagReason) async throws {
        // TODO: Replace with actual API call
    }

    func reviewSession(sessionId: String, decision: ModerationDecision) async throws {
        // TODO: Replace with actual API call
    }

    func getFlaggedSessions() async throws -> [FlaggedSession] {
        // TODO: Replace with actual API call
        return []
    }

    func requiresReview(flagCount: Int) -> Bool {
        flagCount >= Self.reviewThreshold
    }
}

// MARK: - Supporting Types

enum FlagReason: String, Codable, CaseIterable {
    case suspiciousSpeed = "suspicious_speed"
    case motorizedAssistance = "motorized_assistance"
    case impossibleRoute = "impossible_route"
    case fakeSession = "fake_activity"
    case other = "other"

    var displayName: String {
        switch self {
        case .suspiciousSpeed: return "Suspicious Speed"
        case .motorizedAssistance: return "Motorized Assistance"
        case .impossibleRoute: return "Impossible Route"
        case .fakeSession: return "Fake Session"
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

struct FlaggedSession: Identifiable, Codable {
    let id: String
    let sessionId: String
    let userId: String
    let userName: String
    let flagCount: Int
    let reasons: [FlagReason]
    let sessionDetails: Session
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case sessionId = "activityId"
        case userId, userName, flagCount, reasons
        case sessionDetails = "activityDetails"
        case createdAt
    }

    var needsReview: Bool {
        flagCount >= ModerationService.reviewThreshold
    }
}

struct Flag: Identifiable, Codable {
    let id: String
    let sessionId: String
    let flaggedByUserId: String
    let reason: FlagReason
    let notes: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case sessionId = "activityId"
        case flaggedByUserId, reason, notes, createdAt
    }
}
