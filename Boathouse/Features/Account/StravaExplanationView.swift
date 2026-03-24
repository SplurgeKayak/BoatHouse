import SwiftUI

/// Detailed explanation of Garmin connection and how data flows into Race Pace
struct StravaExplanationView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerSection

                whyConnectSection

                howItWorksSection

                dataUsageSection

                faqSection
            }
            .padding(24)
        }
        .navigationTitle("About Garmin")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "applewatch.and.arrow.forward")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.accent)

            Text("Garmin Integration")
                .font(.title2)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity)
    }

    private var whyConnectSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Why Connect Garmin?")
                .font(.headline)

            Text("Race Pace uses Garmin Connect to import your canoe and kayak sessions. This allows us to:")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                BulletPoint(text: "Automatically import eligible sessions from your Garmin device")
                BulletPoint(text: "Verify GPS data for fair competition")
                BulletPoint(text: "Determine your age category from your profile")
                BulletPoint(text: "Confirm sessions are completed in the UK")
            }
        }
    }

    private var howItWorksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How It Works")
                .font(.headline)

            Text("When you connect Garmin, you'll be redirected to Garmin Connect to authorise Race Pace. This is a secure process:")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 16) {
                StepRow(number: 1, title: "Authorise", description: "You log in to Garmin Connect and grant permission")
                StepRow(number: 2, title: "Sync Sessions", description: "Your kayak and canoe sessions are imported automatically")
                StepRow(number: 3, title: "GPS Verification", description: "We verify GPS data to ensure fair racing")
                StepRow(number: 4, title: "Auto Updates", description: "New sessions sync each time you open the app")
            }

            Text("We never see your Garmin credentials. You can revoke access at any time from your Garmin Connect settings.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private var dataUsageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What Data We Access")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                DataAccessRow(item: "Profile information", icon: "person.fill", access: "Read only")
                DataAccessRow(item: "Paddle sport activities", icon: "figure.rowing", access: "Read only")
                DataAccessRow(item: "GPS routes", icon: "location.fill", access: "Read only")
            }

            HStack {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.red)
                Text("We never post to your Garmin or modify any data")
                    .font(.caption)
            }
            .padding()
            .background(Color.red.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private var faqSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Frequently Asked Questions")
                .font(.headline)

            VStack(alignment: .leading, spacing: 16) {
                FAQItem(
                    question: "What sessions are imported?",
                    answer: "Only sessions recorded as paddling activities (canoeing, kayaking) on your Garmin device are imported."
                )

                FAQItem(
                    question: "What if I don't have a date of birth on Garmin?",
                    answer: "You'll need to add your date of birth in the app to determine your race category eligibility."
                )

                FAQItem(
                    question: "Can I disconnect Garmin?",
                    answer: "Yes, you can disconnect at any time from your Account settings. This will prevent new sessions from being imported."
                )

                FAQItem(
                    question: "How often are sessions synced?",
                    answer: "Sessions are synced automatically when you open the app and can be refreshed manually by pulling down on the Home screen."
                )

                FAQItem(
                    question: "Which Garmin devices are supported?",
                    answer: "Any Garmin device that records paddle sport activities and syncs to Garmin Connect is supported."
                )
            }
        }
    }
}

struct BulletPoint: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.caption)

            Text(text)
                .font(.subheadline)
        }
    }
}

struct StepRow: View {
    let number: Int
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(Color.accentColor)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct DataAccessRow: View {
    let item: String
    let icon: String
    let access: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.accent)
                .frame(width: 24)

            Text(item)
                .font(.subheadline)

            Spacer()

            Text(access)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct FAQItem: View {
    let question: String
    let answer: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(question)
                .font(.subheadline)
                .fontWeight(.medium)

            Text(answer)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    NavigationStack {
        StravaExplanationView()
    }
}
