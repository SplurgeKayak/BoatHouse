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
                    // Avatar with ring
                    avatarView
                        .overlay {
                            if story.unseenCount > 0 {
                                Circle()
                                    .stroke(AppColors.accentGradient, lineWidth: ringWidth)
                                    .frame(width: avatarSize + ringWidth * 2, height: avatarSize + ringWidth * 2)
                            }
                        }

                    // Badge showing unseen count
                    if story.unseenCount > 0 {
                        badgeView
                            .offset(x: 4, y: -4)
                    }
                }

                // Name label
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
        Group {
            if let avatarURL = story.athleteAvatarURL {
                AsyncImage(url: avatarURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure, .empty:
                        initialsView
                    @unknown default:
                        initialsView
                    }
                }
            } else {
                initialsView
            }
        }
        .frame(width: avatarSize, height: avatarSize)
        .clipShape(Circle())
    }

    private var initialsView: some View {
        Circle()
            .fill(avatarBackgroundColor)
            .overlay {
                Text(story.initials)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
            }
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

    private var avatarBackgroundColor: Color {
        // Generate consistent color based on athlete ID
        let colors: [Color] = [
            .blue, .purple, .green, .orange, .pink, .teal, .indigo
        ]
        let hash = abs(story.athleteId.hashValue)
        return colors[hash % colors.count]
    }
}

#Preview {
    HStack(spacing: 16) {
        StoryBubbleView(
            story: AthleteStory(
                id: "story-1",
                athleteId: "user-001",
                athleteName: "James Wilson",
                athleteAvatarURL: nil,
                unseenActivities: []
            ),
            onTap: {}
        )

        StoryBubbleView(
            story: AthleteStory(
                id: "story-2",
                athleteId: "user-002",
                athleteName: "Sarah Chen",
                athleteAvatarURL: nil,
                unseenActivities: Array(repeating: Activity(
                    id: "act-1",
                    stravaId: 1,
                    userId: "user-002",
                    name: "Morning Paddle",
                    activityType: .kayaking,
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
                    isUKActivity: true,
                    flagCount: 0,
                    status: .verified,
                    importedAt: Date()
                ), count: 3)
            ),
            onTap: {}
        )

        StoryBubbleView(
            story: AthleteStory(
                id: "story-3",
                athleteId: "user-003",
                athleteName: "Mike Johnson",
                athleteAvatarURL: nil,
                unseenActivities: Array(repeating: Activity(
                    id: "act-2",
                    stravaId: 2,
                    userId: "user-003",
                    name: "Evening Row",
                    activityType: .rowing,
                    startDate: Date(),
                    elapsedTime: 7200,
                    movingTime: 6800,
                    distance: 12000,
                    maxSpeed: 5.0,
                    averageSpeed: 4.0,
                    startLocation: nil,
                    endLocation: nil,
                    polyline: nil,
                    isGPSVerified: true,
                    isUKActivity: true,
                    flagCount: 0,
                    status: .verified,
                    importedAt: Date()
                ), count: 12)
            ),
            onTap: {}
        )
    }
    .padding()
}
