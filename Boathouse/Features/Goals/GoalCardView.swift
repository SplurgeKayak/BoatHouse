import SwiftUI

/// Card displaying a single goal with gauge chart and key metrics.
/// Hierarchy: category label → current best (prominent) → gauge → 30-day avg → trend
struct GoalCardView: View {
    let progress: GoalProgress

    var body: some View {
        VStack(spacing: 12) {
            // 1) Category label
            HStack {
                Image(systemName: progress.goal.category.icon)
                    .foregroundStyle(AppColors.accent)
                Text(progress.goal.category.fullName)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                if progress.isGoalMet {
                    Label("Goal Met", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }

            // 2) Current best time (most prominent)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(progress.formattedBest ?? "--:--")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(progress.isGoalMet ? .green : .primary)

                Text("best")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Target")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(progress.goal.formattedTarget)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(AppColors.accent)
                }
            }

            // 3) Gauge visual
            GaugeChartView(
                progressFraction: progress.progressFraction,
                averageFraction: averageFraction,
                isGoalMet: progress.isGoalMet
            )
            .frame(height: 100)

            // 4) 30-day average
            HStack {
                Label {
                    Text("30-day avg: \(progress.formattedAverage ?? "--:--")")
                        .font(.caption)
                } icon: {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)

                Spacer()

                // 5) Trend indicator (sessions count)
                Text("\(progress.sessionsCount) sessions")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Dummy data subtle indicator (internal, not user-facing label)
            if progress.isDummyData {
                Text("Based on estimated data")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }

    private var averageFraction: Double? {
        guard let avg = progress.averageTime30Days, progress.goal.targetTime > 0 else { return nil }
        return min(progress.goal.targetTime / avg, 1.0)
    }
}
