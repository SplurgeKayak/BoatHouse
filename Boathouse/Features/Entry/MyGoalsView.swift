import SwiftUI

/// Strava-style progress portal for 1km, 5km, and 10km goals.
/// Replaces EntryView as the tab root; EntryView is accessible as a sub-link.
struct MyGoalsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingEditGoals = false

    private let store = GoalsStore.shared
    private var goals: KayakingGoals { store.load() ?? KayakingGoals() }

    private var currentUserId: String { appState.currentUser?.id ?? "andy-001" }

    private var userSessions: [Session] {
        MockData.sessions.filter { $0.userId == currentUserId }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    pbCardsSection
                    weeklyChartSection
                    distanceGoalsSection
                    navigationLinks
                }
                .padding(.bottom, 32)
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingEditGoals) {
                YourGoalsView()
                    .environmentObject(appState)
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("My Goals")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(Color(red: 252/255, green: 76/255, blue: 2/255))

            Text("Your paddling progress")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .padding(.top, 12)
    }

    // MARK: - PB Cards

    private var pbCardsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Personal Bests")
                .font(.headline)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    PBCard(
                        distance: "1km",
                        icon: "1.circle.fill",
                        best: GoalProgressCalculator.best1k(from: userSessions),
                        goal: goals.timeGoal1k,
                        onSetGoal: { showingEditGoals = true }
                    )
                    PBCard(
                        distance: "5km",
                        icon: "5.circle.fill",
                        best: GoalProgressCalculator.best5k(from: userSessions),
                        goal: goals.timeGoal5k,
                        onSetGoal: { showingEditGoals = true }
                    )
                    PBCard(
                        distance: "10km",
                        icon: "10.circle.fill",
                        best: GoalProgressCalculator.best10k(from: userSessions),
                        goal: goals.timeGoal10k,
                        onSetGoal: { showingEditGoals = true }
                    )
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Weekly Chart

    private var weeklyChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Progress")
                .font(.headline)
                .padding(.horizontal)

            WeeklyProgressChartView(sessions: userSessions)
                .padding(.horizontal)
        }
    }

    // MARK: - Distance Goals

    private var distanceGoalsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Time Goals")
                .font(.headline)
                .padding(.horizontal)

            VStack(spacing: 12) {
                if let goal1k = goals.timeGoal1k {
                    GoalProgressRow(
                        label: "1 km",
                        goalTime: goal1k,
                        bestTime: GoalProgressCalculator.best1k(from: userSessions)
                    )
                } else {
                    AddGoalRow(label: "1 km") { showingEditGoals = true }
                }

                if let goal5k = goals.timeGoal5k {
                    GoalProgressRow(
                        label: "5 km",
                        goalTime: goal5k,
                        bestTime: GoalProgressCalculator.best5k(from: userSessions)
                    )
                } else {
                    AddGoalRow(label: "5 km") { showingEditGoals = true }
                }

                if let goal10k = goals.timeGoal10k {
                    GoalProgressRow(
                        label: "10 km",
                        goalTime: goal10k,
                        bestTime: GoalProgressCalculator.best10k(from: userSessions)
                    )
                } else {
                    AddGoalRow(label: "10 km") { showingEditGoals = true }
                }
            }
            .padding(.horizontal)

            Button("Set / Edit Goals") { showingEditGoals = true }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
        }
    }

    // MARK: - Navigation Links

    private var navigationLinks: some View {
        VStack(spacing: 1) {
            Divider()
                .padding(.horizontal)

            NavigationLink {
                EntryView()
                    .environmentObject(appState)
            } label: {
                HStack {
                    Image(systemName: "list.bullet.clipboard")
                        .foregroundStyle(.accent)
                        .frame(width: 28)

                    Text("My Race Entries")
                        .font(.body)
                        .foregroundStyle(.primary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                .padding(.vertical, 14)
            }

            Divider()
                .padding(.horizontal)
        }
    }
}

// MARK: - PB Card

struct PBCard: View {
    let distance: String
    let icon: String
    let best: TimeInterval?
    let goal: TimeInterval?
    let onSetGoal: () -> Void

    private var delta: TimeInterval? {
        guard let b = best, let g = goal else { return nil }
        return b - g
    }

    private var deltaColor: Color {
        guard let d = delta else { return .secondary }
        return d <= 0 ? .green : .orange
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.accent)

                Spacer()

                Text(distance)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }

            if let best = best {
                Text(KayakingGoals.formatTime(best))
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Personal Best")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                if let goal = goal {
                    Text("Goal: \(KayakingGoals.formatTime(goal))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    if let d = delta {
                        Text(d <= 0 ? "-\(KayakingGoals.formatTime(abs(d)))" : "+\(KayakingGoals.formatTime(d))")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(deltaColor)
                    }
                } else {
                    Button("Set goal") { onSetGoal() }
                        .font(.caption)
                        .foregroundStyle(.accent)
                }
            } else {
                Text("—")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)

                Text("No data yet")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(width: 140)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.06), radius: 6, y: 3)
    }
}

#Preview {
    MyGoalsView()
        .environmentObject(AppState())
}
