import SwiftUI

/// Explanation of Garmin connection benefits
struct GarminExplanationView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerSection
                whyConnectSection
                howItWorksSection
            }
            .padding(24)
        }
        .navigationTitle("About Garmin")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "link.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.accentColor)

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

            Text("Connect your Garmin account to automatically import your canoe and kayak sessions.")
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
            Text("How It Works")
                .font(.headline)

            VStack(alignment: .leading, spacing: 16) {
                StepRow(number: 1, title: "Connect", description: "Link your Garmin account to Race Pace")
                StepRow(number: 2, title: "Import", description: "Your canoe and kayak sessions are automatically imported")
                StepRow(number: 3, title: "Compete", description: "Your sessions are verified and entered into races")
            }

            Text("We never modify your Garmin data. You can disconnect at any time from your Account settings.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

#Preview {
    NavigationStack {
        GarminExplanationView()
    }
}
