import SwiftUI

@main
struct RacePaceApp: App {
    @StateObject private var appState:      AppState      = AppState()
    @StateObject private var authViewModel: AuthViewModel = AuthViewModel()
    @StateObject private var themeManager:  ThemeManager  = ThemeManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(authViewModel)
                .environmentObject(themeManager)
                // Injects theme tokens for views that read @Environment(\.theme)
                .environment(\.theme, themeManager.current)
                // Overrides system appearance when user picks Light or Dark
                .preferredColorScheme(themeManager.colorSchemeOverride)
                .onAppear {
                    AppState.shared = appState
                }
        }
    }
}
