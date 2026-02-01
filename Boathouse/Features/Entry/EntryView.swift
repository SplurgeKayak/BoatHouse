import SwiftUI

/// My Entries screen showing user's race entries
struct EntryView: View {
    @StateObject private var viewModel = EntryViewModel()
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationStack {
            Group {
                if appState.isSpectator {
                    spectatorView
                } else if viewModel.isLoading {
                    loadingView
                } else if viewModel.entries.isEmpty {
                    emptyStateView
                } else {
                    entryList
                }
            }
            .navigationTitle("My Entries")
            .task {
                if let userId = appState.currentUser?.id {
                    await viewModel.loadEntries(userId: userId)
                }
            }
            .refreshable {
                if let userId = appState.currentUser?.id {
                    await viewModel.loadEntries(userId: userId)
                }
            }
        }
    }

    private var spectatorView: some View {
        VStack(spacing: 24) {
            Image(systemName: "eye.fill")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text("Spectator Mode")
                .font(.title2)
                .fontWeight(.bold)

            Text("Spectators cannot enter races. Switch to Racer mode in your account settings to compete.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Go to Account") {
                appState.selectedTab = .account
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding(40)
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading entries...")
                .foregroundStyle(.secondary)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "list.bullet.clipboard")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text("No Race Entries")
                .font(.title2)
                .fontWeight(.bold)

            Text("You haven't entered any races yet. Browse available races and start competing!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Browse Races") {
                appState.selectedTab = .races
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding(40)
    }

    private var entryList: some View {
        List {
            Section("Active Races") {
                ForEach(viewModel.activeEntries) { entry in
                    if let race = viewModel.getRace(for: entry) {
                        NavigationLink {
                            RaceDetailView(race: race)
                        } label: {
                            EntryCard(entry: entry, race: race)
                        }
                    }
                }
            }

            if !viewModel.completedEntries.isEmpty {
                Section("Completed") {
                    ForEach(viewModel.completedEntries) { entry in
                        if let race = viewModel.getRace(for: entry) {
                            EntryCard(entry: entry, race: race)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - Entry Card

struct EntryCard: View {
    let entry: Entry
    let race: Race

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: race.type.icon)
                    .foregroundStyle(.accent)

                VStack(alignment: .leading, spacing: 2) {
                    Text(race.type.displayName)
                        .font(.headline)

                    HStack(spacing: 8) {
                        Text(race.duration.displayName)
                        Text("•")
                        Text(race.category.shortName)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                statusBadge
            }

            Divider()

            HStack(spacing: 16) {
                EntryStatView(
                    title: "Prize Pool",
                    value: race.formattedPrizePool,
                    icon: "trophy.fill"
                )

                EntryStatView(
                    title: entry.status == .active ? "Time Left" : "Final Rank",
                    value: entry.status == .active ? formatTimeRemaining(race.timeRemaining) : rankText,
                    icon: entry.status == .active ? "clock.fill" : "medal.fill"
                )

                if let score = entry.score {
                    EntryStatView(
                        title: "Score",
                        value: formatScore(score, for: race.type),
                        icon: "chart.line.uptrend.xyaxis"
                    )
                }
            }

            if let prize = entry.formattedPrize {
                HStack {
                    Image(systemName: "trophy.fill")
                        .foregroundStyle(.yellow)
                    Text("Won \(prize)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.accent)
                }
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(Color.yellow.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(.vertical, 8)
    }

    private var statusBadge: some View {
        Text(entry.status.displayName)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.1))
            .foregroundStyle(statusColor)
            .clipShape(Capsule())
    }

    private var statusColor: Color {
        switch entry.status {
        case .active: return .green
        case .completed: return .blue
        case .disqualified: return .red
        case .refunded: return .orange
        }
    }

    private var rankText: String {
        guard let rank = entry.rank else { return "—" }
        return "#\(rank)"
    }

    private func formatTimeRemaining(_ interval: TimeInterval) -> String {
        guard interval > 0 else { return "Ended" }

        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60

        if hours > 24 {
            return "\(hours / 24)d"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    private func formatScore(_ score: Double, for type: RaceType) -> String {
        switch type {
        case .topSpeed:
            return String(format: "%.1f km/h", score)
        case .furthestDistance:
            return String(format: "%.2f km", score)
        case .fastest1km, .fastest5km:
            let minutes = Int(score) / 60
            let seconds = Int(score) % 60
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}

struct EntryStatView: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
            }
            .foregroundStyle(.secondary)

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    EntryView()
        .environmentObject(AppState())
}
