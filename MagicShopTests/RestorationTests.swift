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

    func testAllExpansionDirectionsPreserveWorldStockIdentityAndCreateReachableCompactRoom() throws {
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

            // The painted architecture must leave all five saved connections
            // open. A narrow visual doorway would contradict these routes.
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
            XCTAssertEqual(expansion.starterConnectionCells.count, 5)
            for connection in expansion.starterConnectionCells {
                let inside = GridPoint(x: connection.x + shift.x, y: connection.y + shift.y)
                let annex = GridPoint(x: inside.x + offset.x, y: inside.y + offset.y)
                let outsideWall = GridPoint(x: annex.x + offset.x * 4, y: annex.y + offset.y * 4)
                let innerCell = try XCTUnwrap(engine.state.world.hitMap.cell(at: inside))
                let annexCell = try XCTUnwrap(engine.state.world.hitMap.cell(at: annex))
                let outerCell = try XCTUnwrap(engine.state.world.hitMap.cell(at: outsideWall))
                XCTAssertTrue(reachable.contains(inside))
                XCTAssertTrue(reachable.contains(annex))
                XCTAssertTrue(reachable.contains(outsideWall))
                XCTAssertFalse(innerCell.adjacentWalls.contains(outward))
                XCTAssertFalse(annexCell.adjacentWalls.contains(inward))
                XCTAssertTrue(outerCell.adjacentWalls.contains(outward))
            }
            XCTAssertEqual(engine.state.world.hitMap.cells.filter { $0.zone != .outside }.count, 146)
            XCTAssertEqual(engine.state.world.hitMap.cells.filter { $0.zone == .outside }.count, 30)
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

    func testExpansionVoidRejectsPlacementAndSharedWallBecomesOpenPassage() throws {
        var engine = freshShop()
        for group in RestorationGroupID.allCases { try engine.repair(group) }
        try engine.expandShop(toward: .right)
        let map = engine.state.world.hitMap
        XCTAssertEqual(map.hit(at: GridPoint(x: 12, y: 0), fixtures: []), .outside)
        let saved = engine.state
        XCTAssertThrowsError(try place(.basicDisplayTable, at: GridPoint(x: 12, y: 0), in: &engine))
        XCTAssertEqual(engine.state, saved)
        XCTAssertFalse(map.cell(at: GridPoint(x: 10, y: 5))!.adjacentWalls.contains(.right))
        XCTAssertFalse(map.cell(at: GridPoint(x: 11, y: 5))!.adjacentWalls.contains(.left))
        XCTAssertTrue(map.cell(at: GridPoint(x: 15, y: 5))!.adjacentWalls.contains(.right))
        XCTAssertThrowsError(try place(.wallClock, at: GridPoint(x: 10, y: 5), in: &engine)) {
            XCTAssertEqual($0 as? PlacementError, .shelfMustBeAdjacentToWall)
        }
        XCTAssertNoThrow(try place(.wallClock, at: GridPoint(x: 15, y: 5), in: &engine))
    }

    func testExpansionRequiresRepairsMoneyAndClearReachableConnection() throws {
        var engine = freshShop()
        let initial = engine.state
        XCTAssertThrowsError(try engine.expandShop(toward: .right))
        XCTAssertEqual(engine.state, initial)
        let obstruction = try place(.basicDisplayTable, at: GridPoint(x: 10, y: 5), in: &engine)
        for group in RestorationGroupID.allCases { try engine.repair(group) }
        let blocked = engine.state
        XCTAssertThrowsError(try engine.expandShop(toward: .right)) { error in
            XCTAssertEqual(error as? RestorationError, .expansionConnectionBlocked)
        }
        XCTAssertEqual(engine.state, blocked)
        try engine.moveFixture(fixtureID: obstruction.id, origin: GridPoint(x: 6, y: 6))
        var poorState = engine.state
        poorState.balance = 249
        var poor = GameEngine(state: poorState)
        XCTAssertThrowsError(try poor.expandShop(toward: .right))
        XCTAssertEqual(poor.state, poorState)
        XCTAssertNoThrow(try engine.expandShop(toward: .right))
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
        invalid.world.hitMap.updateCell(at: GridPoint(x: 0, y: 0)) { $0.zone = .interior }
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
