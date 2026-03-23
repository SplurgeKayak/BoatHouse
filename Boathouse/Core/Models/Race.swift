import Foundation

/// Race model representing a competition event
struct Race: Identifiable, Codable, Equatable {
    let id: String
    let type: RaceType
    let duration: RaceDuration
    let category: RaceCategory
    let startDate: Date
    let endDate: Date
    var entryCount: Int
    var prizePool: Decimal
    var status: RaceStatus
    let createdAt: Date

    var entryFee: Decimal {
        duration.entryFee
    }

    var entryDeadline: Date {
        endDate.addingTimeInterval(-3 * 60 * 60)
    }

    var canEnter: Bool {
        status == .active && Date() < entryDeadline
    }

    var timeRemaining: TimeInterval {
        endDate.timeIntervalSince(Date())
    }

    var formattedPrizePool: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "GBP"
        formatter.currencySymbol = "£"
        return formatter.string(from: prizePool as NSDecimalNumber) ?? "£0.00"
    }

    var formattedEntryFee: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "GBP"
        formatter.currencySymbol = "£"
        return formatter.string(from: entryFee as NSDecimalNumber) ?? "£0.00"
    }

    /// Calculate prizes based on 99% pool distribution
    func calculatePrizes() -> PrizeDistribution {
        let pool = prizePool * 0.99
        return PrizeDistribution(
            first: pool * 0.75,
            second: pool * 0.20,
            third: pool * 0.05,
            platformFee: prizePool * 0.01
        )
    }
}

struct PrizeDistribution: Codable, Equatable {
    let first: Decimal
    let second: Decimal
    let third: Decimal
    let platformFee: Decimal

    func formattedPrize(for position: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "GBP"
        formatter.currencySymbol = "£"

        let amount: Decimal
        switch position {
        case 1: amount = first
        case 2: amount = second
        case 3: amount = third
        default: amount = 0
        }

        return formatter.string(from: amount as NSDecimalNumber) ?? "£0.00"
    }
}

enum RaceType: String, Codable, CaseIterable, Identifiable {
    case fastest1km = "fastest_1km"
    case fastest5km = "fastest_5km"
    case fastest10km = "fastest_10km"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .fastest1km: return "Fastest 1km"
        case .fastest5km: return "Fastest 5km"
        case .fastest10km: return "Fastest 10km"
        }
    }

    var shortName: String {
        switch self {
        case .fastest1km: return "1km"
        case .fastest5km: return "5km"
        case .fastest10km: return "10km"
        }
    }

    var icon: String {
        switch self {
        case .fastest1km: return "1.circle.fill"
        case .fastest5km: return "5.circle.fill"
        case .fastest10km: return "10.circle.fill"
        }
    }

    var unit: String {
        switch self {
        case .fastest1km, .fastest5km, .fastest10km: return "min"
        }
    }

    /// Distance filter options shown on the Club Room screen
    static var distanceFilters: [RaceType] {
        allCases
    }
}

enum RaceDuration: String, Codable, CaseIterable, Identifiable {
    case daily
    case weekly
    case monthly
    case yearly

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .daily: return "Day"
        case .weekly: return "Week"
        case .monthly: return "Month"
        case .yearly: return "This Year"
        }
    }

    var entryFee: Decimal {
        switch self {
        case .daily: return 1.00
        case .weekly: return 4.99
        case .monthly: return 15.99
        case .yearly: return 15.99
        }
    }

    var icon: String {
        switch self {
        case .daily: return "sun.max.fill"
        case .weekly: return "calendar"
        case .monthly, .yearly: return "calendar.badge.clock"
        }
    }
}

enum RaceCategory: String, Codable, CaseIterable, Identifiable {
    case juniorMen   = "JM"
    case juniorWomen = "JW"
    case u23Men      = "U23M"
    case u23Women    = "U23W"
    case seniorMen   = "SM"
    case seniorWomen = "SW"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .juniorMen:   return "Junior Men"
        case .juniorWomen: return "Junior Women"
        case .u23Men:      return "U23 Men"
        case .u23Women:    return "U23 Women"
        case .seniorMen:   return "Senior Men"
        case .seniorWomen: return "Senior Women"
        }
    }

    var shortName: String {
        switch self {
        case .juniorMen:   return "JM"
        case .juniorWomen: return "JW"
        case .u23Men:      return "U23M"
        case .u23Women:    return "U23W"
        case .seniorMen:   return "SM"
        case .seniorWomen: return "SW"
        }
    }
}

enum RaceStatus: String, Codable {
    case upcoming
    case active
    case ended
    case cancelled
}
