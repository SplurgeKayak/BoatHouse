import SwiftUI
import CoreLocation

// MARK: - Session Card (Redesigned)

/// Activity card with visual hierarchy:
/// 1) Header: avatar + name/title + filtered metric badge (top-right)
/// 2) Recorded timestamp
/// 3) Secondary details (de-emphasized)
/// 4) Route preview + badges
/// 5) Tappable → opens full activity detail
struct SessionCard: View {
    let session: Session
    var activeFilter: RaceType? = nil

    /// Looked-up user for avatar display
    private var user: User? { MockData.user(for: session.userId) }

    private var userInitials: String {
        let name = user?.displayName ?? session.userId
        let parts = name.components(separatedBy: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 1) Header: avatar + user context + filtered metric badge
            HStack(alignment: .top) {
                // Profile picture (replaces old Circle placeholder)
                AvatarView(
                    url: user?.profileImageURL,
                    initials: userInitials,
                    id: session.userId,
                    size: 36
                )

                VStack(alignment: .leading, spacing: 1) {
                    Text(user?.displayName ?? session.userId.replacingOccurrences(of: "user-", with: "Athlete "))
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text(session.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Filtered metric badge in header-right ("green area")
                if let metric = filterAwareMetric, isDistanceFilter {
                    FilteredMetricBadge(label: metric.label, value: metric.value)
                } else if session.isFlagged {
                    Image(systemName: "flag.fill")
                        .foregroundStyle(.orange)
                        .font(.caption)
                }
            }

            // 2) Recorded timestamp
            Text("Recorded: \(session.startDate.formatted(date: .abbreviated, time: .shortened))")
                .font(.caption)
                .foregroundStyle(.secondary)

            // 3) Key metric (only when NOT a distance filter — avoids duplication)
            if !isDistanceFilter, let metric = filterAwareMetric {
                HStack(alignment: .firstTextBaseline) {
                    Text(metric.value)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.accent)

                    Text(metric.label)
                        .font(.caption)
                        .foregroundStyle(AppColors.accent.opacity(0.8))
                }
            }

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
        .contentShape(Rectangle())
    }

    /// Whether the active filter is a distance-specific filter (1km/5km/10km)
    private var isDistanceFilter: Bool {
        switch activeFilter {
        case .fastest1km, .fastest5km, .fastest10km: return true
        default: return false
        }
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

// MARK: - Filtered Metric Badge

/// Prominent Strava-orange badge shown in the top-right of the activity card header
/// when a distance filter (1km/5km/10km) is active.
struct FilteredMetricBadge: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            // Strava-orange icon container
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppColors.accent)
                    .frame(width: 32, height: 32)
                    .shadow(color: AppColors.accent.opacity(0.3), radius: 4, y: 2)

                Image(systemName: "flame.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
            }

            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.accent)

            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
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
