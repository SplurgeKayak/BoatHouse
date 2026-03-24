import SwiftUI
import Combine

/// ViewModel for the Races screen
final class RacesViewModel: ObservableObject {
    @Published var races: [Race] = []
    @Published var selectedDuration: RaceDuration? = .weekly
    @Published var selectedCategory: RaceCategory?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let raceService: RaceServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    /// Races filtered by duration + category, sorted by distance (1km → 5km → 10km).
    var filteredRaces: [Race] {
        let typeOrder: [RaceType] = [.fastest1km, .fastest5km, .fastest10km]
        return races
            .filter { race in
                var matches = true
                if let duration = selectedDuration {
                    matches = matches && race.duration == duration
                }
                if let category = selectedCategory {
                    matches = matches && race.category == category
                }
                return matches
            }
            .sorted { lhs, rhs in
                let li = typeOrder.firstIndex(of: lhs.type) ?? 99
                let ri = typeOrder.firstIndex(of: rhs.type) ?? 99
                if li != ri { return li < ri }
                return lhs.category.rawValue < rhs.category.rawValue
            }
    }

    init(raceService: RaceServiceProtocol = RaceService.shared) {
        self.raceService = raceService
    }

    /// Auto-selects the user's primary eligible category if none is selected.
    func autoSelectCategory(for user: User?) {
        if selectedCategory == nil {
            selectedCategory = user?.eligibleCategories.first
        }
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
