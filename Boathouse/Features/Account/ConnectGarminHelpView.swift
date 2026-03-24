import SwiftUI

/// Intermediate help screen shown before Garmin OAuth flow.
/// Explains what connecting Garmin does and what the user needs.
struct ConnectGarminHelpView: View {
    let onConnect: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                headerSection

                requirementsSection

                stepsSection

                connectButton
            }
            .padding(24)
        }
        .navigationTitle("Connect Garmin")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") { dismiss() }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "applewatch.and.arrow.forward")
                .font(.system(size: 56))
                .foregroundStyle(AppColors.accent)

            Text("How to connect your Garmin")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text("Link your Garmin device to Race Pace so your paddle sessions are imported automatically.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Requirements

    private var requirementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Before you start")
                .font(.headline)

            VStack(alignment: .leading, spacing: 10) {
                RequirementRow(
                    icon: "checkmark.circle.fill",
                    text: "A Garmin device that records paddle sports"
                )
                RequirementRow(
                    icon: "checkmark.circle.fill",
                    text: "A Garmin Connect account"
                )
                RequirementRow(
                    icon: "checkmark.circle.fill",
                    text: "At least one kayak or canoe session synced to Garmin Connect"
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Steps

    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What happens next")
                .font(.headline)

            VStack(alignment: .leading, spacing: 16) {
                HelpStepRow(
                    number: 1,
                    title: "Sign in to Garmin Connect",
                    description: "You'll be taken to the Garmin website to log in securely."
                )
                HelpStepRow(
                    number: 2,
                    title: "Grant permission",
                    description: "Allow Race Pace to read your paddle sport activities."
                )
                HelpStepRow(
                    number: 3,
                    title: "Sessions sync automatically",
                    description: "Your kayak and canoe sessions will appear in the app within seconds."
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Connect Button

    private var connectButton: some View {
        Button {
            onConnect()
        } label: {
            HStack {
                Image(systemName: "link")
                Text("Connect your Garmin")
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .tint(AppColors.accent)
    }
}

// MARK: - Supporting Views

private struct RequirementRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(.green)
                .font(.subheadline)

            Text(text)
                .font(.subheadline)
        }
    }
}

private struct HelpStepRow: View {
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
                .background(AppColors.accent)
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

#Preview {
    NavigationStack {
        ConnectGarminHelpView(onConnect: {})
    }
}
