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

        switch (age, gender) {
        case (let a, .male) where a < 18:
            return [.juniorMen]
        case (let a, .female) where a < 18:
            return [.juniorWomen]
        case (_, .male):
            return [.seniorMen]
        case (_, .female):
            return [.seniorWomen]
        default:
            return []
        }
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
