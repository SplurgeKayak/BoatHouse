import SwiftUI

// MARK: - News Source

enum NewsSource: String, CaseIterable {
    case paddleUKMarathon = "Marathon News"
    case paddleUKSprint   = "Sprint News"
    case facebookGroup1   = "Facebook Paddling Group"
    case facebookGroup2   = "Facebook Racing Group"

    var iconName: String {
        switch self {
        case .paddleUKMarathon: return "flag.checkered"
        case .paddleUKSprint:   return "bolt.fill"
        case .facebookGroup1:   return "person.3.fill"
        case .facebookGroup2:   return "trophy.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .paddleUKMarathon: return Color(red: 0/255, green: 122/255, blue: 255/255)
        case .paddleUKSprint:   return Color(red: 255/255, green: 149/255, blue: 0/255)
        case .facebookGroup1:   return Color(red: 66/255, green: 103/255, blue: 178/255)
        case .facebookGroup2:   return Color(red: 52/255, green: 120/255, blue: 246/255)
        }
    }
}

// MARK: - External News Item

struct ExternalNewsItem: Identifiable {
    let id: String
    let title: String
    let snippet: String
    let source: NewsSource
    let publishedAt: Date
    let link: URL?
    let imageURL: URL?
}

// MARK: - Protocol

protocol ExternalNewsServiceProtocol {
    func fetchNews() async -> [ExternalNewsItem]
}

// MARK: - Mock Implementation

struct MockExternalNewsService: ExternalNewsServiceProtocol {
    func fetchNews() async -> [ExternalNewsItem] {
        let now = Date()
        func daysAgo(_ d: Double) -> Date { now.addingTimeInterval(-d * 86_400) }

        return [
            ExternalNewsItem(
                id: "news-001",
                title: "2025 Paddle UK Marathon Nationals – Entry Now Open",
                snippet: "Registration is now live for the 2025 British Canoe Marathon Championships. Athletes are invited to enter across all categories. Don't miss your chance to compete at the pinnacle of UK marathon racing.",
                source: .paddleUKMarathon,
                publishedAt: daysAgo(0.5),
                link: URL(string: "https://paddleuk.org.uk/category/all-news/marathon-news/"),
                imageURL: nil
            ),
            ExternalNewsItem(
                id: "news-002",
                title: "Sprint World Cup Selection – Squad Announced",
                snippet: "Paddle UK Sprint has announced the squad selected for the upcoming World Cup events. Congratulations to all athletes who made the cut following the recent time trials.",
                source: .paddleUKSprint,
                publishedAt: daysAgo(1.2),
                link: URL(string: "https://paddleuk.org.uk/category/all-news/sprint-news/"),
                imageURL: nil
            ),
            ExternalNewsItem(
                id: "news-003",
                title: "Weekend Paddle on the Thames – Who's In?",
                snippet: "We're organising a social paddle along the Thames this Saturday. All abilities welcome. Bring your own boat or we can arrange club demos. Meet at Kingston Bridge at 9am.",
                source: .facebookGroup1,
                publishedAt: daysAgo(1.8),
                link: URL(string: "https://www.facebook.com/groups/260941715090944"),
                imageURL: nil
            ),
            ExternalNewsItem(
                id: "news-004",
                title: "Regatta Results – Twickenham Summer Sprint",
                snippet: "Great racing at this weekend's Twickenham Summer Sprint. Full results now available. Massive PBs across the board – the form is looking sharp heading into the national season.",
                source: .facebookGroup2,
                publishedAt: daysAgo(2.3),
                link: URL(string: "https://www.facebook.com/groups/329276707107635"),
                imageURL: nil
            ),
            ExternalNewsItem(
                id: "news-005",
                title: "Marathon Series Round 3 – Race Report",
                snippet: "An action-packed third round of the Paddle UK Marathon Series took place last weekend on the River Wye. Conditions were challenging but delivered some impressive performances at the front.",
                source: .paddleUKMarathon,
                publishedAt: daysAgo(3.1),
                link: URL(string: "https://paddleuk.org.uk/category/all-news/marathon-news/"),
                imageURL: nil
            ),
            ExternalNewsItem(
                id: "news-006",
                title: "Junior Sprint Development Camp – Applications Open",
                snippet: "Paddle UK Sprint is running a dedicated Junior Development Camp this August. Places are limited – applications close on 1st July. A fantastic opportunity for up-and-coming sprint paddlers.",
                source: .paddleUKSprint,
                publishedAt: daysAgo(4.0),
                link: URL(string: "https://paddleuk.org.uk/category/all-news/sprint-news/"),
                imageURL: nil
            ),
            ExternalNewsItem(
                id: "news-007",
                title: "Club Paddle Saturday Recap – Brilliant Turnout",
                snippet: "Thanks to everyone who joined us on Saturday's club paddle! 22 paddlers hit the water which is a record for a mid-week community session. See photos in the comments below.",
                source: .facebookGroup1,
                publishedAt: daysAgo(5.5),
                link: URL(string: "https://www.facebook.com/groups/260941715090944"),
                imageURL: nil
            ),
            ExternalNewsItem(
                id: "news-008",
                title: "Race Tips: Pacing Strategy for 10km Events",
                snippet: "One of our coaches shares his top tips for pacing a 10km race event. From the start sprint to mid-race conservation and the final push – this is a must-read before your next competition.",
                source: .facebookGroup2,
                publishedAt: daysAgo(6.5),
                link: URL(string: "https://www.facebook.com/groups/329276707107635"),
                imageURL: nil
            ),
        ]
    }
}
