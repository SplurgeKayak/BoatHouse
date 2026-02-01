import Foundation
import PassKit

/// Protocol for wallet operations
protocol WalletServiceProtocol {
    func createWallet(userId: String) async throws -> Wallet
    func getWallet(walletId: String) async throws -> Wallet
    func addFunds(walletId: String, amount: Decimal, paymentMethod: PaymentMethod) async throws -> Transaction
    func withdraw(walletId: String, amount: Decimal) async throws -> Transaction
    func getTransactions(walletId: String, page: Int) async throws -> [Transaction]
    func updateAutoPayoutSetting(walletId: String, enabled: Bool) async throws
    func setupPayoutDetails(walletId: String, details: PayoutDetails) async throws
}

/// Service for wallet and payment operations
final class WalletService: WalletServiceProtocol {
    static let shared = WalletService()

    private let networkClient: NetworkClientProtocol

    init(networkClient: NetworkClientProtocol = NetworkClient.shared) {
        self.networkClient = networkClient
    }

    func createWallet(userId: String) async throws -> Wallet {
        // TODO: Replace with actual API call
        let wallet = Wallet(
            id: UUID().uuidString,
            userId: userId,
            balance: 0,
            autoPayoutEnabled: false,
            payoutDetails: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        return wallet
    }

    func getWallet(walletId: String) async throws -> Wallet {
        // TODO: Replace with actual API call
        return MockData.wallet
    }

    func addFunds(walletId: String, amount: Decimal, paymentMethod: PaymentMethod) async throws -> Transaction {
        // TODO: Replace with actual API call + Apple Pay integration
        let transaction = Transaction(
            id: UUID().uuidString,
            walletId: walletId,
            type: .deposit,
            amount: amount,
            description: "Added funds via \(paymentMethod.displayName)",
            status: .completed,
            relatedRaceId: nil,
            relatedEntryId: nil,
            createdAt: Date()
        )
        return transaction
    }

    func withdraw(walletId: String, amount: Decimal) async throws -> Transaction {
        // TODO: Replace with actual API call
        let transaction = Transaction(
            id: UUID().uuidString,
            walletId: walletId,
            type: .withdrawal,
            amount: amount,
            description: "Withdrawal to bank account",
            status: .pending,
            relatedRaceId: nil,
            relatedEntryId: nil,
            createdAt: Date()
        )
        return transaction
    }

    func getTransactions(walletId: String, page: Int) async throws -> [Transaction] {
        // TODO: Replace with actual API call
        return MockData.transactions
    }

    func updateAutoPayoutSetting(walletId: String, enabled: Bool) async throws {
        // TODO: Replace with actual API call
    }

    func setupPayoutDetails(walletId: String, details: PayoutDetails) async throws {
        // TODO: Replace with actual API call
    }
}

// MARK: - Payment Method

enum PaymentMethod: String, CaseIterable {
    case applePay
    case card

    var displayName: String {
        switch self {
        case .applePay: return "Apple Pay"
        case .card: return "Card"
        }
    }

    var icon: String {
        switch self {
        case .applePay: return "apple.logo"
        case .card: return "creditcard"
        }
    }
}

// MARK: - Apple Pay Handler

final class ApplePayHandler: NSObject {
    static let shared = ApplePayHandler()

    private let merchantIdentifier = "merchant.com.boathouse.app"

    var canMakePayments: Bool {
        PKPaymentAuthorizationController.canMakePayments()
    }

    var canMakePaymentsWithCards: Bool {
        PKPaymentAuthorizationController.canMakePayments(usingNetworks: [.visa, .masterCard, .amex])
    }

    func createPaymentRequest(amount: Decimal) -> PKPaymentRequest {
        let request = PKPaymentRequest()
        request.merchantIdentifier = merchantIdentifier
        request.countryCode = "GB"
        request.currencyCode = "GBP"
        request.supportedNetworks = [.visa, .masterCard, .amex]
        request.merchantCapabilities = .threeDSecure

        request.paymentSummaryItems = [
            PKPaymentSummaryItem(
                label: "Boathouse Wallet Top-up",
                amount: NSDecimalNumber(decimal: amount)
            )
        ]

        return request
    }
}

extension ApplePayHandler: PKPaymentAuthorizationControllerDelegate {
    func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didAuthorizePayment payment: PKPayment,
        handler completion: @escaping (PKPaymentAuthorizationResult) -> Void
    ) {
        // TODO: Process payment with backend
        // Send payment.token to server for processing
        completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
    }

    func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
        controller.dismiss()
    }
}
