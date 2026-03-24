import XCTest
@testable import Boathouse

final class GoalsTests: XCTestCase {

    // MARK: - Time parsing

    func testParseTimeString_validMinutesAndSeconds() {
        XCTAssertEqual(KayakingGoals.parseTimeString("4:30"), 270)
        XCTAssertEqual(KayakingGoals.parseTimeString("0:45"), 45)
        XCTAssertEqual(KayakingGoals.parseTimeString("12:00"), 720)
        XCTAssertEqual(KayakingGoals.parseTimeString("1:01"), 61)
    }

    func testParseTimeString_trailingWhitespace() {
        XCTAssertEqual(KayakingGoals.parseTimeString("  3:15  "), 195)
    }

    func testParseTimeString_invalidFormats() {
        XCTAssertNil(KayakingGoals.parseTimeString(""))
        XCTAssertNil(KayakingGoals.parseTimeString("430"))
        XCTAssertNil(KayakingGoals.parseTimeString("4:60"))    // seconds ≥ 60
        XCTAssertNil(KayakingGoals.parseTimeString("abc"))
        XCTAssertNil(KayakingGoals.parseTimeString("4:30:00")) // too many parts
        XCTAssertNil(KayakingGoals.parseTimeString(":30"))     // empty minutes
        XCTAssertNil(KayakingGoals.parseTimeString("0:00"))    // zero total
    }

    func testParseTimeString_negativeValues() {
        XCTAssertNil(KayakingGoals.parseTimeString("-1:30"))
    }

    // MARK: - Time formatting

    func testFormatTime_roundTrip() {
        XCTAssertEqual(KayakingGoals.formatTime(270), "4:30")
        XCTAssertEqual(KayakingGoals.formatTime(45), "0:45")
        XCTAssertEqual(KayakingGoals.formatTime(720), "12:00")
        XCTAssertEqual(KayakingGoals.formatTime(61), "1:01")
    }

    func testFormatTime_zero() {
        XCTAssertEqual(KayakingGoals.formatTime(0), "0:00")
    }

    // MARK: - Validation

    func testHasAnyGoal_allNil_returnsFalse() {
        let goals = KayakingGoals()
        XCTAssertFalse(goals.hasAnyGoal)
    }

    func testHasAnyGoal_withTimeGoal() {
        var goals = KayakingGoals()
        goals.timeGoal1k = 240
        XCTAssertTrue(goals.hasAnyGoal)
    }

    func testHasAnyGoal_withDistanceGoal() {
        var goals = KayakingGoals()
        goals.distancePerWeekKm = 50
        XCTAssertTrue(goals.hasAnyGoal)
    }

    func testHasAnyGoal_withRankingGoal() {
        var goals = KayakingGoals()
        goals.rankingGoals = ["senior_men": 10]
        XCTAssertTrue(goals.hasAnyGoal)
    }

    // MARK: - Storage round-trip

    func testGoalsStore_saveAndLoad() {
        let testDefaults = UserDefaults(suiteName: "GoalsTests")!
        testDefaults.removePersistentDomain(forName: "GoalsTests")
        let store = GoalsStore(defaults: testDefaults)

        let goals = KayakingGoals(
            timeGoal1k: 240,
            timeGoal5k: 1200,
            timeGoal10k: nil,
            distancePerWeekKm: 50,
            rankingGoals: ["senior_men": 5]
        )

        store.save(goals)
        let loaded = store.load()

        XCTAssertEqual(loaded, goals)
        XCTAssertTrue(store.hasCompletedGoals)
    }

    func testGoalsStore_loadReturnsNilWhenEmpty() {
        let testDefaults = UserDefaults(suiteName: "GoalsTestsEmpty")!
        testDefaults.removePersistentDomain(forName: "GoalsTestsEmpty")
        let store = GoalsStore(defaults: testDefaults)

        XCTAssertNil(store.load())
        XCTAssertFalse(store.hasCompletedGoals)
    }

    func testGoalsStore_clear() {
        let testDefaults = UserDefaults(suiteName: "GoalsTestsClear")!
        testDefaults.removePersistentDomain(forName: "GoalsTestsClear")
        let store = GoalsStore(defaults: testDefaults)

        store.save(KayakingGoals(timeGoal1k: 100))
        XCTAssertTrue(store.hasCompletedGoals)

        store.clear()
        XCTAssertNil(store.load())
        XCTAssertFalse(store.hasCompletedGoals)
    }

    // MARK: - GoalProgressCalculator

    func testGoalProgressCalculator_aheadOfGoal() {
        let sessions = [makeSession(best1k: 230)]   // faster than goal of 240
        XCTAssertEqual(GoalProgressCalculator.status(goal: 240, best: GoalProgressCalculator.best1k(from: sessions)), .aheadOfGoal)
    }

    func testGoalProgressCalculator_needsImprovement() {
        let sessions = [makeSession(best1k: 270)]   // slower than goal of 240
        XCTAssertEqual(GoalProgressCalculator.status(goal: 240, best: GoalProgressCalculator.best1k(from: sessions)), .needsImprovement)
    }

    // Helper — create a minimal Session with a given fastest1kmTime
    private func makeSession(best1k: TimeInterval) -> Session {
        Session(
            id: UUID().uuidString,
            stravaId: 0,
            userId: "andy-001",
            name: "Test",
            sessionType: .kayaking,
            startDate: Date(),
            elapsedTime: 3600,
            movingTime: 3600,
            distance: 10000,
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
            fastest1kmTime: best1k,
            fastest5kmTime: nil,
            fastest10kmTime: nil
        )
    }
}
