import SwiftUI

extension Color {
    /// Dark navy background used throughout the app in dark mode.
    /// Hex #07122A  (R:7 G:18 B:42)
    static let darkNavyBackground = Color(red: 7/255, green: 18/255, blue: 42/255)

    // MARK: - Light theme tokens
    static let lightBackground  = Color.white
    static let lightBodyText    = Color.black
    /// Strava orange #FC4C02 — used as title / heading accent in light mode.
    static let lightTitleText   = Color(red: 252/255, green: 76/255, blue: 2/255)

    // MARK: - Dark theme tokens
    /// Alias for darkNavyBackground for use as the dark-mode canvas colour.
    static let darkBackground   = Color(red: 7/255, green: 18/255, blue: 42/255)
    static let darkBodyText     = Color.white
    /// Strava orange #FC4C02 — remains visible on dark navy background.
    static let darkTitleText    = Color(red: 252/255, green: 76/255, blue: 2/255)
}
