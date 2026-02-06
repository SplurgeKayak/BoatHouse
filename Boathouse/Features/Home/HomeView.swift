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

                    filterSection

                    if viewModel.isLoading {
                        loadingView
                    } else if viewModel.filteredActivities.isEmpty {
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

    // MARK: - Unified activity feed

    private var activityFeed: some View {
        LazyVStack(spacing: 16) {
            ForEach(viewModel.filteredActivities) { activity in
                ActivityCard(activity: activity)
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

            // Core stats
            HStack(spacing: 20) {
                StatView(title: "Distance", value: activity.formattedDistance)
                StatView(title: "Duration", value: activity.formattedDuration)
            }

            // Segment times (only rows that have data)
            let segments = segmentStats
            if !segments.isEmpty {
                HStack(spacing: 20) {
                    ForEach(segments, id: \.title) { stat in
                        StatView(title: stat.title, value: stat.value)
                    }
                }
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

    private var segmentStats: [(title: String, value: String)] {
        var stats: [(title: String, value: String)] = []
        if let t = activity.formattedFastest1km  { stats.append(("Fastest 1km", t)) }
        if let t = activity.formattedFastest5km  { stats.append(("Fastest 5km", t)) }
        if let t = activity.formattedFastest10km { stats.append(("Fastest 10km", t)) }
        return stats
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

            AvatarView(
                url: entry.userProfileURL,
                initials: String(entry.userName.prefix(1)),
                id: entry.userId,
                size: 36
            )

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
