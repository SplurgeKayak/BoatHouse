import SwiftUI

/// Detailed race view with leaderboard and entry option
struct RaceDetailView: View {
    let race: Race
    @StateObject private var viewModel = RaceDetailViewModel()
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var selectedSession: Session?
    @State private var scrollProxy: ScrollViewProxy?

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 24) {
                    headerSection

                    raceSpecificRulesSection

                    leadersPrizeCard

                    rulesSection

                    leaderboardSection

                    if viewModel.isUserEntered {
                        yourPositionCard
                    } else if race.canEnter && appState.isRacer {
                        enterButton
                    }
                }
                .padding()
            }
            .onAppear { scrollProxy = proxy }
        }
        .navigationTitle(race.type.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadLeaderboard(for: race.id)
            if let userId = appState.currentUser?.id {
                await viewModel.loadUserEntry(raceId: race.id, userId: userId)
            }
        }
        .sheet(isPresented: $viewModel.showingEntryConfirmation) {
            EntryConfirmationSheet(race: race, viewModel: viewModel)
        }
        .fullScreenCover(item: $selectedSession) { session in
            let user = MockData.user(for: session.userId)
            ActivityStoryPopup(
                session: session,
                athleteName: user?.displayName ?? "Athlete",
                athleteAvatarURL: user?.profileImageURL
            )
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

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                RaceTypeIcon(type: race.type, size: 48)

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
                StatBlock(title: "Entry Fee", value: race.formattedEntryFee, icon: "sterlingsign.circle.fill")
                Divider()
                StatBlock(title: "Ends In", value: formatCountdown(race.timeRemaining), icon: "clock.fill")
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Race-Specific Rules (below title, above metrics)

    private var raceSpecificRulesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("About This Race")
                .font(.headline)

            RuleRow(icon: "trophy.fill", text: raceObjective)
            RuleRow(icon: "person.fill", text: "Category: \(race.category.displayName)")
            RuleRow(icon: "calendar", text: "Race duration: 1 \(race.duration.displayName.lowercased())")
            RuleRow(icon: "clock.badge.checkmark", text: "Enter at least 48 hours before the race ends")
            RuleRow(icon: "arrow.up.doc.fill", text: "Submit your activity before the race closes")

            if race.type != .furthestDistance {
                RuleRow(icon: "ruler", text: "Session must cover at least \(minimumDistance)")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var raceObjective: String {
        switch race.type {
        case .fastest1km: return "Record the fastest 1km split in a single session"
        case .fastest5km: return "Record the fastest 5km split in a single session"
        case .fastest10km: return "Record the fastest 10km split in a single session"
        case .furthestDistance: return "Record the longest total distance in a single session"
        }
    }

    private var minimumDistance: String {
        switch race.type {
        case .fastest1km: return "1 km"
        case .fastest5km: return "5 km"
        case .fastest10km: return "10 km"
        case .furthestDistance: return ""
        }
    }

    // MARK: - Merged Leaders & Prizes Card

    private var leadersPrizeCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Current Leaders & Prizes")
                .font(.headline)

            if let leaderboard = viewModel.leaderboard, !leaderboard.topThree.isEmpty {
                let prizes = race.calculatePrizes()

                VStack(spacing: 12) {
                    ForEach(leaderboard.topThree) { entry in
                        Button {
                            if let sessionId = entry.sessionId {
                                selectedSession = MockData.session(for: sessionId)
                            }
                        } label: {
                            HStack(spacing: 10) {
                                Circle()
                                    .fill(podiumColor(for: entry.rank))
                                    .frame(width: 28, height: 28)
                                    .overlay {
                                        Text("\(entry.rank)")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundStyle(.white)
                                    }

                                Text(prizes.formattedPrize(for: entry.rank))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .frame(width: 72, alignment: .leading)

                                AvatarView(
                                    url: entry.userProfileURL,
                                    initials: String(entry.userName.prefix(1)),
                                    id: entry.userId,
                                    size: 32
                                )

                                Text(entry.userName.components(separatedBy: " ").first ?? entry.userName)
                                    .font(.subheadline)
                                    .lineLimit(1)

                                Spacer()

                                Text(entry.formattedScore)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.accent)
                            }
                        }
                        .buttonStyle(.plain)

                        if entry.rank < leaderboard.topThree.count {
                            Divider()
                        }
                    }
                }
            }

            HStack {
                Text("Total Prize Pool")
                    .font(.subheadline)
                Spacer()
                Text(race.formattedPrizePool)
                    .font(.headline)
                    .foregroundStyle(.accent)
            }
            .padding(.top, 4)

            if let updatedAt = viewModel.leaderboardUpdatedAt {
                Text("Leaderboard last refreshed: \(updatedAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func podiumColor(for rank: Int) -> Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .secondary
        }
    }

    // MARK: - Race Rules (updated text)

    private var rulesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Race Rules")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                RuleRow(icon: "location.fill", text: "Sessions must be completed in the UK")
                RuleRow(icon: "antenna.radiowaves.left.and.right", text: "GPS verification required")
                RuleRow(icon: "clock.badge.checkmark", text: "You must enter the race at least 48 hours before the race ends")
                RuleRow(icon: "arrow.up.doc.fill", text: "You must submit your activity before the race closes")
                RuleRow(icon: "figure.rowing", text: "Canoe and kayak sessions only")
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

    // MARK: - Leaderboard (clickable rows)

    private var leaderboardSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Leaderboard")
                    .font(.headline)

                Spacer()

                if viewModel.isLoading {
                    ProgressView()
                }
            }

            if let leaderboard = viewModel.leaderboard {
                if leaderboard.entries.isEmpty {
                    Text("No entries yet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    VStack(spacing: 0) {
                        ForEach(leaderboard.entries.prefix(10)) { entry in
                            Button {
                                if let sessionId = entry.sessionId {
                                    selectedSession = MockData.session(for: sessionId)
                                }
                            } label: {
                                LeaderboardDetailRow(entry: entry, raceType: race.type)
                            }
                            .buttonStyle(.plain)
                            .id(entry.userId)

                            if entry.id != leaderboard.entries.prefix(10).last?.id {
                                Divider()
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Your Position Card

    private var yourPositionCard: some View {
        Button {
            if let userId = appState.currentUser?.id {
                withAnimation {
                    scrollProxy?.scrollTo(userId, anchor: .center)
                }
            }
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Text("Your Position")
                    .font(.headline)
                    .foregroundStyle(.white)

                HStack(spacing: 12) {
                    if let user = appState.currentUser {
                        AvatarView(
                            url: user.profileImageURL,
                            initials: String(user.displayName.prefix(1)),
                            id: user.id,
                            size: 40
                        )
                    }

                    if let entry = viewModel.userEntry {
                        Text("#\(entry.rank ?? 0)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)

                        Text("Best: \(formattedUserScore(entry: entry))")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.9))
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Image(systemName: "clock")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                        Text(formatCountdown(race.timeRemaining))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.white.opacity(0.9))
                        Text("remaining")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.accentColor)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private func formattedUserScore(entry: Entry) -> String {
        guard let score = entry.score else { return "—" }
        switch race.type {
        case .furthestDistance:
            return String(format: "%.2f km", score)
        case .fastest1km, .fastest5km, .fastest10km:
            let minutes = Int(score) / 60
            let seconds = Int(score) % 60
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    // MARK: - Enter Button

    private var enterButton: some View {
        Button {
            viewModel.showingEntryConfirmation = true
        } label: {
            HStack {
                Text("Enter Race")
                Text("•")
                Text(race.formattedEntryFee)
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(!appState.currentUser!.canEnterRaces)
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

/// Entry confirmation sheet
struct EntryConfirmationSheet: View {
    let race: Race
    @ObservedObject var viewModel: RaceDetailViewModel
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                RaceTypeIcon(type: race.type, size: 60)

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
