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
        // Simulate initial loading
        try? await Task.sleep(nanoseconds: 500_000_000)

        // For demo purposes, skip auth and show main app with mock data
        appState.currentUser = MockData.racerUser
        appState.isAuthenticated = true
        appState.isLoading = false
    }
}

/// Launch screen shown during app initialization
struct LaunchScreenView: View {
    var body: some View {
        ZStack {
            Color.accentColor
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "figure.rowing")
                    .font(.system(size: 80))
                    .foregroundStyle(.white)

                Text("Boathouse")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                ProgressView()
                    .tint(.white)
                    .padding(.top, 32)
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
        .environmentObject(AuthViewModel())
}
