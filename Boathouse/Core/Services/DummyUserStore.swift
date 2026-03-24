import Foundation

/// Manages the user store: seed users from MockData + persisted users from disk.
/// New accounts created via auth are written to a writable location (Documents)
/// and merged with seed data on startup (persisted users win on id conflict).
final class DummyUserStore {
    static let shared = DummyUserStore()

    private let fileName = "persisted_users.json"
    private var allUsers: [User] = []

    init() {
        allUsers = loadMergedUsers()
    }

    /// All known users (seed + persisted, deduped by id — persisted wins).
    var users: [User] { allUsers }

    /// Look up a user by id.
    func user(for id: String) -> User? {
        allUsers.first { $0.id == id }
    }

    /// Look up a user by email (for login flow).
    func user(byEmail email: String) -> User? {
        allUsers.first { $0.email.lowercased() == email.lowercased() }
    }

    /// Add a new user (from registration) and persist.
    func addUser(_ user: User) {
        // Replace if same id exists, otherwise append
        if let idx = allUsers.firstIndex(where: { $0.id == user.id }) {
            allUsers[idx] = user
        } else {
            allUsers.append(user)
        }
        savePersistedUsers()
    }

    // MARK: - Persistence

    private var persistedFileURL: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = dir.appendingPathComponent("Boathouse", isDirectory: true)
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        return appDir.appendingPathComponent(fileName)
    }

    private func loadPersistedUsers() -> [User] {
        guard let data = try? Data(contentsOf: persistedFileURL) else { return [] }
        return (try? JSONDecoder().decode([User].self, from: data)) ?? []
    }

    private func savePersistedUsers() {
        // Only save users that aren't in the seed set (by id)
        let seedIds = Set(MockData.users.map(\.id))
        let persisted = allUsers.filter { !seedIds.contains($0.id) }
        if let data = try? JSONEncoder().encode(persisted) {
            try? data.write(to: persistedFileURL, options: .atomic)
        }
    }

    /// Merge seed users with persisted users. Persisted wins on id conflict.
    private func loadMergedUsers() -> [User] {
        let seed = MockData.users
        let persisted = loadPersistedUsers()

        // Build merged: start with seed, overlay persisted
        var merged = Dictionary(uniqueKeysWithValues: seed.map { ($0.id, $0) })
        for user in persisted {
            merged[user.id] = user
        }
        return Array(merged.values).sorted { $0.id < $1.id }
    }
}
