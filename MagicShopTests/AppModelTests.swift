#if !SWIFT_PACKAGE
import XCTest
@testable import MagicShop

final class AppModelTests: XCTestCase {
    @MainActor
    func testPurchaseFailureCancelAndRetryNeverChargeTwice() async throws {
        let store = FailingSessionStore()
        let model = AppModel(store: store)
        model.shopNameInput = "Moon & Mortar"
        XCTAssertTrue(model.submitOnboarding())
        model.openBuild()
        model.beginPlacement(kind: .basicDisplayTable)
        store.failWrites = true
        XCTAssertFalse(model.confirmCurrentPlacement())
        XCTAssertEqual(model.state.balance, 500)
        model.cancelCurrentPlacement()
        XCTAssertEqual(model.state.balance, 500)
        XCTAssertTrue(model.state.fixtures.isEmpty)
        store.failWrites = false
        model.beginPlacement(kind: .basicDisplayTable)
        XCTAssertTrue(model.confirmCurrentPlacement())
        XCTAssertEqual(model.state.balance, 450)
        XCTAssertEqual(try store.load().fixtures.count, 1)
    }

    @MainActor
    func testLoadFailureBlocksNewGameWritesAndCanRetryRead() async throws {
        let store = FailingSessionStore()
        store.failReads = true
        let model = AppModel(store: store)
        XCTAssertNotNil(model.inlineMessage)
        model.shopNameInput = "Do not overwrite"
        XCTAssertFalse(model.submitOnboarding())
        XCTAssertEqual(store.writeCount, 0)
        store.failReads = false
        XCTAssertFalse(model.submitOnboarding()) // restores before accepting another command
        XCTAssertEqual(store.writeCount, 0)
        model.shopNameInput = "Recovered Shop"
        XCTAssertTrue(model.submitOnboarding())
        XCTAssertEqual(try store.load().shopName, "Recovered Shop")
    }
}
#endif