import SwiftUI

/// Home screen with Instagram/Strava inspired activity feed
struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var storyViewModel = StoryFeedViewModel()
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Stories strip at the very top
                    if storyViewModel.hasStories {
                        StoriesStripView(stories: storyViewModel.stories) { story in
                            storyViewModel.selectStory(story)
                        }

                        Divider()
                    }

                    latestActivitiesBanner

                    filterSection

                    if viewModel.isLoading {
                        loadingView
                    } else if viewModel.activities.isEmpty {
                        emptyStateView
                    } else {
                        activityFeed
                    }

                    rankingSection
                }
            }
            .navigationTitle("Club Room")
            .refreshable {
                await viewModel.refresh()
                storyViewModel.updateStories(from: viewModel.activities)
            }
            .task {
                await viewModel.loadInitialData()
                storyViewModel.updateStories(from: viewModel.activities)
            }
            .fullScreenCover(isPresented: $storyViewModel.isShowingStoryViewer) {
                if let selectedStory = storyViewModel.selectedStory {
                    StoryViewerView(
                        story: selectedStory,
                        onDismiss: {
                            storyViewModel.dismissStoryViewer()
                        },
                        onMarkSeen: { activityIds in
                            storyViewModel.markActivitiesAsSeen(activityIds, activities: viewModel.activities)
                        }
                    )
                }
            }
        }
    }

    private var latestActivitiesBanner: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.headline)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.recentActivities) { activity in
                        RecentActivityCard(activity: activity)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
    }

    private var filterSection: some View {
        VStack(spacing: 12) {
            Picker("Duration", selection: $viewModel.selectedDuration) {
                ForEach(RaceDuration.allCases) { duration in
                    Text(duration.displayName).tag(duration)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(RaceType.allCases) { type in
                        FilterChip(
                            title: type.displayName,
                            isSelected: viewModel.selectedRaceType == type,
                            action: { viewModel.selectedRaceType = type }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }

    private var activityFeed: some View {
        LazyVStack(spacing: 16) {
            ForEach(viewModel.activities) { activity in
                ActivityCard(activity: activity)
                    .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }

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

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading activities...")
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

            Text("No Activities Yet")
                .font(.headline)

            if appState.isRacer {
                Text("Connect Strava to import your canoe and kayak activities")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                Text("Follow racers to see their activities here")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
    }
}

// MARK: - Supporting Views

struct RecentActivityCard: View {
    let activity: Activity

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: activity.activityType.icon)
                    .foregroundStyle(.accent)

                Text(activity.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
            }

            HStack(spacing: 12) {
                Label(activity.formattedDistance, systemImage: "arrow.left.and.right")
                Label(activity.formattedDuration, systemImage: "clock")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding()
        .frame(width: 180)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct ActivityCard: View {
    let activity: Activity

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay {
                        Image(systemName: activity.activityType.icon)
                            .foregroundStyle(.accent)
                    }

                VStack(alignment: .leading, spacing: 2) {
                    Text(activity.name)
                        .font(.headline)

                    Text(activity.startDate, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if activity.isFlagged {
                    Image(systemName: "flag.fill")
                        .foregroundStyle(.orange)
                }
            }

            HStack(spacing: 20) {
                StatView(title: "Distance", value: activity.formattedDistance)
                StatView(title: "Duration", value: activity.formattedDuration)
                StatView(title: "Max Speed", value: activity.formattedMaxSpeed)
            }

            if let _ = activity.polyline {
                // TODO: Add mini map preview
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray5))
                    .frame(height: 120)
                    .overlay {
                        Image(systemName: "map")
                            .foregroundStyle(.secondary)
                    }
            }

            HStack {
                if activity.isGPSVerified {
                    Label("GPS Verified", systemImage: "checkmark.shield.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }

                if activity.isUKActivity {
                    Label("UK", systemImage: "location.fill")
                        .font(.caption)
                        .foregroundStyle(.accent)
                }

                Spacer()

                Button {
                    // TODO: Implement flag action
                } label: {
                    Image(systemName: "flag")
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}

struct StatView: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color(.systemGray5))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}

struct LeaderboardRow: View {
    let entry: LeaderboardEntry

    var body: some View {
        HStack(spacing: 12) {
            Text("\(entry.rank)")
                .font(.headline)
                .frame(width: 30)
                .foregroundStyle(medalColor)

            Circle()
                .fill(Color(.systemGray5))
                .frame(width: 36, height: 36)
                .overlay {
                    Text(String(entry.userName.prefix(1)))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

            Text(entry.userName)
                .font(.subheadline)

            Spacer()

            Text(entry.formattedScore)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(.vertical, 8)
    }

    private var medalColor: Color {
        switch entry.rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .primary
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(AppState())
}
