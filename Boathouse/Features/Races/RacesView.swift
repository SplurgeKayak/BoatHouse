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
            .navigationTitle("")
            .navigationBarHidden(false)
            .task {
                viewModel.autoSelectCategory(for: appState.currentUser)
                await viewModel.loadRaces()
            }
            .refreshable {
                await viewModel.loadRaces()
            }
        }
    }

    private var filterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Orange title + subtitle header
            VStack(alignment: .leading, spacing: 4) {
                Text("Races")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(Color(red: 252/255, green: 76/255, blue: 2/255))

                Text("Filter when and what distance to race to see how your sessions stack up against paddlers like you.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 8)
            }
            .padding(.horizontal)
            .padding(.top, 12)

            Picker("Duration", selection: $viewModel.selectedDuration) {
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

    /// Fastest time for this race's type from mock sessions within the race's window.
    private var fastestTime: String? {
        let now = Date()
        let windowStart: Date
        switch race.duration {
        case .daily:   windowStart = Calendar.current.startOfDay(for: now)
        case .weekly:  windowStart = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now
        case .monthly: windowStart = Calendar.current.date(byAdding: .month, value: -1, to: now) ?? now
        case .yearly:  windowStart = Calendar.current.date(byAdding: .year, value: -1, to: now) ?? now
        }

        let filtered = MockData.sessions.filter {
            $0.startDate >= windowStart && $0.startDate <= now
        }

        let best: TimeInterval?
        switch race.type {
        case .fastest1km:  best = filtered.compactMap(\.fastest1kmTime).min()
        case .fastest5km:  best = filtered.compactMap(\.fastest5kmTime).min()
        case .fastest10km: best = filtered.compactMap(\.fastest10kmTime).min()
        }

        guard let t = best else { return nil }
        let minutes = Int(t) / 60
        let seconds = Int(t) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

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
            }

            HStack(spacing: 20) {
                StatColumn(title: "Entries", value: "\(race.entryCount)")
                StatColumn(title: "Fastest", value: fastestTime ?? "—")
                StatColumn(title: "Ends In", value: formatTimeRemaining(race.timeRemaining))
            }

            Text("Ends \(race.endDate, style: .relative)")
                .font(.caption)
                .foregroundStyle(.secondary)

            if !race.canEnter {
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
