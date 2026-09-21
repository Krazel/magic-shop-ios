import Foundation
import XCTest

#if SWIFT_PACKAGE
@testable import MagicShopCore
#else
@testable import MagicShop
#endif

final class RestorationTests: XCTestCase {
    func testClockAdvancesOnlyWithCommittedVisitorsAndRollsWeekdays() throws {
        var engine = freshShop()
        let table = try place(.basicDisplayTable, at: GridPoint(x: 4, y: 4), in: &engine)
        XCTAssertEqual(engine.state.calendar.dayNumber, 1)
        XCTAssertEqual(engine.state.calendar.weekdayName, "Monday")
        XCTAssertEqual(engine.state.calendar.timeText, "09:00")
        let unit = try engine.confirm(StockDraft(product: .glowPotion, fixtureID: table.id, slotIndex: 0))
        XCTAssertEqual(engine.state.calendar.timeText, "09:00")
        let day = try engine.openDay()
        XCTAssertEqual(day.visitors.map(\.scheduledMinute), [540, 630, 720, 810, 900, 990])
        for index in 0..<6 {
            try engine.advanceDay(expectedVisitID: day.visitors[index].id)
            engine = try reloaded(engine)
            XCTAssertEqual(engine.state.calendar.minutesSinceMidnight, 540 + (index + 1) * 90)
        }
        XCTAssertEqual(engine.state.calendar.timeText, "18:00")
        XCTAssertEqual(engine.state.calendar.dayNumber, 1)
        let saved = engine.state
        XCTAssertThrowsError(try engine.returnStock(stockID: unit.id))
        XCTAssertEqual(engine.state, saved)
        try engine.acknowledgeDaySummary(dayID: day.id)
        XCTAssertEqual(engine.state.calendar.timeText, "09:00")
        XCTAssertEqual(engine.state.calendar.weekdayName, "Tuesday")
        XCTAssertEqual(ShopCalendar(dayNumber: 7).weekdayName, "Sunday")
        XCTAssertEqual(ShopCalendar(dayNumber: 8).weekdayName, "Monday")
        XCTAssertEqual(ShopCalendar(dayNumber: 365).dayNumber, 365)
    }

    func testRepairPreviewDoesNotSpendAndThreeRealGroupsBecomeBuildable() throws {
        var engine = freshShop()
        let targets: [(RestorationGroupID, GridPoint)] = [
            (.rubble, GridPoint(x: 1, y: 5)),
            (.brokenBoards, GridPoint(x: 9, y: 5)),
            (.discardedPapers, GridPoint(x: 9, y: 2))
        ]
        for (group, point) in targets {
            let draft = PlacementDraft(kind: .basicDisplayTable, origin: point)
            XCTAssertThrowsError(try engine.validate(draft))
            let before = engine.state
            try engine.validateRepair(group)
            XCTAssertEqual(engine.state, before)
            let repaired = try engine.repair(group)
            XCTAssertEqual(engine.state.balance, before.balance - repaired.price)
            XCTAssertNil(engine.state.world.hitMap.cell(at: point)?.staticBlocker)
            XCTAssertNoThrow(try engine.validate(draft))
            let saved = engine.state
            XCTAssertThrowsError(try engine.repair(group))
            XCTAssertEqual(engine.state, saved)
        }
        XCTAssertEqual(engine.state.balance, 375)
        XCTAssertEqual(engine.state.restoration.repairedGroups.count, 3)
        XCTAssertEqual(engine.state.world.hitMap.cell(at: GridPoint(x: 0, y: 0))?.staticBlocker, .frontColumn)
        XCTAssertEqual(engine.state.world.hitMap.cell(at: GridPoint(x: 10, y: 0))?.staticBlocker, .frontColumn)
        XCTAssertEqual(try reloaded(engine).state, engine.state)
    }

    func testRepairFailureAndOpenPhaseLeaveEverythingUnchanged() throws {
        var poor = GameEngine(state: GameState(balance: 24))
        let before = poor.state
        XCTAssertThrowsError(try poor.repair(.discardedPapers))
        XCTAssertEqual(poor.state, before)
        var engine = freshShop()
        let table = try place(.basicDisplayTable, at: GridPoint(x: 4, y: 4), in: &engine)
        try engine.confirm(StockDraft(product: .glowPotion, fixtureID: table.id, slotIndex: 0))
        try engine.openDay()
        for phase in [ShopPhase.open, .summary] {
            if phase == .summary { try finishDay(in: &engine, acknowledge: false) }
            let saved = engine.state
            XCTAssertThrowsError(try engine.repair(.rubble))
            XCTAssertThrowsError(try engine.expandShop(toward: .right))
            XCTAssertEqual(engine.state, saved)
        }
    }

    func testSixDecorationsUsePlacementAndResaleWithoutStockOrWalkingThroughSolidObjects() throws {
        var engine = freshShop()
        XCTAssertEqual(FixtureCatalog.decor.count, 6)
        XCTAssertTrue(FixtureCategory.decor.isAvailable)
        XCTAssertFalse(FixtureCategory.walls.isAvailable)
        let positions = [
            GridPoint(x: 4, y: 6), GridPoint(x: 5, y: 6), GridPoint(x: 6, y: 6),
            GridPoint(x: 0, y: 6), GridPoint(x: 10, y: 6), GridPoint(x: 7, y: 6)
        ]
        var decorations: [PlacedFixture] = []
        for (definition, point) in zip(FixtureCatalog.decor, positions) {
            XCTAssertTrue(definition.kind.isDecoration)
            XCTAssertEqual(definition.stockCapacity, 0)
            let decor = try place(definition.kind, at: point, in: &engine)
            decorations.append(decor)
            let before = engine.state
            XCTAssertThrowsError(try engine.confirm(StockDraft(product: .glowPotion,
                                                               fixtureID: decor.id, slotIndex: 0)))
            XCTAssertEqual(engine.state, before)
        }
        let walkable = ShopAccess.reachableCells(in: engine.state)
        XCTAssertTrue(walkable.contains(decorations[1].origin)) // Rug.
        XCTAssertTrue(walkable.contains(decorations[3].origin)) // Wall clock.
        XCTAssertFalse(walkable.contains(decorations[0].origin)) // Plant.
        XCTAssertEqual(engine.state.restorationProgress.decorationVariety, 6)
        XCTAssertEqual(engine.state.balance, 130)
        for decor in decorations { try engine.sellEmptyFixture(fixtureID: decor.id) }
        XCTAssertEqual(engine.state.balance, 500)
        XCTAssertTrue(engine.state.fixtures.isEmpty)
    }

    func testWallDecorationCannotBePlacedInTheMiddleOrOverlapFurniture() throws {
        var engine = freshShop()
        let initial = engine.state
        XCTAssertThrowsError(try place(.wallClock, at: GridPoint(x: 4, y: 4), in: &engine))
        XCTAssertThrowsError(try place(.moonPainting, at: GridPoint(x: 5, y: 5), in: &engine))
        XCTAssertEqual(engine.state, initial)
        let rug = try place(.starRug, at: GridPoint(x: 4, y: 4), in: &engine)
        let saved = engine.state
        XCTAssertThrowsError(try place(.basicDisplayTable, at: rug.origin, in: &engine))
        XCTAssertEqual(engine.state, saved)
        try engine.moveFixture(fixtureID: rug.id, origin: GridPoint(x: 6, y: 6))
        XCTAssertEqual(engine.state.balance, saved.balance)
    }

    func testAllExpansionDirectionsPreserveWorldStockIdentityAndCreateOneRectangle() throws {
        for direction in ExpansionDirection.allCases {
            var engine = freshShop()
            let table = try place(.basicDisplayTable, at: GridPoint(x: 4, y: 4), in: &engine)
            let unit = try engine.confirm(StockDraft(product: .glowPotion, fixtureID: table.id, slotIndex: 0))
            var saved = engine.state
            let style = FloorStyleID(rawValue: "personalFloor")
            saved.world.floor.setStyleID(style, at: GridPoint(x: 7, y: 7))
            saved.dirt[GridPoint(x: 7, y: 7)] = 2
            engine = GameEngine(state: saved)
            for group in RestorationGroupID.allCases { try engine.repair(group) }
            let before = engine.state
            try engine.validateExpansion(toward: direction)
            XCTAssertEqual(engine.state, before)
            let expansion = try engine.expandShop(toward: direction)
            let shift = expansion.starterOrigin
            XCTAssertEqual(engine.layout, expansion.layout)
            XCTAssertEqual(engine.state.balance, before.balance - 250)
            XCTAssertEqual(engine.state.stock, [unit])
            XCTAssertEqual(engine.state.fixtures.first?.id, table.id)
            XCTAssertEqual(engine.state.fixtures.first?.origin, GridPoint(x: 4 + shift.x, y: 4))
            XCTAssertEqual(engine.state.world.floor.styleID(at: GridPoint(x: 7 + shift.x, y: 7)), style)
            XCTAssertEqual(engine.state.dirt, [GridPoint(x: 7 + shift.x, y: 7): 2])

            // The complete wall disappears. Every old wall cell and its
            // neighbor are interior; the two new front corners stay blocked.
            let outward: WallSide
            let inward: WallSide
            let offset: GridPoint
            switch direction {
            case .left:
                outward = .left; inward = .right; offset = GridPoint(x: -1, y: 0)
            case .right:
                outward = .right; inward = .left; offset = GridPoint(x: 1, y: 0)
            case .rear:
                outward = .rear; inward = .front; offset = GridPoint(x: 0, y: 1)
            }
            let reachable = ShopAccess.reachableCells(in: engine.state)
            XCTAssertEqual(expansion.starterConnectionCells.count, 11)
            for connection in expansion.starterConnectionCells {
                let inside = GridPoint(x: connection.x + shift.x, y: connection.y + shift.y)
                let annex = GridPoint(x: inside.x + offset.x, y: inside.y + offset.y)
                let outsideWall = GridPoint(x: annex.x + offset.x * 4, y: annex.y + offset.y * 4)
                let innerCell = try XCTUnwrap(engine.state.world.hitMap.cell(at: inside))
                let annexCell = try XCTUnwrap(engine.state.world.hitMap.cell(at: annex))
                let outerCell = try XCTUnwrap(engine.state.world.hitMap.cell(at: outsideWall))
                XCTAssertTrue(reachable.contains(inside))
                XCTAssertTrue(reachable.contains(annex))
                XCTAssertEqual(reachable.contains(outsideWall), outerCell.staticBlocker == nil)
                XCTAssertFalse(innerCell.adjacentWalls.contains(outward))
                XCTAssertFalse(annexCell.adjacentWalls.contains(inward))
                XCTAssertTrue(outerCell.adjacentWalls.contains(outward))
            }
            XCTAssertEqual(engine.state.world.hitMap.cells.filter { $0.zone != .outside }.count, 176)
            XCTAssertEqual(engine.state.world.hitMap.cells.filter { $0.zone == .outside }.count, 0)
            XCTAssertEqual(engine.state.world.hitMap.cell(at: GridPoint(x: 5 + shift.x, y: 0))?.zone, .entrance)
            let roomCenter = GridPoint(x: expansion.roomOrigin.x + 2, y: expansion.roomOrigin.y + 2)
            XCTAssertTrue(ShopAccess.reachableCells(in: engine.state).contains(roomCenter))
            let expanded = engine.state
            XCTAssertThrowsError(try engine.expandShop(toward: direction))
            XCTAssertEqual(engine.state, expanded)
            let second = try place(.basicDisplayTable, at: roomCenter, in: &engine)
            let path = try XCTUnwrap(ShopAccess.path(to: second, in: engine.state))
            XCTAssertEqual(path.first, GridPoint(x: 5 + shift.x, y: 0))
            XCTAssertTrue(path.allSatisfy { engine.state.world.hitMap.cell(at: $0)?.zone != .outside })
            try engine.confirm(StockDraft(product: .glowPotion, fixtureID: second.id, slotIndex: 0))
            try engine.openDay()
            try finishDay(in: &engine, acknowledge: false)
            XCTAssertEqual(engine.state.currentDay?.summary?.customersServed, 2)
            XCTAssertEqual(try reloaded(engine).state, engine.state)
        }
    }

    func testExpansionFillsOldVoidsAndOnlyPerimeterAllowsWallMounting() throws {
        var engine = freshShop()
        for group in RestorationGroupID.allCases { try engine.repair(group) }
        try engine.expandShop(toward: .right)
        let map = engine.state.world.hitMap
        XCTAssertEqual(map.hit(at: GridPoint(x: 12, y: 0), fixtures: []), .available)
        XCTAssertNoThrow(try engine.validate(PlacementDraft(kind: .basicDisplayTable, origin: GridPoint(x: 12, y: 0))))
        XCTAssertFalse(map.cell(at: GridPoint(x: 10, y: 5))!.adjacentWalls.contains(.right))
        XCTAssertFalse(map.cell(at: GridPoint(x: 11, y: 5))!.adjacentWalls.contains(.left))
        XCTAssertTrue(map.cell(at: GridPoint(x: 15, y: 5))!.adjacentWalls.contains(.right))
        XCTAssertThrowsError(try place(.wallClock, at: GridPoint(x: 10, y: 5), in: &engine)) {
            XCTAssertEqual($0 as? PlacementError, .shelfMustBeAdjacentToWall)
        }
        XCTAssertNoThrow(try place(.wallClock, at: GridPoint(x: 15, y: 5), in: &engine))
    }

    func testExpansionRequiresRepairsMoneyAndKeepsFloorFurnitureAtFormerWall() throws {
        var engine = freshShop()
        let initial = engine.state
        XCTAssertThrowsError(try engine.expandShop(toward: .right))
        XCTAssertEqual(engine.state, initial)
        let obstruction = try place(.basicDisplayTable, at: GridPoint(x: 10, y: 5), in: &engine)
        for group in RestorationGroupID.allCases { try engine.repair(group) }
        let before = engine.state
        XCTAssertNoThrow(try engine.validateExpansion(toward: .right))
        XCTAssertEqual(engine.state, before)
        var poorState = engine.state
        poorState.balance = 249
        var poor = GameEngine(state: poorState)
        XCTAssertThrowsError(try poor.expandShop(toward: .right))
        XCTAssertEqual(poor.state, poorState)
        XCTAssertNoThrow(try engine.expandShop(toward: .right))
        XCTAssertEqual(engine.state.fixtures.first(where: { $0.id == obstruction.id }), obstruction)
    }

    func testFullRestorationIsReachableFromFiveHundredAndRemainsSandboxAfterResale() throws {
        var engine = freshShop()
        let table = try place(.basicDisplayTable, at: GridPoint(x: 4, y: 4), in: &engine)
        let shelf = try place(.simpleShelf, at: GridPoint(x: 4, y: 10), in: &engine)
        for _ in 0..<3 {
            try stockThree(table: table, shelf: shelf, in: &engine)
            try engine.openDay()
            try finishDay(in: &engine)
            engine = try reloaded(engine)
        }
        XCTAssertEqual(engine.state.balance, 540)
        XCTAssertFalse(engine.state.hasCompletedRestoration)
        for group in RestorationGroupID.allCases { try engine.repair(group) }
        try engine.expandShop(toward: .right)
        let fern = try place(.pottedFern, at: GridPoint(x: 2, y: 6), in: &engine)
        try place(.starRug, at: GridPoint(x: 3, y: 6), in: &engine)
        XCTAssertFalse(engine.state.hasCompletedRestoration)
        try place(.brassLantern, at: GridPoint(x: 4, y: 6), in: &engine)
        XCTAssertEqual(engine.state.balance, 30)
        XCTAssertTrue(engine.state.hasCompletedRestoration)
        XCTAssertTrue(engine.state.restorationProgress.isComplete)
        let completion = try XCTUnwrap(engine.state.restoration.completion)
        engine = try reloaded(engine)
        XCTAssertEqual(engine.state.restoration.completion, completion)

        // The conclusion grants no repeatable cash and never disables play.
        try engine.sellEmptyFixture(fixtureID: fern.id)
        XCTAssertEqual(engine.state.balance, 65)
        XCTAssertFalse(engine.state.restorationProgress.isComplete)
        XCTAssertTrue(engine.state.hasCompletedRestoration)
        try stockThree(table: table, shelf: shelf, in: &engine)
        try engine.openDay()
        try finishDay(in: &engine)
        XCTAssertEqual(engine.state.balance, 145)
        XCTAssertEqual(engine.state.completedDays, 4)
        XCTAssertEqual(engine.state.restoration.completion, completion)
        XCTAssertEqual(try reloaded(engine).state, engine.state)
    }

    func testPermanentRepairsAndExpansionLeaveEnoughRecoverableCapitalToTrade() throws {
        var engine = freshShop()
        for group in RestorationGroupID.allCases { try engine.repair(group) }
        try engine.expandShop(toward: .rear)
        XCTAssertEqual(engine.state.balance, 125)
        let decor = try place(.wallClock, at: GridPoint(x: 0, y: 6), in: &engine)
        XCTAssertEqual(engine.state.balance, 25)
        try engine.sellEmptyFixture(fixtureID: decor.id)
        let table = try place(.basicDisplayTable, at: GridPoint(x: 4, y: 4), in: &engine)
        try engine.confirm(StockDraft(product: .glowPotion, fixtureID: table.id, slotIndex: 0))
        try engine.openDay()
        try finishDay(in: &engine)
        XCTAssertEqual(engine.state.balance, 90)
    }

    func testSchemaThreeMidDayMigrationPreservesJournalMoneyAndClock() throws {
        var engine = GameEngine(state: GameState(shopName: "Legacy Shop", onboardingCompleted: true,
                                                world: .legacyStarter))
        let table = try place(.basicDisplayTable, at: GridPoint(x: 4, y: 4), in: &engine)
        try engine.confirm(StockDraft(product: .glowPotion, fixtureID: table.id, slotIndex: 0))
        let day = try engine.openDay()
        try engine.advanceDay(expectedVisitID: day.visitors[0].id)
        var legacy = engine.state
        legacy.schemaVersion = 3
        let migrated = try JSONDecoder().decode(GameState.self, from: JSONEncoder().encode(legacy))
        XCTAssertEqual(migrated.schemaVersion, GameState.currentSchemaVersion)
        XCTAssertEqual(migrated.currentDay, engine.state.currentDay)
        XCTAssertEqual(migrated.balance, engine.state.balance)
        XCTAssertEqual(migrated.calendar.timeText, "10:30")
        XCTAssertEqual(migrated.world.hitMap.cell(at: GridPoint(x: 1, y: 5))?.staticBlocker, .rubble)
        XCTAssertNil(migrated.world.hitMap.cell(at: GridPoint(x: 1, y: 4))?.staticBlocker)
        var resumed = GameEngine(state: migrated)
        XCTAssertThrowsError(try resumed.advanceDay(expectedVisitID: day.visitors[0].id))
        XCTAssertEqual(resumed.state, migrated)
    }

    func testMigrationNeverMovesDebrisOntoAnExistingFixture() throws {
        let table = PlacedFixture(kind: .basicDisplayTable, origin: GridPoint(x: 1, y: 5))
        let legacy = GameState(schemaVersion: 3, fixtures: [table], world: .legacyStarter)
        let migrated = try JSONDecoder().decode(GameState.self, from: JSONEncoder().encode(legacy))
        XCTAssertEqual(migrated.fixtures, [table])
        XCTAssertNil(migrated.world.hitMap.cell(at: table.origin)?.staticBlocker)
        XCTAssertEqual(migrated.world.hitMap.cell(at: GridPoint(x: 1, y: 4))?.staticBlocker, .rubble)
        var engine = GameEngine(state: migrated)
        try engine.repair(.rubble)
        XCTAssertNil(engine.state.world.hitMap.cell(at: GridPoint(x: 1, y: 4))?.staticBlocker)
    }

    func testCurrentSchemaRejectsMissingRestorationFalseRepairsAndMalformedExpansionShape() throws {
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(GameState.initial))
                                    as? [String: Any])
        object.removeValue(forKey: "restoration")
        XCTAssertThrowsError(try JSONDecoder().decode(GameState.self,
                             from: JSONSerialization.data(withJSONObject: object)))
        object["restoration"] = NSNull()
        XCTAssertThrowsError(try JSONDecoder().decode(GameState.self,
                             from: JSONSerialization.data(withJSONObject: object)))
        var inconsistent = GameState.initial
        inconsistent.restoration.repairedGroups.insert(.rubble)
        XCTAssertThrowsError(try inconsistent.validateIntegrity())
        var engine = freshShop()
        for group in RestorationGroupID.allCases { try engine.repair(group) }
        try engine.expandShop(toward: .left)
        var invalid = engine.state
        invalid.world.hitMap.updateCell(at: GridPoint(x: 0, y: 1)) { $0.zone = .outside }
        XCTAssertThrowsError(try invalid.validateIntegrity())
    }

    func testFloorSpendingCannotLeaveExpansionWithoutRecoverableTradingCapital() throws {
        var engine = freshShop()
        let cells = engine.state.world.hitMap.cells.filter {
            $0.zone != .outside && $0.staticBlocker == nil
        }.prefix(80)
        XCTAssertEqual(cells.count, 80)
        for cell in cells { try engine.paintFloor(at: cell.point, style: .checkerStone) }
        XCTAssertEqual(engine.state.balance, 260)
        try manuallyRepairAll(in: &engine)
        engine = try reloaded(engine)
        let before = engine.state
        for direction in ExpansionDirection.allCases {
            XCTAssertThrowsError(try engine.validateExpansion(toward: direction)) {
                XCTAssertEqual($0 as? LivingShopError, .workingCapitalRequired)
            }
            XCTAssertThrowsError(try engine.expandShop(toward: direction)) {
                XCTAssertEqual($0 as? LivingShopError, .workingCapitalRequired)
            }
            XCTAssertEqual(engine.state, before)
        }
        // The rejected expansion leaves enough actual money to trade.
        let table = try place(.basicDisplayTable, at: GridPoint(x: 4, y: 4), in: &engine)
        try engine.confirm(StockDraft(product: .glowPotion, fixtureID: table.id, slotIndex: 0))
        XCTAssertNoThrow(try engine.openLivingDay())
    }

    func testPaidRepairsPreserveTheSameCapitalBoundaryAndManualRepairRemainsFree() throws {
        for repair in RepairCatalog.all {
            var poor = GameEngine(state: GameState(balance: repair.price - 1))
            let poorBefore = poor.state
            XCTAssertThrowsError(try poor.repair(repair.id)) {
                XCTAssertEqual($0 as? CommerceError,
                    .insufficientFunds(required: repair.price, available: repair.price - 1))
            }
            XCTAssertEqual(poor.state, poorBefore)

            var borderline = GameEngine(state: GameState(balance: repair.price + 59))
            let before = borderline.state
            XCTAssertThrowsError(try borderline.validateRepair(repair.id)) {
                XCTAssertEqual($0 as? LivingShopError, .workingCapitalRequired)
            }
            XCTAssertThrowsError(try borderline.repair(repair.id))
            XCTAssertEqual(borderline.state, before)
            let point = try XCTUnwrap(before.world.hitMap.cells.first {
                $0.staticBlocker == repair.blocker
            }).point
            for _ in 0..<ShopCare.repairStrokesRequired { try borderline.cleanCell(at: point) }
            XCTAssertEqual(borderline.state.balance, before.balance)
            XCTAssertTrue(borderline.state.restoration.repairedGroups.contains(repair.id))

            var exact = GameEngine(state: GameState(balance: repair.price + 60))
            try exact.repair(repair.id)
            XCTAssertEqual(exact.state.balance, ShopCare.minimumRecoverableCapital)
        }
    }

    func testExpansionAcceptsExactlySixtyCashOrRefundableAssetsWithoutRequiringExtraCash() throws {
        var cleared = freshShop()
        try manuallyRepairAll(in: &cleared)
        for balance in [309, 310] {
            var state = cleared.state
            state.balance = balance
            var engine = GameEngine(state: state)
            if balance == 309 {
                XCTAssertThrowsError(try engine.expandShop(toward: .right))
                XCTAssertEqual(engine.state, state)
            } else {
                try engine.expandShop(toward: .right)
                XCTAssertEqual(engine.state.balance, 60)
            }
        }

        let table = try place(.basicDisplayTable, at: GridPoint(x: 4, y: 4), in: &cleared)
        let unit = try cleared.confirm(StockDraft(product: .glowPotion, fixtureID: table.id, slotIndex: 0))
        var state = cleared.state
        state.balance = ExpansionState.price
        var engine = GameEngine(state: state)
        try engine.expandShop(toward: .right)
        XCTAssertEqual(engine.state.balance, 0)
        XCTAssertNoThrow(try engine.state.validateIntegrity())
        try engine.returnStock(stockID: unit.id)
        try engine.sellEmptyFixture(fixtureID: table.id)
        XCTAssertEqual(engine.state.balance, 60)
        let replacement = try place(.basicDisplayTable, at: table.origin, in: &engine)
        try engine.confirm(StockDraft(product: .glowPotion, fixtureID: replacement.id, slotIndex: 0))
        XCTAssertNoThrow(try engine.openLivingDay())
    }

    func testPermanentSpendingCapsImportedRefundValuesBeforeAddingThem() throws {
        var engine = freshShop()
        try manuallyRepairAll(in: &engine)
        let table = try place(.basicDisplayTable, at: GridPoint(x: 4, y: 4), in: &engine)
        var state = engine.state
        state.balance = ExpansionState.price + 3
        state.stock = [StockItem(product: .glowPotion, fixtureID: table.id,
                                 slotIndex: 0, purchaseCost: Int.max)]
        engine = GameEngine(state: state)
        try engine.paintFloor(at: GridPoint(x: 6, y: 6), style: .checkerStone)
        try engine.expandShop(toward: .right)
        XCTAssertEqual(engine.state.balance, 0)
        XCTAssertEqual(engine.state.stock.first?.purchaseCost, Int.max)
        XCTAssertEqual(try reloaded(engine).state, engine.state)

        var wealthy = GameEngine(state: GameState(balance: Int.max))
        try wealthy.repair(.rubble)
        XCTAssertEqual(wealthy.state.balance, Int.max - RepairCatalog.definition(for: .rubble).price)
    }

    private func manuallyRepairAll(in engine: inout GameEngine) throws {
        for repair in RepairCatalog.all {
            let point = try XCTUnwrap(engine.state.world.hitMap.cells.first {
                $0.staticBlocker == repair.blocker
            }).point
            for _ in 0..<ShopCare.repairStrokesRequired { try engine.cleanCell(at: point) }
        }
    }
    private func freshShop() -> GameEngine {
        GameEngine(state: GameState(shopName: "Moon & Mortar", onboardingCompleted: true))
    }

    @discardableResult
    private func place(_ kind: FixtureKind, at point: GridPoint, in engine: inout GameEngine,
                       rotation: FixtureRotation = .north) throws -> PlacedFixture {
        try engine.confirm(PlacementDraft(kind: kind, origin: point, rotation: rotation))
    }

    private func stockThree(table: PlacedFixture, shelf: PlacedFixture, in engine: inout GameEngine) throws {
        try engine.confirm(StockDraft(product: .luckyCharm, fixtureID: table.id, slotIndex: 0))
        try engine.confirm(StockDraft(product: .glowPotion, fixtureID: shelf.id, slotIndex: 0))
        try engine.confirm(StockDraft(product: .pocketSpellbook, fixtureID: shelf.id, slotIndex: 1))
    }

    private func finishDay(in engine: inout GameEngine, acknowledge: Bool = true) throws {
        while let next = engine.state.currentDay?.nextVisit {
            try engine.advanceDay(expectedVisitID: next.id)
        }
        if acknowledge, let day = engine.state.currentDay {
            try engine.acknowledgeDaySummary(dayID: day.id)
        }
    }

    private func reloaded(_ engine: GameEngine) throws -> GameEngine {
        GameEngine(state: try JSONDecoder().decode(GameState.self, from: JSONEncoder().encode(engine.state)))
    }
}


extension RestorationTests {
    func testWholeWallExpansionRelocatesAttachedFurnitureWithoutChargingOrLosingStock() throws {
        for direction in ExpansionDirection.allCases {
            var engine = GameEngine(state: GameState(shopName: "Wall Keepers", onboardingCompleted: true, balance: 1500))
            try manuallyRepairAll(in: &engine)
            let side = direction != .rear
            let wallX = direction == .left ? 0 : 10
            let shelf = try place(.simpleShelf, at: side ? GridPoint(x: wallX, y: 4) : GridPoint(x: 3, y: 10),
                                  in: &engine, rotation: side ? .east : .north)
            let clock = try place(.wallClock, at: side ? GridPoint(x: wallX, y: 7) : GridPoint(x: 7, y: 10), in: &engine)
            let painting = try place(.moonPainting, at: side ? GridPoint(x: wallX, y: 9) : GridPoint(x: 9, y: 10), in: &engine)
            let table = try place(.basicDisplayTable, at: GridPoint(x: 4, y: 4), in: &engine)
            try engine.confirm(StockDraft(product: .pocketSpellbook, fixtureID: shelf.id, slotIndex: 1))
            let before = engine.state
            try engine.validateExpansion(toward: direction)
            XCTAssertEqual(engine.state, before)
            let expansion = try engine.expandShop(toward: direction)
            XCTAssertEqual(engine.state.balance, before.balance - 250)
            XCTAssertEqual(engine.state.stock, before.stock)
            XCTAssertEqual(engine.state.fixtures.map(\.id), before.fixtures.map(\.id))
            for attached in [shelf, clock, painting] {
                let current = try XCTUnwrap(engine.state.fixtures.first { $0.id == attached.id })
                let expected = side ? GridPoint(x: direction == .left ? 0 : 15, y: attached.origin.y)
                    : GridPoint(x: attached.origin.x, y: 15)
                XCTAssertEqual(current.origin, expected)
                XCTAssertEqual(current.rotation, attached.rotation)
            }
            XCTAssertEqual(engine.state.fixtures.first { $0.id == table.id }?.origin,
                           GridPoint(x: table.origin.x + expansion.starterOrigin.x, y: table.origin.y))
            XCTAssertTrue(ShopAccess.isReachable(engine.state.fixtures[0], in: engine.state))
            XCTAssertEqual(try reloaded(engine).state, engine.state)
        }
    }

    func testSchemaFourAndFiveAnnexesBecomeRectanglesWithoutLosingSavedProgress() throws {
        for direction in ExpansionDirection.allCases {
            for version in [4, 5] {
                var original = try legacyAnnex(direction)
                if version == 4 { original.dirt = [:] }
                for number in 1...3 {
                    var day = ShopDayState(id: fixedID(300 + number), dayNumber: number, openingBalance: 0)
                    for visit in day.visitors {
                        let sale = visit.id.index == 0 ? SaleReceipt(stockID: fixedID(400 + number),
                            product: visit.requestedProduct, fixtureID: original.fixtures[0].id,
                            slotIndex: 0, revenue: 25, costOfGoods: 10) : nil
                        day.record(VisitOutcome(visitID: visit.id, requestedProduct: visit.requestedProduct, sale: sale))
                    }
                    original.dayHistory.append(try XCTUnwrap(day.summary))
                }
                original.restoration.completion = RestorationCompletion(completedOnDay: 3)
                try original.validateIntegrity(legacyExpansion: true)
                let result = try migratedAnnex(original, version: version)
                XCTAssertEqual(result.schemaVersion, GameState.currentSchemaVersion)
                XCTAssertEqual(result.balance, original.balance)
                XCTAssertEqual(result.stock, original.stock)
                XCTAssertEqual(result.fixtures.map(\.id), original.fixtures.map(\.id))
                XCTAssertEqual(result.fixtures.map(\.rotation), original.fixtures.map(\.rotation))
                XCTAssertEqual(result.world.floor, original.world.floor)
                XCTAssertEqual(result.dirt, original.dirt)
                XCTAssertEqual(result.dayHistory, original.dayHistory)
                XCTAssertEqual(result.restoration, original.restoration)
                XCTAssertEqual(result.pricing, original.pricing)
                XCTAssertEqual(result.world.hitMap.cells.filter { $0.zone != .outside }.count, 176)
                XCTAssertEqual(result.world.hitMap.cells.filter { $0.staticBlocker == .frontColumn }.map(\.point),
                               [GridPoint(x: 0, y: 0), GridPoint(x: result.world.hitMap.layout.width - 1, y: 0)])
                for old in original.fixtures where FixtureCatalog.definition(for: old.kind).placementConstraint == .anywhereOnFloor {
                    XCTAssertEqual(result.fixtures.first { $0.id == old.id }, old)
                }
                XCTAssertEqual(try migratedAnnex(original, version: version), result)
                XCTAssertEqual(try JSONDecoder().decode(GameState.self, from: JSONEncoder().encode(result)), result)
            }
        }
    }

    func testCrowdedLegacyPerimeterMigratesDeterministicallyWithoutOverlap() throws {
        for direction in ExpansionDirection.allCases {
            var original = try legacyAnnex(direction)
            var occupied = Set(original.fixtures.flatMap { PlacementRules.occupiedCells(for: $0) })
            var number = 100
            for cell in original.world.hitMap.cells where cell.zone == .interior && cell.staticBlocker == nil && !cell.adjacentWalls.isEmpty {
                guard !occupied.contains(cell.point) else { continue }
                original.fixtures.append(PlacedFixture(id: fixedID(number), kind: .wallClock, origin: cell.point))
                number += 1
                occupied.insert(cell.point)
            }
            try original.validateIntegrity(legacyExpansion: true)
            let result = try migratedAnnex(original)
            XCTAssertEqual(result.fixtures.count, original.fixtures.count)
            XCTAssertEqual(result.stock, original.stock)
            XCTAssertEqual(result.balance, original.balance)
            XCTAssertEqual(result.fixtures.map(\.id), original.fixtures.map(\.id))
            let allCells = result.fixtures.flatMap { PlacementRules.occupiedCells(for: $0) }
            XCTAssertEqual(Set(allCells).count, allCells.count)
            for fixture in result.fixtures where FixtureCatalog.definition(for: fixture.kind).placementConstraint == .adjacentToWall {
                XCTAssertFalse(result.world.hitMap.commonWallAdjacency(for: PlacementRules.occupiedCells(for: fixture)).isEmpty)
            }
            XCTAssertEqual(try migratedAnnex(original), result)
        }
    }

    func testMigratedLivingDayKeepsProfilesReceiptsCursorAndResumesExactlyOnce() throws {
        for direction in ExpansionDirection.allCases {
            let original = try legacyLivingAnnex(direction)
            let result = try migratedAnnex(original)
            let before = try XCTUnwrap(original.livingDay), after = try XCTUnwrap(result.livingDay)
            XCTAssertEqual(after.id, before.id)
            XCTAssertEqual(after.seed, before.seed)
            XCTAssertEqual(after.dayNumber, before.dayNumber)
            XCTAssertEqual(after.minute, before.minute)
            XCTAssertEqual(after.openingBalance, before.openingBalance)
            XCTAssertEqual(after.inventoryCashFlow, before.inventoryCashFlow)
            XCTAssertEqual(after.outcomes, before.outcomes)
            XCTAssertEqual(after.sales, before.sales)
            XCTAssertFalse(after.sales.isEmpty)
            XCTAssertEqual(result.balance, original.balance)
            XCTAssertEqual(result.stock, original.stock)
            XCTAssertEqual(result.dirt, original.dirt)
            for (old, new) in zip(before.visitors, after.visitors) {
                XCTAssertEqual(new.id, old.id)
                XCTAssertEqual(new.arrivalMinute, old.arrivalMinute)
                XCTAssertEqual(new.departureMinute, old.departureMinute)
                XCTAssertEqual(new.decisionMinute, old.decisionMinute)
                XCTAssertEqual(new.preferredProduct, old.preferredProduct)
                XCTAssertEqual(new.secondaryProduct, old.secondaryProduct)
                XCTAssertEqual(new.budget, old.budget)
                XCTAssertEqual(new.interestRoll, old.interestRoll)
                XCTAssertEqual(new.hasBuyingIntent, old.hasBuyingIntent)
                XCTAssertEqual(new.stops.map(\.fixtureID), old.stops.map(\.fixtureID))
                XCTAssertEqual(new.stops.map(\.arrivalMinute), old.stops.map(\.arrivalMinute))
                XCTAssertEqual(new.stops.map(\.departureMinute), old.stops.map(\.departureMinute))
            }
            XCTAssertNotEqual(after.visitors.map { $0.stops.map(\.path) }, before.visitors.map { $0.stops.map(\.path) })
            XCTAssertNoThrow(try result.validateIntegrity()) // Also checks every route and display endpoint.
            var uninterrupted = GameEngine(state: result)
            try uninterrupted.advanceLivingDay(expectedDayID: after.id, expectedMinute: after.minute, toMinute: 1080)
            var resumed = try reloaded(GameEngine(state: result))
            let cursor = after.minute + 1
            try resumed.advanceLivingDay(expectedDayID: after.id, expectedMinute: after.minute, toMinute: cursor)
            resumed = try reloaded(resumed)
            let saved = resumed.state
            XCTAssertThrowsError(try resumed.advanceLivingDay(expectedDayID: after.id, expectedMinute: after.minute, toMinute: cursor))
            XCTAssertEqual(resumed.state, saved)
            try resumed.advanceLivingDay(expectedDayID: after.id, expectedMinute: cursor, toMinute: 1080)
            XCTAssertEqual(resumed.state, uninterrupted.state)
            XCTAssertEqual(Array(try XCTUnwrap(resumed.state.livingDay).outcomes.prefix(before.outcomes.count)), before.outcomes)
            try resumed.acknowledgeLivingDaySummary(dayID: after.id)
            let acknowledged = resumed.state
            XCTAssertThrowsError(try resumed.acknowledgeLivingDaySummary(dayID: after.id))
            XCTAssertEqual(resumed.state, acknowledged)
            XCTAssertEqual(try reloaded(resumed).state, acknowledged)
        }
    }

    func testSchemaFourAnnexKeepsLegacyMiddayJournalAndResumesWithoutReplay() throws {
        var original = try legacyAnnex(.left)
        original.dirt = [:]
        var day = ShopDayState(id: fixedID(500), dayNumber: 1, openingBalance: original.balance)
        let visit = day.visitors[0]
        let unit = try XCTUnwrap(original.stock.first { $0.product == visit.requestedProduct })
        let sale = SaleReceipt(stockID: unit.id, product: unit.product, fixtureID: unit.fixtureID,
                               slotIndex: unit.slotIndex, revenue: 25, costOfGoods: unit.purchaseCost)
        day.record(VisitOutcome(visitID: visit.id, requestedProduct: visit.requestedProduct, sale: sale))
        original.stock.removeAll { $0.id == unit.id }
        original.balance += sale.revenue
        original.phase = .open
        original.currentDay = day
        let result = try migratedAnnex(original, version: 4)
        XCTAssertEqual(result.currentDay, original.currentDay)
        XCTAssertEqual(result.balance, original.balance)
        var engine = GameEngine(state: result)
        XCTAssertThrowsError(try engine.advanceDay(expectedVisitID: visit.id))
        XCTAssertEqual(engine.state, result)
        try finishDay(in: &engine)
        XCTAssertEqual(engine.state.dayHistory.first?.outcomes.first, day.outcomes.first)
        XCTAssertEqual(engine.state.balance, day.openingBalance + engine.state.dayHistory[0].revenue)
        XCTAssertEqual(try reloaded(engine).state, engine.state)
    }

    func testMigrationRejectsCorruptSourceTopologyOccupancyAndRoutesBeforeRewriting() throws {
        for direction in ExpansionDirection.allCases {
            let valid = try legacyAnnex(direction)
            var bad = valid
            let outside = try XCTUnwrap(bad.world.hitMap.cells.first { $0.zone == .outside }).point
            bad.world.hitMap.updateCell(at: outside) { $0.zone = .interior }
            XCTAssertThrowsError(try migratedAnnex(bad))
            bad = valid
            bad.world.hitMap.updateCell(at: valid.fixtures[0].origin) { $0.adjacentWalls = [] }
            XCTAssertThrowsError(try migratedAnnex(bad))
            bad = valid
            bad.fixtures.append(PlacedFixture(id: fixedID(999), kind: .basicDisplayTable, origin: valid.fixtures[0].origin))
            XCTAssertThrowsError(try migratedAnnex(bad))
            var object = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(try legacyLivingAnnex(direction))) as? [String: Any])
            object["schemaVersion"] = 5
            var living = try XCTUnwrap(object["livingDay"] as? [String: Any])
            var visitors = try XCTUnwrap(living["visitors"] as? [[String: Any]])
            var stops = try XCTUnwrap(visitors[0]["stops"] as? [[String: Any]])
            stops[0]["path"] = [["x": 1000, "y": 1000]]
            visitors[0]["stops"] = stops
            living["visitors"] = visitors
            object["livingDay"] = living
            XCTAssertThrowsError(try JSONDecoder().decode(GameState.self, from: JSONSerialization.data(withJSONObject: object)))
        }
    }

    func testMigrationKeepsExactLivingPathsWhenOnlyNonblockingDecorMoves() throws {
        for direction in ExpansionDirection.allCases {
            var original = try legacyAnnex(direction)
            original.fixtures.removeAll { $0.kind == .simpleShelf }
            let table = try XCTUnwrap(original.fixtures.first { $0.kind == .basicDisplayTable })
            original.stock = [StockItem(id: fixedID(700), product: .glowPotion, fixtureID: table.id, slotIndex: 0)]
            original.livingDay = try LivingShopDay(id: fixedID(701), dayNumber: 1, seed: 42, state: original)
            original.phase = .open
            try original.validateIntegrity(legacyExpansion: true)
            let result = try migratedAnnex(original)
            XCTAssertEqual(result.livingDay, original.livingDay)
            XCTAssertEqual(result.balance, original.balance)
            XCTAssertEqual(result.stock, original.stock)
            XCTAssertNotEqual(result.fixtures.first { $0.kind == .wallClock }?.origin,
                              original.fixtures.first { $0.kind == .wallClock }?.origin)
        }
    }

    func testFileMigrationPreservesSourceUntilValidatedTransactionAndLeavesCorruptionUntouched() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("MagicShopRectangle-" + UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = FileGameStateStore(fileURL: directory.appendingPathComponent("state.json"))
        var legacy = try legacyAnnex(.left)
        legacy.schemaVersion = 5
        try store.save(legacy)
        let originalData = try Data(contentsOf: store.fileURL)
        let session = try GameSession(store: store)
        XCTAssertEqual(session.engine.state.schemaVersion, GameState.currentSchemaVersion)
        XCTAssertEqual(try Data(contentsOf: store.fileURL), originalData)
        try session.commit { try $0.setPrice(24, for: .glowPotion) }
        XCTAssertEqual(try store.load(), session.engine.state)
        XCTAssertEqual(session.engine.state.balance, legacy.balance)
        XCTAssertEqual(session.engine.state.stock, legacy.stock)

        legacy.world.hitMap.updateCell(at: GridPoint(x: 0, y: 1)) { $0.zone = .interior }
        try store.save(legacy)
        let corruptData = try Data(contentsOf: store.fileURL)
        XCTAssertThrowsError(try GameSession(store: store))
        XCTAssertEqual(try Data(contentsOf: store.fileURL), corruptData)
    }

    /// Independent old geometry: do not call the production expansion builder.
    private func legacyAnnex(_ direction: ExpansionDirection) throws -> GameState {
        let expansion = ExpansionState(direction: direction)
        let shift = direction == .left ? 5 : 0
        let room: GridPoint
        switch direction {
        case .left: room = GridPoint(x: 0, y: 3)
        case .right: room = GridPoint(x: 11, y: 3)
        case .rear: room = GridPoint(x: 3, y: 11)
        }
        let layout = expansion.layout
        var inside = Set<GridPoint>()
        for y in 0..<layout.depth { for x in 0..<layout.width {
            if (x >= shift && x < shift + 11 && y < 11) ||
                (x >= room.x && x < room.x + 5 && y >= room.y && y < room.y + 5) {
                inside.insert(GridPoint(x: x, y: y))
            }
        } }
        var cells: [WorldCellMetadata] = []
        for y in 0..<layout.depth { for x in 0..<layout.width {
            let point = GridPoint(x: x, y: y)
            guard inside.contains(point) else {
                cells.append(WorldCellMetadata(point: point, zone: .outside)); continue
            }
            var walls = Set<WallSide>()
            for (side, dx, dy) in [(WallSide.left, -1, 0), (.right, 1, 0), (.front, 0, -1), (.rear, 0, 1)] {
                if !inside.contains(GridPoint(x: x + dx, y: y + dy)) { walls.insert(side) }
            }
            cells.append(WorldCellMetadata(point: point,
                zone: point == GridPoint(x: 5 + shift, y: 0) ? .entrance : .interior,
                staticBlocker: y == 0 && (x == shift || x == shift + 10) ? .frontColumn : nil,
                adjacentWalls: walls))
        } }
        let side = direction != .rear
        let mainX = direction == .left ? 5 : 10
        let fixtures = [
            PlacedFixture(id: fixedID(1), kind: .simpleShelf,
                origin: side ? GridPoint(x: mainX, y: 1) : GridPoint(x: 0, y: 10), rotation: side ? .east : .north),
            PlacedFixture(id: fixedID(2), kind: .simpleShelf,
                origin: side ? GridPoint(x: room.x + 1, y: 3) : GridPoint(x: 3, y: 12), rotation: side ? .north : .east),
            PlacedFixture(id: fixedID(3), kind: .basicDisplayTable, origin: GridPoint(x: 4 + shift, y: 4)),
            PlacedFixture(id: fixedID(4), kind: .wallClock,
                origin: side ? GridPoint(x: mainX, y: 9) : GridPoint(x: 9, y: 10)),
            PlacedFixture(id: fixedID(5), kind: .moonPainting,
                origin: side ? GridPoint(x: room.x + 3, y: 7) : GridPoint(x: 7, y: 13)),
            PlacedFixture(id: fixedID(6), kind: .pottedFern, origin: GridPoint(x: room.x + 2, y: room.y + 2))
        ]
        var world = ShopWorldState(floor: ShopFloorState(layout: layout), hitMap: WorldHitMap(layout: layout, cells: cells))
        world.floor.setStyleID(.warmOak, at: fixtures[2].origin)
        world.floor.setStyleID(.checkerStone, at: GridPoint(x: room.x + 1, y: room.y + 1))
        let stock = [
            StockItem(id: fixedID(11), product: .glowPotion, fixtureID: fixtures[0].id, slotIndex: 0),
            StockItem(id: fixedID(12), product: .pocketSpellbook, fixtureID: fixtures[0].id, slotIndex: 1),
            StockItem(id: fixedID(13), product: .glowPotion, fixtureID: fixtures[1].id, slotIndex: 0),
            StockItem(id: fixedID(14), product: .pocketSpellbook, fixtureID: fixtures[1].id, slotIndex: 1),
            StockItem(id: fixedID(15), product: .luckyCharm, fixtureID: fixtures[2].id, slotIndex: 0)
        ]
        let state = GameState(shopName: "Saved Annex", onboardingCompleted: true, balance: 287,
            fixtures: fixtures, world: world, stock: stock,
            restoration: ShopRestorationState(repairedGroups: Set(RestorationGroupID.allCases), expansion: expansion),
            dirt: [GridPoint(x: room.x + 1, y: room.y + 1): 2])
        try state.validateIntegrity(legacyExpansion: true)
        return state
    }

    private func legacyLivingAnnex(_ direction: ExpansionDirection) throws -> GameState {
        var state = try legacyAnnex(direction)
        var day = try LivingShopDay(id: fixedID(600), dayNumber: 1, seed: 42, state: state)
        let buyer = try XCTUnwrap(day.visitors.first { visitor in
            visitor.hasBuyingIntent && state.stock.contains { unit in
                visitor.stops.contains { $0.fixtureID == unit.fixtureID } &&
                (unit.product == visitor.preferredProduct || unit.product == visitor.secondaryProduct) &&
                ProductCatalog.definition(for: unit.product).salePrice <= visitor.budget
            }
        })
        let unit = try XCTUnwrap(state.stock.first { unit in
            buyer.stops.contains { $0.fixtureID == unit.fixtureID } &&
            (unit.product == buyer.preferredProduct || unit.product == buyer.secondaryProduct) &&
            ProductCatalog.definition(for: unit.product).salePrice <= buyer.budget
        })
        let cursor = buyer.decisionMinute + 1
        for visitor in day.visitors where visitor.decisionMinute <= cursor {
            let sale = visitor.id == buyer.id ? SaleReceipt(stockID: unit.id, product: unit.product,
                fixtureID: unit.fixtureID, slotIndex: unit.slotIndex,
                revenue: ProductCatalog.definition(for: unit.product).salePrice, costOfGoods: unit.purchaseCost) : nil
            day.record(VisitOutcome(visitID: visitor.id, requestedProduct: visitor.preferredProduct, sale: sale),
                       visitorIndex: visitor.id.index)
        }
        state.stock.removeAll { $0.id == unit.id }
        state.balance += ProductCatalog.definition(for: unit.product).salePrice
        day.setMinute(cursor)
        state.livingDay = day
        state.phase = .open
        try state.validateIntegrity(legacyExpansion: true)
        return state
    }

    private func migratedAnnex(_ state: GameState, version: Int = 5) throws -> GameState {
        var saved = state
        saved.schemaVersion = version
        return try JSONDecoder().decode(GameState.self, from: JSONEncoder().encode(saved))
    }

    private func fixedID(_ value: Int) -> UUID {
        UUID(uuidString: String(format: "20000000-0000-0000-0000-%012d", value))!
    }
}
