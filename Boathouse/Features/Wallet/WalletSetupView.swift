import SwiftUI
import PassKit

/// Wallet setup view with Apple Pay integration
struct WalletSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = WalletSetupViewModel()
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                headerSection

                if viewModel.step == .initial {
                    initialStepView
                } else if viewModel.step == .paymentSetup {
                    paymentSetupView
                } else {
                    confirmationView
                }

                Spacer()
            }
            .padding(24)
            .navigationTitle("Set Up Wallet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Error", isPresented: $viewModel.showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "Something went wrong")
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "wallet.pass.fill")
                .font(.system(size: 64))
                .foregroundStyle(.accent)

            Text(stepTitle)
                .font(.title2)
                .fontWeight(.bold)

            Text(stepDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var stepTitle: String {
        switch viewModel.step {
        case .initial: return "Your Race Wallet"
        case .paymentSetup: return "Add Payment Method"
        case .complete: return "You're All Set!"
        }
    }

    private var stepDescription: String {
        switch viewModel.step {
        case .initial:
            return "Your wallet holds funds for race entries and stores your winnings."
        case .paymentSetup:
            return "Add a payment method to fund your wallet and enter races."
        case .complete:
            return "Your wallet is ready. Start entering races!"
        }
    }

    private var initialStepView: some View {
        VStack(spacing: 16) {
            FeatureRow(icon: "bolt.fill", title: "Quick Entry", description: "Enter races instantly with wallet balance")
            FeatureRow(icon: "trophy.fill", title: "Prize Payouts", description: "Winnings are deposited directly to your wallet")
            FeatureRow(icon: "arrow.up.circle.fill", title: "Easy Withdrawal", description: "Transfer funds to your bank anytime")

            Button {
                viewModel.step = .paymentSetup
            } label: {
                Text("Continue")
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
            }
            .buttonStyle(PrimaryButtonStyle())
        }
    }

    private var paymentSetupView: some View {
        VStack(spacing: 16) {
            if ApplePayHandler.shared.canMakePayments {
                PaymentMethodButton(
                    method: .applePay,
                    isSelected: viewModel.selectedMethod == .applePay,
                    action: { viewModel.selectedMethod = .applePay }
                )
            }

            PaymentMethodButton(
                method: .card,
                isSelected: viewModel.selectedMethod == .card,
                action: { viewModel.selectedMethod = .card }
            )

            Button {
                Task {
                    await viewModel.setupWallet(userId: appState.currentUser?.id ?? "")
                }
            } label: {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Set Up Wallet")
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(viewModel.selectedMethod == nil || viewModel.isLoading)
        }
    }

    private var confirmationView: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)

            Button {
                dismiss()
            } label: {
                Text("Done")
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
            }
            .buttonStyle(PrimaryButtonStyle())
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.accent)
                .frame(width: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct PaymentMethodButton: View {
    let method: PaymentMethod
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: method.icon)
                    .font(.title2)

                Text(method.displayName)
                    .font(.headline)

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .accent : .secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentColor : Color(.systemGray4), lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - ViewModel

@MainActor
final class WalletSetupViewModel: ObservableObject {
    enum SetupStep {
        case initial
        case paymentSetup
        case complete
    }

    @Published var step: SetupStep = .initial
    @Published var selectedMethod: PaymentMethod?
    @Published var isLoading = false
    @Published var showingError = false
    @Published var errorMessage: String?

    private let walletService: WalletServiceProtocol

    nonisolated init(walletService: WalletServiceProtocol = WalletService.shared) {
        self.walletService = walletService
    }

    func setupWallet(userId: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let wallet = try await walletService.createWallet(userId: userId)
            AppState.shared?.currentUser?.wallet = wallet
            step = .complete
        } catch {
            errorMessage = "Failed to create wallet"
            showingError = true
        }
    }
}

#Preview {
    WalletSetupView()
        .environmentObject(AppState())
}
