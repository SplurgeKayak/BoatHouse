import SwiftUI

/// App color constants
enum AppColors {
    static let accent = Color(red: 252/255, green: 76/255, blue: 2/255) // Strava orange #FC4C02
    static let accentGradient = LinearGradient(
        colors: [
            Color(red: 252/255, green: 76/255, blue: 2/255),
            Color(red: 252/255, green: 120/255, blue: 2/255)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

/// Individual story bubble showing athlete avatar with unseen indicator
struct StoryBubbleView: View {
    let story: AthleteStory
    let onTap: () -> Void

    private let avatarSize: CGFloat = 68
    private let ringWidth: CGFloat = 3
    private let badgeSize: CGFloat = 22

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                ZStack(alignment: .topTrailing) {
                    avatarView
                        .overlay {
                            if story.unseenCount > 0 {
                                Circle()
                                    .stroke(AppColors.accentGradient, lineWidth: ringWidth)
                                    .frame(width: avatarSize + ringWidth * 2, height: avatarSize + ringWidth * 2)
                            }
                        }

                    if story.unseenCount > 0 {
                        badgeView
                            .offset(x: 4, y: -4)
                    }
                }

                Text(story.firstName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .frame(width: avatarSize + 8)
            }
        }
        .buttonStyle(.plain)
    }

    private var avatarView: some View {
        AvatarView(
            url: story.athleteAvatarURL,
            initials: story.initials,
            id: story.athleteId,
            size: avatarSize
        )
    }

    private var badgeView: some View {
        Text(story.unseenCount > 99 ? "99+" : "\(story.unseenCount)")
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(.white)
            .frame(minWidth: badgeSize, minHeight: badgeSize)
            .padding(.horizontal, story.unseenCount > 9 ? 4 : 0)
            .background(AppColors.accent)
            .clipShape(Capsule())
    }

}

#Preview {
    HStack(spacing: 16) {
        StoryBubbleView(
            story: AthleteStory(
                id: "story-1",
                athleteId: "user-001",
                athleteName: "James Wilson",
                athleteAvatarURL: URL(string: "https://i.pravatar.cc/150?u=user-001"),
                unseenSessions: []
            ),
            onTap: {}
        )

        StoryBubbleView(
            story: AthleteStory(
                id: "story-2",
                athleteId: "user-002",
                athleteName: "Sarah Chen",
                athleteAvatarURL: URL(string: "https://i.pravatar.cc/150?u=user-002"),
                unseenSessions: Array(repeating: Session(
                    id: "sess-1",
                    stravaId: 1,
                    userId: "user-002",
                    name: "Morning Paddle",
                    sessionType: .kayaking,
                    startDate: Date(),
                    elapsedTime: 3600,
                    movingTime: 3400,
                    distance: 5000,
                    maxSpeed: 4.5,
                    averageSpeed: 3.2,
                    startLocation: nil,
                    endLocation: nil,
                    polyline: nil,
                    isGPSVerified: true,
                    isUKSession: true,
                    flagCount: 0,
                    status: .verified,
                    importedAt: Date()
                ), count: 3)
            ),
            onTap: {}
        )
    }
    .padding()
}
