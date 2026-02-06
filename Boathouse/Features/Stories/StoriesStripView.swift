import SwiftUI

/// Horizontal scrollable strip of story bubbles
struct StoriesStripView: View {
    let stories: [AthleteStory]
    let onTap: (AthleteStory) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Club Group Sessions")
                .font(.headline)
                .padding(.horizontal)
                .accessibilityLabel("Club Group Sessions")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(stories.filter { $0.unseenCount > 0 }) { story in
                        StoryBubbleView(story: story) {
                            onTap(story)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 4)
                .padding(.bottom, 4)
            }
        }
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }
}

#Preview {
    StoriesStripView(
        stories: [
            AthleteStory(
                id: "story-1",
                athleteId: "user-001",
                athleteName: "James Wilson",
                athleteAvatarURL: nil,
                unseenActivities: [
                    Activity(
                        id: "act-1",
                        stravaId: 1,
                        userId: "user-001",
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
                    )
                ]
            ),
            AthleteStory(
                id: "story-2",
                athleteId: "user-002",
                athleteName: "Sarah Chen",
                athleteAvatarURL: nil,
                unseenActivities: [
                    Activity(
                        id: "act-2",
                        stravaId: 2,
                        userId: "user-002",
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
                    ),
                    Activity(
                        id: "act-3",
                        stravaId: 3,
                        userId: "user-002",
                        name: "Weekend Canoe",
                        activityType: .canoeing,
                        startDate: Date().addingTimeInterval(-86400),
                        elapsedTime: 5400,
                        movingTime: 5000,
                        distance: 8000,
                        maxSpeed: 4.2,
                        averageSpeed: 3.5,
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
            AthleteStory(
                id: "story-3",
                athleteId: "user-003",
                athleteName: "Mike Johnson",
                athleteAvatarURL: nil,
                unseenActivities: [
                    Activity(
                        id: "act-4",
                        stravaId: 4,
                        userId: "user-003",
                        name: "Quick Sprint",
                        activityType: .kayaking,
                        startDate: Date(),
                        elapsedTime: 1800,
                        movingTime: 1700,
                        distance: 3000,
                        maxSpeed: 5.5,
                        averageSpeed: 4.5,
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
            )
        ],
        onTap: { story in
            print("Tapped story: \(story.athleteName)")
        }
    )
}
