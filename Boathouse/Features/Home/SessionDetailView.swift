import SwiftUI

// MARK: - Session Detail Sheet

struct SessionDetailSheet: View {
    let session: Session
    let userName: String
    let userAvatarURL: URL?
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var showingUserSessions = false

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

    private var locationText: String {
        guard let loc = session.startLocation else { return "Location unavailable" }
        return String(format: "%.4f, %.4f", loc.latitude, loc.longitude)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, d MMM yyyy · HH:mm"
        return formatter.string(from: session.startDate)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header — avatar + name (tappable to show user sessions)
                    Button {
                        showingUserSessions = true
                    } label: {
                        HStack(spacing: 12) {
                            AvatarView(url: userAvatarURL, initials: avatarInitials, id: session.userId, size: 56)

                            Text(userName)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(.primary)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)

                    Divider()

                    // Location
                    Label(locationText, systemImage: "location.fill")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    // Date & time
                    Label(formattedDate, systemImage: "calendar")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    // Stats row
                    HStack(spacing: 20) {
                        StatView(title: "Distance", value: session.formattedDistance)
                        StatView(title: "Duration", value: session.formattedDuration)
                        StatView(title: "Avg Speed", value: session.formattedAverageSpeed)
                    }

                    // Pace breakdown
                    paceBreakdownSection

                    // Route preview
                    if !session.decodedRouteCoordinates.isEmpty {
                        RoutePreviewShape(coordinates: session.decodedRouteCoordinates)
                            .frame(height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // GPS / UK badges
                    HStack(spacing: 16) {
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
                    }
                }
                .padding()
            }
            .navigationTitle(session.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingUserSessions) {
                UserSessionsView(userId: session.userId, userName: userName)
                    .environmentObject(appState)
            }
        }
    }

    // MARK: - Pace Breakdown

    @ViewBuilder
    private var paceBreakdownSection: some View {
        let rows = paceRows
        if !rows.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Pace Breakdown")
                    .font(.headline)

                let fastestTime = rows.compactMap { $0.time }.min()

                ForEach(rows, id: \.label) { row in
                    HStack {
                        Text(row.label)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(width: 50, alignment: .leading)

                        Text(row.formatted)
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Spacer()

                        if let time = row.time, let fastest = fastestTime, time == fastest {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.yellow)
                                .font(.caption)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private struct PaceRow {
        let label: String
        let formatted: String
        let time: TimeInterval?
    }

    private var paceRows: [PaceRow] {
        var rows: [PaceRow] = []
        if let t = session.fastest1kmTime, let f = session.formattedFastest1km {
            rows.append(PaceRow(label: "1km", formatted: f, time: t))
        }
        if let t = session.fastest5kmTime, let f = session.formattedFastest5km {
            rows.append(PaceRow(label: "5km", formatted: f, time: t))
        }
        if let t = session.fastest10kmTime, let f = session.formattedFastest10km {
            rows.append(PaceRow(label: "10km", formatted: f, time: t))
        }
        return rows
    }
}
