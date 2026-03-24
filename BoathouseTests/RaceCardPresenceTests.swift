import XCTest
@testable import Boathouse

final class RaceCardPresenceTests: XCTestCase {

    // MARK: - All distances present for every category

    func testAllDistancesPresent_forEveryCategory() async throws {
        let service = RaceService()
        let races = try await service.fetchActiveRaces()

        for duration in RaceDuration.allCases {
            for category in RaceCategory.allCases {
                for raceType in RaceType.allCases {
                    let match = races.first {
                        $0.duration == duration &&
                        $0.category == category &&
                        $0.type == raceType
                    }
                    XCTAssertNotNil(
                        match,
                        "Missing race for duration=\(duration.rawValue) category=\(category.rawValue) type=\(raceType.rawValue)"
                    )
                }
            }
        }
    }

    // MARK: - No entries state

    func testNoEntriesState_whenEntryCountZero() {
        let now = Date()
        let race = Race(
            id: "test-zero",
            type: .fastest1km,
            duration: .weekly,
            category: .seniorMen,
            startDate: now.addingTimeInterval(-86400),
            endDate: now.addingTimeInterval(86400),
            entryCount: 0,
            prizePool: 0,
            status: .active,
            createdAt: now
        )
        XCTAssertFalse(race.canEnter, "A race with entryCount==0 should not be enterable")
    }

    // MARK: - Placeholder race has zero entries

    func testPlaceholderRace_hasZeroEntries() async throws {
        let service = RaceService()
        let races = try await service.fetchActiveRaces()

        // Any race whose id starts with "placeholder-" must have entryCount == 0
        let placeholders = races.filter { $0.id.hasPrefix("placeholder-") }
        for race in placeholders {
            XCTAssertEqual(race.entryCount, 0, "Placeholder race \(race.id) should have 0 entries")
        }
    }
}
