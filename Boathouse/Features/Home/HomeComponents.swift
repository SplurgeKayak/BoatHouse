import SwiftUI
import CoreLocation

// MARK: - Session Card (Redesigned)

/// Activity card with new visual hierarchy:
/// 1) User context (name at top)
/// 2) Key performance metric (filter-aware, Strava orange)
/// 3) Time of activity (Strava orange call-out)
/// 4) Secondary details (de-emphasized)
/// 5) Tappable → opens full activity detail
struct SessionCard: View {
    let session: Session
    var activeFilter: RaceType? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 1) User context: profile name + activity type
            HStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.2))
                    .frame(width: 36, height: 36)
                    .overlay {
                        Image(systemName: session.sessionType.icon)
                            .font(.callout)
                            .foregroundStyle(.accent)
                    }

                VStack(alignment: .leading, spacing: 1) {
                    Text(session.userId.replacingOccurrences(of: "user-", with: "Athlete "))
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text(session.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if session.isFlagged {
                    Image(systemName: "flag.fill")
                        .foregroundStyle(.orange)
                        .font(.caption)
                }
            }

            // 2) Key performance metric (filter-aware, Strava orange)
            if let metric = filterAwareMetric {
                HStack(alignment: .firstTextBaseline) {
                    Text(metric.value)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.accent)

                    Text(metric.label)
                        .font(.caption)
                        .foregroundStyle(AppColors.accent.opacity(0.8))
                }
            }

            // 3) Time of activity (Strava orange emphasis)
            Text(session.startDate, style: .relative)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(AppColors.accent)

            // 4) Secondary details (de-emphasized)
            HStack(spacing: 16) {
                StatView(title: "Distance", value: session.formattedDistance)
                StatView(title: "Duration", value: session.formattedDuration)
                if let speed = session.averageSpeedKmh {
                    StatView(title: "Avg Speed", value: String(format: "%.1f km/h", speed))
                }
            }
            .foregroundStyle(.secondary)

            // Route preview
            if !session.decodedRouteCoordinates.isEmpty {
                RoutePreviewShape(coordinates: session.decodedRouteCoordinates)
                    .frame(height: 120)
            }

            // Badges
            HStack(spacing: 8) {
                if session.isGPSVerified {
                    Label("GPS", systemImage: "checkmark.shield.fill")
                        .font(.caption2)
                        .foregroundStyle(.green)
                }
                if session.isUKSession {
                    Label("UK", systemImage: "location.fill")
                        .font(.caption2)
                        .foregroundStyle(.accent)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        .contentShape(Rectangle()) // Make entire card tappable
    }

    /// Extract the key metric based on active filter.
    private var filterAwareMetric: (label: String, value: String)? {
        switch activeFilter {
        case .fastest1km:
            guard let t = session.formattedFastest1km else { return nil }
            return ("Fastest 1km", t)
        case .fastest5km:
            guard let t = session.formattedFastest5km else { return nil }
            return ("Fastest 5km", t)
        case .fastest10km:
            guard let t = session.formattedFastest10km else { return nil }
            return ("Fastest 10km", t)
        default:
            return ("Duration", session.formattedDuration)
        }
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
