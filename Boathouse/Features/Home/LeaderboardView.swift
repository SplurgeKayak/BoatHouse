import SwiftUI

/// Full leaderboard view with filtering
struct LeaderboardView: View {
    let duration: RaceDuration
    let raceType: RaceType

    @StateObject private var viewModel = LeaderboardViewModel()

    var body: some View {
        List {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
            } else if let leaderboard = viewModel.leaderboard {
                ForEach(leaderboard.entries) { entry in
                    LeaderboardFullRow(entry: entry, raceType: raceType)
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("Leaderboard")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadLeaderboard(duration: duration, raceType: raceType)
        }
    }
}

struct LeaderboardFullRow: View {
    let entry: LeaderboardEntry
    let raceType: RaceType
    @EnvironmentObject var appState: AppState

    var isCurrentUser: Bool {
        entry.userId == appState.currentUser?.id
    }

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                if entry.rank <= 3 {
                    Image(systemName: "medal.fill")
                        .font(.title2)
                        .foregroundStyle(medalColor)
                }

                Text("\(entry.rank)")
                    .font(entry.rank <= 3 ? .caption : .headline)
                    .fontWeight(.bold)
                    .foregroundStyle(entry.rank <= 3 ? .white : .primary)
            }
            .frame(width: 40)

            AvatarView(
                url: entry.userProfileURL,
                initials: String(entry.userName.prefix(1)),
                id: entry.userId,
                size: 44
            )

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(entry.userName)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    if isCurrentUser {
                        Text("You")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.accentColor)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                }
            }

            Spacer()

            Text(entry.formattedScore)
                .font(.headline)
                .foregroundStyle(.accent)
        }
        .padding(.vertical, 8)
        .background(isCurrentUser ? Color.accentColor.opacity(0.05) : Color.clear)
    }

    private var medalColor: Color {
        switch entry.rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .clear
        }
    }
}

// MARK: - ViewModel

final class LeaderboardViewModel: ObservableObject {
    @Published var leaderboard: Leaderboard?
    @Published var isLoading: Bool = false

    private let raceService: RaceServiceProtocol

    init(raceService: RaceServiceProtocol = RaceService.shared) {
        self.raceService = raceService
    }

    @MainActor
    func loadLeaderboard(duration: RaceDuration, raceType: RaceType) async {
        isLoading = true
        defer { isLoading = false }

        do {
            leaderboard = try await raceService.fetchLeaderboard(duration: duration, raceType: raceType)
        } catch {
            // Silently fail
        }
    }
}

#Preview {
    NavigationStack {
        LeaderboardView(duration: .daily, raceType: .topSpeed)
            .environmentObject(AppState())
    }
}
