import Foundation

/// Wallet model for managing user balance and transactions
struct Wallet: Identifiable, Codable, Equatable {
    let id: String
    let userId: String
    var balance: Decimal
    var autoPayoutEnabled: Bool
    var payoutDetails: PayoutDetails?
    let createdAt: Date
    var updatedAt: Date

    var formattedBalance: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "GBP"
        formatter.currencySymbol = "£"
        return formatter.string(from: balance as NSDecimalNumber) ?? "£0.00"
    }

    var canWithdraw: Bool {
        balance > 0 && payoutDetails != nil
    }
}

struct PayoutDetails: Codable, Equatable {
    let bankName: String
    let accountNumberLast4: String
    let sortCode: String
    var isVerified: Bool

    var maskedAccount: String {
        "****\(accountNumberLast4)"
    }

    var formattedSortCode: String {
        let digits = sortCode.filter { $0.isNumber }
        guard digits.count == 6 else { return sortCode }
        let index1 = digits.index(digits.startIndex, offsetBy: 2)
        let index2 = digits.index(digits.startIndex, offsetBy: 4)
        return "\(digits[..<index1])-\(digits[index1..<index2])-\(digits[index2...])"
    }
}

struct Transaction: Identifiable, Codable, Equatable {
    let id: String
    let walletId: String
    let type: TransactionType
    let amount: Decimal
    let description: String
    let status: TransactionStatus
    let relatedRaceId: String?
    let relatedEntryId: String?
    let createdAt: Date

    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "GBP"
        formatter.currencySymbol = "£"

        let sign = type.isCredit ? "+" : "-"
        let formatted = formatter.string(from: abs(amount) as NSDecimalNumber) ?? "£0.00"
        return "\(sign)\(formatted)"
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }
}

enum TransactionType: String, Codable, CaseIterable {
    case deposit
    case withdrawal
    case entryFee
    case prize
    case refund

    var displayName: String {
        switch self {
        case .deposit: return "Deposit"
        case .withdrawal: return "Withdrawal"
        case .entryFee: return "Entry Fee"
        case .prize: return "Prize Winnings"
        case .refund: return "Refund"
        }
    }

    var icon: String {
        switch self {
        case .deposit: return "arrow.down.circle.fill"
        case .withdrawal: return "arrow.up.circle.fill"
        case .entryFee: return "ticket.fill"
        case .prize: return "trophy.fill"
        case .refund: return "arrow.uturn.left.circle.fill"
        }
    }

    var isCredit: Bool {
        switch self {
        case .deposit, .prize, .refund:
            return true
        case .withdrawal, .entryFee:
            return false
        }
    }
}

enum TransactionStatus: String, Codable {
    case pending
    case completed
    case failed
    case cancelled

    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .completed: return "Completed"
        case .failed: return "Failed"
        case .cancelled: return "Cancelled"
        }
    }
}
