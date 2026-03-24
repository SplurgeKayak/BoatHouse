import SwiftUI
import CoreLocation

/// Instagram-story-style full-screen popup for viewing a session's activity details.
/// Present via `fullScreenCover(item:)` binding to an optional `Session`.
struct ActivityStoryPopup: View {
    let session: Session
    let athleteName: String
    let athleteAvatarURL: URL?
    @Environment(\.dismiss) private var dismiss
    @GestureState private var dragOffset: CGFloat = 0
    @State private var isDismissing = false

    var body: some View {
        ZStack {
            // Dark overlay — tap to dismiss
            Color.black.opacity(0.85)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            VStack {
                // Header
                headerView
                    .padding(.top, 16)

                Spacer()

                // Activity card
                activityCard
                    .offset(y: dragOffset)
                    .gesture(
                        DragGesture()
                            .updating($dragOffset) { value, state, _ in
                                if value.translation.height > 0 {
                                    state = value.translation.height
                                }
                            }
                            .onEnded { value in
                                if value.translation.height > 120 {
                                    dismiss()
                                }
                            }
                    )

                Spacer()
                    .frame(height: 40)
            }
        }
        .statusBarHidden()
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(spacing: 12) {
            AvatarView(
                url: athleteAvatarURL,
                initials: String(athleteName.prefix(1)),
                id: session.userId,
                size: 40
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(athleteName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)

                Text(session.startDate.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }

            Spacer()

            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Activity Card

    private var activityCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Session type + name
            HStack {
                Image(systemName: session.sessionType.icon)
                    .font(.title2)
                    .foregroundStyle(AppColors.accent)

                Text(session.sessionType.displayName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                if session.isGPSVerified {
                    Label("GPS", systemImage: "checkmark.shield.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }

            Text(session.name)
                .font(.title2)
                .fontWeight(.bold)

            Text(session.startDate.formatted(date: .abbreviated, time: .shortened))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Divider()

            // Route map
            if !session.decodedRouteCoordinates.isEmpty {
                SessionMapView(coordinates: session.decodedRouteCoordinates)
                    .frame(height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // Stats grid
            HStack(spacing: 0) {
                statItem(title: "Distance", value: session.formattedDistance)
                statItem(title: "Duration", value: session.formattedDuration)
                statItem(title: "Avg Speed", value: session.formattedAverageSpeed)
            }

            HStack(spacing: 0) {
                statItem(title: "Max Speed", value: session.formattedMaxSpeed)
                statItem(title: "Moving Time", value: formatMovingTime(session.movingTime))
                if session.isUKSession {
                    statItem(title: "Location", value: "UK")
                } else {
                    Spacer().frame(maxWidth: .infinity)
                }
            }

            // Segment times
            let segments = segmentData
            if !segments.isEmpty {
                Divider()
                ForEach(segments, id: \.label) { segment in
                    HStack {
                        Text(segment.label)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(segment.value)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(AppColors.accent)
                    }
                }
            }
        }
        .padding(24)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
        .padding(.horizontal, 20)
    }

    // MARK: - Helpers

    private var segmentData: [(label: String, value: String)] {
        var result: [(String, String)] = []
        if let t = session.formattedFastest1km { result.append(("Fastest 1km", t)) }
        if let t = session.formattedFastest5km { result.append(("Fastest 5km", t)) }
        if let t = session.formattedFastest10km { result.append(("Fastest 10km", t)) }
        return result
    }

    private func statItem(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func formatMovingTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        if hours > 0 { return "\(hours)h \(minutes)m" }
        return "\(minutes) min"
    }
}
