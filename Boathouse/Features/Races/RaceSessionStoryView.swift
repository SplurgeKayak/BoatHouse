import SwiftUI

/// Story-style full-screen view showing an athlete's session(s) that generated their leaderboard position.
struct RaceSessionStoryView: View {
    let entry: LeaderboardEntry
    let race: Race
    let sessions: [Session]

    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex: Int = 0
    @State private var progress: Double = 0.0
    @State private var timer: Timer? = nil

    private let pageDuration: Double = 6.0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if sessions.isEmpty {
                emptyView
            } else {
                sessionPage(sessions[currentIndex])
            }
        }
        .onAppear { startTimer() }
        .onDisappear { timer?.invalidate() }
        .gesture(
            DragGesture(minimumDistance: 30)
                .onEnded { value in
                    if value.translation.height > 60 { dismiss() }
                }
        )
    }

    // MARK: - Session page

    private func sessionPage(_ session: Session) -> some View {
        VStack(spacing: 0) {
            // Progress bar
            StoryProgressBarView(
                totalCount: max(sessions.count, 1),
                currentIndex: currentIndex,
                progress: progress
            )
            .padding(.horizontal, 16)
            .padding(.top, 56)

            // Header: avatar + name + position
            HStack(spacing: 12) {
                AvatarView(
                    url: entry.userProfileURL,
                    initials: String(entry.userName.prefix(1)),
                    id: entry.userId,
                    size: 40
                )

                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.userName)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)

                    Text("#\(entry.rank) in \(race.type.displayName)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.75))
                }

                Spacer()

                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(8)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)

            Spacer()

            // Session name
            Text(session.name)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            // Key metrics grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                storyMetric(icon: "arrow.left.and.right", label: "Distance", value: session.formattedDistance)
                storyMetric(icon: "timer", label: "Duration", value: session.formattedDuration)

                if let pace1k = session.formattedFastest1km {
                    storyMetric(icon: "1.circle.fill", label: "Fastest 1km", value: pace1k)
                }
                if let pace5k = session.formattedFastest5km {
                    storyMetric(icon: "5.circle.fill", label: "Fastest 5km", value: pace5k)
                }
                if let pace10k = session.formattedFastest10km {
                    storyMetric(icon: "10.circle.fill", label: "Fastest 10km", value: pace10k)
                }

                storyMetric(icon: "calendar", label: "Date",
                            value: session.startDate.formatted(date: .abbreviated, time: .omitted))
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)

            // GPS & leaderboard score row
            HStack(spacing: 20) {
                if session.isGPSVerified {
                    Label("GPS Verified", systemImage: "checkmark.shield.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Leaderboard Score")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.6))
                    Text(entry.formattedScore)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)

            Spacer()

            // Tap areas for navigation
            HStack(spacing: 0) {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { goToPrevious() }

                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { goToNext() }
            }
            .frame(height: 120)
        }
    }

    // MARK: - Empty view

    private var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "figure.water.fitness")
                .font(.system(size: 60))
                .foregroundStyle(.white.opacity(0.5))

            Text("No session data available")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.7))

            Button("Close") { dismiss() }
                .buttonStyle(.bordered)
                .tint(.white)
        }
    }

    // MARK: - Metric cell

    private func storyMetric(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.accentColor)

            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(.white)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Timer

    private func startTimer() {
        progress = 0
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            progress += 0.05 / pageDuration
            if progress >= 1.0 {
                goToNext()
            }
        }
    }

    private func goToNext() {
        if currentIndex < sessions.count - 1 {
            currentIndex += 1
            startTimer()
        } else {
            dismiss()
        }
    }

    private func goToPrevious() {
        if currentIndex > 0 {
            currentIndex -= 1
            startTimer()
        } else {
            progress = 0
        }
    }
}

#Preview {
    RaceSessionStoryView(
        entry: LeaderboardEntry(
            id: "e1", rank: 1, userId: "billy-001",
            userName: "Billy Butler", userProfileURL: nil,
            score: 243, sessionId: nil,
            raceType: .fastest1km
        ),
        race: MockData.races[0],
        sessions: MockData.sessions.filter { $0.userId == "billy-001" }.prefix(3).map { $0 }
    )
}
