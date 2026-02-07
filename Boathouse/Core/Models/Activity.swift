import Foundation
import CoreLocation

/// Session model representing a Strava canoe/kayak session (formerly Activity)
struct Session: Identifiable, Codable, Equatable {
    let id: String
    let stravaId: Int
    let userId: String
    let name: String
    let sessionType: SessionType
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
    var isUKSession: Bool
    var flagCount: Int
    var status: SessionStatus
    let importedAt: Date
    var fastest1kmTime: TimeInterval?
    var fastest5kmTime: TimeInterval?
    var fastest10kmTime: TimeInterval?

    // MARK: - CodingKeys for JSON backward compatibility

    enum CodingKeys: String, CodingKey {
        case id, stravaId, userId, name
        case sessionType = "activityType"
        case startDate, elapsedTime, movingTime, distance
        case maxSpeed, averageSpeed
        case startLocation, endLocation, polyline
        case isGPSVerified
        case isUKSession = "isUKActivity"
        case flagCount, status, importedAt
        case fastest1kmTime, fastest5kmTime, fastest10kmTime
    }

    // MARK: - Computed Properties

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
        isGPSVerified && isUKSession && status == .verified
    }

    var formattedFastest1km: String? {
        guard let time = fastest1kmTime else { return nil }
        return Self.formatSegmentTime(time)
    }

    var formattedFastest5km: String? {
        guard let time = fastest5kmTime else { return nil }
        return Self.formatSegmentTime(time)
    }

    var formattedFastest10km: String? {
        guard let time = fastest10kmTime else { return nil }
        return Self.formatSegmentTime(time)
    }

    /// Decoded route coordinates from the polyline string
    var decodedRouteCoordinates: [CLLocationCoordinate2D] {
        guard let polyline = polyline else { return [] }
        return PolylineCodec.decode(polyline)
    }

    private static func formatSegmentTime(_ time: TimeInterval) -> String {
        let totalSeconds = Int(time)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// Calculate pace for 1km segment
    func pacePerKm() -> TimeInterval? {
        guard distance > 0 else { return nil }
        return movingTime / distanceKm
    }

    /// Extract best 1km time from session
    func best1kmTime() -> TimeInterval? {
        guard distanceKm >= 1.0 else { return nil }
        return pacePerKm()
    }

    /// Extract best 5km time from session
    func best5kmTime() -> TimeInterval? {
        guard distanceKm >= 5.0 else { return nil }
        guard let pace = pacePerKm() else { return nil }
        return pace * 5
    }

    /// Extract best 10km time from session
    func best10kmTime() -> TimeInterval? {
        guard distanceKm >= 10.0 else { return nil }
        guard let pace = pacePerKm() else { return nil }
        return pace * 10
    }
}

struct Coordinate: Codable, Equatable {
    let latitude: Double
    let longitude: Double

    var clLocation: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

enum SessionType: String, Codable, CaseIterable {
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

    static var eligibleTypes: [SessionType] {
        [.canoeing, .kayaking]
    }

    var isEligible: Bool {
        SessionType.eligibleTypes.contains(self)
    }
}

enum SessionStatus: String, Codable {
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
