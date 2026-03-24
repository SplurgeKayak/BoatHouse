import Foundation

extension User {
    /// Derives the primary race category from the user's gender and age.
    /// Returns nil for users with no date of birth, no gender, or non-binary gender (`.other`),
    /// since non-binary athletes have no corresponding `RaceCategory` case yet.
    var raceCategory: RaceCategory? {
        guard let age = age, let gender = gender else { return nil }
        switch (gender, age) {
        case (.male,   ..<18):   return .juniorMen
        case (.female, ..<18):   return .juniorWomen
        case (.male,   18..<23): return .u23Men
        case (.female, 18..<23): return .u23Women
        case (.male,   _):       return .seniorMen
        case (.female, _):       return .seniorWomen
        default:                 return nil
        }
    }
}
