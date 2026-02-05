import SwiftUI

/// Full-screen story viewer showing activities one by one (like Instagram Stories)
struct StoryViewerView: View {
    let story: AthleteStory
    let onDismiss: () -> Void
    let onMarkSeen: ([String]) -> Void

    @State private var currentIndex: Int = 0
    @State private var seenActivityIds: Set<String> = []
    @State private var showAllCaughtUp: Bool = false

    private var activities: [Activity] {
        story.unseenActivities
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.black.ignoresSafeArea()

                // Content
                if showAllCaughtUp {
                    allCaughtUpView
                } else if !activities.isEmpty {
                    // Paged content
                    TabView(selection: $currentIndex) {
                        ForEach(Array(activities.enumerated()), id: \.element.id) { index, activity in
                            StoryActivityDetailView(
                                activity: activity,
                                athleteName: story.athleteName,
                                athleteInitials: story.initials
                            )
                            .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .ignoresSafeArea()

                    // Tap zones for navigation
                    HStack(spacing: 0) {
                        // Left tap zone - go back
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture {
                                goToPrevious()
                            }

                        // Right tap zone - go forward
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture {
                                goToNext()
                            }
                    }
                }

                // Header overlay
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
            // Progress bar
            StoryProgressBarView(
                totalCount: activities.count,
                currentIndex: currentIndex,
                progress: 1.0
            )

            // User info and close button
            HStack(spacing: 12) {
                // Avatar
                Circle()
                    .fill(avatarColor)
                    .frame(width: 36, height: 36)
                    .overlay {
                        Text(story.initials)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                    }

                // Name and time
                VStack(alignment: .leading, spacing: 2) {
                    Text(story.athleteName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)

                    if currentIndex < activities.count {
                        Text(activities[currentIndex].startDate, style: .relative)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }

                Spacer()

                // Close button
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

            Text("You've seen all of \(story.firstName)'s recent activities")
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

    private var avatarColor: Color {
        let colors: [Color] = [.blue, .purple, .green, .orange, .pink, .teal, .indigo]
        let hash = abs(story.athleteId.hashValue)
        return colors[hash % colors.count]
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
        if currentIndex < activities.count - 1 {
            withAnimation(.easeInOut(duration: 0.2)) {
                currentIndex += 1
            }
        } else {
            // Last activity - show all caught up
            withAnimation {
                showAllCaughtUp = true
            }

            // Auto-dismiss after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                dismissViewer()
            }
        }
    }

    private func markCurrentAsSeen(index: Int) {
        guard index < activities.count else { return }
        let activityId = activities[index].id
        if !seenActivityIds.contains(activityId) {
            seenActivityIds.insert(activityId)
            onMarkSeen([activityId])
        }
    }

    private func dismissViewer() {
        // Mark all viewed activities as seen
        onMarkSeen(Array(seenActivityIds))
        onDismiss()
    }
}

/// Activity detail card shown in story viewer
struct StoryActivityDetailView: View {
    let activity: Activity
    let athleteName: String
    let athleteInitials: String

    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()

                // Activity card
                VStack(alignment: .leading, spacing: 16) {
                    // Header with activity type
                    HStack {
                        Image(systemName: activity.activityType.icon)
                            .font(.title2)
                            .foregroundStyle(AppColors.accent)

                        Text(activity.activityType.displayName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Spacer()

                        if activity.isGPSVerified {
                            Label("GPS Verified", systemImage: "checkmark.shield.fill")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                    }

                    // Activity title
                    Text(activity.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)

                    // Time ago
                    Text(activity.startDate, style: .relative)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Divider()

                    // Stats grid
                    HStack(spacing: 0) {
                        statItem(title: "Distance", value: activity.formattedDistance)
                        statItem(title: "Duration", value: activity.formattedDuration)
                        statItem(title: "Avg Speed", value: activity.formattedAverageSpeed)
                    }

                    // Additional stats
                    HStack(spacing: 0) {
                        statItem(title: "Max Speed", value: activity.formattedMaxSpeed)
                        statItem(title: "Moving Time", value: formatMovingTime(activity.movingTime))
                        if activity.isUKActivity {
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
            athleteAvatarURL: nil,
            unseenActivities: [
                Activity(
                    id: "act-1",
                    stravaId: 1,
                    userId: "user-001",
                    name: "Morning Thames Paddle",
                    activityType: .kayaking,
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
                    isUKActivity: true,
                    flagCount: 0,
                    status: .verified,
                    importedAt: Date()
                ),
                Activity(
                    id: "act-2",
                    stravaId: 2,
                    userId: "user-001",
                    name: "Evening Sprint Session",
                    activityType: .canoeing,
                    startDate: Date().addingTimeInterval(-86400),
                    elapsedTime: 2456,
                    movingTime: 2312,
                    distance: 5890.2,
                    maxSpeed: 5.2,
                    averageSpeed: 2.55,
                    startLocation: nil,
                    endLocation: nil,
                    polyline: nil,
                    isGPSVerified: true,
                    isUKActivity: true,
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
