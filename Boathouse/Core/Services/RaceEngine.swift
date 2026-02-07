import Foundation

/// Race engine for calculating scores and managing race logic
final class RaceEngine {
    static let shared = RaceEngine()

    /// Calculate the score for a session based on race type
    func calculateScore(for session: Session, raceType: RaceType) -> Double? {
        guard session.isEligibleForRaces else { return nil }

        switch raceType {
        case .topSpeed:
            return session.maxSpeedKmh

        case .furthestDistance:
            return session.distanceKm

        case .fastest1km:
            return session.best1kmTime()

        case .fastest5km:
            return session.best5kmTime()

        case .fastest10km:
            return session.best10kmTime()
        }
    }

    /// Determine if a higher or lower score is better
    func isBetterScore(_ score1: Double, than score2: Double, for raceType: RaceType) -> Bool {
        switch raceType {
        case .topSpeed, .furthestDistance:
            return score1 > score2

        case .fastest1km, .fastest5km, .fastest10km:
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

    /// Check if a session is eligible for a race
    func isSessionEligible(session: Session, for race: Race) -> SessionEligibility {
        guard session.startDate >= race.startDate,
              session.startDate <= race.endDate else {
            return .ineligible(reason: "Session is outside race time window")
        }

        guard session.isGPSVerified else {
            return .ineligible(reason: "Session requires GPS verification")
        }

        guard session.isUKSession else {
            return .ineligible(reason: "Session must be completed in the UK")
        }

        guard session.sessionType.isEligible else {
            return .ineligible(reason: "Only canoe and kayak sessions are eligible")
        }

        guard session.status == .verified else {
            return .ineligible(reason: "Session must be verified")
        }

        switch race.type {
        case .fastest1km:
            guard session.distanceKm >= 1.0 else {
                return .ineligible(reason: "Session must be at least 1km")
            }
        case .fastest5km:
            guard session.distanceKm >= 5.0 else {
                return .ineligible(reason: "Session must be at least 5km")
            }
        case .fastest10km:
            guard session.distanceKm >= 10.0 else {
                return .ineligible(reason: "Session must be at least 10km")
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
        let rankedEntries = calculateRankings(entries: entries, raceType: race.type)

        let prizeDistributions = distributePrizes(race: race, rankedEntries: rankedEntries)

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

enum SessionEligibility: Equatable {
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
