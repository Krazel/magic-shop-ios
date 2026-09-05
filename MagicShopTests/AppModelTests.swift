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

    @MainActor
    func testDraggingExistingDisplayPreservesStockAndCancelsInvalidOrFailedDrops() async throws {
        let store = FailingSessionStore()
        let model = AppModel(store: store)
        model.shopNameInput = "Movable Magic"
        XCTAssertTrue(model.submitOnboarding())
        model.beginPlacement(kind: .basicDisplayTable)
        XCTAssertTrue(model.confirmCurrentPlacement())
        model.showPanel(.stock)
        XCTAssertTrue(model.confirmStock())
        let id = try XCTUnwrap(model.selectedFixtureID)
        let stock = model.state.stock
        XCTAssertTrue(model.beginWorldDrag(id))
        model.setPlacementOrigin(GridPoint(x: 6, y: 4))
        XCTAssertEqual(model.state.fixtures[0].origin, GridPoint(x: 5, y: 4))
        model.finishWorldDrag(true)
        XCTAssertEqual(model.state.fixtures[0].origin, GridPoint(x: 6, y: 4))
        XCTAssertEqual(model.state.balance, 440)
        XCTAssertEqual(model.state.stock, stock)
        let moved = model.state

        XCTAssertTrue(model.beginWorldDrag(id))
        model.setPlacementOrigin(GridPoint(x: 1, y: 5)) // initial rubble
        XCTAssertFalse(model.isPlacementValid)
        model.finishWorldDrag(true)
        XCTAssertEqual(model.state, moved)
        XCTAssertNil(model.placementDraft)
        XCTAssertNotNil(model.inlineMessage)

        XCTAssertTrue(model.beginWorldDrag(id))
        model.setPlacementOrigin(GridPoint(x: 7, y: 4))
        model.finishWorldDrag(false)
        XCTAssertEqual(model.state, moved)
        XCTAssertTrue(model.beginWorldDrag(id))
        model.setPlacementOrigin(GridPoint(x: 7, y: 4))
        store.failWrites = true
        model.finishWorldDrag(true)
        XCTAssertEqual(model.state, moved)
        XCTAssertEqual(try store.load(), moved)
        XCTAssertNotNil(model.inlineMessage)
        store.failWrites = false
        XCTAssertEqual(AppModel(store: store).state, moved)
    }

    @MainActor
    func testDraggingNewPlacementDoesNotPurchaseAndCancelRestoresItsDraft() async throws {
        let model = AppModel(store: InMemoryGameStateStore())
        model.shopNameInput = "Patient Potions"
        XCTAssertTrue(model.submitOnboarding())
        model.beginPlacement(kind: .pottedFern)
        let original = try XCTUnwrap(model.placementDraft)
        XCTAssertTrue(model.beginWorldDrag(original.fixtureID))
        model.setPlacementOrigin(GridPoint(x: 6, y: 4))
        model.finishWorldDrag(true)
        XCTAssertEqual(model.state.balance, 500)
        XCTAssertTrue(model.state.fixtures.isEmpty)
        XCTAssertEqual(model.placementDraft?.origin, GridPoint(x: 6, y: 4))
        XCTAssertTrue(model.beginWorldDrag(original.fixtureID))
        model.setPlacementOrigin(GridPoint(x: 7, y: 4))
        model.finishWorldDrag(false)
        XCTAssertEqual(model.placementDraft?.origin, GridPoint(x: 6, y: 4))
        XCTAssertEqual(model.state.balance, 500)
        XCTAssertTrue(model.confirmCurrentPlacement())
        XCTAssertEqual(model.state.balance, 465)
        XCTAssertEqual(model.state.fixtures.count, 1)
        XCTAssertEqual(model.state.fixtures[0].id, original.fixtureID)
        model.closeBuild()
        XCTAssertNil(model.placementDraft)
        XCTAssertEqual(model.panel, .none)
    }

    @MainActor
    func testCleaningProgressSurvivesRelaunchAndFailedStrokeDoesNotCount() async throws {
        let store = FailingSessionStore()
        let model = AppModel(store: store)
        model.shopNameInput = "Clean Curios"
        XCTAssertTrue(model.submitOnboarding())
        model.showPanel(.care)
        store.failWrites = true
        model.cleanGroup(.rubble)
        XCTAssertEqual(model.state.repairProgress(for: .rubble), 0)
        XCTAssertEqual(model.state.balance, 500)
        store.failWrites = false
        model.cleanGroup(.rubble)
        XCTAssertEqual(model.state.repairProgress(for: .rubble), 1)
        let restored = AppModel(store: store)
        restored.showPanel(.care)
        restored.cleanGroup(.rubble)
        XCTAssertEqual(restored.state.repairProgress(for: .rubble), 2)
        restored.cleanGroup(.rubble)
        XCTAssertEqual(restored.state.repairProgress(for: .rubble), 3)
        XCTAssertTrue(restored.state.restoration.repairedGroups.contains(.rubble))
        XCTAssertEqual(restored.state.balance, 500)
        let clean = restored.state
        restored.cleanGroup(.rubble)
        XCTAssertEqual(restored.state, clean)
        restored.closeBuild()
        XCTAssertEqual(restored.panel, .none)
    }

    @MainActor
    func testFloorPreviewCancelAndFailedBatchNeverSpendBeforeSuccessfulApply() async throws {
        let store = FailingSessionStore()
        let model = AppModel(store: store)
        model.shopNameInput = "Oak & Moon"
        XCTAssertTrue(model.submitOnboarding())
        model.showPanel(.care)
        model.carePaint = true
        model.selectFloor(.warmOak)
        let points = [GridPoint(x: 4, y: 4), GridPoint(x: 5, y: 4)]
        model.toolStroke(points[0])
        model.toolStroke(points[0])
        model.toolStroke(points[1])
        model.toolStroke(GridPoint(x: 1, y: 5))
        XCTAssertEqual(model.floorPreview, points)
        XCTAssertEqual(model.floorPreviewCost, 4)
        XCTAssertEqual(model.state.balance, 500)
        XCTAssertEqual(model.state.world.floor.styleID(at: points[0]), .wornTerracotta)
        model.cancelFloorPreview()
        XCTAssertTrue(model.floorPreview.isEmpty)
        XCTAssertEqual(model.state.balance, 500)
        for point in points { model.toolStroke(point) }
        let before = model.state
        store.failWrites = true
        XCTAssertFalse(model.applyFloorPreview())
        XCTAssertEqual(model.state, before)
        XCTAssertEqual(try store.load(), before)
        XCTAssertEqual(model.floorPreview, points)
        store.failWrites = false
        XCTAssertTrue(model.applyFloorPreview())
        XCTAssertEqual(model.state.balance, 496)
        XCTAssertTrue(model.floorPreview.isEmpty)
        XCTAssertTrue(points.allSatisfy { model.state.world.floor.styleID(at: $0) == .warmOak })
        for point in points { model.toolStroke(point) }
        XCTAssertTrue(model.floorPreview.isEmpty)
        XCTAssertFalse(model.applyFloorPreview())
        XCTAssertEqual(AppModel(store: store).state, model.state)
    }

    @MainActor
    func testPricesApplyDuringLivingDayAndFailuresPreserveThePreviousPrice() async throws {
        let store = FailingSessionStore()
        let model = AppModel(store: store)
        model.shopNameInput = "Fair Prices"
        XCTAssertTrue(model.submitOnboarding())
        model.beginPlacement(kind: .basicDisplayTable)
        XCTAssertTrue(model.confirmCurrentPlacement())
        model.showPanel(.stock)
        XCTAssertTrue(model.confirmStock())
        model.startDay()
        model.showPanel(.pricing)
        XCTAssertEqual(model.panel, .pricing)
        XCTAssertTrue(model.applyPrice(15, for: .glowPotion))
        XCTAssertEqual(model.pricingQuote(for: .glowPotion).price, 15)
        XCTAssertFalse(model.applyPrice(9, for: .glowPotion))
        XCTAssertEqual(model.state.price(for: .glowPotion), 15)
        store.failWrites = true
        XCTAssertFalse(model.applyPrice(40, for: .glowPotion))
        XCTAssertEqual(model.state.price(for: .glowPotion), 15)
        store.failWrites = false
        XCTAssertTrue(model.applyPrice(40, for: .glowPotion))
        model.showPanel(.stock)
        let stocked = model.state.stock[0]
        model.returnSelectedStock()
        XCTAssertFalse(model.state.stock.contains { $0.id == stocked.id })
        XCTAssertTrue(model.confirmStock())
        XCTAssertEqual(model.state.balance, 440)
        model.showPanel(.care)
        XCTAssertFalse(model.carePaint)
        model.cleanGroup(.discardedPapers)
        XCTAssertEqual(model.state.repairProgress(for: .discardedPapers), 1)
        XCTAssertEqual(AppModel(store: store).state, model.state)
    }
}
#endif