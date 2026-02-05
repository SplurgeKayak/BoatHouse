import SwiftUI
import Combine

/// Global app state managing user session and navigation
final class AppState: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: User?
    @Published var selectedTab: Tab = .home
    @Published var isLoading: Bool = true
    @Published var showOnboarding: Bool = false

    /// Shared instance for global access
    static var shared: AppState?

    enum Tab: Int, CaseIterable {
        case home = 0
        case races
        case entry
        case account

        var title: String {
            switch self {
            case .home: return "Home"
            case .races: return "Races"
            case .entry: return "My Entries"
            case .account: return "Account"
            }
        }

        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .races: return "flag.checkered"
            case .entry: return "list.bullet.clipboard"
            case .account: return "person.fill"
            }
        }
    }

    init() {
        // Default initialization
    }

    var isRacer: Bool {
        currentUser?.userType == .racer
    }

    var isSpectator: Bool {
        currentUser?.userType == .spectator
    }

    @MainActor
    func logout() {
        currentUser = nil
        isAuthenticated = false
        selectedTab = .home
    }
}
