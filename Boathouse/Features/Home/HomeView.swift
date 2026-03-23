import SwiftUI
import CoreLocation

/// Home screen with Instagram/Strava inspired session feed
struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var storyViewModel = StoryFeedViewModel()
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingGoals = false
    @State private var selectedSession: Session? = nil

    var body: some View {
        ZStack(alignment: .bottom) {
            NavigationStack {
                ScrollView {

                    VStack(spacing: 0) {
                        // App headers
                        headerSection

                        // Stories strip
                        if storyViewModel.hasStories {
                            StoriesStripView(stories: storyViewModel.stories) { story in
                                storyViewModel.selectStory(story)
                            }

                            Divider()
                        }

                        if viewModel.isLoading {
                            loadingView
                        } else if viewModel.chronologicalSessions.isEmpty {
                            emptyStateView
                        } else {
                            sessionFeed
                        }

                        rankingSection

                        Spacer().frame(height: 80)
                    }
                }
                .background(colorScheme == .dark ? Color.darkNavyBackground : Color.lightBackground)
                .refreshable {
                    await viewModel.refresh()
                    storyViewModel.updateStories(from: viewModel.sessions)
                }
                .task {
                    await viewModel.loadInitialData()
                    storyViewModel.updateStories(from: viewModel.sessions)
                }
                .sheet(item: $selectedSession) { session in
                    SessionDetailSheet(
                        session: session,
                        userName: viewModel.userName(for: session.userId),
                        userAvatarURL: viewModel.userAvatarURL(for: session.userId)
                    )
                    .environmentObject(appState)
                }
                .fullScreenCover(isPresented: $storyViewModel.isShowingStoryViewer) {
                    if let selectedStory = storyViewModel.selectedStory {
                        StoryViewerView(
                            story: selectedStory,
                            onDismiss: {
                                storyViewModel.dismissStoryViewer()
                            },
                            onMarkSeen: { sessionIds in
                                storyViewModel.markSessionsAsSeen(sessionIds, sessions: viewModel.sessions)
                            }
                        )
                    }
                }
            }

            goalsFloatingButton
                .padding(.bottom, 8)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Race Pace")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(colorScheme == .dark ? Color.darkTitleText : Color.lightTitleText)

            Text("Club Room")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            Text("Race Pace lets you share your sessions, race & compare efforts with the community to see how you stack up and improve against paddlers like you.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    // MARK: - Chronological session feed

    private var sessionFeed: some View {
        LazyVStack(spacing: 12) {
            ForEach(viewModel.chronologicalSessions) { session in
                SessionRow(
                    session: session,
                    userName: viewModel.userName(for: session.userId),
                    userAvatarURL: viewModel.userAvatarURL(for: session.userId)
                ) {
                    selectedSession = session
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }

    // MARK: - Rankings

    private var rankingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Rankings")
                    .font(.headline)

                Spacer()

                NavigationLink("See All") {
                    LeaderboardView(
                        duration: .weekly,
                        raceType: .fastest1km
                    )
                }
                .font(.subheadline)
            }
            .padding(.horizontal)

            if let leaderboard = viewModel.currentLeaderboard {
                VStack(spacing: 8) {
                    ForEach(leaderboard.topThree) { entry in
                        LeaderboardRow(entry: entry)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
    }

    // MARK: - States

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading sessions...")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.water.fitness")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No Sessions Yet")
                .font(.headline)

            if appState.isRacer {
                Text("Connect Garmin to import your canoe and kayak sessions")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                Text("Follow racers to see their sessions here")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
    }

    // MARK: - Goals Floating Button

    private var goalsFloatingButton: some View {
        Button {
            showingGoals = true
        } label: {
            VStack(spacing: 4) {
                Image(systemName: "target")
                    .font(.system(size: 22, weight: .semibold))
                Text("Goals")
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(.white)
            .frame(width: 72, height: 56)
            .background(Color.accentColor.opacity(0.5))
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
        }
        .accessibilityLabel("Goals")
        .accessibilityValue("Primary action")
        .sheet(isPresented: $showingGoals) {
            if GoalsStore.shared.load() != nil {
                GoalProgressView()
                    .environmentObject(appState)
            } else {
                YourGoalsView()
                    .environmentObject(appState)
            }
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(AppState())
}
