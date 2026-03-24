import SwiftUI
import CoreLocation

// MARK: - Instagram Session Card (full-card feed item)

struct InstagramSessionCard: View {
    let session: Session
    let userName: String
    let userAvatarURL: URL?
    let isSubscribed: Bool
    let isFocused: Bool
    let onTap: () -> Void
    let onToggleSubscription: () -> Void
    let onSetFocus: () -> Void
    let onClearFocus: () -> Void

    private var avatarInitials: String {
        let result = userName
            .split(separator: " ")
            .prefix(2)
            .compactMap { $0.first }
            .map { String($0) }
            .joined()
            .uppercased()
        return result.isEmpty ? "?" : result
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Title
                Text(session.name)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                // Secondary stats row
                HStack(spacing: 16) {
                    Label(session.sessionType.displayName, systemImage: session.sessionType.icon)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Label(session.formattedDuration, systemImage: "timer")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Label(session.formattedDistance, systemImage: "arrow.left.and.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Route preview
                if !session.decodedRouteCoordinates.isEmpty {
                    RoutePreviewShape(coordinates: session.decodedRouteCoordinates)
                        .frame(height: 140)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                // Pace metrics
                let paceStats = paceSegmentStats
                if !paceStats.isEmpty {
                    HStack(spacing: 16) {
                        ForEach(paceStats, id: \.title) { stat in
                            StatView(title: stat.title, value: stat.value)
                        }
                    }
                }

                Divider()

                // Meta row: avatar, name, time, follow button
                HStack(spacing: 10) {
                    AvatarView(url: userAvatarURL, initials: avatarInitials, id: session.userId, size: 32)

                    VStack(alignment: .leading, spacing: 1) {
                        Text(userName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)

                        Text(session.startDate, style: .relative)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // Verification badges
                    if session.isGPSVerified {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }

                    // Subscribe button
                    Button(action: onToggleSubscription) {
                        Image(systemName: isSubscribed ? "person.badge.checkmark.fill" : "person.badge.plus")
                            .font(.system(size: 18))
                            .foregroundStyle(isSubscribed ? Color.accentColor : Color.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(isSubscribed
                        ? String(format: Strings.Feed.unsubscribeFromAthlete, userName)
                        : String(format: Strings.Feed.subscribeToAthlete, userName))
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                onToggleSubscription()
            } label: {
                Label(
                    isSubscribed
                        ? String(format: Strings.Feed.unsubscribeFromAthlete, userName)
                        : String(format: Strings.Feed.subscribeToAthlete, userName),
                    systemImage: isSubscribed ? "person.badge.minus" : "person.badge.plus"
                )
            }

            Button {
                onSetFocus()
            } label: {
                Label(String(format: Strings.Feed.focusOnAthlete, userName), systemImage: "scope")
            }

            if isFocused {
                Button {
                    onClearFocus()
                } label: {
                    Label(Strings.Feed.showAllAthletes, systemImage: "person.3")
                }
            }
        }
    }

    private var paceSegmentStats: [(title: String, value: String)] {
        var stats: [(title: String, value: String)] = []
        if let t = session.formattedFastest1km  { stats.append(("1km", t)) }
        if let t = session.formattedFastest5km  { stats.append(("5km", t)) }
        if let t = session.formattedFastest10km { stats.append(("10km", t)) }
        return stats
    }
}

// MARK: - News Card

struct NewsCard: View {
    let item: ExternalNewsItem
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) { cardContent }
            .buttonStyle(.plain)
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Source badge
            HStack(spacing: 6) {
                Image(systemName: item.source.iconName)
                    .font(.caption)
                    .foregroundStyle(item.source.accentColor)

                Text(item.source.rawValue)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(item.source.accentColor)

                Spacer()

                Text(item.publishedAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(item.source.accentColor.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Title
            Text(item.title)
                .font(.headline)
                .foregroundStyle(.primary)
                .lineLimit(3)

            // Snippet
            Text(item.snippet)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(3)

            // "Read more" hint
            if item.link != nil {
                HStack {
                    Spacer()
                    Label(Strings.Feed.readMore, systemImage: "arrow.up.right.square")
                        .font(.caption)
                        .foregroundStyle(item.source.accentColor)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 4)
                .fill(item.source.accentColor)
                .frame(width: 4)
                .padding(.vertical, 8)
        }
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}

// MARK: - Session Row (compact tappable row for home feed)

struct SessionRow: View {
    let session: Session
    let userName: String
    let userAvatarURL: URL?
    let onTap: () -> Void

    private var avatarInitials: String {
        let result = userName
            .split(separator: " ")
            .prefix(2)
            .compactMap { $0.first }
            .map { String($0) }
            .joined()
            .uppercased()
        return result.isEmpty ? "?" : result
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                AvatarView(url: userAvatarURL, initials: avatarInitials, id: session.userId, size: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(userName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    Text(session.startDate, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(session.formattedDistance)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)

                    Text(session.formattedDuration)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Session Card

struct SessionCard: View {
    let session: Session
    var userName: String? = nil
    var userAvatarURL: URL? = nil
    var rank: Int? = nil

    private var displayName: String { userName ?? session.userId }

    private var avatarInitials: String {
        let result = displayName
            .split(separator: " ")
            .prefix(2)
            .compactMap { $0.first }
            .map { String($0) }
            .joined()
            .uppercased()
        return result.isEmpty ? "?" : result
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: avatar + name + date + optional rank badge
            HStack(spacing: 12) {
                AvatarView(url: userAvatarURL, initials: avatarInitials, id: session.userId, size: 44)

                VStack(alignment: .leading, spacing: 2) {
                    Text(displayName)
                        .font(.headline)

                    Text(session.startDate, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if let rank {
                    Text("#\(rank)")
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }

                if session.isFlagged {
                    Image(systemName: "flag.fill")
                        .foregroundStyle(.orange)
                }
            }

            // Core stats
            HStack(spacing: 20) {
                StatView(title: "Distance", value: session.formattedDistance)
                StatView(title: "Duration", value: session.formattedDuration)
            }

            // Pace metrics — only shown for distances actually covered
            let paceStats = paceSegmentStats
            if !paceStats.isEmpty {
                HStack(spacing: 20) {
                    ForEach(paceStats, id: \.title) { stat in
                        StatView(title: stat.title, value: stat.value)
                    }
                }
            }

            // Route preview (lightweight Canvas instead of MapKit)
            if !session.decodedRouteCoordinates.isEmpty {
                RoutePreviewShape(coordinates: session.decodedRouteCoordinates)
                    .frame(height: 160)
            }

            HStack {
                if session.isGPSVerified {
                    Label("GPS Verified", systemImage: "checkmark.shield.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }

                if session.isUKSession {
                    Label("UK", systemImage: "location.fill")
                        .font(.caption)
                        .foregroundStyle(.accent)
                }

                Spacer()

                Button {
                    // TODO: Implement flag action
                } label: {
                    Image(systemName: "flag")
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }

    private var paceSegmentStats: [(title: String, value: String)] {
        var stats: [(title: String, value: String)] = []
        if let t = session.formattedFastest1km  { stats.append(("1km Pace", t)) }
        if let t = session.formattedFastest5km  { stats.append(("5km Pace", t)) }
        if let t = session.formattedFastest10km { stats.append(("10km Pace", t)) }
        return stats
    }
}

// MARK: - Stat View

struct StatView: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color(.systemGray5))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}

// MARK: - Leaderboard Row

struct LeaderboardRow: View {
    let entry: LeaderboardEntry

    var body: some View {
        HStack(spacing: 12) {
            Text("\(entry.rank)")
                .font(.headline)
                .frame(width: 30)
                .foregroundStyle(medalColor)

            AvatarView(
                url: entry.userProfileURL,
                initials: String(entry.userName.prefix(1)),
                id: entry.userId,
                size: 36
            )

            Text(entry.userName)
                .font(.subheadline)

            Spacer()

            Text(entry.formattedScore)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(.vertical, 8)
    }

    private var medalColor: Color {
        switch entry.rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .primary
        }
    }
}
