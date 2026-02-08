import SwiftUI

/// Full-screen Goals overlay that sits on top of tab content.
/// Dark blue theme, dismissible via drag-down gesture or close button.
/// Lightweight and never blocks navigation — a layer that comes and goes.
struct GoalsOverlayView: View {
    let onDismiss: () -> Void

    @StateObject private var viewModel = GoalsViewModel()
    @State private var showGoalEntry = false
    @State private var dragOffset: CGFloat = 0
    @EnvironmentObject var appState: AppState

    /// Threshold for drag-to-dismiss (points)
    private let dismissThreshold: CGFloat = 120

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: 0) {
                    // Drag handle + header
                    overlayHeader

                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                    } else if viewModel.progress.isEmpty {
                        emptyGoalsPrompt
                    } else {
                        goalsContent
                    }
                }
                .frame(minHeight: geo.size.height)
            }
            .background(GoalColors.darkBlue)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .offset(y: max(dragOffset, 0))
            .gesture(dismissDragGesture)
        }
        .task {
            await viewModel.loadGoals()
        }
        .sheet(isPresented: $showGoalEntry) {
            GoalEntrySheet { goals in
                Task { await viewModel.saveAndReload(goals) }
                appState.hasCompletedGoals = true
            }
        }
    }

    // MARK: - Header

    private var overlayHeader: some View {
        VStack(spacing: 12) {
            // Drag handle
            Capsule()
                .fill(GoalColors.mutedBlue)
                .frame(width: 36, height: 5)
                .padding(.top, 10)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Your Goals")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(GoalColors.textPrimary)

                    Text("Track your paddling progress")
                        .font(.caption)
                        .foregroundStyle(GoalColors.textSecondary)
                }

                Spacer()

                // Edit goals
                if viewModel.hasGoals {
                    Button {
                        showGoalEntry = true
                    } label: {
                        Image(systemName: "pencil.circle.fill")
                            .font(.title3)
                            .foregroundStyle(GoalColors.textSecondary)
                    }
                }

                // Dismiss button
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(GoalColors.textSecondary)
                }
                .accessibilityLabel("Dismiss goals")
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
    }

    // MARK: - Goals Content (Dark Blue Cards)

    private var goalsContent: some View {
        LazyVStack(spacing: 14) {
            ForEach(viewModel.progress) { progress in
                DarkGoalCardView(progress: progress)
                    .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 12)
    }

    // MARK: - Empty State

    private var emptyGoalsPrompt: some View {
        VStack(spacing: 20) {
            Image(systemName: "flag.checkered")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.accent)

            Text("Set Your Paddling Goals")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(GoalColors.textPrimary)

            Text("Track progress with personal time targets\nfor 1km, 5km, and 10km distances.")
                .font(.subheadline)
                .foregroundStyle(GoalColors.textSecondary)
                .multilineTextAlignment(.center)

            Button {
                showGoalEntry = true
            } label: {
                Text("Set Goals")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppColors.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 32)
        }
        .padding(.vertical, 40)
    }

    // MARK: - Drag to Dismiss

    private var dismissDragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                // Only allow downward drag
                if value.translation.height > 0 {
                    dragOffset = value.translation.height
                }
            }
            .onEnded { value in
                if value.translation.height > dismissThreshold ||
                   value.predictedEndTranslation.height > dismissThreshold * 1.5 {
                    onDismiss()
                }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    dragOffset = 0
                }
            }
    }
}

// MARK: - Dark Goal Card View

/// Goal card with dark blue theme — replaces the light GoalCardView in the overlay.
/// Strong contrast for readability, green success indicator, modern athletic aesthetic.
struct DarkGoalCardView: View {
    let progress: GoalProgress

    var body: some View {
        VStack(spacing: 12) {
            // 1) Category + status
            HStack {
                Image(systemName: progress.goal.category.icon)
                    .foregroundStyle(AppColors.accent)
                Text(progress.goal.category.fullName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(GoalColors.textPrimary)

                Spacer()

                if progress.isGoalMet {
                    Label("Goal Met", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.green)
                }
            }

            // 2) Best time + target
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(progress.formattedBest ?? "--:--")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(progress.isGoalMet ? .green : GoalColors.textPrimary)

                Text("best")
                    .font(.caption)
                    .foregroundStyle(GoalColors.textSecondary)

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Target")
                        .font(.caption2)
                        .foregroundStyle(GoalColors.textSecondary)
                    Text(progress.goal.formattedTarget)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(AppColors.accent)
                }
            }

            // 3) Gauge (dark-aware)
            DarkGaugeView(
                progressFraction: progress.progressFraction,
                averageFraction: averageFraction,
                isGoalMet: progress.isGoalMet
            )
            .frame(height: 100)

            // 4) 30-day avg + session count
            HStack {
                Label {
                    Text("30-day avg: \(progress.formattedAverage ?? "--:--")")
                        .font(.caption)
                } icon: {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.caption)
                }
                .foregroundStyle(GoalColors.textSecondary)

                Spacer()

                Text("\(progress.sessionsCount) sessions")
                    .font(.caption)
                    .foregroundStyle(GoalColors.textSecondary)
            }

            if progress.isDummyData {
                Text("Based on estimated data")
                    .font(.caption2)
                    .foregroundStyle(GoalColors.mutedBlue)
            }
        }
        .padding()
        .background(GoalColors.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var averageFraction: Double? {
        guard let avg = progress.averageTime30Days, progress.goal.targetTime > 0 else { return nil }
        return min(progress.goal.targetTime / avg, 1.0)
    }
}

// MARK: - Dark Gauge View

/// Gauge chart styled for dark blue background.
/// Uses Circle().trim() for a 270° arc (from bottom-left to bottom-right).
/// Track uses dark blue; progress and success colors stay vivid for contrast.
struct DarkGaugeView: View {
    let progressFraction: Double
    let averageFraction: Double?
    let isGoalMet: Bool

    /// 270° arc = 0.75 of a full circle
    private let arcFraction: Double = 0.75
    /// Rotate so the arc starts at bottom-left (135° from 3-o'clock)
    private let rotationOffset: Angle = .degrees(135)
    private let lineWidth: CGFloat = 12

    var body: some View {
        ZStack {
            // Track (dark blue background)
            Circle()
                .trim(from: 0, to: arcFraction)
                .stroke(GoalColors.trackBlue, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(rotationOffset)

            // Progress fill
            Circle()
                .trim(from: 0, to: arcFraction * min(progressFraction, 1.0))
                .stroke(progressColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(rotationOffset)

            // Average marker
            if let avg = averageFraction, avg > 0 {
                averageMarker(fraction: min(avg, 1.0))
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private var progressColor: Color {
        if isGoalMet {
            return .green
        } else if progressFraction > 0.8 {
            return AppColors.accent
        } else if progressFraction > 0.5 {
            return .yellow
        } else {
            return GoalColors.mutedBlue
        }
    }

    private func averageMarker(fraction: Double) -> some View {
        GeometryReader { geo in
            let size: CGFloat = min(geo.size.width, geo.size.height)
            let cx: CGFloat = size / 2
            let cy: CGFloat = size / 2
            let r: CGFloat = (size / 2) - lineWidth / 2
            // 135° start + 270° sweep * fraction, converted to radians
            let a: Double = (135.0 + 270.0 * fraction) * .pi / 180.0
            let x: CGFloat = cx + r * CGFloat(cos(a))
            let y: CGFloat = cy + r * CGFloat(sin(a))

            Circle()
                .fill(Color.white)
                .frame(width: 8, height: 8)
                .shadow(color: .black.opacity(0.3), radius: 2)
                .position(x: x, y: y)
        }
    }
}
