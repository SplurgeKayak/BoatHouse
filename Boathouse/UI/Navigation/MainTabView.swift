import SwiftUI

/// Custom tab bar with elevated center "Goals" target button.
/// Goals overlay sits as a layer on top of tab content, animated in/out.
struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack(alignment: .bottom) {
            // Tab content area
            tabContent
                .padding(.bottom, 70) // reserve space for custom bar

            // Goals overlay — sits above tab content, below the nav bar conceptually
            if appState.isGoalsVisible {
                GoalsOverlayView(
                    onDismiss: { dismissGoals() }
                )
                .transition(goalsTransition)
                .zIndex(1)
                .padding(.bottom, 70)
            }

            // Custom bottom navigation bar
            CustomBottomBar(
                selectedTab: $appState.selectedTab,
                isGoalsVisible: appState.isGoalsVisible,
                onGoalsTap: { toggleGoals() }
            )
            .zIndex(2)
        }
        .ignoresSafeArea(.keyboard) // prevent bar jumping on keyboard
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch appState.selectedTab {
        case .home:
            HomeView()
        case .races:
            RacesView()
        case .entry:
            EntryView()
        case .account:
            AccountView()
        }
    }

    // MARK: - Goals Animation

    private func dismissGoals() {
        let animation: Animation = reduceMotion
            ? .easeOut(duration: 0.15)
            : .spring(response: 0.35, dampingFraction: 0.85)
        withAnimation(animation) {
            appState.isGoalsVisible = false
        }
    }

    private func toggleGoals() {
        let animation: Animation = reduceMotion
            ? .easeInOut(duration: 0.15)
            : .spring(response: 0.4, dampingFraction: 0.8)
        withAnimation(animation) {
            appState.isGoalsVisible.toggle()
        }
    }

    /// Transition: slide up from bottom + fade. Feels like a layer rising from the nav bar.
    private var goalsTransition: AnyTransition {
        if reduceMotion {
            return .opacity
        }
        return .asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .bottom).combined(with: .opacity)
        )
    }
}

// MARK: - Custom Bottom Bar

/// Bottom navigation with 4 standard tabs + elevated center target button.
/// The center button is visually raised and uses a red accent.
struct CustomBottomBar: View {
    @Binding var selectedTab: AppState.Tab
    let isGoalsVisible: Bool
    let onGoalsTap: () -> Void

    /// Left tabs: home, races — Right tabs: entry, account
    private let leftTabs: [AppState.Tab] = [.home, .races]
    private let rightTabs: [AppState.Tab] = [.entry, .account]

    var body: some View {
        HStack(spacing: 0) {
            // Left tabs
            ForEach(leftTabs, id: \.rawValue) { tab in
                tabButton(tab)
            }

            // Center: Goals target button (elevated)
            centerGoalsButton
                .frame(maxWidth: .infinity)

            // Right tabs
            ForEach(rightTabs, id: \.rawValue) { tab in
                tabButton(tab)
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 8)
        .padding(.bottom, 20) // safe area padding for bottom
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.08), radius: 8, y: -2)
                .ignoresSafeArea(.all, edges: .bottom)
        )
    }

    // MARK: - Tab Button

    private func tabButton(_ tab: AppState.Tab) -> some View {
        Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 2) {
                Image(systemName: tab.icon)
                    .font(.system(size: 20))

                Text(tab.title)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundStyle(selectedTab == tab ? AppColors.accent : .secondary)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
    }

    // MARK: - Center Goals Button

    /// Elevated red target icon — visually dominant, custom hit area.
    private var centerGoalsButton: some View {
        Button(action: onGoalsTap) {
            ZStack {
                // Elevated circle background
                Circle()
                    .fill(GoalColors.targetRed)
                    .frame(width: 56, height: 56)
                    .shadow(color: GoalColors.targetRed.opacity(0.35), radius: 8, y: 4)

                Image(systemName: "target")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .offset(y: -16) // elevate above the bar
            .scaleEffect(isGoalsVisible ? 0.92 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isGoalsVisible)
        }
        .buttonStyle(.plain)
        .frame(width: 64, height: 56)
        .contentShape(Rectangle().size(width: 64, height: 72))
        .accessibilityLabel("Goals")
        .accessibilityHint(isGoalsVisible ? "Hide goals" : "Show goals")
    }
}

// MARK: - Goal Colors

/// Dark blue palette for Goals UI — cohesive with splash/brand wave aesthetic.
enum GoalColors {
    /// Deep navy primary background for goal cards
    static let darkBlue = Color(red: 0.04, green: 0.10, blue: 0.18) // #0B1A2E

    /// Slightly lighter navy for card surfaces
    static let cardSurface = Color(red: 0.08, green: 0.16, blue: 0.25) // #142840

    /// Muted blue for secondary elements on dark background
    static let mutedBlue = Color(red: 0.20, green: 0.30, blue: 0.42) // #334D6B

    /// Track color for gauges on dark background
    static let trackBlue = Color(red: 0.12, green: 0.20, blue: 0.30) // #1F334D

    /// Red accent for the center target button
    static let targetRed = Color(red: 0.85, green: 0.15, blue: 0.15) // #D92626

    /// Text on dark: primary
    static let textPrimary = Color.white

    /// Text on dark: secondary
    static let textSecondary = Color.white.opacity(0.6)
}

#Preview {
    MainTabView()
        .environmentObject(AppState())
        .environmentObject(AuthViewModel())
}
