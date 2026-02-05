import SwiftUI

/// ViewModel for My Entries screen
final class EntryViewModel: ObservableObject {
    @Published var entries: [Entry] = []
    @Published var races: [Race] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let raceService: RaceServiceProtocol

    var activeEntries: [Entry] {
        entries.filter { $0.status == .active }
    }

    var completedEntries: [Entry] {
        entries.filter { $0.status != .active }
    }

    init(raceService: RaceServiceProtocol = RaceService.shared) {
        self.raceService = raceService
    }

    @MainActor
    func loadEntries(userId: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            async let entriesTask = raceService.fetchUserEntries(userId: userId)
            async let racesTask = raceService.fetchActiveRaces()

            let (fetchedEntries, fetchedRaces) = await (try entriesTask, try racesTask)

            entries = fetchedEntries
            races = fetchedRaces
        } catch {
            errorMessage = "Failed to load entries"
        }
    }

    func getRace(for entry: Entry) -> Race? {
        races.first { $0.id == entry.raceId }
    }
}
