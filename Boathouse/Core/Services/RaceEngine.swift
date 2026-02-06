import Foundation

/// Race engine for calculating scores and managing race logic
final class RaceEngine {
    static let shared = RaceEngine()

    /// Calculate the score for an activity based on race type
    func calculateScore(for activity: Activity, raceType: RaceType) -> Double? {
        guard activity.isEligibleForRaces else { return nil }

        switch raceType {
        case .topSpeed:
            return activity.maxSpeedKmh

        case .furthestDistance:
            return activity.distanceKm

        case .fastest1km:
            return activity.best1kmTime()

        case .fastest5km:
            return activity.best5kmTime()

        case .fastest10km:
            return activity.best10kmTime()
        }
    }

    /// Determine if a higher or lower score is better
    func isBetterScore(_ score1: Double, than score2: Double, for raceType: RaceType) -> Bool {
        switch raceType {
        case .topSpeed, .furthestDistance:
            // Higher is better
            return score1 > score2

        case .fastest1km, .fastest5km, .fastest10km:
            // Lower is better (faster time)
            return score1 < score2
        }
    }

    /// Calculate leaderboard rankings from entries
    func calculateRankings(entries: [Entry], raceType: RaceType) -> [Entry] {
        let scoredEntries = entries.filter { $0.score != nil }

        let sorted: [Entry]
        switch raceType {
        case .topSpeed, .furthestDistance:
            sorted = scoredEntries.sorted { ($0.score ?? 0) > ($1.score ?? 0) }
        case .fastest1km, .fastest5km, .fastest10km:
            sorted = scoredEntries.sorted { ($0.score ?? .infinity) < ($1.score ?? .infinity) }
        }

        return sorted.enumerated().map { index, entry in
            var rankedEntry = entry
            rankedEntry.rank = index + 1
            return rankedEntry
        }
    }

    /// Calculate prize distribution for race winners
    func distributePrizes(race: Race, rankedEntries: [Entry]) -> [(entry: Entry, prize: Decimal)] {
        let prizes = race.calculatePrizes()
        var distributions: [(Entry, Decimal)] = []

        for entry in rankedEntries {
            guard let rank = entry.rank else { continue }

            switch rank {
            case 1:
                distributions.append((entry, prizes.first))
            case 2:
                distributions.append((entry, prizes.second))
            case 3:
                distributions.append((entry, prizes.third))
            default:
                break
            }
        }

        return distributions
    }

    /// Check if an activity is eligible for a race
    func isActivityEligible(activity: Activity, for race: Race) -> ActivityEligibility {
        // Check if activity is within race time window
        guard activity.startDate >= race.startDate,
              activity.startDate <= race.endDate else {
            return .ineligible(reason: "Activity is outside race time window")
        }

        // Check GPS verification
        guard activity.isGPSVerified else {
            return .ineligible(reason: "Activity requires GPS verification")
        }

        // Check UK location
        guard activity.isUKActivity else {
            return .ineligible(reason: "Activity must be completed in the UK")
        }

        // Check activity type
        guard activity.activityType.isEligible else {
            return .ineligible(reason: "Only canoe and kayak activities are eligible")
        }

        // Check activity status
        guard activity.status == .verified else {
            return .ineligible(reason: "Activity must be verified")
        }

        // Check minimum distance for timed races
        switch race.type {
        case .fastest1km:
            guard activity.distanceKm >= 1.0 else {
                return .ineligible(reason: "Activity must be at least 1km")
            }
        case .fastest5km:
            guard activity.distanceKm >= 5.0 else {
                return .ineligible(reason: "Activity must be at least 5km")
            }
        case .fastest10km:
            guard activity.distanceKm >= 10.0 else {
                return .ineligible(reason: "Activity must be at least 10km")
            }
        default:
            break
        }

        return .eligible
    }

    /// Check if a user is eligible to enter a race category
    func isUserEligible(user: User, for category: RaceCategory) -> Bool {
        user.eligibleCategories.contains(category)
    }

    /// Process race ending - calculate final rankings and distribute prizes
    func processRaceEnd(race: Race, entries: [Entry]) async throws -> RaceResult {
        // Calculate final rankings
        let rankedEntries = calculateRankings(entries: entries, raceType: race.type)

        // Calculate prizes
        let prizeDistributions = distributePrizes(race: race, rankedEntries: rankedEntries)

        // TODO: Update entries in database with final ranks
        // TODO: Credit wallets with prize money
        // TODO: Create prize transactions

        return RaceResult(
            raceId: race.id,
            rankedEntries: rankedEntries,
            prizeDistributions: prizeDistributions.map {
                PrizeAward(entryId: $0.entry.id, userId: $0.entry.userId, amount: $0.prize, rank: $0.entry.rank ?? 0)
            },
            totalPrizePool: race.prizePool,
            platformFee: race.prizePool * 0.01,
            processedAt: Date()
        )
    }
}

// MARK: - Supporting Types

enum ActivityEligibility: Equatable {
    case eligible
    case ineligible(reason: String)

    var isEligible: Bool {
        if case .eligible = self { return true }
        return false
    }
}

struct RaceResult {
    let raceId: String
    let rankedEntries: [Entry]
    let prizeDistributions: [PrizeAward]
    let totalPrizePool: Decimal
    let platformFee: Decimal
    let processedAt: Date
}

struct PrizeAward {
    let entryId: String
    let userId: String
    let amount: Decimal
    let rank: Int
}
