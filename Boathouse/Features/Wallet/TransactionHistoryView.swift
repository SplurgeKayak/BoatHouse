import SwiftUI

/// Transaction history view showing all wallet transactions
struct TransactionHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = TransactionHistoryViewModel()
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.transactions.isEmpty {
                    loadingView
                } else if viewModel.transactions.isEmpty {
                    emptyView
                } else {
                    transactionList
                }
            }
            .navigationTitle("Transaction History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
            }
            .task {
                if let walletId = appState.currentUser?.wallet?.id {
                    await viewModel.loadTransactions(walletId: walletId)
                }
            }
        }
    }

    private var loadingView: some View {
        VStack {
            ProgressView()
            Text("Loading transactions...")
                .foregroundStyle(.secondary)
        }
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No Transactions Yet")
                .font(.headline)

            Text("Your transaction history will appear here")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var transactionList: some View {
        List {
            ForEach(groupedTransactions.keys.sorted(by: >), id: \.self) { date in
                Section(header: Text(formatSectionDate(date))) {
                    ForEach(groupedTransactions[date] ?? []) { transaction in
                        TransactionRow(transaction: transaction)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var groupedTransactions: [Date: [WalletTransaction]] {
        Dictionary(grouping: viewModel.transactions) { transaction in
            Calendar.current.startOfDay(for: transaction.createdAt)
        }
    }

    private func formatSectionDate(_ date: Date) -> String {
        let formatter = DateFormatter()

        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }
}

struct TransactionRow: View {
    let transaction: WalletTransaction

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: transaction.type.icon)
                .font(.title2)
                .foregroundStyle(transaction.type.isCredit ? .green : .red)
                .frame(width: 44, height: 44)
                .background(
                    (transaction.type.isCredit ? Color.green : Color.red)
                        .opacity(0.1)
                )
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.type.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(transaction.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(transaction.formattedAmount)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(transaction.type.isCredit ? .green : .primary)

                Text(formatTime(transaction.createdAt))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - ViewModel

@MainActor
final class TransactionHistoryViewModel: ObservableObject {
    @Published var transactions: [WalletTransaction] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let walletService: WalletServiceProtocol

    nonisolated init(walletService: WalletServiceProtocol = WalletService.shared) {
        self.walletService = walletService
    }

    func loadTransactions(walletId: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            transactions = try await walletService.getTransactions(walletId: walletId, page: 1)
        } catch {
            errorMessage = "Failed to load transactions"
        }
    }
}

#Preview {
    TransactionHistoryView()
        .environmentObject(AppState())
}
