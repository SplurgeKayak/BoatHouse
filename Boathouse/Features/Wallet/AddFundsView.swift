import SwiftUI
import PassKit

/// View for adding funds to wallet with Apple Pay
struct AddFundsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AddFundsViewModel()
    @EnvironmentObject var appState: AppState

    private let presetAmounts: [Decimal] = [5, 10, 20, 50]

    var body: some View {
        VStack(spacing: 24) {
            balanceSection

            amountSection

            paymentMethodSection

            Spacer()

            addFundsButton
        }
        .padding(24)
        .navigationTitle("Add Funds")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Success", isPresented: $viewModel.showingSuccess) {
            Button("Done") { dismiss() }
        } message: {
            Text("Funds added successfully!")
        }
        .alert("Error", isPresented: $viewModel.showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "Something went wrong")
        }
    }

    private var balanceSection: some View {
        VStack(spacing: 8) {
            Text("Current Balance")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(appState.currentUser?.wallet?.formattedBalance ?? "£0.00")
                .font(.system(size: 40, weight: .bold))
        }
    }

    private var amountSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Select Amount")
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

    private var paymentMethodSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Payment Method")
                .font(.headline)

            if ApplePayHandler.shared.canMakePayments {
                PaymentMethodRow(
                    method: .applePay,
                    isSelected: viewModel.paymentMethod == .applePay,
                    action: { viewModel.paymentMethod = .applePay }
                )
            }

            PaymentMethodRow(
                method: .card,
                isSelected: viewModel.paymentMethod == .card,
                action: { viewModel.paymentMethod = .card }
            )
        }
    }

    private var addFundsButton: some View {
        Button {
            Task {
                await viewModel.addFunds(walletId: appState.currentUser?.wallet?.id ?? "")
            }
        } label: {
            if viewModel.isLoading {
                ProgressView()
                    .tint(.white)
            } else if viewModel.paymentMethod == .applePay {
                ApplePayButton()
            } else {
                Text("Add \(viewModel.formattedAmount)")
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(viewModel.isValid ? Color.accentColor : Color(.systemGray4))
        .foregroundStyle(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .disabled(!viewModel.isValid || viewModel.isLoading)
    }
}

struct AmountButton: View {
    let amount: Decimal
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(formattedAmount)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(isSelected ? Color.accentColor : Color(.systemGray6))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "GBP"
        formatter.currencySymbol = "£"
        return formatter.string(from: amount as NSDecimalNumber) ?? "£\(amount)"
    }
}

struct PaymentMethodRow: View {
    let method: PaymentMethod
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: method.icon)
                    .frame(width: 32)

                Text(method.displayName)

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .accent : .secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

struct ApplePayButton: View {
    var body: some View {
        HStack {
            Image(systemName: "apple.logo")
            Text("Pay")
        }
        .font(.headline)
    }
}

// MARK: - ViewModel

@MainActor
final class AddFundsViewModel: ObservableObject {
    @Published var selectedAmount: Decimal?
    @Published var customAmount: Decimal?
    @Published var paymentMethod: PaymentMethod = .applePay
    @Published var isLoading = false
    @Published var showingSuccess = false
    @Published var showingError = false
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

    nonisolated init(walletService: WalletServiceProtocol = WalletService.shared) {
        self.walletService = walletService
    }

    func addFunds(walletId: String) async {
        guard isValid else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            if paymentMethod == .applePay {
                // TODO: Present Apple Pay sheet
                // For now, simulate success
            }

            _ = try await walletService.addFunds(
                walletId: walletId,
                amount: amount,
                paymentMethod: paymentMethod
            )

            // Update local wallet balance
            if var wallet = AppState.shared?.currentUser?.wallet {
                wallet.balance += amount
                AppState.shared?.currentUser?.wallet = wallet
            }

            showingSuccess = true
        } catch {
            errorMessage = "Payment failed. Please try again."
            showingError = true
        }
    }
}

#Preview {
    NavigationStack {
        AddFundsView()
            .environmentObject(AppState())
    }
}
