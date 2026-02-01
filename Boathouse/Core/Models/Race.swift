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
    case topSpeed = "top_speed"
    case furthestDistance = "furthest_distance"
    case fastest1km = "fastest_1km"
    case fastest5km = "fastest_5km"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .topSpeed: return "Top Speed"
        case .furthestDistance: return "Furthest Distance"
        case .fastest1km: return "Fastest 1km"
        case .fastest5km: return "Fastest 5km"
        }
    }

    var icon: String {
        switch self {
        case .topSpeed: return "bolt.fill"
        case .furthestDistance: return "arrow.left.and.right"
        case .fastest1km: return "1.circle.fill"
        case .fastest5km: return "5.circle.fill"
        }
    }

    var unit: String {
        switch self {
        case .topSpeed: return "km/h"
        case .furthestDistance: return "km"
        case .fastest1km, .fastest5km: return "min"
        }
    }
}

enum RaceDuration: String, Codable, CaseIterable, Identifiable {
    case daily
    case weekly
    case monthly

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        }
    }

    var entryFee: Decimal {
        switch self {
        case .daily: return 1.00
        case .weekly: return 4.99
        case .monthly: return 15.99
        }
    }

    var icon: String {
        switch self {
        case .daily: return "sun.max.fill"
        case .weekly: return "calendar"
        case .monthly: return "calendar.badge.clock"
        }
    }
}

enum RaceCategory: String, Codable, CaseIterable, Identifiable {
    case juniorGirls = "junior_girls"
    case juniorBoys = "junior_boys"
    case womenU23 = "women_u23"
    case menU23 = "men_u23"
    case seniorWomen = "senior_women"
    case seniorMen = "senior_men"
    case mastersWomen = "masters_women"
    case mastersMen = "masters_men"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .juniorGirls: return "Junior Girls (U18)"
        case .juniorBoys: return "Junior Boys (U18)"
        case .womenU23: return "Women (U23)"
        case .menU23: return "Men (U23)"
        case .seniorWomen: return "Senior Women (23+)"
        case .seniorMen: return "Senior Men (23+)"
        case .mastersWomen: return "Masters Women (35+)"
        case .mastersMen: return "Masters Men (35+)"
        }
    }

    var shortName: String {
        switch self {
        case .juniorGirls: return "JG"
        case .juniorBoys: return "JB"
        case .womenU23: return "WU23"
        case .menU23: return "MU23"
        case .seniorWomen: return "SW"
        case .seniorMen: return "SM"
        case .mastersWomen: return "MW"
        case .mastersMen: return "MM"
        }
    }

    var isMaleCategory: Bool {
        switch self {
        case .juniorBoys, .menU23, .seniorMen, .mastersMen:
            return true
        default:
            return false
        }
    }
}

enum RaceStatus: String, Codable {
    case upcoming
    case active
    case ended
    case cancelled
}
