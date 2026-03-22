import SwiftUI

@main
struct RacePaceApp: App {
    @StateObject private var appState: AppState = AppState()
    @StateObject private var authViewModel: AuthViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(authViewModel)
                .preferredColorScheme(appState.preferredColorScheme)
                .onAppear {
                    AppState.shared = appState
                }
        }
    }
}
