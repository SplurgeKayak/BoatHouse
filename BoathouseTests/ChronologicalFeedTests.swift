import XCTest
@testable import Boathouse

final class ChronologicalFeedTests: XCTestCase {

    func testChronologicalOrder_newestFirst() {
        let early = Date(timeIntervalSince1970: 1000)
        let late  = Date(timeIntervalSince1970: 9000)
        let vm = HomeViewModel()
        vm.sessions = [
            makeSession(id: "a", date: early),
            makeSession(id: "b", date: late),
        ]
        XCTAssertEqual(vm.chronologicalSessions.map(\.id), ["b", "a"])
    }

    func testChronologicalOrder_emptyList() {
        let vm = HomeViewModel()
        vm.sessions = []
        XCTAssertTrue(vm.chronologicalSessions.isEmpty)
    }

    func testUserName_knownUser() {
        let vm = HomeViewModel()
        // MockData.users must have at least one user; pick first
        if let user = MockData.users.first {
            XCTAssertEqual(vm.userName(for: user.id), user.displayName)
        }
    }

    func testUserName_unknownUser() {
        let vm = HomeViewModel()
        XCTAssertEqual(vm.userName(for: "unknown-xyz"), "unknown-xyz")
    }

    func testChronologicalOrder_multipleItems() {
        let d1 = Date(timeIntervalSince1970: 1000)
        let d2 = Date(timeIntervalSince1970: 5000)
        let d3 = Date(timeIntervalSince1970: 9000)
        let vm = HomeViewModel()
        vm.sessions = [
            makeSession(id: "a", date: d2),
            makeSession(id: "b", date: d1),
            makeSession(id: "c", date: d3),
        ]
        XCTAssertEqual(vm.chronologicalSessions.map(\.id), ["c", "a", "b"])
    }

    func testUserAvatarURL_unknownUser_returnsNil() {
        let vm = HomeViewModel()
        XCTAssertNil(vm.userAvatarURL(for: "unknown-xyz"))
    }

    // MARK: - Helper

    private func makeSession(id: String, date: Date) -> Session {
        Session(
            id: id, stravaId: 0, userId: "u1",
            name: "Test", sessionType: .kayaking,
            startDate: date, elapsedTime: 600, movingTime: 600,
            distance: 1000, maxSpeed: nil, averageSpeed: nil,
            startLocation: nil, endLocation: nil, polyline: nil,
            isGPSVerified: true, isUKSession: true,
            flagCount: 0, status: .verified, importedAt: date,
            fastest1kmTime: nil, fastest5kmTime: nil, fastest10kmTime: nil
        )
    }
}
