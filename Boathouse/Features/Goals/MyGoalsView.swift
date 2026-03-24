import SwiftUI

// MARK: - MyGoalsView

/// Full-page Goals tab: PB summary cards + weekly progress chart + set-goals CTA
struct MyGoalsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingSetGoals = false
    @State private var selectedDistance: GoalDistance = .oneKm

    private let store = GoalsStore.shared
    private var goals: KayakingGoals { store.load() ?? KayakingGoals() }
    private var andySessions: [Session] {
        MockData.sessions.filter { $0.userId == "andy-001" }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    pbCardsSection
                    chartSection
                    entriesLinkSection
                }
                .padding()
            }
            .navigationTitle("My Goals")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Edit Goals") { showingSetGoals = true }
                }
            }
            .sheet(isPresented: $showingSetGoals) {
                YourGoalsView().environmentObject(appState)
            }
        }
    }

    // MARK: - PB Cards

    private var pbCardsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Personal Bests vs Goals")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    PBCard(
                        label: "1 km",
                        goalTime: goals.timeGoal1k,
                        bestTime: GoalProgressCalculator.best1k(from: andySessions)
                    )
                    PBCard(
                        label: "5 km",
                        goalTime: goals.timeGoal5k,
                        bestTime: GoalProgressCalculator.best5k(from: andySessions)
                    )
                    PBCard(
                        label: "10 km",
                        goalTime: goals.timeGoal10k,
                        bestTime: GoalProgressCalculator.best10k(from: andySessions)
                    )
                }
            }
        }
    }

    // MARK: - Chart

    private var chartSection: some View {
        let pts = GoalProgressCalculator.dataPoints(for: selectedDistance, from: andySessions)
        let goalPace = GoalProgressCalculator.goalPace(for: selectedDistance, goals: goals)
        let benchmark = BenchmarkService.categoryBenchmark(
            for: selectedDistance,
            category: appState.currentUser?.raceCategory ?? .seniorMen,
            allSessions: MockData.sessions,
            allUsers: MockData.users
        )

        return VStack(alignment: .leading, spacing: 12) {
            Text("Performance History")
                .font(.headline)

            Picker("Distance", selection: $selectedDistance) {
                ForEach(GoalDistance.allCases, id: \.self) { d in
                    Text(d.label).tag(d)
                }
            }
            .pickerStyle(.segmented)

            RacePerformanceChart(
                distanceLabel: selectedDistance.label,
                dataPoints: pts,
                goalPace: goalPace,
                categoryBenchmark: benchmark
            )
            .frame(height: 240)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    // MARK: - Race Entries Link

    private var entriesLinkSection: some View {
        NavigationLink {
            EntryView()
        } label: {
            HStack {
                Label("My Race Entries", systemImage: "list.bullet.clipboard")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - PBCard

private struct PBCard: View {
    let label: String
    let goalTime: TimeInterval?
    let bestTime: TimeInterval?

    private var delta: TimeInterval? {
        guard let g = goalTime, let b = bestTime else { return nil }
        return b - g  // negative = ahead of goal
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            if let best = bestTime {
                Text(formatTime(best))
                    .font(.title2)
                    .fontWeight(.bold)
                    .monospacedDigit()
            } else {
                Text("–")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
            }

            if let d = delta {
                Text(deltaLabel(d))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(d <= 0 ? Color.green : Color.orange)
            } else if goalTime == nil {
                Text("No goal set")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(width: 110)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.06), radius: 6, y: 3)
    }

    private func formatTime(_ t: TimeInterval) -> String {
        let mins = Int(t) / 60
        let secs = Int(t) % 60
        return String(format: "%d:%02d", mins, secs)
    }

    private func deltaLabel(_ d: TimeInterval) -> String {
        let abs = Swift.abs(d)
        let mins = Int(abs) / 60
        let secs = Int(abs) % 60
        let sign = d <= 0 ? "-" : "+"
        return "\(sign)\(mins > 0 ? "\(mins)m " : "")\(secs)s"
    }
}

// MARK: - GoalDistance

enum GoalDistance: CaseIterable {
    case oneKm, fiveKm, tenKm

    var label: String {
        switch self {
        case .oneKm:  return "1 km"
        case .fiveKm: return "5 km"
        case .tenKm:  return "10 km"
        }
    }

    init(raceType: RaceType) {
        switch raceType {
        case .fastest1km:  self = .oneKm
        case .fastest5km:  self = .fiveKm
        case .fastest10km: self = .tenKm
        }
    }
}

#Preview {
    MyGoalsView()
        .environmentObject(AppState())
}
