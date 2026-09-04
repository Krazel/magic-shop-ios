import Foundation
import XCTest

#if SWIFT_PACKAGE
@testable import MagicShopCore
#else
@testable import MagicShop
#endif

final class CommerceTests: XCTestCase {
    func testPlayableBuildStockOpenLoopSurvivesEveryRelaunchWithoutRepeatedIncome() throws {
        var engine = newShop()
        let table = try place(.basicDisplayTable, at: GridPoint(x: 4, y: 4), in: &engine)
        let shelf = try place(.simpleShelf, at: GridPoint(x: 4, y: 10), in: &engine)
        try stock(.luckyCharm, on: table, slot: 0, in: &engine)
        try stock(.glowPotion, on: shelf, slot: 0, in: &engine)
        try stock(.pocketSpellbook, on: shelf, slot: 1, in: &engine)
        XCTAssertEqual(engine.state.balance, 240)

        let day = try engine.openDay()
        XCTAssertEqual(day.visitors.map(\.requestedProduct),
                       [.glowPotion, .luckyCharm, .pocketSpellbook,
                        .glowPotion, .luckyCharm, .pocketSpellbook])
        var receipts: [SaleReceipt] = []
        while let visit = engine.state.currentDay?.nextVisit {
            let result = try engine.advanceDay(expectedVisitID: visit.id)
            if let sale = result.sale { receipts.append(sale) }
            engine = try reloaded(engine)
            let saved = engine.state
            XCTAssertThrowsError(try engine.advanceDay(expectedVisitID: visit.id))
            XCTAssertEqual(engine.state, saved)
        }
        XCTAssertEqual(receipts.count, 3)
        XCTAssertEqual(engine.state.phase, .summary)
        XCTAssertEqual(engine.state.balance, 380)
        XCTAssertTrue(engine.state.stock.isEmpty)
        XCTAssertEqual(engine.state.currentDay?.summary?.revenue, 140)
        XCTAssertEqual(engine.state.currentDay?.summary?.costOfGoods, 60)
        XCTAssertEqual(engine.state.currentDay?.summary?.profit, 80)
        XCTAssertEqual(engine.state.currentDay?.summary?.customersWithoutPurchase, 3)

        let summary = try engine.acknowledgeDaySummary(dayID: day.id)
        engine = try reloaded(engine)
        XCTAssertEqual(engine.state.phase, .preparing)
        XCTAssertEqual(engine.state.balance, 380)
        XCTAssertEqual(engine.state.dayHistory, [summary])
        XCTAssertEqual(engine.state.completedDays, 1)
        let acknowledged = engine.state
        XCTAssertThrowsError(try engine.acknowledgeDaySummary(dayID: day.id))
        XCTAssertEqual(engine.state, acknowledged)

        // Reinvest the actual earnings into another display and another unit.
        let secondTable = try place(.basicDisplayTable, at: GridPoint(x: 6, y: 6), in: &engine)
        try stock(.glowPotion, on: secondTable, slot: 0, in: &engine)
        XCTAssertEqual(engine.state.balance, 320)
        XCTAssertThrowsError(try engine.openDay(dayID: day.id)) { error in
            XCTAssertEqual(error as? CommerceError, .duplicateDayID(day.id))
        }
        let secondDay = try engine.openDay()
        XCTAssertEqual(secondDay.dayNumber, 2)
        try finishDay(in: &engine)
        XCTAssertEqual(engine.state.balance, 345)
        XCTAssertEqual(engine.state.currentDay?.summary?.customersServed, 1)
    }

    func testStockPreviewAndCancelDoNotMutateSave() throws {
        var engine = newShop()
        let table = try place(.basicDisplayTable, at: GridPoint(x: 4, y: 4), in: &engine)
        let saved = engine.state
        let draft = engine.makeStockDraft(product: .glowPotion, fixtureID: table.id, slotIndex: 0)
        try engine.validate(draft)
        engine.cancel(draft)
        XCTAssertEqual(engine.state, saved)
        try engine.confirm(draft)
        XCTAssertEqual(engine.state.balance, saved.balance - 10)
        XCTAssertEqual(engine.state.stock.count, 1)
    }

    func testOneUnitPerSlotAndFixtureCompatibility() throws {
        var engine = newShop()
        let table = try place(.basicDisplayTable, at: GridPoint(x: 4, y: 4), in: &engine)
        let shelf = try place(.simpleShelf, at: GridPoint(x: 4, y: 10), in: &engine)
        let saved = engine.state
        assertCommerceError(.incompatibleProduct) {
            try engine.confirm(StockDraft(product: .pocketSpellbook, fixtureID: table.id, slotIndex: 0))
        }
        assertCommerceError(.incompatibleProduct) {
            try engine.confirm(StockDraft(product: .luckyCharm, fixtureID: shelf.id, slotIndex: 0))
        }
        assertCommerceError(.invalidSlot) {
            try engine.confirm(StockDraft(product: .glowPotion, fixtureID: table.id, slotIndex: 1))
        }
        assertCommerceError(.invalidSlot) {
            try engine.confirm(StockDraft(product: .glowPotion, fixtureID: shelf.id, slotIndex: -1))
        }
        XCTAssertEqual(engine.state, saved)
        try stock(.glowPotion, on: table, slot: 0, in: &engine)
        try stock(.glowPotion, on: shelf, slot: 0, in: &engine)
        try stock(.pocketSpellbook, on: shelf, slot: 1, in: &engine)
        let full = engine.state
        assertCommerceError(.slotOccupied) {
            try engine.confirm(StockDraft(product: .luckyCharm, fixtureID: table.id, slotIndex: 0))
        }
        assertCommerceError(.invalidSlot) {
            try engine.confirm(StockDraft(product: .glowPotion, fixtureID: shelf.id, slotIndex: 2))
        }
        XCTAssertEqual(engine.state, full)
        XCTAssertEqual(engine.state.stock.count, 3)
    }

    func testStockInsufficientFundsMissingFixtureAndDuplicateIdentityDoNotMutate() throws {
        let table = PlacedFixture(kind: .basicDisplayTable, origin: GridPoint(x: 4, y: 4))
        var poor = GameEngine(state: GameState(balance: 9, fixtures: [table]))
        let initial = poor.state
        assertCommerceError(.insufficientFunds(required: 10, available: 9)) {
            try poor.confirm(StockDraft(product: .glowPotion, fixtureID: table.id, slotIndex: 0))
        }
        let missing = UUID()
        assertCommerceError(.fixtureNotFound(missing)) {
            try poor.confirm(StockDraft(product: .glowPotion, fixtureID: missing, slotIndex: 0))
        }
        XCTAssertEqual(poor.state, initial)

        var engine = newShop()
        let shelf = try place(.simpleShelf, at: GridPoint(x: 4, y: 10), in: &engine)
        let unit = try stock(.glowPotion, on: shelf, slot: 0, in: &engine)
        let stocked = engine.state
        assertCommerceError(.duplicateStockID(unit.id)) {
            try engine.confirm(StockDraft(stockID: unit.id, product: .glowPotion,
                                          fixtureID: shelf.id, slotIndex: 1))
        }
        XCTAssertEqual(engine.state, stocked)
    }

    func testDuplicateFurnitureIdentityIsRejectedEvenAtAnotherFreeCell() throws {
        var engine = newShop()
        let table = try place(.basicDisplayTable, at: GridPoint(x: 4, y: 4), in: &engine)
        let saved = engine.state
        let replay = PlacementDraft(fixtureID: table.id, kind: table.kind, origin: GridPoint(x: 6, y: 6))
        XCTAssertThrowsError(try engine.confirm(replay)) { error in
            XCTAssertEqual(error as? PlacementError, .duplicateFixtureID(table.id))
        }
        XCTAssertEqual(engine.state, saved)
    }

    func testUnreachableProductRemainsStockedAndDoesNotGenerateIncome() throws {
        var engine = newShop()
        let trapped = try place(.basicDisplayTable, at: GridPoint(x: 4, y: 4), in: &engine)
        for point in [GridPoint(x: 4, y: 3), GridPoint(x: 3, y: 4),
                      GridPoint(x: 5, y: 4), GridPoint(x: 4, y: 5)] {
            try place(.basicDisplayTable, at: point, in: &engine)
        }
        let accessible = try place(.basicDisplayTable, at: GridPoint(x: 6, y: 6), in: &engine)
        let charm = try stock(.luckyCharm, on: trapped, slot: 0, in: &engine)
        try stock(.glowPotion, on: accessible, slot: 0, in: &engine)
        XCTAssertFalse(ShopAccess.isReachable(trapped, in: engine.state))
        XCTAssertNil(ShopAccess.path(to: trapped, in: engine.state))
        XCTAssertTrue(ShopAccess.isReachable(accessible, in: engine.state))
        let balance = engine.state.balance

        try engine.openDay()
        try finishDay(in: &engine)
        XCTAssertEqual(engine.state.balance, balance + 25)
        XCTAssertEqual(engine.state.stock, [charm])
        XCTAssertEqual(engine.state.currentDay?.summary?.customersServed, 1)
    }

    func testRoutingRespectsStaticBlockersAndOnlyCardinalAccess() throws {
        var world = ShopWorldState.starter
        let table = PlacedFixture(kind: .basicDisplayTable, origin: GridPoint(x: 4, y: 4))
        for point in [GridPoint(x: 4, y: 3), GridPoint(x: 3, y: 4),
                      GridPoint(x: 5, y: 4), GridPoint(x: 4, y: 5)] {
            world.hitMap.updateCell(at: point) { $0.staticBlocker = .rubble }
        }
        let blocked = GameState(fixtures: [table], world: world)
        XCTAssertNil(ShopAccess.path(to: table, in: blocked))
        world.hitMap.updateCell(at: GridPoint(x: 4, y: 3)) { $0.staticBlocker = nil }
        let open = GameState(fixtures: [table], world: world)
        let path = try XCTUnwrap(ShopAccess.path(to: table, in: open))
        XCTAssertEqual(path.first, GridPoint(x: 5, y: 0))
        XCTAssertEqual(path.last, GridPoint(x: 4, y: 3))
        let reachable = ShopAccess.reachableCells(in: open)
        for (from, to) in zip(path, path.dropFirst()) {
            XCTAssertEqual(abs(from.x - to.x) + abs(from.y - to.y), 1)
            XCTAssertTrue(reachable.contains(to))
        }
        XCTAssertEqual(path, ShopAccess.path(to: table, in: open))
        XCTAssertFalse(reachable.contains(table.origin))
        XCTAssertFalse(reachable.contains(GridPoint(x: 3, y: 4)))
    }

    func testOpeningRequiresOnboardingAndReachableStock() throws {
        var engine = GameEngine()
        let initial = engine.state
        assertCommerceError(.onboardingRequired) { try engine.openDay() }
        XCTAssertEqual(engine.state, initial)
        try engine.completeOnboarding(shopName: "Moon & Mortar")
        let named = engine.state
        assertCommerceError(.noReachableStock) { try engine.openDay() }
        XCTAssertEqual(engine.state, named)

        var world = engine.state.world
        world.hitMap.updateCell(at: GridPoint(x: 5, y: 0)) { $0.staticBlocker = .rubble }
        let table = PlacedFixture(kind: .basicDisplayTable, origin: GridPoint(x: 4, y: 4))
        let unit = StockItem(product: .glowPotion, fixtureID: table.id, slotIndex: 0)
        engine = GameEngine(state: GameState(shopName: "Moon & Mortar", onboardingCompleted: true,
                                            fixtures: [table], world: world, stock: [unit]))
        let unreachable = engine.state
        assertCommerceError(.noReachableStock) { try engine.openDay() }
        XCTAssertEqual(engine.state, unreachable)
    }

    func testOpenAndSummaryBlockAllShopMutations() throws {
        var engine = newShop()
        let table = try place(.basicDisplayTable, at: GridPoint(x: 4, y: 4), in: &engine)
        let unit = try stock(.glowPotion, on: table, slot: 0, in: &engine)
        try engine.openDay()
        for phase in [ShopPhase.open, .summary] {
            if phase == .summary { try finishDay(in: &engine) }
            let saved = engine.state
            let newFurniture = PlacementDraft(kind: .basicDisplayTable, origin: GridPoint(x: 7, y: 7))
            XCTAssertThrowsError(try engine.confirm(newFurniture)) { error in
                XCTAssertEqual(error as? PlacementError, .shopIsNotPreparing(phase))
            }
            let newStock = StockDraft(product: .luckyCharm, fixtureID: table.id, slotIndex: 0)
            assertCommerceError(.wrongPhase(required: .preparing, actual: phase)) {
                try engine.confirm(newStock)
            }
            XCTAssertThrowsError(try engine.moveFixture(fixtureID: table.id, origin: GridPoint(x: 6, y: 6)))
            XCTAssertThrowsError(try engine.returnStock(stockID: unit.id))
            XCTAssertThrowsError(try engine.sellEmptyFixture(fixtureID: table.id))
            XCTAssertThrowsError(try engine.openDay())
            engine.cancel(newFurniture)
            engine.cancel(newStock)
            XCTAssertEqual(engine.state, saved)
        }
    }

    func testOutOfOrderOrDifferentDayVisitCannotAdvanceAndWrongSummaryCannotClose() throws {
        var engine = newShop()
        let table = try place(.basicDisplayTable, at: GridPoint(x: 4, y: 4), in: &engine)
        try stock(.glowPotion, on: table, slot: 0, in: &engine)
        let day = try engine.openDay()
        let initialDay = engine.state
        assertCommerceError(.unexpectedVisit) {
            try engine.advanceDay(expectedVisitID: VisitID(dayID: day.id, index: 1))
        }
        assertCommerceError(.unexpectedVisit) {
            try engine.advanceDay(expectedVisitID: VisitID(dayID: UUID(), index: 0))
        }
        XCTAssertThrowsError(try engine.acknowledgeDaySummary(dayID: day.id))
        XCTAssertEqual(engine.state, initialDay)
        try finishDay(in: &engine)
        let finished = engine.state
        assertCommerceError(.unexpectedDay) {
            try engine.acknowledgeDaySummary(dayID: UUID())
        }
        XCTAssertEqual(engine.state, finished)
    }

    func testAllMoneySpentOnFurnitureIsRecoverableWithoutResetOrGift() throws {
        var engine = newShop()
        for x in 0..<10 {
            try place(.basicDisplayTable, at: GridPoint(x: x, y: 6), in: &engine)
        }
        XCTAssertEqual(engine.state.balance, 0)
        let furniture = engine.state.fixtures
        XCTAssertEqual(try engine.sellEmptyFixture(fixtureID: furniture[0].id), 50)
        XCTAssertEqual(engine.state.balance, 50)
        let unit = try stock(.glowPotion, on: furniture[1], slot: 0, in: &engine)
        XCTAssertEqual(engine.state.balance, 40)
        let stocked = engine.state
        assertCommerceError(.fixtureContainsStock) {
            try engine.sellEmptyFixture(fixtureID: furniture[1].id)
        }
        XCTAssertEqual(engine.state, stocked)
        XCTAssertEqual(try engine.returnStock(stockID: unit.id), 10)
        XCTAssertEqual(engine.state.balance, 50)
        let returned = engine.state
        assertCommerceError(.stockNotFound(unit.id)) { try engine.returnStock(stockID: unit.id) }
        assertCommerceError(.fixtureNotFound(furniture[0].id)) {
            try engine.sellEmptyFixture(fixtureID: furniture[0].id)
        }
        XCTAssertEqual(engine.state, returned)
        try stock(.glowPotion, on: furniture[1], slot: 0, in: &engine)
        try engine.openDay()
        try finishDay(in: &engine)
        XCTAssertEqual(engine.state.balance, 65)
    }

    func testMovingStockedShelfPreservesIdentityStockAndZeroBalance() throws {
        let shelf = PlacedFixture(kind: .simpleShelf, origin: GridPoint(x: 4, y: 10))
        let units = [StockItem(product: .glowPotion, fixtureID: shelf.id, slotIndex: 0),
                     StockItem(product: .pocketSpellbook, fixtureID: shelf.id, slotIndex: 1)]
        var engine = GameEngine(state: GameState(balance: 0, fixtures: [shelf], stock: units))
        let moved = try engine.moveFixture(fixtureID: shelf.id, origin: GridPoint(x: 0, y: 6),
                                            rotation: .east)
        XCTAssertEqual(moved.id, shelf.id)
        XCTAssertEqual(moved.kind, shelf.kind)
        XCTAssertEqual(engine.state.balance, 0)
        XCTAssertEqual(engine.state.stock, units)
        let saved = engine.state
        XCTAssertThrowsError(try engine.moveFixture(fixtureID: shelf.id, origin: GridPoint(x: 4, y: 4)))
        XCTAssertEqual(engine.state, saved)
        try engine.moveFixture(fixtureID: shelf.id, origin: moved.origin)
        XCTAssertEqual(engine.state, saved)
        XCTAssertEqual(try reloaded(engine).state, saved)
    }

    func testMoveIgnoresOnlyOwnFootprintAndStillRejectsEntranceDebrisBoundsAndOtherFurniture() throws {
        var engine = newShop()
        let table = try place(.basicDisplayTable, at: GridPoint(x: 4, y: 4), in: &engine)
        try place(.basicDisplayTable, at: GridPoint(x: 6, y: 6), in: &engine)
        let saved = engine.state
        try engine.moveFixture(fixtureID: table.id, origin: table.origin)
        for point in [GridPoint(x: 6, y: 6), GridPoint(x: 5, y: 0),
                      GridPoint(x: 1, y: 5), GridPoint(x: Int.max, y: 4)] {
            XCTAssertThrowsError(try engine.moveFixture(fixtureID: table.id, origin: point))
            XCTAssertEqual(engine.state, saved)
        }
    }

    func testRefundOverflowIsRejectedWithoutRemovingStock() {
        let table = PlacedFixture(kind: .basicDisplayTable, origin: GridPoint(x: 4, y: 4))
        let unit = StockItem(product: .glowPotion, fixtureID: table.id, slotIndex: 0)
        var engine = GameEngine(state: GameState(balance: Int.max, fixtures: [table], stock: [unit]))
        let saved = engine.state
        assertCommerceError(.balanceOverflow) { try engine.returnStock(stockID: unit.id) }
        XCTAssertEqual(engine.state, saved)
    }

    func testSaleOverflowDoesNotConsumeStockOrVisitor() throws {
        let table = PlacedFixture(kind: .basicDisplayTable, origin: GridPoint(x: 4, y: 4))
        let unit = StockItem(product: .glowPotion, fixtureID: table.id, slotIndex: 0)
        var engine = GameEngine(state: GameState(shopName: "Moon & Mortar", onboardingCompleted: true,
                                                balance: Int.max, fixtures: [table], stock: [unit]))
        let day = try engine.openDay()
        let saved = engine.state
        assertCommerceError(.balanceOverflow) {
            try engine.advanceDay(expectedVisitID: day.visitors[0].id)
        }
        XCTAssertEqual(engine.state, saved)
    }

    func testSaleCostOverflowDoesNotConsumeStockOrVisitor() throws {
        let shelf = PlacedFixture(kind: .simpleShelf, origin: GridPoint(x: 4, y: 10))
        let units = [
            StockItem(product: .glowPotion, fixtureID: shelf.id, slotIndex: 0, purchaseCost: Int.max),
            StockItem(product: .glowPotion, fixtureID: shelf.id, slotIndex: 1, purchaseCost: 1)
        ]
        var engine = GameEngine(state: GameState(shopName: "Old Shop", onboardingCompleted: true,
                                                fixtures: [shelf], stock: units))
        let day = try engine.openDay()
        for index in 0..<3 { try engine.advanceDay(expectedVisitID: day.visitors[index].id) }
        let saved = engine.state
        assertCommerceError(.totalOverflow) {
            try engine.advanceDay(expectedVisitID: day.visitors[3].id)
        }
        XCTAssertEqual(engine.state, saved)
        XCTAssertNoThrow(try engine.state.validateIntegrity())
    }

    private func newShop() -> GameEngine {
        GameEngine(state: GameState(shopName: "Moon & Mortar", onboardingCompleted: true))
    }

    @discardableResult
    private func place(_ kind: FixtureKind, at point: GridPoint, in engine: inout GameEngine) throws -> PlacedFixture {
        try engine.confirm(engine.makePlacementDraft(kind: kind, origin: point))
    }

    @discardableResult
    private func stock(_ kind: ProductKind, on fixture: PlacedFixture, slot: Int,
                       in engine: inout GameEngine) throws -> StockItem {
        try engine.confirm(engine.makeStockDraft(product: kind, fixtureID: fixture.id, slotIndex: slot))
    }

    private func finishDay(in engine: inout GameEngine) throws {
        while let visit = engine.state.currentDay?.nextVisit {
            try engine.advanceDay(expectedVisitID: visit.id)
        }
    }

    private func reloaded(_ engine: GameEngine) throws -> GameEngine {
        GameEngine(state: try JSONDecoder().decode(GameState.self, from: JSONEncoder().encode(engine.state)))
    }

    private func assertCommerceError<T>(
        _ expected: CommerceError, file: StaticString = #filePath, line: UInt = #line,
        operation: () throws -> T
    ) {
        XCTAssertThrowsError(try operation(), file: file, line: line) { error in
            XCTAssertEqual(error as? CommerceError, expected, file: file, line: line)
        }
    }
}
