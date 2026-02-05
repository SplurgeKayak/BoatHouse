import Foundation
import SwiftUI
import Combine

/// Represents a user/athlete with their unseen activities for the Stories strip
struct AthleteStory: Identifiable, Equatable {
    let id: String
    let athleteId: String
    let athleteName: String
    let athleteAvatarURL: URL?
    let unseenActivities: [Activity]

    var unseenCount: Int { unseenActivities.count }

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

    private let seenStore: SeenActivityStore
    private var cancellables = Set<AnyCancellable>()

    // Mock user data for demo purposes
    private let mockUsers: [String: (name: String, avatarURL: URL?)] = [
        "user-001": ("James Wilson", nil),
        "user-002": ("Sarah Chen", nil),
        "user-003": ("Mike Johnson", nil),
        "user-004": ("Emma Davis", nil),
        "user-005": ("Tom Roberts", nil),
        "user-010": ("David Henderson", nil),
        "user-011": ("Michael Roberts", nil),
        "user-012": ("Christopher Lee", nil)
    ]

    init(seenStore: SeenActivityStore = .shared) {
        self.seenStore = seenStore

        // Listen for changes to seen activities
        seenStore.$seenActivityIDs
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    /// Update stories based on the current activities
    @MainActor
    func updateStories(from activities: [Activity]) {
        // Group activities by user
        let groupedByUser = Dictionary(grouping: activities) { $0.userId }

        // Create stories for users with unseen activities
        var newStories: [AthleteStory] = []

        for (userId, userActivities) in groupedByUser {
            let unseenActivities = seenStore.unseenActivities(from: userActivities)
                .sorted { $0.startDate > $1.startDate } // Most recent first

            guard !unseenActivities.isEmpty else { continue }

            let userData = mockUsers[userId] ?? (name: "Athlete", avatarURL: nil)

            let story = AthleteStory(
                id: "story-\(userId)",
                athleteId: userId,
                athleteName: userData.name,
                athleteAvatarURL: userData.avatarURL,
                unseenActivities: unseenActivities
            )

            newStories.append(story)
        }

        // Sort by most recent activity
        stories = newStories.sorted {
            ($0.unseenActivities.first?.startDate ?? .distantPast) >
            ($1.unseenActivities.first?.startDate ?? .distantPast)
        }
    }

    /// Called when user taps on a story bubble
    @MainActor
    func selectStory(_ story: AthleteStory) {
        selectedStory = story
        isShowingStoryViewer = true
    }

    /// Called when story viewer is dismissed
    @MainActor
    func dismissStoryViewer() {
        isShowingStoryViewer = false
        selectedStory = nil
    }

    /// Mark activities as seen and refresh stories
    @MainActor
    func markActivitiesAsSeen(_ activityIds: [String], activities: [Activity]) {
        seenStore.markSeen(activityIds: activityIds)
        updateStories(from: activities)
    }

    /// Check if there are any stories to show
    var hasStories: Bool {
        !stories.isEmpty
    }
}
