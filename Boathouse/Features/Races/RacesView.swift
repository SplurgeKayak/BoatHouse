import SwiftUI

/// Races screen displaying all current races with filtering
struct RacesView: View {
    @StateObject private var viewModel = RacesViewModel()
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterSection

                if viewModel.isLoading {
                    loadingView
                } else if viewModel.filteredRaces.isEmpty {
                    emptyStateView
                } else {
                    raceList
                }
            }
            .navigationTitle("Races")
            .task {
                await viewModel.loadRaces()
            }
            .refreshable {
                await viewModel.loadRaces()
            }
        }
    }

    private var filterSection: some View {
        VStack(spacing: 12) {
            Picker("Duration", selection: $viewModel.selectedDuration) {
                Text("All").tag(RaceDuration?.none)
                ForEach(RaceDuration.allCases) { duration in
                    Text(duration.displayName).tag(Optional(duration))
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(
                        title: "All Types",
                        isSelected: viewModel.selectedRaceType == nil,
                        action: { viewModel.selectedRaceType = nil }
                    )

                    ForEach(RaceType.allCases) { type in
                        FilterChip(
                            title: type.displayName,
                            isSelected: viewModel.selectedRaceType == type,
                            action: { viewModel.selectedRaceType = type }
                        )
                    }
                }
                .padding(.horizontal)
            }

            if appState.isRacer, let user = appState.currentUser {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        Text("Categories:")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        ForEach(user.eligibleCategories) { category in
                            FilterChip(
                                title: category.shortName,
                                isSelected: viewModel.selectedCategory == category,
                                action: { viewModel.selectedCategory = category }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
    }

    private var raceList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.filteredRaces) { race in
                    NavigationLink {
                        RaceDetailView(race: race)
                    } label: {
                        RaceCard(race: race)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading races...")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "flag.checkered")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No Races Found")
                .font(.headline)

            Text("Try adjusting your filters or check back later")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Race Card

struct RaceCard: View {
    let race: Race
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: race.type.icon)
                    .font(.title2)
                    .foregroundStyle(.accent)
                    .frame(width: 44, height: 44)
                    .background(Color.accentColor.opacity(0.1))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(race.type.displayName)
                        .font(.headline)

                    HStack(spacing: 8) {
                        Label(race.duration.displayName, systemImage: race.duration.icon)
                        Text("•")
                        Text(race.category.shortName)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(race.formattedPrizePool)
                        .font(.headline)
                        .foregroundStyle(.accent)

                    Text("Prize Pool")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 20) {
                StatColumn(title: "Entries", value: "\(race.entryCount)")
                StatColumn(title: "Entry Fee", value: race.formattedEntryFee)
                StatColumn(title: "Ends In", value: formatTimeRemaining(race.timeRemaining))
            }

            if race.canEnter && appState.isRacer {
                Button {
                    // Navigation handled by NavigationLink
                } label: {
                    Text("View & Enter")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            } else if !race.canEnter {
                HStack {
                    Image(systemName: "clock.badge.xmark")
                    Text("Entry closed")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color(.systemGray5))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }

    private func formatTimeRemaining(_ interval: TimeInterval) -> String {
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

struct StatColumn: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    RacesView()
        .environmentObject(AppState())
}
