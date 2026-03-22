import SwiftUI

/// Lightweight goals setup form shown before the main tab UI on first launch.
struct YourGoalsView: View {
    @EnvironmentObject var appState: AppState

    @State private var time1k = ""
    @State private var time5k = ""
    @State private var time10k = ""
    @State private var distancePerWeek = ""
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
            Label("Weekly Distance", systemImage: "figure.water.fitness")
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
        var goals = KayakingGoals()

        goals.timeGoal1k = KayakingGoals.parseTimeString(time1k)
        goals.timeGoal5k = KayakingGoals.parseTimeString(time5k)
        goals.timeGoal10k = KayakingGoals.parseTimeString(time10k)

        if let dist = Double(distancePerWeek), dist > 0 {
            goals.distancePerWeekKm = dist
        }

        if let target = Int(rankingTarget), target > 0 {
            for category in selectedCategories {
                goals.rankingGoals[category.rawValue] = target
            }
        }

        guard goals.hasAnyGoal else {
            showValidationError = true
            return
        }

        store.save(goals)
        appState.hasCompletedGoals = true
    }
}

#Preview {
    YourGoalsView()
        .environmentObject(AppState())
}
