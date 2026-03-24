import SwiftUI
import CoreLocation

/// Home screen: Club Room activity feed with stories, filters, and rankings.
/// Goals are shown via the GoalsOverlayView (center target button in bottom nav).
struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var storyViewModel = StoryFeedViewModel()
    @EnvironmentObject var appState: AppState
    @State private var selectedSession: Session?
    @State private var selectedLeaderboardSession: Session?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    headerSection

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
            .refreshable {
                await viewModel.refresh()
                storyViewModel.updateStories(from: viewModel.sessions)
            }
            .task {
                await viewModel.loadInitialData()
                storyViewModel.updateStories(from: viewModel.sessions)
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
            .fullScreenCover(item: $selectedLeaderboardSession) { session in
                let user = MockData.user(for: session.userId)
                ActivityStoryPopup(
                    session: session,
                    athleteName: user?.displayName ?? "Athlete",
                    athleteAvatarURL: user?.profileImageURL
                )
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Race Pace")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Club Room")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    // MARK: - Filters

    private var filterSection: some View {
        VStack(spacing: 16) {
            Picker("Time Period", selection: $viewModel.selectedDuration) {
                ForEach(RaceDuration.allCases) { duration in
                    Text(duration.displayName).tag(duration)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            HStack {
                Spacer()
                ForEach(RaceType.distanceFilters) { type in
                    CircularFilterButton(
                        title: type.shortName,
                        isSelected: viewModel.selectedRaceType == type,
                        action: { viewModel.selectedRaceType = type }
                    )
                    Spacer()
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
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
                        Button {
                            if let sessionId = entry.sessionId {
                                selectedLeaderboardSession = MockData.session(for: sessionId)
                            }
                        } label: {
                            LeaderboardRow(entry: entry)
                        }
                        .buttonStyle(.plain)
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
    @State private var rank1km = ""
    @State private var rank5km = ""
    @State private var rank10km = ""
    @State private var rankDistance = ""
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

                    VStack(alignment: .leading, spacing: 12) {
                        Label("Rank Targets", systemImage: "chart.line.uptrend.xyaxis")
                            .font(.headline)

                        Text("Your target ranking vs all users over the last month")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            rankGoalField(label: "1km Target Rank", text: $rank1km)
                            rankGoalField(label: "5km Target Rank", text: $rank5km)
                            rankGoalField(label: "10km Target Rank", text: $rank10km)
                            rankGoalField(label: "Distance Rank", text: $rankDistance)
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

    private func rankGoalField(label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            HStack(spacing: 4) {
                Text("Top")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                TextField("10", text: text)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
            }
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
        if let r = Int(rank1km), r > 0 {
            goals.append(Goal(category: .rank1km, targetTime: Double(r)))
        }
        if let r = Int(rank5km), r > 0 {
            goals.append(Goal(category: .rank5km, targetTime: Double(r)))
        }
        if let r = Int(rank10km), r > 0 {
            goals.append(Goal(category: .rank10km, targetTime: Double(r)))
        }
        if let r = Int(rankDistance), r > 0 {
            goals.append(Goal(category: .rankDistance, targetTime: Double(r)))
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
