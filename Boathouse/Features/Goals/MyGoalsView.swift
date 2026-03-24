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
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Progress")
                .font(.headline)

            Picker("Distance", selection: $selectedDistance) {
                ForEach(GoalDistance.allCases, id: \.self) { d in
                    Text(d.label).tag(d)
                }
            }
            .pickerStyle(.segmented)

            WeeklyProgressChartView(sessions: andySessions, distance: selectedDistance)
                .frame(height: 200)
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
}

// MARK: - WeeklyProgressChartView

/// Pure-SwiftUI scatter chart: best pace per week for a chosen distance.
struct WeeklyProgressChartView: View {
    let sessions: [Session]
    let distance: GoalDistance

    private struct WeekPoint: Identifiable {
        let id: Int           // week index (0 = oldest)
        let weekLabel: String
        let bestTime: TimeInterval
    }

    private var points: [WeekPoint] {
        let cal = Calendar.current
        let now = Date()
        var result: [WeekPoint] = []
        for offset in stride(from: -5, through: 0, by: 1) {
            guard let weekStart = cal.date(byAdding: .weekOfYear, value: offset, to: now) else { continue }
            let weekSessions = sessions.filter {
                cal.isDate($0.startDate, equalTo: weekStart, toGranularity: .weekOfYear)
            }
            let times: [TimeInterval] = weekSessions.compactMap { s in
                switch distance {
                case .oneKm:  return s.fastest1kmTime
                case .fiveKm: return s.fastest5kmTime
                case .tenKm:  return s.fastest10kmTime
                }
            }
            if let best = times.min() {
                let formatter = DateFormatter()
                formatter.dateFormat = "d/M"
                result.append(WeekPoint(id: offset + 5, weekLabel: formatter.string(from: weekStart), bestTime: best))
            }
        }
        return result
    }

    var body: some View {
        GeometryReader { geo in
            let pts = points
            if pts.isEmpty {
                Text("No data for selected distance")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                let times = pts.map(\.bestTime)
                let minT = (times.min() ?? 0) * 0.95
                let maxT = (times.max() ?? 1) * 1.05
                let w = geo.size.width
                let h = geo.size.height - 24 // leave room for labels

                ZStack {
                    // Grid lines
                    ForEach(0..<4) { i in
                        let y = h * CGFloat(i) / 3
                        Path { p in
                            p.move(to: CGPoint(x: 0, y: y))
                            p.addLine(to: CGPoint(x: w, y: y))
                        }
                        .stroke(Color(.systemGray5), lineWidth: 1)
                    }

                    // Connecting line
                    Path { p in
                        for (i, pt) in pts.enumerated() {
                            let x = xPos(index: i, count: pts.count, width: w)
                            let y = yPos(time: pt.bestTime, minT: minT, maxT: maxT, height: h)
                            if i == 0 { p.move(to: CGPoint(x: x, y: y)) }
                            else { p.addLine(to: CGPoint(x: x, y: y)) }
                        }
                    }
                    .stroke(Color.accentColor.opacity(0.5), lineWidth: 2)

                    // Dots + week labels
                    ForEach(pts) { pt in
                        let i = pt.id
                        let x = xPos(index: i, count: pts.count, width: w)
                        let y = yPos(time: pt.bestTime, minT: minT, maxT: maxT, height: h)
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 8, height: 8)
                            .position(x: x, y: y)

                        Text(pt.weekLabel)
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                            .position(x: x, y: h + 12)
                    }
                }
            }
        }
    }

    private func xPos(index: Int, count: Int, width: CGFloat) -> CGFloat {
        guard count > 1 else { return width / 2 }
        return width * CGFloat(index) / CGFloat(count - 1)
    }

    private func yPos(time: TimeInterval, minT: TimeInterval, maxT: TimeInterval, height: CGFloat) -> CGFloat {
        guard maxT > minT else { return height / 2 }
        // Faster (lower time) = higher on chart = smaller y
        let ratio = CGFloat((time - minT) / (maxT - minT))
        return height * (1 - ratio)
    }
}

#Preview {
    MyGoalsView()
        .environmentObject(AppState())
}
