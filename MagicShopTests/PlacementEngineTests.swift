import XCTest

#if SWIFT_PACKAGE
@testable import MagicShopCore
#else
@testable import MagicShop
#endif

final class PlacementEngineTests: XCTestCase {
    func testConfirmingBasicTableSpendsMoneyAndAddsFixture() throws {
        var engine = GameEngine()
        let fixtureID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let draft = engine.makePlacementDraft(
            kind: .basicDisplayTable,
            origin: GridPoint(x: 4, y: 4),
            fixtureID: fixtureID
        )

        let fixture = try engine.confirm(draft)

        XCTAssertEqual(fixture.id, fixtureID)
        XCTAssertEqual(engine.state.balance, 450)
        XCTAssertEqual(engine.state.fixtures, [fixture])
    }

    func testValidationAndCancellationDoNotSpendMoney() throws {
        var engine = GameEngine()
        let draft = engine.makePlacementDraft(
            kind: .basicDisplayTable,
            origin: GridPoint(x: 3, y: 3)
        )

        try engine.validate(draft)
        engine.cancel(draft)

        XCTAssertEqual(engine.state.balance, 500)
        XCTAssertTrue(engine.state.fixtures.isEmpty)
    }

    func testInsufficientFundsRejectsPlacementWithoutMutation() {
        var engine = GameEngine(state: GameState(balance: 49))
        let draft = engine.makePlacementDraft(
            kind: .basicDisplayTable,
            origin: GridPoint(x: 1, y: 1)
        )

        XCTAssertThrowsError(try engine.confirm(draft)) { error in
            XCTAssertEqual(
                error as? PlacementError,
                .insufficientFunds(required: 50, available: 49)
            )
        }
        XCTAssertEqual(engine.state.balance, 49)
        XCTAssertTrue(engine.state.fixtures.isEmpty)
    }

    func testOutsideBoundsIsRejected() {
        let engine = GameEngine()
        let negative = engine.makePlacementDraft(
            kind: .basicDisplayTable,
            origin: GridPoint(x: -1, y: 0)
        )
        let beyondEdge = engine.makePlacementDraft(
            kind: .basicDisplayTable,
            origin: GridPoint(x: 11, y: 10)
        )

        assertPlacementError(.outsideShopBounds) {
            try engine.validate(negative)
        }
        assertPlacementError(.outsideShopBounds) {
            try engine.validate(beyondEdge)
        }
    }

    func testOneByOneBasicTableFitsInTheFinalGridCell() throws {
        let engine = GameEngine()
        let finalCell = engine.makePlacementDraft(
            kind: .basicDisplayTable,
            origin: GridPoint(x: 10, y: 10)
        )

        XCTAssertNoThrow(try engine.validate(finalCell))
    }

    func testStaticDebrisBlocksPlacement() {
        let engine = GameEngine()
        let rubbleCell = engine.makePlacementDraft(
            kind: .basicDisplayTable,
            origin: GridPoint(x: 1, y: 5)
        )

        assertPlacementError(.blockedByStaticObject(.rubble)) {
            try engine.validate(rubbleCell)
        }
    }

    func testEntranceMustRemainClear() {
        let engine = GameEngine()
        let entrance = engine.makePlacementDraft(
            kind: .basicDisplayTable,
            origin: GridPoint(x: 5, y: 0)
        )

        assertPlacementError(.entranceMustRemainClear) {
            try engine.validate(entrance)
        }
    }

    func testOverlappingFixtureIsRejected() throws {
        var engine = GameEngine()
        let firstDraft = engine.makePlacementDraft(
            kind: .basicDisplayTable,
            origin: GridPoint(x: 4, y: 4)
        )
        try engine.confirm(firstDraft)
        let overlap = engine.makePlacementDraft(
            kind: .basicDisplayTable,
            origin: GridPoint(x: 4, y: 4)
        )

        assertPlacementError(.overlapsExistingFixture) {
            try engine.validate(overlap)
        }
        XCTAssertEqual(engine.state.balance, 450)
        XCTAssertEqual(engine.state.fixtures.count, 1)
    }

    func testShelfMustBeAdjacentToWall() {
        let engine = GameEngine()
        let centerShelf = engine.makePlacementDraft(
            kind: .simpleShelf,
            origin: GridPoint(x: 4, y: 4)
        )

        assertPlacementError(.shelfMustBeAdjacentToWall) {
            try engine.validate(centerShelf)
        }
    }

    func testShelfCanBePlacedAgainstAnyWall() throws {
        let engine = GameEngine()
        let leftWall = engine.makePlacementDraft(
            kind: .simpleShelf,
            origin: GridPoint(x: 0, y: 4),
            rotation: .east
        )
        let rearWall = engine.makePlacementDraft(
            kind: .simpleShelf,
            origin: GridPoint(x: 4, y: 10)
        )

        XCTAssertNoThrow(try engine.validate(leftWall))
        XCTAssertNoThrow(try engine.validate(rearWall))
    }

    func testShelfAdjacencyComesFromHitMapMetadata() throws {
        var world = ShopWorldState.starter
        world.hitMap.updateCell(at: GridPoint(x: 4, y: 4)) {
            $0.adjacentWalls = [.rear]
        }
        world.hitMap.updateCell(at: GridPoint(x: 5, y: 4)) {
            $0.adjacentWalls = [.rear]
        }
        let engine = GameEngine(state: GameState(world: world))
        let shelf = engine.makePlacementDraft(
            kind: .simpleShelf,
            origin: GridPoint(x: 4, y: 4)
        )

        XCTAssertNoThrow(try engine.validate(shelf))
    }

    func testShelfAtCoordinateEdgeFailsWhenWallMetadataIsRemoved() {
        var world = ShopWorldState.starter
        world.hitMap.updateCell(at: GridPoint(x: 4, y: 10)) {
            $0.adjacentWalls.remove(.rear)
        }
        world.hitMap.updateCell(at: GridPoint(x: 5, y: 10)) {
            $0.adjacentWalls.remove(.rear)
        }
        let engine = GameEngine(state: GameState(world: world))
        let shelf = engine.makePlacementDraft(
            kind: .simpleShelf,
            origin: GridPoint(x: 4, y: 10)
        )

        assertPlacementError(.shelfMustBeAdjacentToWall) {
            try engine.validate(shelf)
        }
    }

#if !SWIFT_PACKAGE
    func testAppModelPlacementDoesNotSpendUntilPlaceAndPersistsResult() async throws {
        let initial = GameState(shopName: "My Shop", onboardingCompleted: true)
        let store = InMemoryGameStateStore(initialState: initial)

        await MainActor.run {
            let model = AppModel(store: store)
            model.openBuild()
            model.beginPlacement(kind: .basicDisplayTable)

            XCTAssertEqual(model.state.balance, 500)
            XCTAssertTrue(model.isPlacementValid)

            XCTAssertTrue(model.confirmCurrentPlacement())
            XCTAssertEqual(model.state.balance, 450)
            XCTAssertEqual(model.state.fixtures.count, 1)

            let reloaded = AppModel(store: store)
            XCTAssertEqual(reloaded.state.balance, 450)
            XCTAssertEqual(reloaded.state.fixtures.count, 1)
        }
    }
#endif

    private func assertPlacementError(
        _ expected: PlacementError,
        file: StaticString = #filePath,
        line: UInt = #line,
        operation: () throws -> Void
    ) {
        XCTAssertThrowsError(try operation(), file: file, line: line) { error in
            XCTAssertEqual(error as? PlacementError, expected, file: file, line: line)
        }
    }
}
