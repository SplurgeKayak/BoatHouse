import SwiftUI

/// Main content view that handles navigation based on auth state
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
        // Show splash for a bit while "loading"
        try? await Task.sleep(nanoseconds: 2_000_000_000)

        // For demo purposes, skip auth and show main app with mock data
        appState.currentUser = MockData.racerUser
        appState.isAuthenticated = true
        appState.isLoading = false
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
        .environmentObject(AuthViewModel())
}
