import SwiftUI
import CoreLocation

/// Home screen: state-based goals-first rendering.
/// State A: no goals → inline goal entry.
/// State B: goals saved → goals dashboard + activity feed.
struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var goalsViewModel = GoalsViewModel()
    @StateObject private var storyViewModel = StoryFeedViewModel()
    @EnvironmentObject var appState: AppState
    @State private var showGoalEntry = false
    @State private var selectedSession: Session?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    headerSection

                    if goalsViewModel.hasGoals {
                        // State B: Goals dashboard + activity feed
                        stateB
                    } else {
                        // State A: Goal entry (lightweight, no heavy Strava fetch)
                        stateA
                    }
                }
            }
            .refreshable {
                await viewModel.refresh()
                await goalsViewModel.loadGoals()
                storyViewModel.updateStories(from: viewModel.sessions)
            }
            .task {
                await goalsViewModel.loadGoals()
                if goalsViewModel.hasGoals {
                    await viewModel.loadInitialData()
                    storyViewModel.updateStories(from: viewModel.sessions)
                }
            }
            .sheet(isPresented: $showGoalEntry) {
                GoalEntrySheet { goals in
                    Task { await goalsViewModel.saveAndReload(goals) }
                    // Also load activity data now that goals exist
                    Task {
                        await viewModel.loadInitialData()
                        storyViewModel.updateStories(from: viewModel.sessions)
                    }
                    appState.hasCompletedGoals = true
                }
            }
            .fullScreenCover(item: $selectedSession) { session in
                ActivityDetailView(
                    session: session,
                    activeFilter: viewModel.selectedRaceType
                )
            }
            .fullScreenCover(isPresented: $storyViewModel.isShowingStoryViewer) {
                if let selectedStory = storyViewModel.selectedStory {
                    StoryViewerView(
                        story: selectedStory,
                        onDismiss: { storyViewModel.dismissStoryViewer() },
                        onMarkSeen: { ids in storyViewModel.markSessionsAsSeen(ids, sessions: viewModel.sessions) }
                    )
                }
            }
        }
    }

    // MARK: - Header with My Goals icon

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Race Pace")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text(goalsViewModel.hasGoals ? "Your Goals" : "Club Room")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // My Goals icon — always returns to goals dashboard
            Button {
                if goalsViewModel.hasGoals {
                    // Scroll to top / already on goals
                } else {
                    showGoalEntry = true
                }
            } label: {
                Image(systemName: "target")
                    .font(.title2)
                    .foregroundStyle(AppColors.accent)
            }
        }
        .padding(.horizontal)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    // MARK: - State A: No goals — lightweight entry

    private var stateA: some View {
        VStack(spacing: 24) {
            // Inline goal entry prompt
            VStack(spacing: 16) {
                Image(systemName: "flag.checkered")
                    .font(.system(size: 48))
                    .foregroundStyle(AppColors.accent)

                Text("Set Your Paddling Goals")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Track your progress with personal time targets for 1km, 5km, and 10km distances.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button {
                    showGoalEntry = true
                } label: {
                    Text("Set Goals")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColors.accent)
            }
            .padding(24)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
            .padding(.horizontal)
            .padding(.top, 20)
        }
    }

    // MARK: - State B: Goals dashboard + feed

    private var stateB: some View {
        VStack(spacing: 0) {
            // Goals dashboard
            GoalsDashboardView(
                viewModel: goalsViewModel,
                showGoalEntry: $showGoalEntry
            )

            Divider()
                .padding(.vertical, 8)

            // Stories strip
            if storyViewModel.hasStories {
                StoriesStripView(stories: storyViewModel.stories) { story in
                    storyViewModel.selectStory(story)
                }
                Divider()
            }

            // Filters
            filterSection

            // Activity feed
            if viewModel.isLoading {
                loadingView
            } else if viewModel.filteredSessions.isEmpty {
                emptyStateView
            } else {
                sessionFeed
            }

            // Rankings
            rankingSection
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

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(RaceType.distanceFilters) { type in
                        FilterChip(
                            title: type.shortName,
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

    // MARK: - Redesigned session feed

    private var sessionFeed: some View {
        LazyVStack(spacing: 16) {
            ForEach(viewModel.filteredSessions) { session in
                SessionCard(
                    session: session,
                    activeFilter: viewModel.selectedRaceType
                )
                .padding(.horizontal)
                .onTapGesture {
                    selectedSession = session
                }
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
            Text("Connect Strava to import your canoe and kayak sessions")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
}

// MARK: - Goal Entry Sheet

/// Sheet wrapper for goal entry that creates Goal objects.
struct GoalEntrySheet: View {
    let onSave: ([Goal]) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var time1k = ""
    @State private var time5k = ""
    @State private var time10k = ""
    @State private var showError = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Image(systemName: "flag.checkered")
                            .font(.system(size: 44))
                            .foregroundStyle(AppColors.accent)

                        Text("Set your paddling goals")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Enter target times as M:SS (e.g. 4:30)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Label("Time Goals", systemImage: "timer")
                            .font(.headline)

                        HStack(spacing: 12) {
                            goalField(label: "1km", text: $time1k)
                            goalField(label: "5km", text: $time5k)
                            goalField(label: "10km", text: $time10k)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    Button {
                        save()
                    } label: {
                        Text("Save Goals")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppColors.accent)
                    .alert("Enter at least one goal time.", isPresented: $showError) {
                        Button("OK", role: .cancel) {}
                    }
                }
                .padding()
            }
            .navigationTitle("Your Goals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func goalField(label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            TextField("M:SS", text: text)
                .keyboardType(.numbersAndPunctuation)
                .textFieldStyle(.roundedBorder)
        }
    }

    private func save() {
        var goals: [Goal] = []

        if let t = KayakingGoals.parseTimeString(time1k) {
            goals.append(Goal(category: .fastest1km, targetTime: t))
        }
        if let t = KayakingGoals.parseTimeString(time5k) {
            goals.append(Goal(category: .fastest5km, targetTime: t))
        }
        if let t = KayakingGoals.parseTimeString(time10k) {
            goals.append(Goal(category: .fastest10km, targetTime: t))
        }

        guard !goals.isEmpty else {
            showError = true
            return
        }

        onSave(goals)
        dismiss()
    }
}

#Preview {
    HomeView()
        .environmentObject(AppState())
}
