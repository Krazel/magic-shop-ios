import XCTest

#if SWIFT_PACKAGE
@testable import MagicShopCore
#else
@testable import MagicShop
#endif

final class ShopNameValidatorTests: XCTestCase {
    func testCompletingOnboardingTrimsAndCollapsesWhitespace() throws {
        var engine = GameEngine()

        let name = try engine.completeOnboarding(shopName: "  Moon   &   Mortar  ")

        XCTAssertEqual(name, "Moon & Mortar")
        XCTAssertEqual(engine.state.shopName, "Moon & Mortar")
        XCTAssertTrue(engine.state.onboardingCompleted)
    }

    func testEmptyNameIsRejectedWithoutCompletingOnboarding() {
        var engine = GameEngine()

        XCTAssertThrowsError(try engine.completeOnboarding(shopName: "   ")) { error in
            XCTAssertEqual(error as? ShopNameValidationError, .empty)
        }
        XCTAssertFalse(engine.state.onboardingCompleted)
        XCTAssertNil(engine.state.shopName)
    }

    func testTooShortAndTooLongNamesAreRejected() {
        XCTAssertThrowsError(try ShopNameValidator.normalized("A")) { error in
            XCTAssertEqual(error as? ShopNameValidationError, .tooShort)
        }
        XCTAssertThrowsError(try ShopNameValidator.normalized(String(repeating: "A", count: 25))) { error in
            XCTAssertEqual(error as? ShopNameValidationError, .tooLong)
        }
    }
}
