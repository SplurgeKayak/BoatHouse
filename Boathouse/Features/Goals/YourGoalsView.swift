import SwiftUI

/// Lightweight goals setup form shown before the main tab UI on first launch.
struct YourGoalsView: View {
    @EnvironmentObject var appState: AppState

    @State private var time1k = ""
    @State private var time5k = ""
    @State private var time10k = ""
    @State private var distancePerWeek = ""
    @State private var rank1km = ""
    @State private var rank5km = ""
    @State private var rank10km = ""
    @State private var rankDistance = ""
    @State private var selectedCategories: Set<RaceCategory> = []
    @State private var rankingTarget = "10"
    @State private var showValidationError = false

    private let store = GoalsStore.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    timeGoalsSection
                    distanceGoalSection
                    rankTargetSection
                    rankingGoalSection

                    saveButton
                    skipButton
                }
                .padding()
            }
            .navigationTitle("Your Goals")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "flag.checkered")
                .font(.system(size: 44))
                .foregroundStyle(.accent)

            Text("Set your paddling goals")
                .font(.title2)
                .fontWeight(.bold)

            Text("Track progress against personal targets. You can change these anytime in Settings.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 8)
    }

    // MARK: - Time Goals

    private var timeGoalsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Time Goals", systemImage: "timer")
                .font(.headline)

            Text("Enter target times as M:SS (e.g. 4:30)")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                timeField(label: "1km", text: $time1k)
                timeField(label: "5km", text: $time5k)
                timeField(label: "10km", text: $time10k)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func timeField(label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            TextField("M:SS", text: text)
                .keyboardType(.numbersAndPunctuation)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Distance Goal

    private var distanceGoalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Weekly Distance", systemImage: "figure.rowing")
                .font(.headline)

            HStack {
                TextField("km per week", text: $distancePerWeek)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)

                Text("km / week")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Rank Targets

    private var rankTargetSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Rank Targets", systemImage: "chart.line.uptrend.xyaxis")
                .font(.headline)

            Text("Your target ranking vs all users over the last month")
                .font(.caption)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                rankField(label: "1km Target Rank", text: $rank1km)
                rankField(label: "5km Target Rank", text: $rank5km)
                rankField(label: "10km Target Rank", text: $rank10km)
                rankField(label: "Distance Rank", text: $rankDistance)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func rankField(label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            HStack(spacing: 4) {
                Text("Top")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                TextField("10", text: text)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }

    // MARK: - Ranking Goals

    private var rankingGoalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Ranking Goals", systemImage: "chart.bar.fill")
                .font(.headline)

            Text("Select categories and a target ranking")
                .font(.caption)
                .foregroundStyle(.secondary)

            FlowLayout(spacing: 8) {
                ForEach(RaceCategory.allCases) { category in
                    let isSelected = selectedCategories.contains(category)
                    Button {
                        if isSelected {
                            selectedCategories.remove(category)
                        } else {
                            selectedCategories.insert(category)
                        }
                    } label: {
                        Text(category.shortName)
                            .font(.subheadline)
                            .fontWeight(isSelected ? .semibold : .regular)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(isSelected ? Color.accentColor : Color(.systemGray5))
                            .foregroundStyle(isSelected ? .white : .primary)
                            .clipShape(Capsule())
                    }
                }
            }

            if !selectedCategories.isEmpty {
                HStack {
                    Text("Target: Top")
                        .font(.subheadline)

                    TextField("10", text: $rankingTarget)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Actions

    private var saveButton: some View {
        Button {
            saveGoals()
        } label: {
            Text("Save & Continue")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .alert("Set at least one goal, or tap Skip.", isPresented: $showValidationError) {
            Button("OK", role: .cancel) {}
        }
    }

    private var skipButton: some View {
        Button {
            store.hasCompletedGoals = true
            appState.hasCompletedGoals = true
        } label: {
            Text("Skip for Now")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func saveGoals() {
        // Build legacy model for backward compat
        var legacyGoals = KayakingGoals()
        legacyGoals.timeGoal1k = KayakingGoals.parseTimeString(time1k)
        legacyGoals.timeGoal5k = KayakingGoals.parseTimeString(time5k)
        legacyGoals.timeGoal10k = KayakingGoals.parseTimeString(time10k)

        if let dist = Double(distancePerWeek), dist > 0 {
            legacyGoals.distancePerWeekKm = dist
        }

        if let r = Int(rank1km), r > 0 { legacyGoals.rankTarget1km = r }
        if let r = Int(rank5km), r > 0 { legacyGoals.rankTarget5km = r }
        if let r = Int(rank10km), r > 0 { legacyGoals.rankTarget10km = r }
        if let r = Int(rankDistance), r > 0 { legacyGoals.rankTargetDistance = r }

        if let target = Int(rankingTarget), target > 0 {
            for category in selectedCategories {
                legacyGoals.rankingGoals[category.rawValue] = target
            }
        }

        guard legacyGoals.hasAnyGoal else {
            showValidationError = true
            return
        }

        // Save legacy format
        store.save(legacyGoals)

        // Also save as Goal array so overlay/dashboard can display them
        var goalArray: [Goal] = []
        if let t = legacyGoals.timeGoal1k {
            goalArray.append(Goal(category: .fastest1km, targetTime: t))
        }
        if let t = legacyGoals.timeGoal5k {
            goalArray.append(Goal(category: .fastest5km, targetTime: t))
        }
        if let t = legacyGoals.timeGoal10k {
            goalArray.append(Goal(category: .fastest10km, targetTime: t))
        }
        if let r = legacyGoals.rankTarget1km {
            goalArray.append(Goal(category: .rank1km, targetTime: Double(r)))
        }
        if let r = legacyGoals.rankTarget5km {
            goalArray.append(Goal(category: .rank5km, targetTime: Double(r)))
        }
        if let r = legacyGoals.rankTarget10km {
            goalArray.append(Goal(category: .rank10km, targetTime: Double(r)))
        }
        if let r = legacyGoals.rankTargetDistance {
            goalArray.append(Goal(category: .rankDistance, targetTime: Double(r)))
        }
        store.saveGoals(goalArray)

        appState.hasCompletedGoals = true
    }
}

#Preview {
    YourGoalsView()
        .environmentObject(AppState())
}
