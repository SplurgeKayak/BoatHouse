import SwiftUI

/// Shows Andy's goal progress vs his mock Garmin sessions.
struct GoalProgressView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    @State private var showingEditGoals = false

    private let store = GoalsStore.shared
    private var goals: KayakingGoals { store.load() ?? KayakingGoals() }

    /// Andy's sessions from mock data
    private var andySessions: [Session] {
        MockData.sessions.filter { $0.userId == "andy-001" }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    goalRows
                    editGoalsButton
                }
                .padding(24)
            }
            .navigationTitle("My Goals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .sheet(isPresented: $showingEditGoals) {
                YourGoalsView()
                    .environmentObject(appState)
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "target")
                .font(.system(size: 44))
                .foregroundStyle(.accent)
            Text("Your Progress")
                .font(.title2)
                .fontWeight(.bold)
            Text("Based on your Garmin session data")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Goal rows

    private var goalRows: some View {
        VStack(spacing: 16) {
            if let goal1k = goals.timeGoal1k {
                GoalProgressRow(
                    label: "1 km",
                    goalTime: goal1k,
                    bestTime: GoalProgressCalculator.best1k(from: andySessions)
                )
            } else {
                AddGoalRow(label: "1 km") { showingEditGoals = true }
            }

            if let goal5k = goals.timeGoal5k {
                GoalProgressRow(
                    label: "5 km",
                    goalTime: goal5k,
                    bestTime: GoalProgressCalculator.best5k(from: andySessions)
                )
            } else {
                AddGoalRow(label: "5 km") { showingEditGoals = true }
            }

            if let goal10k = goals.timeGoal10k {
                GoalProgressRow(
                    label: "10 km",
                    goalTime: goal10k,
                    bestTime: GoalProgressCalculator.best10k(from: andySessions)
                )
            } else {
                AddGoalRow(label: "10 km") { showingEditGoals = true }
            }
        }
    }

    private var editGoalsButton: some View {
        Button("Edit Goals") { showingEditGoals = true }
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }
}

// MARK: - GoalProgressRow

struct GoalProgressRow: View {
    let label: String
    let goalTime: TimeInterval
    let bestTime: TimeInterval?

    private var status: GoalProgressCalculator.Status {
        GoalProgressCalculator.status(goal: goalTime, best: bestTime)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(label)
                    .font(.headline)
                Spacer()
                statusBadge
            }

            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Goal")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(KayakingGoals.formatTime(goalTime))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Your Best")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(bestTime.map { KayakingGoals.formatTime($0) } ?? "No data yet")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(bestTime == nil ? .secondary : .primary)
                }

                if let best = bestTime {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Gap")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        let diff = best - goalTime
                        Text(diff <= 0
                             ? "-\(KayakingGoals.formatTime(abs(diff)))"
                             : "+\(KayakingGoals.formatTime(diff))")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(diff <= 0 ? .green : .orange)
                    }
                }
            }

            if let best = bestTime {
                ProgressView(value: min(goalTime / best, 1.5), total: 1.5)
                    .tint(status.color)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var statusBadge: some View {
        Text(status.label)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(status.color.opacity(0.15))
            .foregroundStyle(status.color)
            .clipShape(Capsule())
    }
}

// MARK: - AddGoalRow

struct AddGoalRow: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(label)
                    .font(.headline)
                Spacer()
                Image(systemName: "plus.circle")
                    .foregroundStyle(.accent)
                Text("Add goal")
                    .font(.subheadline)
                    .foregroundStyle(.accent)
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    GoalProgressView()
        .environmentObject(AppState())
}
