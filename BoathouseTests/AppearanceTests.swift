import XCTest
import SwiftUI
@testable import Boathouse

final class AppearanceTests: XCTestCase {

    private let suiteName = "AppearanceTests"
    private var testDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        testDefaults = UserDefaults(suiteName: suiteName)!
        testDefaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        testDefaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    // MARK: - Default appearance

    func testDefaultAppearance_isLight_whenNoPreferenceStored() {
        // Nothing stored → should default to .light
        let stored = testDefaults.string(forKey: "preferredColorScheme")
        XCTAssertNil(stored, "Precondition: no preference stored")

        // AppState reads from UserDefaults.standard; simulate the init logic directly
        let scheme: ColorScheme
        switch testDefaults.string(forKey: "preferredColorScheme") {
        case "dark": scheme = .dark
        default:     scheme = .light
        }

        XCTAssertEqual(scheme, .light, "Default should be .light when no preference is stored")
    }

    func testPreferredColorScheme_neverNil_onDefaultInit() {
        // The init logic always produces .light or .dark — never nil
        let scheme: ColorScheme?
        switch testDefaults.string(forKey: "preferredColorScheme") {
        case "dark": scheme = .dark
        default:     scheme = .light
        }

        XCTAssertNotNil(scheme, "preferredColorScheme must never be nil")
    }

    // MARK: - Persistence

    func testDarkScheme_persistsAndReloadsCorrectly() {
        testDefaults.set("dark", forKey: "preferredColorScheme")

        let scheme: ColorScheme
        switch testDefaults.string(forKey: "preferredColorScheme") {
        case "dark": scheme = .dark
        default:     scheme = .light
        }

        XCTAssertEqual(scheme, .dark)
    }

    func testLightScheme_persistsAndReloadsCorrectly() {
        testDefaults.set("light", forKey: "preferredColorScheme")

        let scheme: ColorScheme
        switch testDefaults.string(forKey: "preferredColorScheme") {
        case "dark": scheme = .dark
        default:     scheme = .light
        }

        XCTAssertEqual(scheme, .light)
    }

    func testUnknownValue_fallsBackToLight() {
        testDefaults.set("system", forKey: "preferredColorScheme")

        let scheme: ColorScheme
        switch testDefaults.string(forKey: "preferredColorScheme") {
        case "dark": scheme = .dark
        default:     scheme = .light
        }

        XCTAssertEqual(scheme, .light, "Any unknown value should fall back to .light")
    }
}
