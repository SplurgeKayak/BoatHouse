import Foundation

/// App-wide configuration
enum AppConfig {

    // MARK: - API Configuration

    /// Base URL for the backend API
    /// TODO: Update with actual production URL
    static let apiBaseURL = "https://api.boathouse.app/v1"

    /// API timeout in seconds
    static let apiTimeout: TimeInterval = 30

    // MARK: - Strava Configuration

    /// Strava OAuth client ID
    /// TODO: Replace with actual Strava app credentials
    static let stravaClientId = "YOUR_STRAVA_CLIENT_ID"

    /// Strava OAuth client secret
    /// TODO: Store securely, not in source code
    static let stravaClientSecret = "YOUR_STRAVA_CLIENT_SECRET"

    /// Strava OAuth redirect URI
    static let stravaRedirectURI = "boathouse://strava-callback"

    // MARK: - Apple Pay Configuration

    /// Apple Pay merchant identifier
    /// TODO: Configure in Apple Developer Portal
    static let merchantIdentifier = "merchant.com.boathouse.app"

    // MARK: - Race Configuration

    /// Minimum hours before race end to allow entry
    static let entryDeadlineHours = 3

    /// Prize pool percentage distribution
    static let prizeDistribution = (
        first: Decimal(0.75),
        second: Decimal(0.20),
        third: Decimal(0.05)
    )

    /// Platform fee percentage
    static let platformFeePercentage = Decimal(0.01)

    /// Flag threshold for admin review
    static let flagReviewThreshold = 3

    // MARK: - Feature Flags

    /// Enable/disable features for gradual rollout
    struct Features {
        static let enableApplePay = true
        static let enableCalendarReminders = true
        static let enablePushNotifications = true
    }
}

// MARK: - App Environment

enum AppEnvironment {
    case development
    case staging
    case production

    static var current: AppEnvironment {
        #if DEBUG
        return .development
        #else
        return .production
        #endif
    }

    var apiBaseURL: String {
        switch self {
        case .development:
            return "http://localhost:3000/v1"
        case .staging:
            return "https://staging-api.boathouse.app/v1"
        case .production:
            return "https://api.boathouse.app/v1"
        }
    }
}
