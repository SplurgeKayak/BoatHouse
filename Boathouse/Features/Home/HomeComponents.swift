import SwiftUI
import CoreLocation

// MARK: - Session Card

struct SessionCard: View {
    let session: Session

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay {
                        Image(systemName: session.sessionType.icon)
                            .foregroundStyle(.accent)
                    }

                VStack(alignment: .leading, spacing: 2) {
                    Text(session.name)
                        .font(.headline)

                    Text(session.startDate, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

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

            // Segment times (only rows that have data)
            let segments = segmentStats
            if !segments.isEmpty {
                HStack(spacing: 20) {
                    ForEach(segments, id: \.title) { stat in
                        StatView(title: stat.title, value: stat.value)
                    }
                }
            }

            // Map preview
            if !session.decodedRouteCoordinates.isEmpty {
                SessionMapView(coordinates: session.decodedRouteCoordinates)
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

    private var segmentStats: [(title: String, value: String)] {
        var stats: [(title: String, value: String)] = []
        if let t = session.formattedFastest1km  { stats.append(("Fastest 1km", t)) }
        if let t = session.formattedFastest5km  { stats.append(("Fastest 5km", t)) }
        if let t = session.formattedFastest10km { stats.append(("Fastest 10km", t)) }
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
