import SwiftUI

/// Goals splash screen shown on every cold launch before the main UI.
/// Shows goal progress summary if goals exist, or a motivational prompt if not.
/// Automatically dismisses after a brief delay, or on tap.
struct GoalsSplashView: View {
    let onDismiss: () -> Void

    @StateObject private var viewModel = GoalsViewModel()
    @State private var appeared = false

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [AppColors.accent.opacity(0.15), Color(.systemBackground)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // Icon
                Image(systemName: "target")
                    .font(.system(size: 56))
                    .foregroundStyle(AppColors.accent)
                    .scaleEffect(appeared ? 1.0 : 0.5)
                    .opacity(appeared ? 1.0 : 0.0)

                Text("Your Goals")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .opacity(appeared ? 1.0 : 0.0)

                if viewModel.hasGoals {
                    // Show quick goal summary
                    VStack(spacing: 12) {
                        ForEach(viewModel.progress) { progress in
                            HStack {
                                Image(systemName: progress.goal.category.icon)
                                    .foregroundStyle(AppColors.accent)
                                    .frame(width: 24)

                                Text(progress.goal.category.fullName)
                                    .font(.subheadline)

                                Spacer()

                                if progress.isGoalMet {
                                    Label("Met", systemImage: "checkmark.circle.fill")
                                        .font(.caption)
                                        .foregroundStyle(.green)
                                } else if let best = progress.formattedBest {
                                    Text(best)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(AppColors.accent)
                                } else {
                                    Text("--:--")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground).opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 32)
                    .opacity(appeared ? 1.0 : 0.0)
                } else {
                    Text("Set paddling goals to track your progress")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .opacity(appeared ? 1.0 : 0.0)
                }

                Spacer()

                // Tap to continue hint
                Text("Tap to continue")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .opacity(appeared ? 0.6 : 0.0)

                Spacer()
                    .frame(height: 40)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onDismiss()
        }
        .task {
            await viewModel.loadGoals()
            withAnimation(.easeOut(duration: 0.5)) {
                appeared = true
            }
            // Auto-dismiss after 2.5 seconds
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            onDismiss()
        }
    }
}
