import SwiftUI

// MARK: - Appearance Enum

enum AppAppearance: String, CaseIterable, Identifiable {
    case system = "System"
    case light  = "Light"
    case dark   = "Dark"

    var id: String { rawValue }

    var colorSchemeOverride: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }

    var icon: String {
        switch self {
        case .system: return "iphone"
        case .light:  return "sun.max.fill"
        case .dark:   return "moon.fill"
        }
    }
}

// MARK: - Theme Token Struct

struct AppTheme {
    let background:          Color
    let secondaryBackground: Color
    let cardBackground:      Color
    let primaryText:         Color
    let secondaryText:       Color
    let accent:              Color
    let divider:             Color
}

// MARK: - Concrete Themes

extension AppTheme {
    /// Matches the current light app — white cards, orange accents
    static let light = AppTheme(
        background:          Color(hex: "#F2F2F7"),
        secondaryBackground: Color(hex: "#FFFFFF"),
        cardBackground:      Color(hex: "#FFFFFF"),
        primaryText:         Color(hex: "#000000"),
        secondaryText:       Color(hex: "#6C6C70"),
        accent:              Color(hex: "#F05C00"),
        divider:             Color(hex: "#C6C6C8")
    )

    /// Matches the website hero — deep navy, orange CTA, white text
    static let dark = AppTheme(
        background:          Color(hex: "#0D1B2A"),
        secondaryBackground: Color(hex: "#1C2E40"),
        cardBackground:      Color(hex: "#1C2E40"),
        primaryText:         Color(hex: "#F5F5F5"),
        secondaryText:       Color(hex: "#8E9BB0"),
        accent:              Color(hex: "#F05C00"),
        divider:             Color(hex: "#2A3F55")
    )
}

// MARK: - Theme Manager

/// Stores the user's appearance choice and exposes the active theme tokens.
/// Injected as an @EnvironmentObject from the app entry point.
final class ThemeManager: ObservableObject {
    /// Persisted across launches via @AppStorage
    @AppStorage("appAppearance") var appearance: AppAppearance = .system

    /// Pass this to .preferredColorScheme() on your root view
    var colorSchemeOverride: ColorScheme? {
        appearance.colorSchemeOverride
    }

    /// The current token set — use this in views instead of hard-coded colors
    var current: AppTheme {
        switch appearance {
        case .system:
            return systemPrefersDark ? .dark : .light
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }

    // Reads the device's current interface style to inform .system behavior
    private var systemPrefersDark: Bool {
        UITraitCollection.current.userInterfaceStyle == .dark
    }
}

// MARK: - Environment Key

private struct ThemeKey: EnvironmentKey {
    static let defaultValue = AppTheme.light
}

extension EnvironmentValues {
    var theme: AppTheme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

// MARK: - Color(hex:) Helper

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double(int & 0xFF)          / 255
        self.init(red: r, green: g, blue: b)
    }
}
