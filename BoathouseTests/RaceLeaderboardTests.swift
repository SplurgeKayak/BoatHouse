import XCTest
@testable import Boathouse

final class RaceLeaderboardTests: XCTestCase {

    // MARK: - fastestTimeFormatted default

    func testEmptyLeaderboard_fastestTimeFormattedIsDash() {
        let vm = RaceDetailViewModel()
        XCTAssertEqual(vm.fastestTimeFormatted, "—")
    }

    // MARK: - Podium edge cases

    func testFewerThanThreeEntries_podiumHandled() {
        // Build a leaderboard with 2 entries — verify no crash accessing prefix(3)
        let entries = [
            makeEntry(rank: 1, userId: "u1", userName: "Alice", score: 180),
            makeEntry(rank: 2, userId: "u2", userName: "Bob",   score: 200),
        ]
        let leaderboard = Leaderboard(
            id: "lb-test",
            raceId: "race-test",
            entries: entries,
            updatedAt: Date()
        )
        let top3 = Array(leaderboard.entries.prefix(3))
        XCTAssertEqual(top3.count, 2)
    }

    func testFewerThanFiveEntries_leaderboardHandled() {
        // Leaderboard with 3 entries: top5 truncates safely
        let entries = [
            makeEntry(rank: 1, userId: "u1", userName: "Alice", score: 180),
            makeEntry(rank: 2, userId: "u2", userName: "Bob",   score: 195),
            makeEntry(rank: 3, userId: "u3", userName: "Carol", score: 210),
        ]
        let leaderboard = Leaderboard(
            id: "lb-test",
            raceId: "race-test",
            entries: entries,
            updatedAt: Date()
        )
        let top5 = Array(leaderboard.entries.prefix(5))
        XCTAssertEqual(top5.count, 3)
        // remaining (positions 6+) is empty — no crash
        let remaining = Array(leaderboard.entries.dropFirst(5))
        XCTAssertTrue(remaining.isEmpty)
    }

    // MARK: - Ranking order

    func testRanking_sortedByScore() {
        // Entries already ranked; verify rank field matches order
        let entries = [
            makeEntry(rank: 1, userId: "u1", userName: "First",  score: 170),
            makeEntry(rank: 2, userId: "u2", userName: "Second", score: 185),
            makeEntry(rank: 3, userId: "u3", userName: "Third",  score: 200),
        ]
        for (i, entry) in entries.enumerated() {
            XCTAssertEqual(entry.rank, i + 1)
        }
    }

    func testUserNotInTopThree_entryFound() {
        // User at rank 4 should be findable for "Your position"
        let currentUserId = "u4"
        let entries = [
            makeEntry(rank: 1, userId: "u1", userName: "A", score: 170),
            makeEntry(rank: 2, userId: "u2", userName: "B", score: 185),
            makeEntry(rank: 3, userId: "u3", userName: "C", score: 200),
            makeEntry(rank: 4, userId: currentUserId, userName: "D", score: 220),
        ]
        let leaderboard = Leaderboard(
            id: "lb-test",
            raceId: "race-test",
            entries: entries,
            updatedAt: Date()
        )
        let top3 = Array(leaderboard.entries.prefix(3))
        XCTAssertFalse(top3.contains(where: { $0.userId == currentUserId }))
        let userEntry = leaderboard.entries.first(where: { $0.userId == currentUserId })
        XCTAssertNotNil(userEntry)
        XCTAssertEqual(userEntry?.rank, 4)
    }

    // MARK: - Deduplication tests

    func testDeduplication_oneRowPerUser() {
        // Two entries for the same user — only the faster one should appear
        let entries = [
            makeRaceEntry(id: "e1", userId: "u1", score: 200),
            makeRaceEntry(id: "e2", userId: "u1", score: 180), // faster
            makeRaceEntry(id: "e3", userId: "u2", score: 190),
        ]
        let result = RaceEngine.shared.calculateRankingsDeduplicatedByUser(entries: entries, raceType: .fastest1km)
        XCTAssertEqual(result.count, 2, "Should have exactly one entry per user")
        let u1Entry = result.first(where: { $0.userId == "u1" })
        XCTAssertEqual(u1Entry?.score, 180, "Should keep the faster entry for u1")
    }

    func testDeduplication_sortedAscending() {
        let entries = [
            makeRaceEntry(id: "e1", userId: "u1", score: 250),
            makeRaceEntry(id: "e2", userId: "u2", score: 180),
            makeRaceEntry(id: "e3", userId: "u3", score: 210),
        ]
        let result = RaceEngine.shared.calculateRankingsDeduplicatedByUser(entries: entries, raceType: .fastest1km)
        XCTAssertEqual(result.map(\.userId), ["u2", "u3", "u1"], "Leaderboard must be sorted ascending by score")
        XCTAssertEqual(result.map(\.rank), [1, 2, 3])
    }

    func testDeduplication_multipleDistances() {
        // Works for 5km and 10km as well
        for raceType in RaceType.allCases {
            let entries = [
                makeRaceEntry(id: "a", userId: "u1", score: 500),
                makeRaceEntry(id: "b", userId: "u1", score: 490), // faster
                makeRaceEntry(id: "c", userId: "u2", score: 480),
            ]
            let result = RaceEngine.shared.calculateRankingsDeduplicatedByUser(entries: entries, raceType: raceType)
            XCTAssertEqual(result.count, 2, "One row per user for raceType \(raceType)")
            XCTAssertEqual(result.first?.userId, "u2", "Fastest user first for \(raceType)")
        }
    }

    func testDeduplication_tiebreaker() {
        // Same score for two users — deterministic ordering by entry.id
        let entries = [
            makeRaceEntry(id: "z-entry", userId: "u1", score: 200),
            makeRaceEntry(id: "a-entry", userId: "u2", score: 200),
        ]
        let result = RaceEngine.shared.calculateRankingsDeduplicatedByUser(entries: entries, raceType: .fastest1km)
        XCTAssertEqual(result.count, 2)
        // "a-entry" < "z-entry" alphabetically → u2 should be rank 1
        XCTAssertEqual(result.first?.userId, "u2", "Tiebreaker should use entry.id lexicographic order")
    }

    // MARK: - Extended helpers

    private func makeRaceEntry(id: String, userId: String, score: Double) -> Entry {
        Entry(
            id: id,
            userId: userId,
            raceId: "race-1",
            sessionId: nil,
            enteredAt: Date(),
            score: score,
            rank: nil,
            status: .active,
            prizeWon: nil,
            transactionId: nil
        )
    }

    // MARK: - Helper

    private func makeEntry(rank: Int, userId: String, userName: String, score: Double) -> LeaderboardEntry {
        LeaderboardEntry(
            id: "entry-\(rank)",
            rank: rank,
            userId: userId,
            userName: userName,
            userProfileURL: nil,
            score: score,
            sessionId: nil,
            raceType: .fastest1km,
            isGPSVerified: true
        )
    }
}
