import Foundation

/// User model supporting both Spectator and Racer types
struct User: Identifiable, Codable, Equatable {
    let id: String
    var email: String
    var displayName: String
    var userType: UserType
    var stravaConnection: StravaConnection?
    var wallet: Wallet?
    var dateOfBirth: Date?
    var gender: Gender?
    var profileImageURL: URL?
    var createdAt: Date
    var updatedAt: Date

    enum UserType: String, Codable, CaseIterable {
        case spectator
        case racer
    }

    enum Gender: String, Codable, CaseIterable {
        case male
        case female
        case other

        var displayName: String {
            switch self {
            case .male: return "Male"
            case .female: return "Female"
            case .other: return "Other"
            }
        }
    }

    var age: Int? {
        guard let dob = dateOfBirth else { return nil }
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: dob, to: Date())
        return ageComponents.year
    }

    /// Determines eligible race categories based on age and gender
    var eligibleCategories: [RaceCategory] {
        guard let age = age, let gender = gender else { return [] }

        var categories: [RaceCategory] = []

        switch (age, gender) {
        case (let a, .female) where a < 18:
            categories = [.juniorGirls, .juniorBoys, .womenU23, .menU23, .seniorWomen, .seniorMen, .mastersWomen, .mastersMen]
        case (let a, .male) where a < 18:
            categories = [.juniorBoys, .menU23, .seniorMen, .mastersMen]
        case (let a, .female) where a < 23:
            categories = [.womenU23, .menU23, .seniorWomen, .seniorMen, .mastersWomen, .mastersMen]
        case (let a, .male) where a < 23:
            categories = [.menU23, .seniorMen, .mastersMen]
        case (let a, .female) where a < 35:
            categories = [.seniorWomen, .seniorMen, .mastersWomen, .mastersMen]
        case (let a, .male) where a < 35:
            categories = [.seniorMen, .mastersMen]
        case (_, .female):
            categories = [.mastersWomen, .mastersMen]
        case (_, .male):
            categories = [.mastersMen]
        default:
            categories = []
        }

        return categories
    }

    var isStravaConnected: Bool {
        stravaConnection?.isValid ?? false
    }

    var canEnterRaces: Bool {
        userType == .racer && isStravaConnected && wallet != nil
    }
}

struct StravaConnection: Codable, Equatable {
    let athleteId: Int
    var accessToken: String
    var refreshToken: String
    var expiresAt: Date
    var athleteProfile: StravaAthleteProfile?

    var isValid: Bool {
        Date() < expiresAt
    }

    var needsRefresh: Bool {
        Date().addingTimeInterval(300) >= expiresAt
    }
}

struct StravaAthleteProfile: Codable, Equatable {
    let id: Int
    let firstName: String
    let lastName: String
    let profileImageURL: URL?
    let city: String?
    let country: String?
    let sex: String?
    let dateOfBirth: Date?

    var fullName: String {
        "\(firstName) \(lastName)"
    }
}
