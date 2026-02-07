import Foundation
import SwiftUI
import Combine

/// Represents a user/athlete with their unseen sessions for the Stories strip
struct AthleteStory: Identifiable, Equatable {
    let id: String
    let athleteId: String
    let athleteName: String
    let athleteAvatarURL: URL?
    let unseenSessions: [Session]

    var unseenCount: Int { unseenSessions.count }

    var firstName: String {
        athleteName.components(separatedBy: " ").first ?? athleteName
    }

    var initials: String {
        let parts = athleteName.components(separatedBy: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        return String(athleteName.prefix(2)).uppercased()
    }

    static func == (lhs: AthleteStory, rhs: AthleteStory) -> Bool {
        lhs.id == rhs.id && lhs.unseenCount == rhs.unseenCount
    }
}

/// ViewModel for managing the Stories strip on the Home screen
final class StoryFeedViewModel: ObservableObject {
    @Published var stories: [AthleteStory] = []
    @Published var selectedStory: AthleteStory?
    @Published var isShowingStoryViewer: Bool = false

    private let seenStore: SeenSessionStore
    private var cancellables = Set<AnyCancellable>()

    // Mock user data for demo purposes (with avatar URLs for some)
    private let mockUsers: [String: (name: String, avatarURL: URL?)] = [
        "user-001": ("James Wilson", URL(string: "https://i.pravatar.cc/150?u=user-001")),
        "user-002": ("Sarah Chen", URL(string: "https://i.pravatar.cc/150?u=user-002")),
        "user-003": ("Mike Johnson", URL(string: "https://i.pravatar.cc/150?u=user-003")),
        "user-004": ("Emma Davis", URL(string: "https://i.pravatar.cc/150?u=user-004")),
        "user-005": ("Tom Roberts", URL(string: "https://i.pravatar.cc/150?u=user-005")),
        "user-010": ("David Henderson", nil),
        "user-011": ("Michael Roberts", nil),
        "user-012": ("Christopher Lee", nil)
    ]

    init(seenStore: SeenSessionStore = .shared) {
        self.seenStore = seenStore

        seenStore.$seenSessionIDs
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    /// Update stories based on the current sessions
    @MainActor
    func updateStories(from sessions: [Session]) {
        let groupedByUser = Dictionary(grouping: sessions) { $0.userId }

        var newStories: [AthleteStory] = []

        for (userId, userSessions) in groupedByUser {
            let unseenSessions = seenStore.unseenSessions(from: userSessions)
                .sorted { $0.startDate > $1.startDate }

            guard !unseenSessions.isEmpty else { continue }

            let userData = mockUsers[userId] ?? (name: "Athlete", avatarURL: nil)

            let story = AthleteStory(
                id: "story-\(userId)",
                athleteId: userId,
                athleteName: userData.name,
                athleteAvatarURL: userData.avatarURL,
                unseenSessions: unseenSessions
            )

            newStories.append(story)
        }

        stories = newStories.sorted {
            ($0.unseenSessions.first?.startDate ?? .distantPast) >
            ($1.unseenSessions.first?.startDate ?? .distantPast)
        }
    }

    @MainActor
    func selectStory(_ story: AthleteStory) {
        selectedStory = story
        isShowingStoryViewer = true
    }

    @MainActor
    func dismissStoryViewer() {
        isShowingStoryViewer = false
        selectedStory = nil
    }

    @MainActor
    func markSessionsAsSeen(_ sessionIds: [String], sessions: [Session]) {
        seenStore.markSeen(sessionIds: sessionIds)
        updateStories(from: sessions)
    }

    var hasStories: Bool {
        !stories.isEmpty
    }
}
