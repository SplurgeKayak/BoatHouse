import SwiftUI

/// Pop-out sheet showing full race details, stats, and scrollable leaderboard.
struct RacePopoutView: View {
    let race: Race
    @StateObject private var viewModel = RaceDetailViewModel()
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var selectedEntry: LeaderboardEntry? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    statsSection
                    leaderboardSection

                    if race.canEnter, appState.isRacer {
                        enterButton
                    }

                    Spacer().frame(height: 32)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .task {
            await viewModel.loadLeaderboard(for: race.id)
        }
        .sheet(item: $selectedEntry) { entry in
            RaceSessionStoryView(
                entry: entry,
                race: race,
                sessions: sessions(for: entry)
            )
        }
        .sheet(isPresented: $viewModel.showingEntryConfirmation) {
            EntryConfirmationSheet(race: race, viewModel: viewModel)
                .environmentObject(appState)
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                Image(systemName: race.type.icon)
                    .font(.system(size: 36))
                    .foregroundStyle(.accent)
                    .frame(width: 56, height: 56)
                    .background(Color.accentColor.opacity(0.12))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(race.type.displayName)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(race.category.displayName)
                        .font(.subheadline)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.accentColor.opacity(0.12))
                        .foregroundStyle(.accent)
                        .clipShape(Capsule())
                }

                Spacer()
            }

            // Duration pill
            HStack {
                Label(race.duration.displayName, systemImage: race.duration.icon)
                    .font(.subheadline)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray5))
                    .clipShape(Capsule())

                Spacer()

                Text(race.status == .active ? "Active" : "Ended")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(race.status == .active ? .green : .red)
            }
        }
    }

    private var statsSection: some View {
        HStack(spacing: 0) {
            StatBlock(title: "Entries", value: "\(race.entryCount)", icon: "person.3.fill")
            Divider()
            StatBlock(title: "Fastest", value: viewModel.fastestTimeFormatted, icon: "stopwatch.fill")
            Divider()
            StatBlock(title: "Ends In", value: formatCountdown(race.timeRemaining), icon: "clock.fill")
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var leaderboardSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Leaderboard")
                .font(.headline)

            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else if let leaderboard = viewModel.leaderboard, !leaderboard.entries.isEmpty {
                VStack(spacing: 0) {
                    ForEach(leaderboard.entries) { entry in
                        Button {
                            selectedEntry = entry
                        } label: {
                            HStack(spacing: 12) {
                                Text("\(entry.rank)")
                                    .font(.headline)
                                    .frame(width: 30)
                                    .foregroundStyle(medalColor(for: entry.rank))

                                AvatarView(
                                    url: entry.userProfileURL,
                                    initials: String(entry.userName.prefix(1)),
                                    id: entry.userId,
                                    size: 36
                                )

                                Text(entry.userName)
                                    .font(.subheadline)
                                    .lineLimit(1)

                                Spacer()

                                Text(entry.formattedScore)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.accent)

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 4)
                            .background(entry.userId == appState.currentUser?.id
                                        ? Color.accentColor.opacity(0.06) : Color.clear)
                        }
                        .buttonStyle(.plain)

                        Divider()
                    }
                }
            } else {
                Text("No leaderboard data available")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var enterButton: some View {
        Button {
            viewModel.showingEntryConfirmation = true
        } label: {
            Label("Enter Race", systemImage: "flag.checkered")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Helpers

    /// Sessions belonging to this entry's user that fall within the race window.
    private func sessions(for entry: LeaderboardEntry) -> [Session] {
        let now = Date()
        let windowStart: Date
        switch race.duration {
        case .daily:   windowStart = Calendar.current.startOfDay(for: now)
        case .weekly:  windowStart = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now
        case .monthly: windowStart = Calendar.current.date(byAdding: .month, value: -1, to: now) ?? now
        case .yearly:  windowStart = Calendar.current.date(byAdding: .year, value: -1, to: now) ?? now
        }
        return MockData.sessions.filter {
            $0.userId == entry.userId
                && $0.startDate >= windowStart
                && $0.startDate <= now
        }
    }

    private func medalColor(for rank: Int) -> Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .primary
        }
    }

    private func formatCountdown(_ interval: TimeInterval) -> String {
        guard interval > 0 else { return "Ended" }
        let days  = Int(interval) / 86400
        let hours = (Int(interval) % 86400) / 3600
        let mins  = (Int(interval) % 3600) / 60
        if days  > 0 { return "\(days)d \(hours)h" }
        if hours > 0 { return "\(hours)h \(mins)m" }
        return "\(mins)m"
    }
}

#Preview {
    RacePopoutView(race: MockData.races[0])
        .environmentObject(AppState())
}
