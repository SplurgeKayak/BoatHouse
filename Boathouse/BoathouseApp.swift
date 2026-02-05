import SwiftUI

@main
struct BoathouseApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(authViewModel)
                .task {
                    // Set shared reference on MainActor
                    AppState.shared = appState
                }
        }
    }
}
