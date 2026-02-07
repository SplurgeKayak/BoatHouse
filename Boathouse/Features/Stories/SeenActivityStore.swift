import Foundation
import SwiftUI

/// Persistence layer for tracking seen session IDs using UserDefaults
final class SeenSessionStore: ObservableObject {
    private let storageKey = "seenActivityIDs"

    @Published private(set) var seenSessionIDs: Set<String> = []

    static let shared = SeenSessionStore()

    init() {
        loadSeenSessions()
    }

    // MARK: - Public Methods

    func isSeen(sessionId: String) -> Bool {
        seenSessionIDs.contains(sessionId)
    }

    func markSeen(sessionIds: [String]) {
        let newIds = Set(sessionIds)
        seenSessionIDs.formUnion(newIds)
        saveSeenSessions()
    }

    func markSeen(sessionId: String) {
        seenSessionIDs.insert(sessionId)
        saveSeenSessions()
    }

    func unseenSessions(from allSessions: [Session]) -> [Session] {
        allSessions.filter { !isSeen(sessionId: $0.id) }
    }

    func clearAll() {
        seenSessionIDs.removeAll()
        saveSeenSessions()
    }

    // MARK: - Private Methods

    private func loadSeenSessions() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let ids = try? JSONDecoder().decode(Set<String>.self, from: data) else {
            seenSessionIDs = []
            return
        }
        seenSessionIDs = ids
    }

    private func saveSeenSessions() {
        guard let data = try? JSONEncoder().encode(seenSessionIDs) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
