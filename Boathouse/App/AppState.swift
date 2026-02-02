import SwiftUI
import Combine

/// Global app state managing user session and navigation
@MainActor
final class AppState: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var selectedTab: Tab = .home
    @Published var isLoading = true
    @Published var showOnboarding = false

    /// Shared instance for global access (set by App)
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

    func logout() {
        currentUser = nil
        isAuthenticated = false
        selectedTab = .home
    }
}
