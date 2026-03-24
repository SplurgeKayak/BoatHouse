import XCTest
@testable import Boathouse

final class RankingTests: XCTestCase {

    // MARK: - Helpers

    private var now: Date {
        DateComponents(
            calendar: calendar,
            year: 2025, month: 6, day: 16,
            hour: 12, minute: 0, second: 0
        ).date!
    }

    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        cal.firstWeekday = 2
        return cal
    }

    private func makeSession(
        id: String,
        userId: String = "user-test",
        startDate: Date? = nil,
        fastest1km: TimeInterval? = nil,
        fastest5km: TimeInterval? = nil,
        fastest10km: TimeInterval? = nil
    ) -> Session {
        Session(
            id: id,
            stravaId: 0,
            userId: userId,
            name: "Test Session",
            sessionType: .kayaking,
            startDate: startDate ?? now,
            elapsedTime: 3600,
            movingTime: 3600,
            distance: 12000,
            maxSpeed: nil,
            averageSpeed: nil,
            startLocation: nil,
            endLocation: nil,
            polyline: nil,
            isGPSVerified: true,
            isUKSession: true,
            flagCount: 0,
            status: .verified,
            importedAt: Date(),
            fastest1kmTime: fastest1km,
            fastest5kmTime: fastest5km,
            fastest10kmTime: fastest10km
        )
    }

    // MARK: - Rank calculation

    func testRankCalculation_rank1IsFastest_1km() {
        let sessions = [
            makeSession(id: "slow", fastest1km: 300),
            makeSession(id: "fast", fastest1km: 180),
            makeSession(id: "mid",  fastest1km: 240),
        ]

        let filtered = HomeViewModel.filterSessions(
            sessions: sessions,
            timeFilter: .daily,
            distanceFilter: .fastest1km,
            now: now,
            calendar: calendar
        )

        XCTAssertEqual(filtered.first?.id, "fast", "Rank 1 (index 0) should be the fastest session")
        XCTAssertEqual(filtered.last?.id, "slow", "Last rank should be the slowest session")
    }

    func testRankCalculation_rank1IsFastest_5km() {
        let sessions = [
            makeSession(id: "b", fastest5km: 1500),
            makeSession(id: "a", fastest5km: 900),
        ]

        let filtered = HomeViewModel.filterSessions(
            sessions: sessions,
            timeFilter: .daily,
            distanceFilter: .fastest5km,
            now: now,
            calendar: calendar
        )

        XCTAssertEqual(filtered.map(\.id), ["a", "b"])
    }

    func testRankCalculation_rank1IsFastest_10km() {
        let sessions = [
            makeSession(id: "c", fastest10km: 3600),
            makeSession(id: "a", fastest10km: 2400),
            makeSession(id: "b", fastest10km: 3000),
        ]

        let filtered = HomeViewModel.filterSessions(
            sessions: sessions,
            timeFilter: .daily,
            distanceFilter: .fastest10km,
            now: now,
            calendar: calendar
        )

        XCTAssertEqual(filtered.map(\.id), ["a", "b", "c"])
    }

    // MARK: - Sessions without the metric are excluded

    func testSessionsWithoutMetric_areExcluded_from1km() {
        let sessions = [
            makeSession(id: "has-1k", fastest1km: 200),
            makeSession(id: "no-1k",  fastest1km: nil),
        ]

        let filtered = HomeViewModel.filterSessions(
            sessions: sessions,
            timeFilter: .daily,
            distanceFilter: .fastest1km,
            now: now,
            calendar: calendar
        )

        XCTAssertEqual(filtered.map(\.id), ["has-1k"])
    }

    func testSessionsWithoutMetric_areExcluded_from5km() {
        let sessions = [
            makeSession(id: "has-5k", fastest5km: 1200),
            makeSession(id: "no-5k",  fastest5km: nil),
        ]

        let filtered = HomeViewModel.filterSessions(
            sessions: sessions,
            timeFilter: .daily,
            distanceFilter: .fastest5km,
            now: now,
            calendar: calendar
        )

        XCTAssertEqual(filtered.map(\.id), ["has-5k"])
    }

    // MARK: - Tie handling

    func testTieHandling_equalTimes_sortedByIdAscending() {
        let sessions = [
            makeSession(id: "z-session", fastest1km: 200),
            makeSession(id: "a-session", fastest1km: 200),
            makeSession(id: "m-session", fastest1km: 200),
        ]

        let filtered = HomeViewModel.filterSessions(
            sessions: sessions,
            timeFilter: .daily,
            distanceFilter: .fastest1km,
            now: now,
            calendar: calendar
        )

        XCTAssertEqual(filtered.map(\.id), ["a-session", "m-session", "z-session"],
                       "Ties should be broken by id ascending for determinism")
    }

    // MARK: - usersInCategory helper

    func testUsersInCategory_seniorMen_containsExpectedIds() {
        let seniorMen = HomeViewModel.usersInCategory(.seniorMen)
        XCTAssertFalse(seniorMen.isEmpty, "Should have at least some Senior Men in MockData")

        // All returned ids should belong to Senior Men users
        for userId in seniorMen {
            guard let user = MockData.users.first(where: { $0.id == userId }) else {
                XCTFail("userId \(userId) not found in MockData.users")
                continue
            }
            XCTAssertTrue(user.eligibleCategories.contains(.seniorMen),
                          "User \(userId) should be eligible for seniorMen")
        }
    }

    func testUsersInCategory_returnsDifferentSetsForDifferentCategories() {
        let seniorMen   = Set(HomeViewModel.usersInCategory(.seniorMen))
        let seniorWomen = Set(HomeViewModel.usersInCategory(.seniorWomen))

        // The sets should be disjoint — a user cannot be both SM and SW
        XCTAssertTrue(seniorMen.isDisjoint(with: seniorWomen),
                      "Senior Men and Senior Women user sets should be disjoint")
    }
}
