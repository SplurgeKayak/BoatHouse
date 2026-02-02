import SwiftUI

@main
struct BoathouseApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var authViewModel = AuthViewModel()

    init() {
        // Store reference for global access
        AppState.shared = nil // Will be set after StateObject init
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(authViewModel)
                .onAppear {
                    AppState.shared = appState
                }
        }
    }
}
