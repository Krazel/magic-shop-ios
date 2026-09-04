#if !SWIFT_PACKAGE
import XCTest
@testable import MagicShop

final class CompleteAppModelTests: XCTestCase {
    @MainActor
    func testClockPausesAndSixVisitsFinishWithoutDuplicateSales() async throws {
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
        for _ in 0..<200 { model.tick(seconds: 0.25) }
        XCTAssertEqual(model.state.balance, 440)
        XCTAssertEqual(model.visitProgress, 0)
        model.setAppActive(true)
        model.togglePause()
        model.tick(seconds: 0.25)
        XCTAssertEqual(model.visitProgress, 0)
        model.togglePause()
        for _ in 0..<200 { model.tick(seconds: 0.25) }
        XCTAssertTrue(model.showsSummary)
        XCTAssertEqual(model.clockText, "18:00")
        XCTAssertEqual(model.state.balance, 465)
        XCTAssertEqual(model.state.currentDay?.outcomes.count, 6)
        for _ in 0..<200 { model.tick(seconds: 0.25) }
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
        let token = model.activeVisit?.id
        store.failWrites = true
        for _ in 0..<30 { model.tick(seconds: 0.25) }
        XCTAssertTrue(model.isPaused)
        XCTAssertEqual(model.state.balance, 440)
        XCTAssertEqual(model.state.currentDay?.nextVisitIndex, 0)
        XCTAssertEqual(model.activeVisit?.id, token)
        store.failWrites = false
        model.togglePause()
        for _ in 0..<30 { model.tick(seconds: 0.25) }
        XCTAssertEqual(model.state.balance, 465)
        XCTAssertEqual(model.state.currentDay?.sales.count, 1)
        let restored = AppModel(store: store)
        for _ in 0..<180 { restored.tick(seconds: 0.25) }
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