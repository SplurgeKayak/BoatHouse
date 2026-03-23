import SwiftUI

/// Detailed race view with leaderboard and entry option
struct RaceDetailView: View {
    let race: Race
    @StateObject private var viewModel = RaceDetailViewModel()
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection

                podiumSection

                rulesSection

                leaderboardSection
            }
            .padding()
        }
        .navigationTitle(race.type.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadLeaderboard(for: race.id)
        }
        .sheet(isPresented: $viewModel.showingEntryConfirmation) {
            EntryConfirmationSheet(race: race, viewModel: viewModel)
        }
        .alert("Entry Successful", isPresented: $viewModel.showingSuccess) {
            Button("OK") { dismiss() }
        } message: {
            Text("You have entered the race. Good luck!")
        }
        .alert("Error", isPresented: $viewModel.showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "Something went wrong")
        }
    }

    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: race.type.icon)
                    .font(.system(size: 40))
                    .foregroundStyle(.accent)

                VStack(alignment: .leading) {
                    Text(race.type.displayName)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(race.category.displayName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text(race.duration.displayName)
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())

                    Text(race.status == .active ? "Active" : "Ended")
                        .font(.caption)
                        .foregroundStyle(race.status == .active ? .green : .red)
                }
            }

            HStack(spacing: 0) {
                StatBlock(title: "Entries", value: "\(race.entryCount)", icon: "person.3.fill")
                Divider()
                StatBlock(title: "Fastest Time", value: viewModel.fastestTimeFormatted, icon: "stopwatch.fill")
                Divider()
                StatBlock(title: "Ends In", value: formatCountdown(race.timeRemaining), icon: "clock.fill")
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Podium section

    private var podiumSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Podium")
                .font(.headline)

            let top3 = Array(viewModel.leaderboard?.entries.prefix(3) ?? [])
            let currentUserId = appState.currentUser?.id

            VStack(spacing: 12) {
                ForEach(Array(top3.enumerated()), id: \.element.id) { index, entry in
                    PodiumRow(
                        entry: entry,
                        raceType: race.type,
                        isCurrentUser: entry.userId == currentUserId
                    )
                }

                // Show current user's position if not in top 3
                if let userId = currentUserId,
                   !top3.contains(where: { $0.userId == userId }),
                   let userEntry = viewModel.leaderboard?.entries.first(where: { $0.userId == userId }) {
                    Divider()
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your position")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        PodiumRow(entry: userEntry, raceType: race.type, isCurrentUser: true)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var rulesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Race Rules")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                RuleRow(icon: "location.fill", text: "Sessions must be completed in the UK")
                RuleRow(icon: "antenna.radiowaves.left.and.right", text: "GPS verification required")
                RuleRow(icon: "clock.badge.checkmark", text: "Entry closes 3 hours before race ends")
                RuleRow(icon: "figure.water.fitness", text: "Canoe and kayak sessions only")
            }

            Divider()

            Text("Allowed Conditions")
                .font(.subheadline)
                .fontWeight(.medium)

            VStack(alignment: .leading, spacing: 8) {
                RuleRow(icon: "checkmark.circle.fill", text: "Natural stream flow", color: .green)
                RuleRow(icon: "checkmark.circle.fill", text: "Wind assistance", color: .green)
                RuleRow(icon: "checkmark.circle.fill", text: "Washes from other boats", color: .green)
            }

            Text("Prohibited")
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.top, 8)

            VStack(alignment: .leading, spacing: 8) {
                RuleRow(icon: "xmark.circle.fill", text: "Motorised assistance", color: .red)
                RuleRow(icon: "xmark.circle.fill", text: "Non-natural aids", color: .red)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Leaderboard section — top 5 + current user + full list

    private var leaderboardSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Leaderboard")
                .font(.headline)

            if viewModel.isLoading {
                ProgressView()
            } else if let leaderboard = viewModel.leaderboard {
                let entries = leaderboard.entries
                let currentUserId = appState.currentUser?.id
                let top5 = Array(entries.prefix(5))
                let userInTop5 = top5.contains(where: { $0.userId == currentUserId })

                VStack(spacing: 0) {
                    ForEach(top5) { entry in
                        LeaderboardDetailRow(entry: entry, raceType: race.type)
                            .background(entry.userId == currentUserId ? Color.accentColor.opacity(0.06) : Color.clear)
                        Divider()
                    }

                    // Current user row if not in top 5
                    if !userInTop5, let userId = currentUserId,
                       let userEntry = entries.first(where: { $0.userId == userId }) {
                        HStack {
                            Text("Your position")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.leading)
                            Spacer()
                        }
                        .padding(.top, 8)
                        LeaderboardDetailRow(entry: userEntry, raceType: race.type)
                            .background(Color.accentColor.opacity(0.06))
                        Divider()
                    }

                    // Full list (positions 6+)
                    if entries.count > 5 {
                        let remaining = Array(entries.dropFirst(5).filter { $0.userId != currentUserId })
                        ForEach(remaining) { entry in
                            LeaderboardDetailRow(entry: entry, raceType: race.type)
                                .background(entry.userId == currentUserId ? Color.accentColor.opacity(0.06) : Color.clear)
                            Divider()
                        }
                    }
                }
            } else {
                Text("No leaderboard data available")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func formatCountdown(_ interval: TimeInterval) -> String {
        guard interval > 0 else { return "Ended" }

        let days = Int(interval) / 86400
        let hours = (Int(interval) % 86400) / 3600
        let minutes = (Int(interval) % 3600) / 60

        if days > 0 {
            return "\(days)d \(hours)h"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Podium Row

struct PodiumRow: View {
    let entry: LeaderboardEntry
    let raceType: RaceType
    let isCurrentUser: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Medal circle
            Circle()
                .fill(medalColor)
                .frame(width: 32, height: 32)
                .overlay {
                    Text(entry.rank <= 3 ? ["🥇", "🥈", "🥉"][entry.rank - 1] : "#\(entry.rank)")
                        .font(.caption)
                }

            // Avatar
            AvatarView(
                url: entry.userProfileURL,
                initials: String(entry.userName.prefix(1)),
                id: entry.userId,
                size: 36
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.userName)
                    .font(.subheadline)
                    .fontWeight(isCurrentUser ? .bold : .regular)
                if entry.isGPSVerified {
                    Label("GPS Verified", systemImage: "checkmark.shield.fill")
                        .font(.caption2)
                        .foregroundStyle(.green)
                }
            }

            Spacer()

            Text(entry.formattedScore)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.accent)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(isCurrentUser ? Color.accentColor.opacity(0.08) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var medalColor: Color {
        switch entry.rank {
        case 1: return Color(red: 1, green: 0.84, blue: 0)
        case 2: return Color(.systemGray3)
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.2)
        default: return Color(.systemGray5)
        }
    }
}

// MARK: - Supporting Views

struct StatBlock: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(.accent)

            Text(value)
                .font(.headline)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct PrizeRow: View {
    let position: Int
    let amount: String
    let percentage: String

    var body: some View {
        HStack {
            Circle()
                .fill(medalColor)
                .frame(width: 32, height: 32)
                .overlay {
                    Text("\(position)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }

            Text(positionText)
                .font(.subheadline)

            Spacer()

            Text(percentage)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(amount)
                .font(.subheadline)
                .fontWeight(.semibold)
                .frame(width: 80, alignment: .trailing)
        }
    }

    private var medalColor: Color {
        switch position {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .secondary
        }
    }

    private var positionText: String {
        switch position {
        case 1: return "1st Place"
        case 2: return "2nd Place"
        case 3: return "3rd Place"
        default: return "\(position)th Place"
        }
    }
}

struct RuleRow: View {
    let icon: String
    let text: String
    var color: Color = .accent

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 20)

            Text(text)
                .font(.subheadline)
        }
    }
}

struct LeaderboardDetailRow: View {
    let entry: LeaderboardEntry
    let raceType: RaceType

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
                .lineLimit(1)

            Spacer()

            Text(entry.formattedScore)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.accent)
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

/// Entry confirmation sheet (kept for backward compatibility)
struct EntryConfirmationSheet: View {
    let race: Race
    @ObservedObject var viewModel: RaceDetailViewModel
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: race.type.icon)
                    .font(.system(size: 60))
                    .foregroundStyle(.accent)

                Text("Confirm Entry")
                    .font(.title2)
                    .fontWeight(.bold)

                VStack(spacing: 16) {
                    ConfirmRow(label: "Race", value: race.type.displayName)
                    ConfirmRow(label: "Category", value: race.category.displayName)
                    ConfirmRow(label: "Duration", value: race.duration.displayName)
                    Divider()
                    ConfirmRow(label: "Entry Fee", value: race.formattedEntryFee, highlight: true)
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                if let wallet = appState.currentUser?.wallet {
                    HStack {
                        Text("Wallet Balance")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(wallet.formattedBalance)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }

                Spacer()

                Button {
                    Task {
                        await viewModel.enterRace(raceId: race.id, userId: appState.currentUser?.id ?? "")
                        dismiss()
                    }
                } label: {
                    if viewModel.isProcessing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Pay & Enter")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(viewModel.isProcessing)
            }
            .padding(24)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

struct ConfirmRow: View {
    let label: String
    let value: String
    var highlight: Bool = false

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(highlight ? .bold : .regular)
                .foregroundStyle(highlight ? .accent : .primary)
        }
        .font(.subheadline)
    }
}

#Preview {
    NavigationStack {
        RaceDetailView(race: MockData.races[0])
            .environmentObject(AppState())
    }
}
