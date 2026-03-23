import SwiftUI

/// Account screen with profile, Strava connection, wallet, and settings
struct AccountView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = AccountViewModel()

    var body: some View {
        NavigationStack {
            List {
                profileSection

                if appState.isRacer {
                    garminSection
                    walletSection
                    categorySection
                }

                appearanceSection
                settingsSection

                logoutSection
            }
            .navigationTitle("Account")
            .sheet(isPresented: $viewModel.showingGarminOAuth) {
                GarminOAuthView()
            }
            .sheet(isPresented: $viewModel.showingWalletSetup) {
                WalletSetupView()
            }
            .sheet(isPresented: $viewModel.showingTransactionHistory) {
                TransactionHistoryView()
            }
        }
    }

    private var profileSection: some View {
        Section {
            HStack(spacing: 16) {
                Circle()
                    .fill(Color.accentColor.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay {
                        Text(initials)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.accent)
                    }

                VStack(alignment: .leading, spacing: 4) {
                    Text(appState.currentUser?.displayName ?? "User")
                        .font(.headline)

                    Text(appState.currentUser?.email ?? "")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(appState.isRacer ? "Racer" : "Spectator")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(appState.isRacer ? Color.accent : Color.secondary)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            }
            .padding(.vertical, 8)
        }
    }

    private var garminSection: some View {
        Section("Garmin Connection") {
            if let connection = appState.currentUser?.garminConnection {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Connected")
                            .font(.subheadline)

                        if let profile = connection.athleteProfile {
                            Text(profile.fullName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    Button("Disconnect") {
                        Task {
                            await viewModel.disconnectGarmin()
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.red)
                }
            } else {
                Button {
                    viewModel.showingGarminOAuth = true
                } label: {
                    HStack {
                        Image(systemName: "link")
                        Text("Connect Garmin")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            NavigationLink {
                GarminExplanationView()
            } label: {
                HStack {
                    Image(systemName: "questionmark.circle")
                    Text("Why connect Garmin?")
                }
            }
        }
    }

    private var walletSection: some View {
        Section("Wallet") {
            if let wallet = appState.currentUser?.wallet {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Balance")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(wallet.formattedBalance)
                            .font(.title2)
                            .fontWeight(.bold)
                    }

                    Spacer()

                    NavigationLink {
                        AddFundsView()
                    } label: {
                        Text("Add Funds")
                            .font(.subheadline)
                    }
                    .buttonStyle(.borderedProminent)
                }

                Toggle("Auto-payout winnings", isOn: Binding(
                    get: { wallet.autoPayoutEnabled },
                    set: { _ in Task { await viewModel.toggleAutoPayout() } }
                ))

                Button {
                    viewModel.showingTransactionHistory = true
                } label: {
                    HStack {
                        Image(systemName: "list.bullet.rectangle")
                        Text("Transaction History")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                Button {
                    viewModel.showingWalletSetup = true
                } label: {
                    HStack {
                        Image(systemName: "creditcard")
                        Text("Set Up Wallet")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var categorySection: some View {
        Section("Race Eligibility") {
            if let user = appState.currentUser {
                if let age = user.age {
                    HStack {
                        Text("Age")
                        Spacer()
                        Text("\(age)")
                            .foregroundStyle(.secondary)
                    }
                }

                if let gender = user.gender {
                    HStack {
                        Text("Gender")
                        Spacer()
                        Text(gender.displayName)
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Eligible Categories")
                        .font(.subheadline)

                    if user.eligibleCategories.isEmpty {
                        Text("Connect Garmin to determine eligibility")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        FlowLayout(spacing: 8) {
                            ForEach(user.eligibleCategories) { category in
                                Text(category.displayName)
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color.accentColor.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
        }
    }

    private var appearanceSection: some View {
        Section("Appearance") {
            Picker("Theme", selection: Binding(
                get: {
                    appState.preferredColorScheme == .dark ? 1 : 0
                },
                set: { value in
                    appState.preferredColorScheme = value == 1 ? .dark : .light
                }
            )) {
                Text("Light").tag(0)
                Text("Dark").tag(1)
            }
            .pickerStyle(.segmented)
        }
    }

    private var settingsSection: some View {
        Section("Settings") {
            if appState.isSpectator {
                Button {
                    viewModel.showingGarminOAuth = true
                } label: {
                    HStack {
                        Image(systemName: "figure.water.fitness")
                        Text("Upgrade to Racer")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            NavigationLink {
                NotificationSettingsView()
            } label: {
                HStack {
                    Image(systemName: "bell")
                    Text("Notifications")
                }
            }

            NavigationLink {
                // Privacy settings
                Text("Privacy Settings")
            } label: {
                HStack {
                    Image(systemName: "hand.raised")
                    Text("Privacy")
                }
            }

            NavigationLink {
                // Help & Support
                Text("Help & Support")
            } label: {
                HStack {
                    Image(systemName: "questionmark.circle")
                    Text("Help & Support")
                }
            }
        }
    }

    private var logoutSection: some View {
        Section {
            Button(role: .destructive) {
                Task {
                    await authViewModel.logout()
                }
            } label: {
                HStack {
                    Spacer()
                    Text("Log Out")
                    Spacer()
                }
            }
        }
    }

    private var initials: String {
        guard let name = appState.currentUser?.displayName else { return "?" }
        let components = name.split(separator: " ")
        let first = components.first?.prefix(1) ?? ""
        let last = components.count > 1 ? components.last?.prefix(1) ?? "" : ""
        return "\(first)\(last)".uppercased()
    }
}

#Preview {
    AccountView()
        .environmentObject(AppState())
        .environmentObject(AuthViewModel())
}
