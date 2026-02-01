import Foundation
import CoreLocation

/// Activity model representing a Strava canoe/kayak activity
struct Activity: Identifiable, Codable, Equatable {
    let id: String
    let stravaId: Int
    let userId: String
    let name: String
    let activityType: ActivityType
    let startDate: Date
    let elapsedTime: TimeInterval
    let movingTime: TimeInterval
    let distance: Double
    let maxSpeed: Double?
    let averageSpeed: Double?
    let startLocation: Coordinate?
    let endLocation: Coordinate?
    let polyline: String?
    var isGPSVerified: Bool
    var isUKActivity: Bool
    var flagCount: Int
    var status: ActivityStatus
    let importedAt: Date

    var distanceKm: Double {
        distance / 1000.0
    }

    var maxSpeedKmh: Double? {
        guard let speed = maxSpeed else { return nil }
        return speed * 3.6
    }

    var averageSpeedKmh: Double? {
        guard let speed = averageSpeed else { return nil }
        return speed * 3.6
    }

    var formattedDistance: String {
        String(format: "%.2f km", distanceKm)
    }

    var formattedDuration: String {
        let hours = Int(movingTime) / 3600
        let minutes = (Int(movingTime) % 3600) / 60
        let seconds = Int(movingTime) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var formattedMaxSpeed: String {
        guard let speed = maxSpeedKmh else { return "N/A" }
        return String(format: "%.1f km/h", speed)
    }

    var formattedAverageSpeed: String {
        guard let speed = averageSpeedKmh else { return "N/A" }
        return String(format: "%.1f km/h", speed)
    }

    var isFlagged: Bool {
        flagCount > 0
    }

    var requiresReview: Bool {
        flagCount >= 3
    }

    var isEligibleForRaces: Bool {
        isGPSVerified && isUKActivity && status == .verified
    }

    /// Calculate pace for 1km segment
    func pacePerKm() -> TimeInterval? {
        guard distance > 0 else { return nil }
        return movingTime / distanceKm
    }

    /// Extract best 1km time from activity
    func best1kmTime() -> TimeInterval? {
        guard distanceKm >= 1.0 else { return nil }
        // TODO: Implement segment analysis from polyline
        // For now, estimate from average pace
        return pacePerKm()
    }

    /// Extract best 5km time from activity
    func best5kmTime() -> TimeInterval? {
        guard distanceKm >= 5.0 else { return nil }
        // TODO: Implement segment analysis from polyline
        guard let pace = pacePerKm() else { return nil }
        return pace * 5
    }
}

struct Coordinate: Codable, Equatable {
    let latitude: Double
    let longitude: Double

    var clLocation: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

enum ActivityType: String, Codable, CaseIterable {
    case canoeing = "Canoeing"
    case kayaking = "Kayaking"
    case rowing = "Rowing"
    case standUpPaddling = "StandUpPaddling"

    var displayName: String {
        switch self {
        case .canoeing: return "Canoeing"
        case .kayaking: return "Kayaking"
        case .rowing: return "Rowing"
        case .standUpPaddling: return "Stand Up Paddling"
        }
    }

    var icon: String {
        switch self {
        case .canoeing, .kayaking: return "figure.rowing"
        case .rowing: return "figure.rowing"
        case .standUpPaddling: return "figure.surfing"
        }
    }

    static var eligibleTypes: [ActivityType] {
        [.canoeing, .kayaking]
    }

    var isEligible: Bool {
        ActivityType.eligibleTypes.contains(self)
    }
}

enum ActivityStatus: String, Codable {
    case pending
    case verified
    case flagged
    case underReview
    case disqualified

    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .verified: return "Verified"
        case .flagged: return "Flagged"
        case .underReview: return "Under Review"
        case .disqualified: return "Disqualified"
        }
    }

    var color: String {
        switch self {
        case .pending: return "gray"
        case .verified: return "green"
        case .flagged: return "orange"
        case .underReview: return "yellow"
        case .disqualified: return "red"
        }
    }
}
