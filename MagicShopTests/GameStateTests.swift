import XCTest

#if SWIFT_PACKAGE
@testable import MagicShopCore
#else
@testable import MagicShop
#endif

final class GameStateTests: XCTestCase {
    func testInitialStateStartsWithFiveHundredDollars() {
        let state = GameState.initial

        XCTAssertEqual(state.balance, 500)
        XCTAssertNil(state.shopName)
        XCTAssertFalse(state.onboardingCompleted)
        XCTAssertTrue(state.fixtures.isEmpty)
    }

    func testFirstSliceCatalogContainsOnlyTablesAndShelves() {
        XCTAssertEqual(FixtureCatalog.firstSlice.map(\.kind), [
            .basicDisplayTable,
            .simpleShelf
        ])
        XCTAssertTrue(FixtureCategory.tables.isAvailableInFirstSlice)
        XCTAssertTrue(FixtureCategory.shelves.isAvailableInFirstSlice)
        XCTAssertFalse(FixtureCategory.decor.isAvailableInFirstSlice)
        XCTAssertFalse(FixtureCategory.walls.isAvailableInFirstSlice)
    }

    func testFixtureEconomyAndCapacityMatchProductDecision() {
        XCTAssertEqual(FixtureCatalog.basicDisplayTable.price, 50)
        XCTAssertEqual(FixtureCatalog.basicDisplayTable.stockCapacity, 1)
        XCTAssertEqual(FixtureCatalog.basicDisplayTable.footprint, GridFootprint(width: 1, depth: 1))

        XCTAssertEqual(FixtureCatalog.simpleShelf.price, 150)
        XCTAssertEqual(FixtureCatalog.simpleShelf.stockCapacity, 2)
        XCTAssertEqual(FixtureCatalog.simpleShelf.footprint, GridFootprint(width: 2, depth: 1))
        XCTAssertEqual(FixtureCatalog.simpleShelf.placementConstraint, .adjacentToWall)
    }

    func testFirstSliceFlowFollowsOnboardingBuildAndPlacement() {
        var flow = FirstSliceFlow(state: .initial)
        XCTAssertEqual(flow.route, .onboarding)

        flow.didCompleteOnboarding()
        XCTAssertEqual(flow.route, .shop)

        flow.openBuild()
        XCTAssertEqual(flow.route, .buildCatalog)

        let draft = PlacementDraft(
            fixtureID: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
            kind: .basicDisplayTable,
            origin: GridPoint(x: 5, y: 5)
        )
        flow.beginPlacement(draft)
        XCTAssertEqual(flow.route, .placement(draft))

        flow.cancelPlacement()
        XCTAssertEqual(flow.route, .buildCatalog)
    }

    func testCompletedSaveStartsOnShopRoute() {
        let state = GameState(shopName: "Moon & Mortar", onboardingCompleted: true)
        XCTAssertEqual(FirstSliceFlow(state: state).route, .shop)
    }

#if !SWIFT_PACKAGE
    func testAppModelOnboardingPersistsNameAndUpdatesHUDState() async {
        let store = InMemoryGameStateStore()

        await MainActor.run {
            let model = AppModel(store: store)
            model.shopNameInput = "  The   Gilded   Acorn  "

            XCTAssertTrue(model.submitOnboarding())
            XCTAssertEqual(model.state.shopName, "The Gilded Acorn")
            XCTAssertTrue(model.state.onboardingCompleted)
            XCTAssertEqual(model.flow.route, .shop)

            let reloaded = AppModel(store: store)
            XCTAssertEqual(reloaded.state.shopName, "The Gilded Acorn")
            XCTAssertEqual(reloaded.flow.route, .shop)
        }
    }
#endif
}

extension GameStateTests {
    func testCommerceStartsPreparingWithoutInventoryOrDayHistory() {
        let state = GameState.initial
        XCTAssertEqual(state.schemaVersion, 3)
        XCTAssertEqual(state.phase, .preparing)
        XCTAssertTrue(state.stock.isEmpty)
        XCTAssertNil(state.currentDay)
        XCTAssertTrue(state.dayHistory.isEmpty)
    }

    func testProductCatalogHasThreeCompatibleStarterGoods() {
        XCTAssertEqual(ProductCatalog.all.map(\.kind), [.glowPotion, .luckyCharm, .pocketSpellbook])
        XCTAssertEqual(ProductCatalog.all.map(\.purchasePrice), [10, 20, 30])
        XCTAssertEqual(ProductCatalog.all.map(\.salePrice), [25, 45, 70])
        XCTAssertTrue(ProductCatalog.definition(for: .glowPotion).isCompatible(with: .basicDisplayTable))
        XCTAssertTrue(ProductCatalog.definition(for: .glowPotion).isCompatible(with: .simpleShelf))
        XCTAssertEqual(ProductCatalog.definition(for: .luckyCharm).compatibleFixtures, [.basicDisplayTable])
        XCTAssertEqual(ProductCatalog.definition(for: .pocketSpellbook).compatibleFixtures, [.simpleShelf])
    }

    func testSchemaOneAndTwoMigrateWithoutChangingEconomyFurnitureOrExistingWorld() throws {
        let fixture = PlacedFixture(kind: .basicDisplayTable, origin: GridPoint(x: 4, y: 4))
        var world = ShopWorldState.starter
        world.floor.setStyleID(FloorStyleID(rawValue: "moonstone"), at: GridPoint(x: 6, y: 6))
        for version in [1, 2] {
            let original = GameState(schemaVersion: version, shopName: "Old Shop",
                                     onboardingCompleted: true, balance: 450, fixtures: [fixture], world: world)
            var json = try jsonObject(original)
            json.removeValue(forKey: "stock")
            json.removeValue(forKey: "phase")
            json.removeValue(forKey: "currentDay")
            json.removeValue(forKey: "dayHistory")
            if version == 1 { json.removeValue(forKey: "world") }
            let decoded = try decodeObject(json)
            XCTAssertEqual(decoded.schemaVersion, 3)
            XCTAssertEqual(decoded.shopName, original.shopName)
            XCTAssertEqual(decoded.balance, original.balance)
            XCTAssertEqual(decoded.fixtures, original.fixtures)
            XCTAssertEqual(decoded.world, version == 1 ? .starter : world)
            XCTAssertEqual(decoded.phase, .preparing)
            XCTAssertTrue(decoded.stock.isEmpty)
            XCTAssertTrue(decoded.dayHistory.isEmpty)
        }
    }

    func testFutureOrInvalidSchemaIsRejectedInsteadOfSilentlyDowngraded() throws {
        for version in [0, 4, Int.max] {
            let data = "{\"schemaVersion\":\(version)}".data(using: .utf8)!
            XCTAssertThrowsError(try JSONDecoder().decode(GameState.self, from: data)) { error in
                XCTAssertEqual(error as? GameStateValidationError, .unsupportedSchemaVersion(version))
            }
        }
    }

    func testNegativeBalanceAndDuplicateFurnitureIdentityAreRejectedOnDecode() throws {
        try assertInvalidSave(GameState(balance: -1))
        let fixture = PlacedFixture(kind: .basicDisplayTable, origin: GridPoint(x: 4, y: 4))
        try assertInvalidSave(GameState(fixtures: [fixture, fixture]))
    }

    func testInvalidStockReferencesCapacityIdentityAndSlotsAreRejectedOnDecode() throws {
        let table = PlacedFixture(kind: .basicDisplayTable, origin: GridPoint(x: 4, y: 4))
        let valid = StockItem(product: .glowPotion, fixtureID: table.id, slotIndex: 0)
        let invalidUnits = [
            StockItem(product: .glowPotion, fixtureID: UUID(), slotIndex: 0),
            StockItem(product: .glowPotion, fixtureID: table.id, slotIndex: 1),
            StockItem(product: .pocketSpellbook, fixtureID: table.id, slotIndex: 0),
            StockItem(product: .glowPotion, fixtureID: table.id, slotIndex: -1),
            StockItem(product: .glowPotion, fixtureID: table.id, slotIndex: 0, purchaseCost: -1)
        ]
        for invalid in invalidUnits {
            try assertInvalidSave(GameState(fixtures: [table], stock: [invalid]))
        }
        try assertInvalidSave(GameState(fixtures: [table], stock: [valid, valid]))
        let sameSlot = StockItem(product: .luckyCharm, fixtureID: table.id, slotIndex: 0)
        try assertInvalidSave(GameState(fixtures: [table], stock: [valid, sameSlot]))
    }

    func testMalformedDayCursorPhaseAndBalanceAreRejectedOnDecode() throws {
        let day = ShopDayState(dayNumber: 1, openingBalance: 500)
        let active = GameState(shopName: "Old Shop", onboardingCompleted: true,
                               phase: .open, currentDay: day)
        XCTAssertNoThrow(try decodeObject(jsonObject(active)))
        try assertInvalidSave(GameState(phase: .open))
        try assertInvalidSave(GameState(currentDay: day))
        try assertInvalidSave(GameState(shopName: "Old Shop", onboardingCompleted: true,
                                        phase: .summary, currentDay: day))
        try assertInvalidSave(GameState(shopName: "Old Shop", onboardingCompleted: true,
                                        balance: 499, phase: .open, currentDay: day))
        var json = try jsonObject(active)
        var current = try XCTUnwrap(json["currentDay"] as? [String: Any])
        current["nextVisitIndex"] = 7
        json["currentDay"] = current
        XCTAssertThrowsError(try decodeObject(json))
        current["nextVisitIndex"] = 1
        json["currentDay"] = current
        XCTAssertThrowsError(try decodeObject(json))
    }

    func testHistoricalStockCostSurvivesSaveAndControlsRefund() throws {
        let table = PlacedFixture(kind: .basicDisplayTable, origin: GridPoint(x: 4, y: 4))
        let historical = StockItem(product: .glowPotion, fixtureID: table.id, slotIndex: 0, purchaseCost: 7)
        let saved = GameState(balance: 10, fixtures: [table], stock: [historical])
        let decoded = try decodeObject(jsonObject(saved))
        var engine = GameEngine(state: decoded)
        XCTAssertEqual(try engine.returnStock(stockID: historical.id), 7)
        XCTAssertEqual(engine.state.balance, 17)
    }

    func testImportedSaleTotalsCannotOverflow() throws {
        let shelf = PlacedFixture(kind: .simpleShelf, origin: GridPoint(x: 4, y: 10))
        let units = [StockItem(product: .glowPotion, fixtureID: shelf.id, slotIndex: 0),
                     StockItem(product: .glowPotion, fixtureID: shelf.id, slotIndex: 1)]
        var engine = GameEngine(state: GameState(shopName: "Old Shop", onboardingCompleted: true,
                                                fixtures: [shelf], stock: units))
        try engine.openDay()
        while let visit = engine.state.currentDay?.nextVisit {
            try engine.advanceDay(expectedVisitID: visit.id)
        }
        var json = try jsonObject(engine.state)
        var current = try XCTUnwrap(json["currentDay"] as? [String: Any])
        var outcomes = try XCTUnwrap(current["outcomes"] as? [[String: Any]])
        for index in [0, 3] {
            var sale = try XCTUnwrap(outcomes[index]["sale"] as? [String: Any])
            sale["revenue"] = Int.max
            outcomes[index]["sale"] = sale
        }
        current["outcomes"] = outcomes
        json["currentDay"] = current
        XCTAssertThrowsError(try decodeObject(json))
    }

    private func assertInvalidSave(
        _ state: GameState, file: StaticString = #filePath, line: UInt = #line
    ) throws {
        let data = try JSONEncoder().encode(state)
        XCTAssertThrowsError(try JSONDecoder().decode(GameState.self, from: data), file: file, line: line)
    }

    private func jsonObject(_ state: GameState) throws -> [String: Any] {
        try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(state)) as? [String: Any])
    }

    private func decodeObject(_ object: [String: Any]) throws -> GameState {
        try JSONDecoder().decode(GameState.self, from: JSONSerialization.data(withJSONObject: object))
    }
}

extension GameStateTests {
    func testSchemaThreeRejectsMissingOrNullRequiredStateFields() throws {
        let original = try jsonObject(.initial)
        for key in ["balance", "onboardingCompleted", "fixtures", "world",
                    "stock", "phase", "dayHistory"] {
            var missing = original
            missing.removeValue(forKey: key)
            XCTAssertThrowsError(try decodeObject(missing), "Missing required field: \(key)")
            var null = original
            null[key] = NSNull()
            XCTAssertThrowsError(try decodeObject(null), "Null required field: \(key)")
        }
        var unnamed = original
        unnamed.removeValue(forKey: "shopName")
        XCTAssertEqual(try decodeObject(unnamed), .initial)
        unnamed["shopName"] = NSNull()
        XCTAssertEqual(try decodeObject(unnamed), .initial)
    }

    func testSchemaTwoRejectsMissingOrNullPersistedWorld() throws {
        var legacy = try jsonObject(GameState(schemaVersion: 2))
        legacy.removeValue(forKey: "world")
        XCTAssertThrowsError(try decodeObject(legacy))
        legacy["world"] = NSNull()
        XCTAssertThrowsError(try decodeObject(legacy))
    }
}
