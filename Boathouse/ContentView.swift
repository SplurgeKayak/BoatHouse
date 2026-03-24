import SwiftUI
import os.signpost

private let launchLog = OSLog(subsystem: "com.boathouse.app", category: "Launch")

/// Main content view that handles navigation based on auth state.
/// Goals overlay is now inside MainTabView, not a separate splash phase.
struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        Group {
            if appState.isLoading {
                LaunchScreenView()
            } else if !appState.isAuthenticated {
                AuthenticationView()
            } else if appState.showOnboarding {
                OnboardingView()
            } else {
                MainTabView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appState.isAuthenticated)
        .task {
            await checkInitialState()
        }
    }

    @MainActor
    private func checkInitialState() async {
        os_signpost(.begin, log: launchLog, name: "checkInitialState")

        // Load mock user off the main actor's critical path
        let user = await Task.detached(priority: .userInitiated) {
            os_signpost(.begin, log: launchLog, name: "MockData.init")
            let u = MockData.racerUser
            os_signpost(.end, log: launchLog, name: "MockData.init")
            return u
        }.value

        // Brief splash so the animation is visible (≤0.6s vs old 2s)
        try? await Task.sleep(nanoseconds: 600_000_000)

        appState.currentUser = user
        appState.isAuthenticated = true
        appState.isLoading = false

        os_signpost(.end, log: launchLog, name: "checkInitialState")
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
        .environmentObject(AuthViewModel())
}
