import Foundation

/// A unified feed item for the Club Room mixed feed.
enum FeedItem: Identifiable {
    case session(Session, userName: String, userAvatarURL: URL?)
    case news(ExternalNewsItem)

    var id: String {
        switch self {
        case .session(let s, _, _): return "session-\(s.id)"
        case .news(let n):          return "news-\(n.id)"
        }
    }

    var publishedAt: Date {
        switch self {
        case .session(let s, _, _): return s.startDate
        case .news(let n):          return n.publishedAt
        }
    }
}
