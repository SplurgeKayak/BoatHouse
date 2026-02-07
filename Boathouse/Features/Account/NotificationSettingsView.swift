import SwiftUI
import UserNotifications

/// Notification settings view
struct NotificationSettingsView: View {
    @StateObject private var viewModel = NotificationSettingsViewModel()

    var body: some View {
        List {
            Section {
                Toggle("Push Notifications", isOn: $viewModel.pushEnabled)
                    .onChange(of: viewModel.pushEnabled) { _, newValue in
                        if newValue {
                            viewModel.requestPermission()
                        }
                    }
            } footer: {
                Text("Enable push notifications to receive updates about races and results.")
            }

            if viewModel.pushEnabled {
                Section("Race Notifications") {
                    Toggle("Race Starting Soon", isOn: $viewModel.raceStarting)
                    Toggle("Race Ending Soon", isOn: $viewModel.raceEnding)
                    Toggle("Results Available", isOn: $viewModel.resultsAvailable)
                    Toggle("Prize Won", isOn: $viewModel.prizeWon)
                }

                Section("Session Notifications") {
                    Toggle("Session Imported", isOn: $viewModel.sessionImported)
                    Toggle("Session Flagged", isOn: $viewModel.sessionFlagged)
                }

                Section {
                    Toggle("Add Races to Calendar", isOn: $viewModel.calendarReminders)
                } header: {
                    Text("Calendar Reminders")
                } footer: {
                    Text("Automatically add race deadlines to your calendar using EventKit.")
                }
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.checkPermissionStatus()
        }
    }
}

// MARK: - ViewModel

final class NotificationSettingsViewModel: ObservableObject {
    @Published var pushEnabled: Bool = false
    @Published var raceStarting: Bool = true
    @Published var raceEnding: Bool = true
    @Published var resultsAvailable: Bool = true
    @Published var prizeWon: Bool = true
    @Published var sessionImported: Bool = true
    @Published var sessionFlagged: Bool = true
    @Published var calendarReminders: Bool = false

    init() {}

    @MainActor
    func checkPermissionStatus() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        pushEnabled = settings.authorizationStatus == .authorized
    }

    func requestPermission() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                self.pushEnabled = granted
            }
        }
    }
}

#Preview {
    NavigationStack {
        NotificationSettingsView()
    }
}
