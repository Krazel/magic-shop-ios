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
