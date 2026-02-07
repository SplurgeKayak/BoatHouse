import SwiftUI
import CoreLocation

/// Home screen with Instagram/Strava inspired session feed
struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var storyViewModel = StoryFeedViewModel()
    @EnvironmentObject var appState: AppState

    var body: some View {
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

                    filterSection

                    if viewModel.isLoading {
                        loadingView
                    } else if viewModel.filteredSessions.isEmpty {
                        emptyStateView
                    } else {
                        sessionFeed
                    }

                    rankingSection
                }
            }
            .refreshable {
                await viewModel.refresh()
                storyViewModel.updateStories(from: viewModel.sessions)
            }
            .task {
                await viewModel.loadInitialData()
                storyViewModel.updateStories(from: viewModel.sessions)
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
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Race Pace")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Club Room")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    // MARK: - Filters

    private var filterSection: some View {
        VStack(spacing: 12) {
            Picker("Time Period", selection: $viewModel.selectedDuration) {
                ForEach(RaceDuration.allCases) { duration in
                    Text(duration.displayName).tag(duration)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .accessibilityLabel("Time period filter")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(RaceType.distanceFilters) { type in
                        FilterChip(
                            title: type.shortName,
                            isSelected: viewModel.selectedRaceType == type,
                            action: { viewModel.selectedRaceType = type }
                        )
                        .accessibilityLabel("Sort by \(type.displayName)")
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }

    // MARK: - Unified session feed

    private var sessionFeed: some View {
        LazyVStack(spacing: 16) {
            ForEach(viewModel.filteredSessions) { session in
                SessionCard(session: session)
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
                        duration: viewModel.selectedDuration,
                        raceType: viewModel.selectedRaceType
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
            Image(systemName: "figure.rowing")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No Sessions Yet")
                .font(.headline)

            if appState.isRacer {
                Text("Connect Strava to import your canoe and kayak sessions")
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
}

#Preview {
    HomeView()
        .environmentObject(AppState())
}
