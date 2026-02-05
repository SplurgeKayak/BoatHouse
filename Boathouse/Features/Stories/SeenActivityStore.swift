import Foundation
import SwiftUI

/// Persistence layer for tracking seen activity IDs using UserDefaults
final class SeenActivityStore: ObservableObject {
    private let storageKey = "seenActivityIDs"

    @Published private(set) var seenActivityIDs: Set<String> = []

    static let shared = SeenActivityStore()

    init() {
        loadSeenActivities()
    }

    // MARK: - Public Methods

    /// Check if an activity has been seen
    func isSeen(activityId: String) -> Bool {
        seenActivityIDs.contains(activityId)
    }

    /// Mark multiple activities as seen
    func markSeen(activityIds: [String]) {
        let newIds = Set(activityIds)
        seenActivityIDs.formUnion(newIds)
        saveSeenActivities()
    }

    /// Mark a single activity as seen
    func markSeen(activityId: String) {
        seenActivityIDs.insert(activityId)
        saveSeenActivities()
    }

    /// Filter activities to return only unseen ones
    func unseenActivities(from allActivities: [Activity]) -> [Activity] {
        allActivities.filter { !isSeen(activityId: $0.id) }
    }

    /// Clear all seen activities (useful for testing)
    func clearAll() {
        seenActivityIDs.removeAll()
        saveSeenActivities()
    }

    // MARK: - Private Methods

    private func loadSeenActivities() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let ids = try? JSONDecoder().decode(Set<String>.self, from: data) else {
            seenActivityIDs = []
            return
        }
        seenActivityIDs = ids
    }

    private func saveSeenActivities() {
        guard let data = try? JSONEncoder().encode(seenActivityIDs) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
