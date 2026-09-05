import XCTest

#if SWIFT_PACKAGE
@testable import MagicShopCore
#else
@testable import MagicShop
#endif

final class LivingShopTests: XCTestCase {
    private let dayID = UUID(uuidString: "00000000-0000-0000-0000-000000000500")!

    private func stockedEngine(displays: Int = 1) throws -> GameEngine {
        var engine = GameEngine()
        try engine.completeOnboarding(shopName: "Living Lantern")
        let points = [GridPoint(x: 3, y: 4), GridPoint(x: 6, y: 4), GridPoint(x: 4, y: 7)]
        for index in 0..<displays {
            let fixtureID = UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", index + 1))!
            let table = try engine.confirm(engine.makePlacementDraft(kind: .basicDisplayTable,
                origin: points[index], fixtureID: fixtureID))
            _ = try engine.confirm(engine.makeStockDraft(product: .glowPotion, fixtureID: table.id, slotIndex: 0,
                stockID: UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", index + 101))!))
        }
        return engine
    }

    private func finish(_ engine: inout GameEngine) throws {
        let day = try XCTUnwrap(engine.state.livingDay)
        _ = try engine.advanceLivingDay(expectedDayID: day.id, expectedMinute: day.minute, toMinute: 1080)
    }

    private func roundTrip(_ state: GameState) throws -> GameState {
        try JSONDecoder().decode(GameState.self, from: JSONEncoder().encode(state))
    }

    private func saleReadyEngine() throws -> GameEngine {
        for seed in UInt64(0)..<100 {
            var engine = try stockedEngine()
            try engine.setPrice(10, for: .glowPotion)
            let day = try engine.openLivingDay(dayID: dayID, seed: seed)
            let eligible = day.visitors.filter {
                $0.hasBuyingIntent && $0.preferredProduct == .glowPotion && $0.interestRoll < 90
            }
            if eligible.count >= 2 { return engine }
        }
        XCTFail("Expected a deterministic seed with multiple interested visitors")
        throw LivingShopError.unexpectedMinute
    }

    func testSeededVisitorsOverlapBrowseAndUseWalkableCardinalRoutes() throws {
        var engine = try stockedEngine(displays: 3)
        let day = try engine.openLivingDay(dayID: dayID, seed: 99)
        var copy = try stockedEngine(displays: 3)
        let same = try copy.openLivingDay(dayID: dayID, seed: 99)
        XCTAssertEqual(day, same)
        XCTAssertEqual(day.visitors.count, 12)
        XCTAssertEqual(day.minute, 540)
        XCTAssertTrue(day.visitors.allSatisfy { (540...1020).contains($0.arrivalMinute) })
        XCTAssertTrue(day.visitors.allSatisfy { (2...3).contains($0.stops.count) })
        let peak = (540...1080).map { minute in
            day.visitors.filter { $0.arrivalMinute <= minute && minute < $0.departureMinute }.count
        }.max()!
        XCTAssertTrue((2...4).contains(peak))
        let gaps = zip(day.visitors, day.visitors.dropFirst()).map { pair in pair.1.arrivalMinute - pair.0.arrivalMinute }
        XCTAssertGreaterThan(Set(gaps).count, 1)
        let reachable = ShopAccess.reachableCells(in: engine.state)
        for visitor in day.visitors {
            for path in visitor.stops.map(\.path) + [visitor.exitPath] {
                XCTAssertTrue(path.allSatisfy { reachable.contains($0) })
                for (a, b) in zip(path, path.dropFirst()) {
                    XCTAssertEqual(abs(a.x - b.x) + abs(a.y - b.y), 1)
                }
            }
            let point = visitor.position(at: Double(visitor.arrivalMinute))
            XCTAssertEqual(point.progress, 0)
            XCTAssertEqual(visitor.status(at: visitor.departureMinute), .departed)
        }
        XCTAssertEqual(try roundTrip(engine.state), engine.state)
    }

    func testRelaunchAndDifferentAdvanceChunksProduceIdenticalState() throws {
        var whole = try stockedEngine(displays: 3)
        try whole.openLivingDay(dayID: dayID, seed: 42)
        var chunked = GameEngine(state: whole.state)
        try finish(&whole)
        for minute in [590, 677, 781, 902, 1015, 1080] {
            let current = try XCTUnwrap(chunked.state.livingDay)
            try chunked.advanceLivingDay(expectedDayID: dayID, expectedMinute: current.minute, toMinute: minute)
            chunked = GameEngine(state: try roundTrip(chunked.state))
        }
        XCTAssertEqual(chunked.state, whole.state)
        XCTAssertEqual(whole.state.calendar.timeText, "18:00")
        XCTAssertEqual(whole.state.livingDay?.outcomes.count, 12)
        let before = whole.state
        XCTAssertThrowsError(try whole.advanceLivingDay(expectedDayID: dayID, expectedMinute: 540, toMinute: 1080))
        XCTAssertEqual(whole.state, before)
        let summary = try whole.acknowledgeLivingDaySummary(dayID: dayID)
        XCTAssertEqual(summary.simulation, .living)
        XCTAssertEqual(summary.visitorCount, 12)
        XCTAssertEqual(whole.state.calendar.weekdayName, "Tuesday")
        let acknowledged = whole.state
        XCTAssertThrowsError(try whole.acknowledgeLivingDaySummary(dayID: dayID))
        XCTAssertEqual(whole.state, acknowledged)
    }

    func testMultipleInterestedVisitorsCannotPurchaseTheSamePhysicalUnit() throws {
        var engine = try saleReadyEngine()
        let starting = engine.state
        let unit = try XCTUnwrap(starting.stock.first)
        try finish(&engine)
        let sales = try XCTUnwrap(engine.state.livingDay).sales
        XCTAssertEqual(sales.count, 1)
        XCTAssertEqual(sales.first?.stockID, unit.id)
        XCTAssertEqual(engine.state.balance, starting.balance + 10)
        XCTAssertEqual(engine.state.livingDay?.summary?.customersWithoutPurchase, 11)
        XCTAssertTrue(engine.state.stock.isEmpty)
    }

    func testLivingStockPriceChangesAndRefundsReconcileCashFlow() throws {
        var engine = try saleReadyEngine()
        let opening = engine.state.balance
        let initialUnit = try XCTUnwrap(engine.state.stock.first)
        let table = try XCTUnwrap(engine.state.fixtures.first)
        XCTAssertEqual(try engine.returnStock(stockID: initialUnit.id), 10)
        XCTAssertEqual(engine.state.livingDay?.inventoryCashFlow, 10)
        let replacement = try engine.confirm(engine.makeStockDraft(product: .glowPotion, fixtureID: table.id, slotIndex: 0))
        XCTAssertEqual(engine.state.livingDay?.inventoryCashFlow, 0)
        try engine.setPrice(11, for: .glowPotion)
        let lastDecision = try XCTUnwrap(engine.state.livingDay).visitors.map(\.decisionMinute).max()!
        try engine.advanceLivingDay(expectedDayID: dayID, expectedMinute: 540, toMinute: lastDecision)
        let sale = try XCTUnwrap(engine.state.livingDay?.sales.first)
        XCTAssertEqual(sale.revenue, 11)
        XCTAssertEqual(sale.stockID, replacement.id)
        try engine.setPrice(75, for: .glowPotion)
        XCTAssertEqual(engine.state.livingDay?.sales.first, sale)
        XCTAssertThrowsError(try engine.confirm(engine.makeStockDraft(product: .glowPotion,
            fixtureID: table.id, slotIndex: 0, stockID: sale.stockID)))
        XCTAssertEqual(engine.state.balance, opening + 11)
        XCTAssertEqual(try roundTrip(engine.state), engine.state)
    }

    func testMarketPriceAppealIsMonotonicAndBelowCostOrExtremePricesNeverMutate() throws {
        var engine = try stockedEngine()
        let low = engine.pricingQuote(for: .glowPotion, price: 10)
        let market = engine.pricingQuote(for: .glowPotion, price: 25)
        let high = engine.pricingQuote(for: .glowPotion, price: 75)
        XCTAssertGreaterThan(low.estimatedDemandPercent, market.estimatedDemandPercent)
        XCTAssertGreaterThan(market.estimatedDemandPercent, high.estimatedDemandPercent)
        XCTAssertEqual(low.minimumPrice, 10)
        XCTAssertEqual(market.marketPrice, 25)
        XCTAssertTrue(engine.pricingQuote(for: .glowPotion, price: 1).isBelowCost)
        let before = engine.state
        for price in [Int.min, 0, 1, 9, 76, Int.max] {
            XCTAssertThrowsError(try engine.setPrice(price, for: .glowPotion))
            XCTAssertEqual(engine.state, before)
        }
        try engine.setPrice(75, for: .glowPotion)
        XCTAssertEqual(engine.state.price(for: .glowPotion), 75)
    }

    func testPriceAndBudgetCanMakeInterestedVisitorsLeaveWithoutBuying() throws {
        var engine = try stockedEngine()
        try engine.setPrice(75, for: .glowPotion)
        try engine.openLivingDay(dayID: dayID, seed: 13)
        // Potion budgets are at most $55; secondary interest may have larger
        // budgets, so this seed also exercises the low appeal roll.
        let opening = engine.state.balance
        try finish(&engine)
        XCTAssertTrue(engine.state.livingDay!.visitors.filter { $0.preferredProduct == .glowPotion }
            .allSatisfy { $0.sale == nil })
        XCTAssertEqual(engine.state.balance, opening + engine.state.livingDay!.revenue)
        XCTAssertGreaterThan(engine.state.livingDay!.summary!.customersWithoutPurchase, 0)
    }

    func testMinuteTokenAndFailedAtomicSaveLeaveEverythingUnchangedUntilRetry() throws {
        let engine = try saleReadyEngine()
        let store = LivingFailingStore(engine.state)
        let session = try GameSession(store: store)
        let before = session.engine.state
        store.failWrites = true
        XCTAssertThrowsError(try session.commit {
            try $0.advanceLivingDay(expectedDayID: dayID, expectedMinute: 540, toMinute: 800)
        })
        XCTAssertEqual(session.engine.state, before)
        XCTAssertEqual(try store.load(), before)
        store.failWrites = false
        try session.commit { try $0.advanceLivingDay(expectedDayID: dayID, expectedMinute: 540, toMinute: 800) }
        let saved = session.engine.state
        XCTAssertThrowsError(try session.commit {
            try $0.advanceLivingDay(expectedDayID: dayID, expectedMinute: 540, toMinute: 800)
        })
        XCTAssertEqual(session.engine.state, saved)
        let relaunched = try GameSession(store: store)
        try relaunched.commit { try $0.advanceLivingDay(expectedDayID: dayID, expectedMinute: 800, toMinute: 1080) }
        XCTAssertEqual(relaunched.engine.state.livingDay?.sales.count, 1)
    }

    func testManualRepairsTakeThreeSavedStrokesAndRemainFreeDuringLivingDay() throws {
        var engine = try saleReadyEngine()
        let opening = engine.state.balance
        for repair in RepairCatalog.all {
            let point = try XCTUnwrap(engine.state.world.hitMap.cells.first { $0.staticBlocker == repair.blocker }).point
            for stroke in 1...3 {
                let result = try engine.cleanCell(at: point)
                XCTAssertEqual(result.repairProgress, stroke)
                XCTAssertEqual(result.completedRepair, stroke == 3)
                engine = GameEngine(state: try roundTrip(engine.state))
            }
            XCTAssertTrue(engine.state.restoration.repairedGroups.contains(repair.id))
            XCTAssertNil(engine.state.manualRepairProgress[repair.id])
            XCTAssertFalse(try engine.cleanCell(at: point).didChange)
        }
        XCTAssertEqual(engine.state.balance, opening)
        try finish(&engine)
        XCTAssertThrowsError(try engine.cleanCell(at: GridPoint(x: 3, y: 4)))
    }

    func testFootfallDirtPersistsIsBoundedAndCleaningReducesItWithoutElapsedTime() throws {
        var engine = try stockedEngine(displays: 3)
        XCTAssertTrue(engine.state.dirt.isEmpty)
        try engine.openLivingDay(dayID: dayID, seed: 77)
        let pristine = engine.state
        XCTAssertEqual(try roundTrip(pristine).dirt, [:])
        try engine.advanceLivingDay(expectedDayID: dayID, expectedMinute: 540, toMinute: 800)
        XCTAssertFalse(engine.state.dirt.isEmpty)
        XCTAssertLessThanOrEqual(engine.state.dirt.count, 64)
        XCTAssertTrue(engine.state.dirt.values.allSatisfy { (1...3).contains($0) })
        let point = try XCTUnwrap(engine.state.dirt.keys.first)
        let level = engine.state.dirt[point]!
        XCTAssertEqual(try engine.cleanCell(at: point).removedDirt, 1)
        XCTAssertEqual(engine.state.dirt[point] ?? 0, level - 1)
        XCTAssertEqual(try roundTrip(engine.state).dirt, engine.state.dirt)
        var filled = GameState.initial
        for cell in filled.world.hitMap.cells where cell.staticBlocker == nil {
            for _ in 0..<5 { filled.addFootfallDirt(at: cell.point) }
        }
        XCTAssertEqual(filled.dirt.count, 64)
        XCTAssertTrue(filled.dirt.values.allSatisfy { $0 == 3 })
    }

    func testFloorPaintingChargesOnceRejectsInvalidCellsAndReservesWorkingCapital() throws {
        var engine = GameEngine()
        let point = GridPoint(x: 4, y: 4)
        XCTAssertEqual(try engine.paintFloor(at: point, style: .warmOak), 2)
        XCTAssertEqual(try engine.paintFloor(at: point, style: .warmOak), 0)
        XCTAssertEqual(engine.state.balance, 498)
        XCTAssertEqual(engine.state.world.floor.styleID(at: point), .warmOak)
        let before = engine.state
        XCTAssertThrowsError(try engine.paintFloor(at: GridPoint(x: 1, y: 5), style: .warmOak))
        XCTAssertThrowsError(try engine.paintFloor(at: GridPoint(x: -1, y: 4), style: .terracotta))
        XCTAssertThrowsError(try engine.paintFloor(at: point, style: .wornTerracotta))
        XCTAssertEqual(engine.state, before)
        var poor = GameEngine(state: GameState(balance: 61))
        XCTAssertEqual(try poor.paintFloor(at: point, style: .terracotta), 1)
        let reserved = poor.state
        XCTAssertThrowsError(try poor.paintFloor(at: GridPoint(x: 5, y: 4), style: .terracotta))
        XCTAssertEqual(poor.state, reserved)
        XCTAssertEqual(poor.state.balance, 60)
    }

    func testFloorBatchSaveFailureAndInvalidCellRollbackEntireStroke() throws {
        let store = LivingFailingStore(.initial)
        let session = try GameSession(store: store)
        XCTAssertThrowsError(try session.commit { engine in
            try engine.paintFloor(at: GridPoint(x: 4, y: 4), style: .checkerStone)
            try engine.paintFloor(at: GridPoint(x: 1, y: 5), style: .checkerStone)
        })
        XCTAssertEqual(session.engine.state, .initial)
        store.failWrites = true
        XCTAssertThrowsError(try session.commit {
            try $0.paintFloor(at: GridPoint(x: 4, y: 4), style: .checkerStone)
        })
        XCTAssertEqual(session.engine.state, .initial)
    }

    func testFurnitureAndFloorAreLockedDuringLivingTradingButCareAndStockAreAvailable() throws {
        var engine = try saleReadyEngine()
        let table = try XCTUnwrap(engine.state.fixtures.first)
        let before = engine.state
        XCTAssertThrowsError(try engine.moveFixture(fixtureID: table.id, origin: GridPoint(x: 4, y: 4)))
        XCTAssertThrowsError(try engine.paintFloor(at: GridPoint(x: 4, y: 4), style: .warmOak))
        XCTAssertThrowsError(try engine.confirm(engine.makePlacementDraft(kind: .pottedFern, origin: GridPoint(x: 5, y: 5))))
        XCTAssertEqual(engine.state, before)
        XCTAssertTrue(engine.state.canManageStock)
        try finish(&engine)
        let summary = engine.state
        XCTAssertThrowsError(try engine.setPrice(25, for: .glowPotion))
        XCTAssertThrowsError(try engine.confirm(engine.makeStockDraft(product: .glowPotion, fixtureID: table.id, slotIndex: 0)))
        XCTAssertEqual(engine.state, summary)
    }

    func testSchemaFourMiddayKeepsSixVisitorRulesThenNextDayUsesLivingEngine() throws {
        var original = try stockedEngine()
        let oldDay = try original.openDay(dayID: dayID)
        try original.advanceDay(expectedVisitID: oldDay.visitors[0].id)
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(original.state)) as? [String: Any])
        json["schemaVersion"] = 4
        for key in ["livingDay", "pricing", "dirt", "manualRepairProgress"] { json.removeValue(forKey: key) }
        let migrated = try JSONDecoder().decode(GameState.self, from: JSONSerialization.data(withJSONObject: json))
        XCTAssertEqual(migrated.schemaVersion, 5)
        XCTAssertNil(migrated.livingDay)
        XCTAssertEqual(migrated.currentDay, original.state.currentDay)
        XCTAssertEqual(migrated.balance, original.state.balance)
        var engine = GameEngine(state: migrated)
        XCTAssertThrowsError(try engine.setPrice(10, for: .glowPotion))
        while let next = engine.state.currentDay?.nextVisit { try engine.advanceDay(expectedVisitID: next.id) }
        let summary = try engine.acknowledgeDaySummary(dayID: dayID)
        XCTAssertEqual(summary.simulation, .legacy)
        let table = engine.state.fixtures[0]
        try engine.confirm(engine.makeStockDraft(product: .glowPotion, fixtureID: table.id, slotIndex: 0))
        let next = try engine.openLivingDay(seed: 5)
        XCTAssertEqual(next.dayNumber, 2)
        XCTAssertEqual(engine.state.calendar.weekdayName, "Tuesday")
        XCTAssertEqual(try roundTrip(engine.state), engine.state)
    }

    func testCurrentSchemaRejectsMissingPricingCorruptDirtAndConflictingDayModes() throws {
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(GameState.initial)) as? [String: Any])
        for key in ["pricing", "dirt", "manualRepairProgress"] {
            var missing = json
            missing.removeValue(forKey: key)
            XCTAssertThrowsError(try JSONDecoder().decode(GameState.self, from: JSONSerialization.data(withJSONObject: missing)))
            missing[key] = NSNull()
            XCTAssertThrowsError(try JSONDecoder().decode(GameState.self, from: JSONSerialization.data(withJSONObject: missing)))
        }
        json["schemaVersion"] = 6
        XCTAssertThrowsError(try JSONDecoder().decode(GameState.self, from: JSONSerialization.data(withJSONObject: json)))
        var corrupt = GameState.initial
        corrupt.dirt[GridPoint(x: 4, y: 4)] = 4
        XCTAssertThrowsError(try roundTrip(corrupt))
        corrupt = .initial
        corrupt.manualRepairProgress[.rubble] = 3
        XCTAssertThrowsError(try roundTrip(corrupt))
        corrupt = .initial
        corrupt.pricing[.glowPotion] = 9
        XCTAssertThrowsError(try roundTrip(corrupt))
        var engine = try saleReadyEngine()
        corrupt = engine.state
        corrupt.currentDay = ShopDayState(dayNumber: 1, openingBalance: corrupt.balance)
        XCTAssertThrowsError(try roundTrip(corrupt))
        try engine.advanceLivingDay(expectedDayID: dayID, expectedMinute: 540, toMinute: 700)
        var current = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(engine.state)) as? [String: Any])
        var day = try XCTUnwrap(current["livingDay"] as? [String: Any])
        day["minute"] = 540
        current["livingDay"] = day
        XCTAssertThrowsError(try JSONDecoder().decode(GameState.self, from: JSONSerialization.data(withJSONObject: current)))
    }


    func testLivingDaysCompleteRestorationAndContinueWithRecoverableCapital() throws {
        var engine = try saleReadyEngine()
        let seed = try XCTUnwrap(engine.state.livingDay).seed
        for number in 1...3 {
            if number > 1 {
                let table = engine.state.fixtures[0]
                try engine.confirm(engine.makeStockDraft(product: .glowPotion, fixtureID: table.id, slotIndex: 0))
                try engine.openLivingDay(seed: seed)
            }
            try finish(&engine)
            XCTAssertEqual(engine.state.livingDay?.summary?.customersServed, 1)
            let id = engine.state.livingDay!.id
            try engine.acknowledgeLivingDaySummary(dayID: id)
        }
        for repair in RepairCatalog.all {
            let point = try XCTUnwrap(engine.state.world.hitMap.cells.first { $0.staticBlocker == repair.blocker }).point
            for _ in 0..<3 { try engine.cleanCell(at: point) }
        }
        try engine.expandShop(toward: .right)
        for (kind, point) in [(FixtureKind.pottedFern, GridPoint(x: 2, y: 6)),
                              (.starRug, GridPoint(x: 4, y: 6)), (.brassLantern, GridPoint(x: 7, y: 6))] {
            try engine.confirm(engine.makePlacementDraft(kind: kind, origin: point))
        }
        XCTAssertTrue(engine.state.hasCompletedRestoration)
        XCTAssertEqual(engine.state.balance, 65)
        XCTAssertEqual(engine.state.dayHistory.map(\.simulation), [.living, .living, .living])
        let table = engine.state.fixtures[0]
        try engine.confirm(engine.makeStockDraft(product: .glowPotion, fixtureID: table.id, slotIndex: 0))
        try engine.openLivingDay(seed: seed)
        try finish(&engine)
        XCTAssertTrue(engine.state.hasCompletedRestoration)
        XCTAssertEqual(try roundTrip(engine.state), engine.state)
    }

    func testImportedAcquisitionCostCannotOverflowDuringSecondLivingSale() throws {
        let ready = try saleReadyEngine()
        var state = ready.state
        let original = state.stock[0]
        state.stock = [StockItem(id: original.id, product: original.product, fixtureID: original.fixtureID,
                                slotIndex: 0, purchaseCost: Int.max)]
        var engine = GameEngine(state: state)
        let firstDecision = state.livingDay!.visitors.filter {
            $0.hasBuyingIntent && ($0.preferredProduct == .glowPotion || $0.secondaryProduct == .glowPotion) &&
            $0.interestRoll < ($0.preferredProduct == .glowPotion ? 95 : 80) && $0.budget >= 10
        }.map(\.decisionMinute).min()!
        try engine.advanceLivingDay(expectedDayID: dayID, expectedMinute: 540, toMinute: firstDecision)
        XCTAssertEqual(engine.state.livingDay?.costOfGoods, Int.max)
        try engine.confirm(engine.makeStockDraft(product: .glowPotion, fixtureID: original.fixtureID, slotIndex: 0))
        let before = engine.state
        XCTAssertThrowsError(try engine.advanceLivingDay(expectedDayID: dayID,
            expectedMinute: firstDecision, toMinute: 1080))
        XCTAssertEqual(engine.state, before)
    }
    func testLeftExpansionTranslatesDirtAndPaintWithoutLosingTheirIdentity() throws {
        var engine = GameEngine()
        try engine.paintFloor(at: GridPoint(x: 4, y: 4), style: .warmOak)
        var state = engine.state
        state.dirt[GridPoint(x: 4, y: 4)] = 2
        engine = GameEngine(state: state)
        for repair in RepairCatalog.all {
            let point = try XCTUnwrap(engine.state.world.hitMap.cells.first { $0.staticBlocker == repair.blocker }).point
            for _ in 0..<3 { try engine.cleanCell(at: point) }
        }
        try engine.expandShop(toward: .left)
        XCTAssertEqual(engine.state.dirt[GridPoint(x: 9, y: 4)], 2)
        XCTAssertNil(engine.state.dirt[GridPoint(x: 4, y: 4)])
        XCTAssertEqual(engine.state.world.floor.styleID(at: GridPoint(x: 9, y: 4)), .warmOak)
        let before = engine.state
        XCTAssertThrowsError(try engine.paintFloor(at: GridPoint(x: 0, y: 0), style: .terracotta))
        XCTAssertThrowsError(try engine.cleanCell(at: GridPoint(x: 0, y: 0)))
        XCTAssertEqual(engine.state, before)
    }
}

private final class LivingFailingStore: GameStateStore, @unchecked Sendable {
    enum Failure: Error { case disk }
    var failWrites = false
    private var state: GameState
    init(_ state: GameState) { self.state = state }
    func load() throws -> GameState { state }
    func save(_ state: GameState) throws {
        if failWrites { throw Failure.disk }
        self.state = state
    }
}
