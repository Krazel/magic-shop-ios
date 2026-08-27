import Foundation
import XCTest

#if SWIFT_PACKAGE
@testable import MagicShopCore
#else
@testable import MagicShop
#endif

final class PersistenceTests: XCTestCase {
    func testMissingFileLoadsInitialState() throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = FileGameStateStore(fileURL: directory.appendingPathComponent("state.json"))

        XCTAssertEqual(try store.load(), .initial)
    }

    func testNameBalanceAndFixturesRoundTrip() throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = FileGameStateStore(fileURL: directory.appendingPathComponent("save/state.json"))
        let fixture = PlacedFixture(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            kind: .basicDisplayTable,
            origin: GridPoint(x: 2, y: 3)
        )
        var world = ShopWorldState.starter
        let futureFloor = FloorStyleID(rawValue: "moonstone")
        world.floor.setStyleID(futureFloor, at: GridPoint(x: 6, y: 6))
        world.hitMap.updateCell(at: GridPoint(x: 7, y: 7)) {
            $0.staticBlocker = .discardedPapers
        }
        let expected = GameState(
            shopName: "Moon & Mortar",
            onboardingCompleted: true,
            balance: 450,
            fixtures: [fixture],
            world: world
        )

        try store.save(expected)

        XCTAssertEqual(try store.load(), expected)
        XCTAssertEqual(try store.load().world.floor.styleID(at: GridPoint(x: 6, y: 6)), futureFloor)
        XCTAssertEqual(
            try store.load().world.hitMap.cell(at: GridPoint(x: 7, y: 7))?.staticBlocker,
            .discardedPapers
        )
    }

    private func temporaryDirectory() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("MagicShopTests-\(UUID().uuidString)", isDirectory: true)
    }
}
