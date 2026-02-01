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
                    stravaSection
                    walletSection
                    categorySection
                }

                settingsSection

                logoutSection
            }
            .navigationTitle("Account")
            .sheet(isPresented: $viewModel.showingStravaOAuth) {
                StravaOAuthView()
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

    private var stravaSection: some View {
        Section("Strava Connection") {
            if let connection = appState.currentUser?.stravaConnection {
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
                            await viewModel.disconnectStrava()
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.red)
                }
            } else {
                Button {
                    viewModel.showingStravaOAuth = true
                } label: {
                    HStack {
                        Image(systemName: "link")
                        Text("Connect Strava")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            NavigationLink {
                StravaExplanationView()
            } label: {
                HStack {
                    Image(systemName: "questionmark.circle")
                    Text("Why connect Strava?")
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
                        Text("Connect Strava to determine eligibility")
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

    private var settingsSection: some View {
        Section("Settings") {
            if appState.isSpectator {
                Button {
                    viewModel.showingStravaOAuth = true
                } label: {
                    HStack {
                        Image(systemName: "figure.rowing")
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

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                     y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in width: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > width && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: width, height: y + rowHeight)
        }
    }
}

#Preview {
    AccountView()
        .environmentObject(AppState())
        .environmentObject(AuthViewModel())
}
