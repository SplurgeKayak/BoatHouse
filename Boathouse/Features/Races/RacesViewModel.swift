import SwiftUI
import Combine

/// ViewModel for the Races screen
final class RacesViewModel: ObservableObject {
    @Published var races: [Race] = []
    @Published var selectedDuration: RaceDuration?
    @Published var selectedRaceType: RaceType?
    @Published var selectedCategory: RaceCategory?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let raceService: RaceServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    var filteredRaces: [Race] {
        races.filter { race in
            var matches = true

            if let duration = selectedDuration {
                matches = matches && race.duration == duration
            }

            if let type = selectedRaceType {
                matches = matches && race.type == type
            }

            if let category = selectedCategory {
                matches = matches && race.category == category
            }

            return matches
        }
    }

    init(raceService: RaceServiceProtocol = RaceService.shared) {
        self.raceService = raceService
    }

    @MainActor
    func loadRaces() async {
        isLoading = true
        defer { isLoading = false }

        do {
            races = try await raceService.fetchActiveRaces()
        } catch {
            errorMessage = "Failed to load races"
        }
    }
}
