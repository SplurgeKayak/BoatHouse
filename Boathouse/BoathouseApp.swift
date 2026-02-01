import SwiftUI

@main
struct BoathouseApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(authViewModel)
        }
    }
}
