import XCTest
@testable import Boathouse

final class SessionFilterTests: XCTestCase {

    // MARK: - Helpers

    /// Fixed reference date: Monday 2025-06-16 12:00:00 UTC
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
        cal.firstWeekday = 2 // Monday
        return cal
    }

    /// Create a minimal Session with the given date and split times.
    private func makeSession(
        id: String = UUID().uuidString,
        startDate: Date,
        fastest1km: TimeInterval? = nil,
        fastest5km: TimeInterval? = nil,
        fastest10km: TimeInterval? = nil
    ) -> Session {
        Session(
            id: id,
            stravaId: 0,
            userId: "user-test",
            name: "Test Session",
            sessionType: .kayaking,
            startDate: startDate,
            elapsedTime: 3600,
            movingTime: 3600,
            distance: 12000,
            maxSpeed: 5.0,
            averageSpeed: 3.3,
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

    // MARK: - Time filter: Weekly

    func testWeeklyFilter_includesSameWeek() {
        // now is Monday 16 June 2025; same week = Mon 16 – Sun 22
        let monday = now
        let friday = calendar.date(byAdding: .day, value: 4, to: now)!
        let lastSunday = calendar.date(byAdding: .day, value: -1, to: now)! // previous week

        let sessions = [
            makeSession(id: "mon", startDate: monday),
            makeSession(id: "fri", startDate: friday),
            makeSession(id: "prev", startDate: lastSunday),
        ]

        let result = HomeViewModel.filterSessions(
            sessions: sessions,
            timeFilter: .weekly,
            distanceFilter: .furthestDistance,
            now: now,
            calendar: calendar
        )

        let ids = result.map(\.id)
        XCTAssertTrue(ids.contains("mon"))
        XCTAssertTrue(ids.contains("fri"))
        XCTAssertFalse(ids.contains("prev"))
    }

    // MARK: - Time filter: Monthly

    func testMonthlyFilter_includesSameMonth() {
        let earlyMonth = DateComponents(calendar: calendar, year: 2025, month: 6, day: 1, hour: 9).date!
        let lateMonth = DateComponents(calendar: calendar, year: 2025, month: 6, day: 30, hour: 18).date!
        let previousMonth = DateComponents(calendar: calendar, year: 2025, month: 5, day: 31, hour: 23).date!

        let sessions = [
            makeSession(id: "early", startDate: earlyMonth),
            makeSession(id: "late", startDate: lateMonth),
            makeSession(id: "prev", startDate: previousMonth),
        ]

        let result = HomeViewModel.filterSessions(
            sessions: sessions,
            timeFilter: .monthly,
            distanceFilter: .furthestDistance,
            now: now,
            calendar: calendar
        )

        XCTAssertEqual(result.map(\.id).sorted(), ["early", "late"])
    }

    // MARK: - Distance filter: Fastest 1km

    func testFastest1km_filtersAndSortsAscending() {
        let sessions = [
            makeSession(id: "slow", startDate: now, fastest1km: 300),
            makeSession(id: "fast", startDate: now, fastest1km: 180),
            makeSession(id: "mid", startDate: now, fastest1km: 240),
            makeSession(id: "none", startDate: now, fastest1km: nil),
        ]

        let result = HomeViewModel.filterSessions(
            sessions: sessions,
            timeFilter: .weekly,
            distanceFilter: .fastest1km,
            now: now,
            calendar: calendar
        )

        XCTAssertEqual(result.map(\.id), ["fast", "mid", "slow"])
        XCTAssertFalse(result.map(\.id).contains("none"))
    }

    // MARK: - Distance filter: Fastest 5km

    func testFastest5km_filtersAndSortsAscending() {
        let sessions = [
            makeSession(id: "b", startDate: now, fastest5km: 1200),
            makeSession(id: "a", startDate: now, fastest5km: 900),
            makeSession(id: "no5k", startDate: now, fastest5km: nil),
        ]

        let result = HomeViewModel.filterSessions(
            sessions: sessions,
            timeFilter: .weekly,
            distanceFilter: .fastest5km,
            now: now,
            calendar: calendar
        )

        XCTAssertEqual(result.map(\.id), ["a", "b"])
    }

    // MARK: - Distance filter: Fastest 10km

    func testFastest10km_filtersAndSortsAscending() {
        let sessions = [
            makeSession(id: "c", startDate: now, fastest10km: 3600),
            makeSession(id: "a", startDate: now, fastest10km: 2400),
            makeSession(id: "b", startDate: now, fastest10km: 3000),
        ]

        let result = HomeViewModel.filterSessions(
            sessions: sessions,
            timeFilter: .weekly,
            distanceFilter: .fastest10km,
            now: now,
            calendar: calendar
        )

        XCTAssertEqual(result.map(\.id), ["a", "b", "c"])
    }

    // MARK: - Distance filter: furthestDistance (default sort)

    func testFurthestDistance_sortsByDateDescending() {
        let early = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: now)!
        let late = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: now)!

        let sessions = [
            makeSession(id: "early", startDate: early),
            makeSession(id: "late", startDate: late),
        ]

        let result = HomeViewModel.filterSessions(
            sessions: sessions,
            timeFilter: .weekly,
            distanceFilter: .furthestDistance,
            now: now,
            calendar: calendar
        )

        XCTAssertEqual(result.map(\.id), ["late", "early"])
    }

    // MARK: - Combined: time + distance filters compose

    func testCombinedFilters_timeAndDistanceCompose() {
        let today = now
        let lastWeek = calendar.date(byAdding: .day, value: -8, to: now)!

        let sessions = [
            makeSession(id: "thisweek-fast", startDate: today, fastest1km: 180),
            makeSession(id: "thisweek-slow", startDate: today, fastest1km: 300),
            makeSession(id: "thisweek-no1k", startDate: today, fastest1km: nil),
            makeSession(id: "lastweek", startDate: lastWeek, fastest1km: 150), // fast but wrong week
        ]

        let result = HomeViewModel.filterSessions(
            sessions: sessions,
            timeFilter: .weekly,
            distanceFilter: .fastest1km,
            now: now,
            calendar: calendar
        )

        // Only this week's sessions with 1km times, sorted ascending
        XCTAssertEqual(result.map(\.id), ["thisweek-fast", "thisweek-slow"])
    }

    // MARK: - Edge cases

    func testEmptySessionsList_returnsEmpty() {
        let result = HomeViewModel.filterSessions(
            sessions: [],
            timeFilter: .weekly,
            distanceFilter: .fastest5km,
            now: now,
            calendar: calendar
        )

        XCTAssertTrue(result.isEmpty)
    }

    func testAllSessionsFilteredOut_returnsEmpty() {
        let oldSession = DateComponents(calendar: calendar, year: 2020, month: 1, day: 1).date!
        let sessions = [makeSession(id: "old", startDate: oldSession)]

        let result = HomeViewModel.filterSessions(
            sessions: sessions,
            timeFilter: .weekly,
            distanceFilter: .furthestDistance,
            now: now,
            calendar: calendar
        )

        XCTAssertTrue(result.isEmpty)
    }

    func testDeterministicTiebreaker_sortsByIdWhenTimesEqual() {
        let sessions = [
            makeSession(id: "z-session", startDate: now, fastest1km: 200),
            makeSession(id: "a-session", startDate: now, fastest1km: 200),
            makeSession(id: "m-session", startDate: now, fastest1km: 200),
        ]

        let result = HomeViewModel.filterSessions(
            sessions: sessions,
            timeFilter: .weekly,
            distanceFilter: .fastest1km,
            now: now,
            calendar: calendar
        )

        // Equal times → sorted by id ascending
        XCTAssertEqual(result.map(\.id), ["a-session", "m-session", "z-session"])
    }
}
