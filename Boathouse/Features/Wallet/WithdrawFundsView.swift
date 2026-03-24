import SwiftUI

/// View for withdrawing prize funds from wallet
struct WithdrawFundsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = WithdrawFundsViewModel()
    @EnvironmentObject var appState: AppState

    private let presetAmounts: [Decimal] = [5, 10, 20, 50]

    var body: some View {
        VStack(spacing: 24) {
            balanceSection

            amountSection

            withdrawMethodSection

            Spacer()

            withdrawButton
        }
        .padding(24)
        .navigationTitle("Withdraw Funds")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") { dismiss() }
            }
        }
        .alert("Withdrawal Requested", isPresented: $viewModel.showingSuccess) {
            Button("Done") { dismiss() }
        } message: {
            Text("Your withdrawal is being processed. Funds typically arrive within 3–5 business days.")
        }
        .alert("Error", isPresented: $viewModel.showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "Something went wrong")
        }
    }

    private var balanceSection: some View {
        VStack(spacing: 8) {
            Text("Available Balance")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(appState.currentUser?.wallet?.formattedBalance ?? "£0.00")
                .font(.system(size: 40, weight: .bold))
        }
    }

    private var amountSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Withdraw Amount")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(presetAmounts, id: \.self) { amount in
                    AmountButton(
                        amount: amount,
                        isSelected: viewModel.selectedAmount == amount,
                        action: { viewModel.selectedAmount = amount }
                    )
                }
            }

            Button {
                viewModel.selectedAmount = appState.currentUser?.wallet?.balance
                viewModel.customAmount = nil
            } label: {
                Text("Withdraw All")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)

            HStack {
                Text("£")
                    .font(.title2)
                    .foregroundStyle(.secondary)

                TextField("Custom amount", value: $viewModel.customAmount, format: .number)
                    .font(.title2)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.plain)
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .onTapGesture {
                viewModel.selectedAmount = nil
            }
        }
    }

    private var withdrawMethodSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Withdraw To")
                .font(.headline)

            WithdrawMethodRow(
                icon: "apple.logo",
                title: "Apple Pay",
                subtitle: "Instant to your linked card",
                isSelected: viewModel.withdrawMethod == .applePay,
                action: { viewModel.withdrawMethod = .applePay }
            )

            WithdrawMethodRow(
                icon: "building.columns",
                title: "Bank Account",
                subtitle: "3–5 business days",
                isSelected: viewModel.withdrawMethod == .bankAccount,
                action: { viewModel.withdrawMethod = .bankAccount }
            )
        }
    }

    private var withdrawButton: some View {
        Button {
            Task {
                await viewModel.withdraw(walletId: appState.currentUser?.wallet?.id ?? "")
            }
        } label: {
            if viewModel.isLoading {
                ProgressView()
                    .tint(.white)
            } else {
                Text("Withdraw \(viewModel.formattedAmount)")
            }
        }
        .font(.headline)
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(viewModel.isValid ? AppColors.accent : Color(.systemGray4))
        .foregroundStyle(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .disabled(!viewModel.isValid || viewModel.isLoading)
    }
}

// MARK: - Withdraw Method Row

private struct WithdrawMethodRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? AppColors.accent : .secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Withdraw Method

enum WithdrawMethod: String {
    case applePay
    case bankAccount

    var displayName: String {
        switch self {
        case .applePay: return "Apple Pay"
        case .bankAccount: return "Bank Account"
        }
    }
}

// MARK: - ViewModel

final class WithdrawFundsViewModel: ObservableObject {
    @Published var selectedAmount: Decimal?
    @Published var customAmount: Decimal?
    @Published var withdrawMethod: WithdrawMethod = .applePay
    @Published var isLoading: Bool = false
    @Published var showingSuccess: Bool = false
    @Published var showingError: Bool = false
    @Published var errorMessage: String?

    private let walletService: WalletServiceProtocol

    var amount: Decimal {
        selectedAmount ?? customAmount ?? 0
    }

    var isValid: Bool {
        amount > 0
    }

    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "GBP"
        formatter.currencySymbol = "£"
        return formatter.string(from: amount as NSDecimalNumber) ?? "£0.00"
    }

    init(walletService: WalletServiceProtocol = WalletService.shared) {
        self.walletService = walletService
    }

    @MainActor
    func withdraw(walletId: String) async {
        guard isValid else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            _ = try await walletService.withdraw(walletId: walletId, amount: amount)

            // Update local wallet balance
            if var wallet = AppState.shared?.currentUser?.wallet {
                wallet.balance -= amount
                AppState.shared?.currentUser?.wallet = wallet
            }

            showingSuccess = true
        } catch {
            errorMessage = "Withdrawal failed. Please try again."
            showingError = true
        }
    }
}

#Preview {
    NavigationStack {
        WithdrawFundsView()
            .environmentObject(AppState())
    }
}
