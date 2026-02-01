import SwiftUI
import AuthenticationServices

/// Strava OAuth connection view with explanation
struct StravaOAuthView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = StravaOAuthViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    explanationSection
                    permissionsSection
                    connectButton
                }
                .padding(24)
            }
            .navigationTitle("Connect Strava")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Connection Failed", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "Please try again")
            }
            .sheet(isPresented: $viewModel.showWebAuth) {
                StravaWebAuthView(viewModel: viewModel)
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 16) {
            Image("strava-logo")
                .resizable()
                .scaledToFit()
                .frame(height: 60)
                .accessibilityHidden(true)

            // Fallback if asset not available
            Image(systemName: "figure.run")
                .font(.system(size: 48))
                .foregroundStyle(.orange)

            Text("Connect Your Strava Account")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
        }
    }

    private var explanationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Why Connect Strava?")
                .font(.headline)

            VStack(alignment: .leading, spacing: 12) {
                ExplanationRow(
                    icon: "arrow.down.circle.fill",
                    title: "Import Activities",
                    description: "Your canoe and kayak activities are automatically imported"
                )

                ExplanationRow(
                    icon: "person.fill",
                    title: "Profile Verification",
                    description: "Your age determines race category eligibility"
                )

                ExplanationRow(
                    icon: "location.fill",
                    title: "UK Verification",
                    description: "Only UK-based activities qualify for races"
                )

                ExplanationRow(
                    icon: "checkmark.shield.fill",
                    title: "GPS Verification",
                    description: "GPS data ensures fair competition"
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var permissionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Permissions Required")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                PermissionRow(text: "Read your activity data", granted: true)
                PermissionRow(text: "Read your profile information", granted: true)
                PermissionRow(text: "Read activity GPS data", granted: true)
            }

            Text("We never post to your Strava account or share your data with third parties.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var connectButton: some View {
        Button {
            viewModel.startOAuthFlow()
        } label: {
            HStack {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "link")
                    Text("Connect with Strava")
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
        }
        .buttonStyle(StravaButtonStyle())
        .disabled(viewModel.isLoading)
    }
}

struct ExplanationRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.accent)
                .frame(width: 24)

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

struct PermissionRow: View {
    let text: String
    let granted: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: granted ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(granted ? .green : .secondary)

            Text(text)
                .font(.subheadline)
        }
    }
}

struct StravaButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .background(Color.orange)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

/// Web authentication view for Strava OAuth
struct StravaWebAuthView: View {
    @ObservedObject var viewModel: StravaOAuthViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            StravaWebViewRepresentable(viewModel: viewModel)
                .navigationTitle("Strava Login")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") {
                            viewModel.cancelOAuth()
                            dismiss()
                        }
                    }
                }
        }
    }
}

#Preview {
    StravaOAuthView()
}
