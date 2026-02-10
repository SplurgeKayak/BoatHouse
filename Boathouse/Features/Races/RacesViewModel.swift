import SwiftUI
import Combine

/// ViewModel for the Races screen
final class RacesViewModel: ObservableObject {
    @Published var races: [Race] = []
    @Published var selectedDuration: RaceDuration = .weekly
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let raceService: RaceServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    /// Canonical display order for race types
    private static let typeOrder: [RaceType] = [.fastest1km, .fastest5km, .fastest10km, .furthestDistance]

    var filteredRaces: [Race] {
        let matching = races.filter { $0.duration == selectedDuration }
        return matching.sorted { a, b in
            let ai = Self.typeOrder.firstIndex(of: a.type) ?? Int.max
            let bi = Self.typeOrder.firstIndex(of: b.type) ?? Int.max
            return ai < bi
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
