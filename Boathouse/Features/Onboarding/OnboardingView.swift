import SwiftUI

/// Onboarding flow for new users
struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "figure.rowing",
            title: "Welcome to Race Pace",
            description: "The UK's digital canoe and kayak racing platform. Compete for real prizes using your Strava sessions."
        ),
        OnboardingPage(
            icon: "link",
            title: "Connect Strava",
            description: "Link your Strava account to automatically import your canoe and kayak sessions."
        ),
        OnboardingPage(
            icon: "trophy.fill",
            title: "Enter Races",
            description: "Compete in daily, weekly, and monthly races. Win real prize money based on your performance."
        ),
        OnboardingPage(
            icon: "location.fill",
            title: "UK Sessions Only",
            description: "Only GPS-verified sessions completed in the United Kingdom qualify for races."
        )
    ]

    var body: some View {
        VStack {
            TabView(selection: $currentPage) {
                ForEach(pages.indices, id: \.self) { index in
                    OnboardingPageView(page: pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            VStack(spacing: 16) {
                if currentPage == pages.count - 1 {
                    Button {
                        appState.showOnboarding = false
                    } label: {
                        Text("Get Started")
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                } else {
                    Button {
                        withAnimation {
                            currentPage += 1
                        }
                    } label: {
                        Text("Next")
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }

                if currentPage < pages.count - 1 {
                    Button("Skip") {
                        appState.showOnboarding = false
                    }
                    .foregroundStyle(.secondary)
                }
            }
            .padding(24)
        }
    }
}

struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
}

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: page.icon)
                .font(.system(size: 80))
                .foregroundStyle(.accent)

            VStack(spacing: 16) {
                Text(page.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text(page.description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppState())
}
