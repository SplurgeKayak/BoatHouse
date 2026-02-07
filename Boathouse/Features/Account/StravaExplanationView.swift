import SwiftUI

/// Detailed explanation of Strava connection and OAuth
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
        .navigationTitle("About Strava")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.run")
                .font(.system(size: 48))
                .foregroundStyle(.orange)

            Text("Strava Integration")
                .font(.title2)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity)
    }

    private var whyConnectSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Why Connect Strava?")
                .font(.headline)

            Text("Race Pace uses Strava to import your canoe and kayak sessions. This allows us to:")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                BulletPoint(text: "Automatically import eligible sessions")
                BulletPoint(text: "Verify GPS data for fair competition")
                BulletPoint(text: "Determine your age category from your profile")
                BulletPoint(text: "Confirm sessions are completed in the UK")
            }
        }
    }

    private var howItWorksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How OAuth Works")
                .font(.headline)

            Text("When you connect Strava, you'll be redirected to Strava's website to authorise Race Pace. This is a secure process called OAuth 2.0:")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 16) {
                StepRow(number: 1, title: "Authorise", description: "You log in to Strava and grant permission")
                StepRow(number: 2, title: "Token Exchange", description: "Strava gives us a secure access token")
                StepRow(number: 3, title: "Data Access", description: "We use the token to read your sessions")
                StepRow(number: 4, title: "Token Refresh", description: "Tokens expire and are automatically refreshed")
            }

            Text("We never see your Strava password. You can revoke access at any time from your Strava settings.")
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
                DataAccessRow(item: "Session data", icon: "figure.rowing", access: "Read only")
                DataAccessRow(item: "GPS routes", icon: "location.fill", access: "Read only")
            }

            HStack {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.red)
                Text("We never post to your Strava or modify any data")
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
                    answer: "Only sessions marked as 'Canoeing' or 'Kayaking' on Strava are imported."
                )

                FAQItem(
                    question: "What if I don't have a date of birth on Strava?",
                    answer: "You'll need to add your date of birth in the app to determine your race category eligibility."
                )

                FAQItem(
                    question: "Can I disconnect Strava?",
                    answer: "Yes, you can disconnect at any time from your Account settings. This will prevent new sessions from being imported."
                )

                FAQItem(
                    question: "How often are sessions synced?",
                    answer: "Sessions are synced automatically when you open the app and can be refreshed manually by pulling down on the Home screen."
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
