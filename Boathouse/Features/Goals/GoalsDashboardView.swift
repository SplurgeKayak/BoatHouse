import SwiftUI

/// Goals dashboard view — shown as Home when goals exist (State B).
/// Displays goal cards with progress, followed by recent activity context.
struct GoalsDashboardView: View {
    @ObservedObject var viewModel: GoalsViewModel
    @Binding var showGoalEntry: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header with "My Goals" link
            HStack {
                Label("Your Goals", systemImage: "target")
                    .font(.headline)

                Spacer()

                Button {
                    showGoalEntry = true
                } label: {
                    Label("Edit", systemImage: "pencil")
                        .font(.caption)
                        .foregroundStyle(AppColors.accent)
                }
            }
            .padding(.horizontal)

            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else if viewModel.progress.isEmpty {
                emptyGoalsState
            } else {
                // Goal cards
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.progress) { progress in
                        GoalCardView(progress: progress)
                            .padding(.horizontal)
                    }
                }
            }
        }
        .padding(.vertical)
    }

    private var emptyGoalsState: some View {
        VStack(spacing: 12) {
            Image(systemName: "target")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)

            Text("Set your first goal to track progress")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button("Add Goal") {
                showGoalEntry = true
            }
            .buttonStyle(.borderedProminent)
            .tint(AppColors.accent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}
