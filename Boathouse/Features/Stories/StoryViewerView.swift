import SwiftUI

/// Full-screen story viewer showing sessions one by one (like Instagram Stories)
struct StoryViewerView: View {
    let story: AthleteStory
    let onDismiss: () -> Void
    let onMarkSeen: ([String]) -> Void

    @State private var currentIndex: Int = 0
    @State private var seenSessionIds: Set<String> = []
    @State private var showAllCaughtUp: Bool = false

    private var sessions: [Session] {
        story.unseenSessions
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()

                if showAllCaughtUp {
                    allCaughtUpView
                } else if !sessions.isEmpty {
                    TabView(selection: $currentIndex) {
                        ForEach(Array(sessions.enumerated()), id: \.element.id) { index, session in
                            StorySessionDetailView(
                                session: session,
                                athleteName: story.athleteName,
                                athleteInitials: story.initials
                            )
                            .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .ignoresSafeArea()

                    HStack(spacing: 0) {
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture {
                                goToPrevious()
                            }

                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture {
                                goToNext()
                            }
                    }
                }

                VStack {
                    headerView
                        .padding(.top, geometry.safeAreaInsets.top + 8)
                        .padding(.horizontal)

                    Spacer()
                }
            }
        }
        .statusBarHidden()
        .onChange(of: currentIndex) { _, newIndex in
            markCurrentAsSeen(index: newIndex)
        }
        .onAppear {
            markCurrentAsSeen(index: currentIndex)
        }
    }

    private var headerView: some View {
        VStack(spacing: 12) {
            StoryProgressBarView(
                totalCount: sessions.count,
                currentIndex: currentIndex,
                progress: 1.0
            )

            HStack(spacing: 12) {
                AvatarView(
                    url: story.athleteAvatarURL,
                    initials: story.initials,
                    id: story.athleteId,
                    size: 36
                )

                VStack(alignment: .leading, spacing: 2) {
                    Text(story.athleteName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)

                    if currentIndex < sessions.count {
                        Text(sessions[currentIndex].startDate, style: .relative)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }

                Spacer()

                Button {
                    dismissViewer()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Circle())
                }
            }
        }
    }

    private var allCaughtUpView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(AppColors.accent)

            Text("All Caught Up!")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)

            Text("You've seen all of \(story.firstName)'s recent sessions")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button {
                dismissViewer()
            } label: {
                Text("Done")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(width: 120, height: 44)
                    .background(AppColors.accent)
                    .clipShape(Capsule())
            }
            .padding(.top, 20)
        }
    }

    // MARK: - Actions

    private func goToPrevious() {
        if currentIndex > 0 {
            withAnimation(.easeInOut(duration: 0.2)) {
                currentIndex -= 1
            }
        }
    }

    private func goToNext() {
        if currentIndex < sessions.count - 1 {
            withAnimation(.easeInOut(duration: 0.2)) {
                currentIndex += 1
            }
        } else {
            withAnimation {
                showAllCaughtUp = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                dismissViewer()
            }
        }
    }

    private func markCurrentAsSeen(index: Int) {
        guard index < sessions.count else { return }
        let sessionId = sessions[index].id
        if !seenSessionIds.contains(sessionId) {
            seenSessionIds.insert(sessionId)
            onMarkSeen([sessionId])
        }
    }

    private func dismissViewer() {
        onMarkSeen(Array(seenSessionIds))
        onDismiss()
    }
}

/// Session detail card shown in story viewer
struct StorySessionDetailView: View {
    let session: Session
    let athleteName: String
    let athleteInitials: String

    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()

                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: session.sessionType.icon)
                            .font(.title2)
                            .foregroundStyle(AppColors.accent)

                        Text(session.sessionType.displayName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Spacer()

                        if session.isGPSVerified {
                            Label("GPS Verified", systemImage: "checkmark.shield.fill")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                    }

                    Text(session.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)

                    Text(session.startDate, style: .relative)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Divider()

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
                            Spacer()
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding(24)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
                .padding(.horizontal, 20)

                Spacer()
                    .frame(height: geometry.safeAreaInsets.bottom + 40)
            }
        }
    }

    private func statItem(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func formatMovingTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes) min"
    }
}

#Preview {
    StoryViewerView(
        story: AthleteStory(
            id: "story-1",
            athleteId: "user-001",
            athleteName: "James Wilson",
            athleteAvatarURL: URL(string: "https://i.pravatar.cc/150?u=user-001"),
            unseenSessions: [
                Session(
                    id: "sess-1",
                    stravaId: 1,
                    userId: "user-001",
                    name: "Morning Thames Paddle",
                    sessionType: .kayaking,
                    startDate: Date().addingTimeInterval(-3600),
                    elapsedTime: 3845,
                    movingTime: 3602,
                    distance: 8750.5,
                    maxSpeed: 4.8,
                    averageSpeed: 2.43,
                    startLocation: nil,
                    endLocation: nil,
                    polyline: nil,
                    isGPSVerified: true,
                    isUKSession: true,
                    flagCount: 0,
                    status: .verified,
                    importedAt: Date()
                )
            ]
        ),
        onDismiss: { print("Dismissed") },
        onMarkSeen: { ids in print("Marked seen: \(ids)") }
    )
}
