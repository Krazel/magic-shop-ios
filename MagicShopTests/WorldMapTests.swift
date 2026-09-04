import Foundation
import XCTest

#if SWIFT_PACKAGE
@testable import MagicShopCore
#else
@testable import MagicShop
#endif

final class WorldMapTests: XCTestCase {
    func testStarterFloorContainsOneHundredTwentyOneTerracottaTiles() {
        let floor = ShopFloorState()

        XCTAssertEqual(floor.layout, .starter)
        XCTAssertEqual(floor.tiles.count, 121)
        XCTAssertTrue(floor.tiles.allSatisfy { $0.styleID == .wornTerracotta })
        XCTAssertEqual(
            FloorStyleCatalog.definition(for: .wornTerracotta)?.displayName,
            "Worn Terracotta"
        )
    }

    func testFloorCanChangeOneCellOrReplaceEveryTile() {
        let futureStyle = FloorStyleID(rawValue: "moonstone")
        let paintedCell = GridPoint(x: 3, y: 7)
        var floor = ShopFloorState()

        XCTAssertTrue(floor.setStyleID(futureStyle, at: paintedCell))
        XCTAssertEqual(floor.styleID(at: paintedCell), futureStyle)
        XCTAssertEqual(floor.styleID(at: GridPoint(x: 4, y: 7)), .wornTerracotta)

        floor.replaceAll(with: futureStyle)
        XCTAssertTrue(floor.tiles.allSatisfy { $0.styleID == futureStyle })
    }

    func testFloorStyleRoundTripsThroughCodable() throws {
        let futureStyle = FloorStyleID(rawValue: "moonstone")
        var expected = ShopFloorState()
        expected.setStyleID(futureStyle, at: GridPoint(x: 6, y: 2))

        let data = try JSONEncoder().encode(expected)
        let decoded = try JSONDecoder().decode(ShopFloorState.self, from: data)

        XCTAssertEqual(decoded, expected)
    }

    func testStarterHitMapContainsInteriorEntranceAndBoundaryMetadata() {
        let map = WorldHitMap.starter

        XCTAssertEqual(map.cells.count, 121)
        XCTAssertEqual(map.cell(at: GridPoint(x: 5, y: 0))?.zone, .entrance)
        XCTAssertEqual(map.cell(at: GridPoint(x: 5, y: 10))?.adjacentWalls, [.rear])
        XCTAssertEqual(map.cell(at: GridPoint(x: 0, y: 5))?.adjacentWalls, [.left])
        XCTAssertEqual(map.cell(at: GridPoint(x: 10, y: 10))?.adjacentWalls, [.right, .rear])
        XCTAssertNil(map.cell(at: GridPoint(x: -1, y: 0)))
    }

    func testStarterHitMapIdentifiesDebrisArchitectureAndEntrance() {
        let map = WorldHitMap.starter

        XCTAssertEqual(map.hit(at: GridPoint(x: 1, y: 5), fixtures: []), .blocked(.rubble))
        XCTAssertEqual(map.hit(at: GridPoint(x: 9, y: 5), fixtures: []), .blocked(.brokenBoards))
        XCTAssertEqual(map.hit(at: GridPoint(x: 9, y: 2), fixtures: []), .blocked(.discardedPapers))
        XCTAssertEqual(map.hit(at: GridPoint(x: 0, y: 0), fixtures: []), .blocked(.frontColumn))
        XCTAssertEqual(map.hit(at: GridPoint(x: 5, y: 0), fixtures: []), .entrance)
        XCTAssertEqual(map.hit(at: GridPoint(x: 5, y: 5), fixtures: []), .available)
    }

    func testDynamicFixtureOccupancyIsProjectedIntoHitMap() {
        let id = UUID(uuidString: "00000000-0000-0000-0000-000000000010")!
        let fixture = PlacedFixture(
            id: id,
            kind: .simpleShelf,
            origin: GridPoint(x: 4, y: 10)
        )
        let map = WorldHitMap.starter

        XCTAssertEqual(map.dynamicOccupancy(fixtures: [fixture]).count, 2)
        XCTAssertEqual(map.hit(at: GridPoint(x: 4, y: 10), fixtures: [fixture]), .occupied(id))
        XCTAssertEqual(map.hit(at: GridPoint(x: 5, y: 10), fixtures: [fixture]), .occupied(id))
    }

    func testCommonWallAdjacencyRequiresEveryFootprintCellToShareWall() {
        let map = WorldHitMap.starter
        let rearCells: Set<GridPoint> = [
            GridPoint(x: 4, y: 10),
            GridPoint(x: 5, y: 10)
        ]
        let cornerTurn: Set<GridPoint> = [
            GridPoint(x: 0, y: 0),
            GridPoint(x: 0, y: 1),
            GridPoint(x: 1, y: 0)
        ]

        XCTAssertEqual(map.commonWallAdjacency(for: rearCells), [.rear])
        XCTAssertTrue(map.commonWallAdjacency(for: cornerTurn).isEmpty)
    }

    func testWorldGeometryMapsSquareTileCentersAndRejectsEdgesOutside() {
        let geometry = WorldGridGeometry(tileSide: 10)

        XCTAssertEqual(geometry.cell(at: WorldPoint(x: 0, y: 0)), GridPoint(x: 5, y: 5))
        XCTAssertEqual(geometry.cell(at: WorldPoint(x: -54.999, y: -54.999)), GridPoint(x: 0, y: 0))
        XCTAssertEqual(geometry.cell(at: WorldPoint(x: 54.999, y: 54.999)), GridPoint(x: 10, y: 10))
        XCTAssertNil(geometry.cell(at: WorldPoint(x: 55, y: 0)))
        XCTAssertNil(geometry.cell(at: WorldPoint(x: 0, y: -55.001)))
        XCTAssertEqual(geometry.center(of: GridPoint(x: 5, y: 5)), WorldPoint(x: 0, y: 0))
    }

    func testCameraViewportTransformAccountsForZoomAndVerticalPan() {
        let transform = CameraViewportTransform(
            width: 200,
            height: 400,
            camera: WorldCameraState(zoom: 1.25, verticalOffset: 20)
        )

        XCTAssertEqual(
            transform.worldPoint(fromScreen: ScreenPoint(x: 120, y: 180)),
            WorldPoint(x: 25, y: 45)
        )
    }

    func testScreenPointMapsToExpectedCellAfterZoomAndPan() {
        let camera = WorldCameraState(zoom: 1.25, verticalOffset: 20)
        let transform = CameraViewportTransform(width: 200, height: 400, camera: camera)
        let geometry = WorldGridGeometry(tileSide: 10)

        let worldPoint = transform.worldPoint(fromScreen: ScreenPoint(x: 100, y: 216))

        XCTAssertEqual(worldPoint, WorldPoint(x: 0, y: 0))
        XCTAssertEqual(geometry.cell(at: worldPoint), GridPoint(x: 5, y: 5))
    }

    func testLegacySaveMigratesToStarterWorld() throws {
        let legacy = """
        {
          "schemaVersion": 1,
          "shopName": "Old Save",
          "onboardingCompleted": true,
          "balance": 450,
          "fixtures": []
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(GameState.self, from: legacy)

        XCTAssertEqual(decoded.schemaVersion, GameState.currentSchemaVersion)
        XCTAssertEqual(decoded.world, .starter)
        XCTAssertEqual(decoded.shopName, "Old Save")
    }
}
