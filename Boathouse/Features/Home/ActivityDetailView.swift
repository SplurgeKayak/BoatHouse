import SwiftUI
import CoreLocation

/// Full-screen activity detail view showing all session data.
/// Includes Strava deep link and flag UI.
struct ActivityDetailView: View {
    let session: Session
    let activeFilter: RaceType?
    @Environment(\.dismiss) private var dismiss
    @State private var showFlagConfirmation = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Key metric hero (filter-aware)
                    keyMetricSection

                    // Route map (full MapKit, not the lightweight preview)
                    if !session.decodedRouteCoordinates.isEmpty {
                        SessionMapView(coordinates: session.decodedRouteCoordinates)
                            .frame(height: 220)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal)
                    }

                    // All stats
                    statsSection

                    // Segment times
                    segmentTimesSection

                    // Session metadata
                    metadataSection

                    // Actions: Strava deep link + flag
                    actionsSection
                }
                .padding(.vertical)
            }
            .navigationTitle(session.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .alert("Flag Activity", isPresented: $showFlagConfirmation) {
                Button("Flag as Suspicious", role: .destructive) {
                    // UI only — no backend logic required yet
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Flag this activity for review? This cannot be undone.")
            }
        }
    }

    // MARK: - Key Metric (filter-aware)

    private var keyMetricSection: some View {
        VStack(spacing: 8) {
            // User context
            HStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.2))
                    .frame(width: 44, height: 44)
                    .overlay {
                        Image(systemName: session.sessionType.icon)
                            .foregroundStyle(.accent)
                    }

                VStack(alignment: .leading, spacing: 2) {
                    Text(session.name)
                        .font(.headline)
                    Text(session.startDate, style: .relative)
                        .font(.caption)
                        .foregroundStyle(AppColors.accent)
                }

                Spacer()
            }

            // Primary metric from active filter
            if let metric = filterAwareMetric {
                VStack(spacing: 4) {
                    Text(metric.label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(metric.value)
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.accent)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
        }
        .padding(.horizontal)
    }

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

    // MARK: - Stats Grid

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Performance")
                .font(.headline)
                .padding(.horizontal)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                statCell(title: "Distance", value: session.formattedDistance)
                statCell(title: "Duration", value: session.formattedDuration)
                statCell(title: "Avg Speed", value: session.formattedAverageSpeed)
                statCell(title: "Max Speed", value: session.formattedMaxSpeed)
            }
            .padding(.horizontal)
        }
    }

    private func statCell(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Segment Times

    private var segmentTimesSection: some View {
        let segments = [
            ("Fastest 1km", session.formattedFastest1km),
            ("Fastest 5km", session.formattedFastest5km),
            ("Fastest 10km", session.formattedFastest10km)
        ].compactMap { label, value -> (String, String)? in
            guard let v = value else { return nil }
            return (label, v)
        }

        return Group {
            if !segments.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Segment Times")
                        .font(.headline)
                        .padding(.horizontal)

                    ForEach(segments, id: \.0) { label, value in
                        HStack {
                            Text(label)
                                .font(.subheadline)
                            Spacer()
                            Text(value)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(AppColors.accent)
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
    }

    // MARK: - Metadata

    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Details")
                .font(.headline)
                .padding(.horizontal)

            Group {
                metaRow(icon: "figure.rowing", label: "Type", value: session.sessionType.displayName)
                metaRow(icon: "clock", label: "Elapsed Time", value: formatElapsed(session.elapsedTime))

                if session.isGPSVerified {
                    metaRow(icon: "checkmark.shield.fill", label: "GPS Verified", value: "Yes", color: .green)
                }

                if session.isUKSession {
                    metaRow(icon: "location.fill", label: "UK Session", value: "Yes")
                }

                metaRow(icon: "shield", label: "Status", value: session.status.displayName)
            }
            .padding(.horizontal)
        }
    }

    private func metaRow(icon: String, label: String, value: String, color: Color = .primary) -> some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 20)
                .foregroundStyle(.secondary)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(color)
        }
    }

    private func formatElapsed(_ time: TimeInterval) -> String {
        let h = Int(time) / 3600
        let m = (Int(time) % 3600) / 60
        let s = Int(time) % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%02d:%02d", m, s)
    }

    // MARK: - Actions

    private var actionsSection: some View {
        VStack(spacing: 12) {
            // Open in Strava
            Button {
                openInStrava()
            } label: {
                Label("Open in Strava", systemImage: "arrow.up.right.square")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppColors.accent)

            // Flag activity
            Button(role: .destructive) {
                showFlagConfirmation = true
            } label: {
                Label("Flag Activity", systemImage: "flag")
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.bordered)
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private func openInStrava() {
        // Deep link: strava://activities/{stravaId}
        // Fallback: web URL
        let stravaURL = URL(string: "strava://activities/\(session.stravaId)")
        let webURL = URL(string: "https://www.strava.com/activities/\(session.stravaId)")

        if let url = stravaURL, UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else if let url = webURL {
            UIApplication.shared.open(url)
        }
    }
}
