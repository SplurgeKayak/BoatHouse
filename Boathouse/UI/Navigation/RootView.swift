import SwiftUI

/// Root view handling authentication state and main navigation
struct RootView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        Group {
            if appState.isLoading {
                LaunchScreen()
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
            await authViewModel.checkAuthState()
        }
    }
}

struct LaunchScreen: View {
    var body: some View {
        ZStack {
            Color.accentColor
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "figure.rowing")
                    .font(.system(size: 80))
                    .foregroundStyle(.white)

                Text("Race Pace")
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
    RootView()
        .environmentObject(AppState())
        .environmentObject(AuthViewModel())
}
