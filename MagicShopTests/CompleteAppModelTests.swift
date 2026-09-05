#if !SWIFT_PACKAGE
import XCTest
@testable import MagicShop

final class CompleteAppModelTests: XCTestCase {
    @MainActor
    func testClockPausesAndTwelveLivingVisitorsFinishWithoutDuplicateSales() async throws {
        let store = InMemoryGameStateStore()
        let model = AppModel(store: store)
        model.shopNameInput = "Clockwork Curios"
        XCTAssertTrue(model.submitOnboarding())
        model.beginPlacement(kind: .basicDisplayTable)
        XCTAssertTrue(model.confirmCurrentPlacement())
        model.showPanel(.stock)
        XCTAssertTrue(model.confirmStock())
        XCTAssertEqual(model.state.balance, 440)
        model.startDay()
        XCTAssertEqual(model.clockText, "09:00")
        model.setAppActive(false)
        for _ in 0..<300 { model.tick(seconds: 0.25) }
        XCTAssertEqual(model.state.balance, 440)
        XCTAssertEqual(model.state.livingDay?.minute, 540)
        XCTAssertEqual(model.livingMinute, 540)
        model.setAppActive(true)
        model.togglePause()
        model.tick(seconds: 0.25)
        XCTAssertEqual(model.state.livingDay?.minute, 540)
        XCTAssertEqual(model.livingMinute, 540)
        model.togglePause()
        for _ in 0..<300 { model.tick(seconds: 0.25) }
        XCTAssertTrue(model.showsSummary)
        XCTAssertEqual(model.clockText, "18:00")
        XCTAssertEqual(model.state.balance, 465)
        XCTAssertEqual(model.state.livingDay?.outcomes.count, 12)
        for _ in 0..<300 { model.tick(seconds: 0.25) }
        XCTAssertEqual(model.state.balance, 465)
        model.prepareNextDay()
        XCTAssertEqual(model.state.calendar.weekdayName, "Tuesday")
        XCTAssertEqual(model.clockText, "09:00")
        let restored = AppModel(store: store)
        XCTAssertEqual(restored.state, model.state)
    }

    @MainActor
    func testFailedVisitSavePausesAndRetryUsesTheSameToken() async throws {
        let store = FailingSessionStore()
        let model = AppModel(store: store)
        model.shopNameInput = "Safe Spells"
        XCTAssertTrue(model.submitOnboarding())
        model.beginPlacement(kind: .basicDisplayTable)
        XCTAssertTrue(model.confirmCurrentPlacement())
        model.showPanel(.stock)
        XCTAssertTrue(model.confirmStock())
        model.startDay()
        let token = try XCTUnwrap(model.state.livingDay).id
        store.failWrites = true
        for _ in 0..<30 { model.tick(seconds: 0.25) }
        XCTAssertTrue(model.isPaused)
        XCTAssertEqual(model.state.balance, 440)
        XCTAssertEqual(model.state.livingDay?.minute, 540)
        XCTAssertEqual(model.state.livingDay?.id, token)
        store.failWrites = false
        model.togglePause()
        for _ in 0..<90 { model.tick(seconds: 0.25) }
        XCTAssertEqual(model.state.balance, 465)
        XCTAssertEqual(model.state.livingDay?.sales.count, 1)
        let restored = AppModel(store: store)
        for _ in 0..<300 { restored.tick(seconds: 0.25) }
        XCTAssertEqual(restored.state.balance, 465)
        XCTAssertTrue(restored.showsSummary)
    }

    @MainActor
    func testReturningStockAndMovingFixtureAreReversible() async throws {
        let model = AppModel(store: InMemoryGameStateStore())
        model.shopNameInput = "Little Lantern"
        XCTAssertTrue(model.submitOnboarding())
        model.beginPlacement(kind: .basicDisplayTable)
        XCTAssertTrue(model.confirmCurrentPlacement())
        let id = model.selectedFixtureID
        model.showPanel(.stock)
        XCTAssertTrue(model.confirmStock())
        model.beginMovingSelectedFixture()
        model.movePlacement(deltaX: 1, deltaY: 0)
        XCTAssertTrue(model.confirmCurrentPlacement())
        XCTAssertEqual(model.state.balance, 440)
        XCTAssertEqual(model.state.stock.first?.fixtureID, id)
        model.showPanel(.stock)
        model.returnSelectedStock()
        XCTAssertEqual(model.state.balance, 450)
        model.sellSelectedFixture()
        XCTAssertEqual(model.state.balance, 500)
        XCTAssertTrue(model.state.fixtures.isEmpty)
    }
}
#endif