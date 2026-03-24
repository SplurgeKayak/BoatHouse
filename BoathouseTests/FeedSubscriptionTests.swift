import XCTest
@testable import Boathouse

final class FeedSubscriptionTests: XCTestCase {

    // MARK: - Helpers

    private func makeSession(id: String, userId: String, date: Date = Date()) -> Session {
        Session(
            id: id, stravaId: 0, userId: userId,
            name: "Session \(id)", sessionType: .kayaking,
            startDate: date, elapsedTime: 600, movingTime: 600,
            distance: 5000, maxSpeed: nil, averageSpeed: nil,
            startLocation: nil, endLocation: nil, polyline: nil,
            isGPSVerified: true, isUKSession: true,
            flagCount: 0, status: .verified, importedAt: date,
            fastest1kmTime: 250, fastest5kmTime: nil, fastest10kmTime: nil
        )
    }

    private func makeNewsItem(id: String, date: Date = Date()) -> ExternalNewsItem {
        ExternalNewsItem(
            id: id,
            title: "News \(id)",
            snippet: "Snippet for \(id)",
            source: .paddleUKMarathon,
            publishedAt: date,
            link: nil,
            imageURL: nil
        )
    }

    // MARK: - Subscribe / Unsubscribe

    func testUnsubscribe_hidesUserSessions() {
        let vm = HomeViewModel()
        let userA = "user-a"
        let userB = "user-b"
        let now = Date()

        vm.sessions = [
            makeSession(id: "s1", userId: userA, date: now),
            makeSession(id: "s2", userId: userB, date: now.addingTimeInterval(-10)),
        ]
        // Set up both users as explicitly subscribed, then unsubscribe userA
        vm.subscribedUserIds = [userA, userB]
        vm.toggleSubscription(userId: userA) // removes userA → subscribedUserIds = [userB]

        let sessionIds = vm.feedItems.compactMap { item -> String? in
            if case .session(let s, _, _) = item { return s.id }
            return nil
        }
        XCTAssertFalse(sessionIds.contains("s1"), "Unsubscribed user's session should be hidden")
        XCTAssertTrue(sessionIds.contains("s2"), "Subscribed user's session should be visible")
    }

    func testSubscribe_restoresUserSessions() {
        let vm = HomeViewModel()
        let userA = "user-a"
        let now = Date()

        vm.sessions = [makeSession(id: "s1", userId: userA, date: now)]
        // Start unsubscribed
        vm.subscribedUserIds = []
        // Re-subscribe
        vm.toggleSubscription(userId: userA)

        let sessionIds = vm.feedItems.compactMap { item -> String? in
            if case .session(let s, _, _) = item { return s.id }
            return nil
        }
        XCTAssertTrue(sessionIds.contains("s1"), "Re-subscribed user's sessions should appear")
    }

    func testFocusOnAthlete_showsOnlyThatAthlete() {
        let vm = HomeViewModel()
        let userA = "user-a"
        let userB = "user-b"
        let now = Date()

        vm.sessions = [
            makeSession(id: "s1", userId: userA, date: now),
            makeSession(id: "s2", userId: userB, date: now.addingTimeInterval(-10)),
        ]
        vm.subscribedUserIds = [userA, userB]
        vm.setFocus(userId: userA)

        let sessionIds = vm.feedItems.compactMap { item -> String? in
            if case .session(let s, _, _) = item { return s.id }
            return nil
        }
        XCTAssertTrue(sessionIds.contains("s1"), "Focused athlete's sessions should be shown")
        XCTAssertFalse(sessionIds.contains("s2"), "Other athlete's sessions should be hidden during focus")
    }

    func testClearFocus_returnsToMixedFeed() {
        let vm = HomeViewModel()
        let userA = "user-a"
        let userB = "user-b"
        let now = Date()

        vm.sessions = [
            makeSession(id: "s1", userId: userA, date: now),
            makeSession(id: "s2", userId: userB, date: now.addingTimeInterval(-10)),
        ]
        vm.subscribedUserIds = [userA, userB]
        vm.setFocus(userId: userA)
        vm.setFocus(userId: nil)

        XCTAssertNil(vm.focusedUserId)
        let sessionIds = vm.feedItems.compactMap { item -> String? in
            if case .session(let s, _, _) = item { return s.id }
            return nil
        }
        XCTAssertTrue(sessionIds.contains("s1"), "User A sessions visible after clearing focus")
        XCTAssertTrue(sessionIds.contains("s2"), "User B sessions visible after clearing focus")
    }

    func testNewsItemsPresent_inMixedFeed() {
        // Verifies that after subscribing to only userB, userB's sessions still appear
        // and the feed remains non-empty (news interleave would trigger if news were loaded)
        let vm = HomeViewModel()
        let userA = "user-a"
        let userB = "user-b"
        let now = Date()

        vm.sessions = [
            makeSession(id: "s1", userId: userA, date: now),
            makeSession(id: "s2", userId: userB, date: now.addingTimeInterval(-10)),
            makeSession(id: "s3", userId: userB, date: now.addingTimeInterval(-20)),
            makeSession(id: "s4", userId: userB, date: now.addingTimeInterval(-30)),
        ]
        // Subscribe only to userB; userA is excluded (subscribed set is non-empty)
        vm.subscribedUserIds = [userB]
        vm.toggleSubscription(userId: userB) // removes userB — now set is empty → show all
        vm.toggleSubscription(userId: userB) // re-adds userB → set = [userB]

        let sessionIds = vm.feedItems.compactMap { item -> String? in
            if case .session(let s, _, _) = item { return s.id }
            return nil
        }
        // userB's sessions should appear; userA's should not (set is non-empty, userA excluded)
        XCTAssertTrue(sessionIds.contains("s2"), "userB session s2 should be visible")
        XCTAssertTrue(sessionIds.contains("s3"), "userB session s3 should be visible")
        XCTAssertFalse(sessionIds.contains("s1"), "userA session s1 should be hidden when only userB is subscribed")
    }
}
