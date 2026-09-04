import Foundation
import XCTest

#if SWIFT_PACKAGE
@testable import MagicShopCore
#else
@testable import MagicShop
#endif

final class GameSessionTests: XCTestCase {
    func testFailedPurchaseSaveLeavesMoneyAndFixturesUntouchedAndCanRetry() throws {
        let store = FailingSessionStore()
        let session = try GameSession(store: store)
        let draft = session.engine.makePlacementDraft(kind: .basicDisplayTable, origin: GridPoint(x: 5, y: 4))
        store.failWrites = true
        XCTAssertThrowsError(try session.commit { try $0.confirm(draft) })
        XCTAssertEqual(session.engine.state, .initial)
        XCTAssertEqual(try store.load(), .initial)

        store.failWrites = false
        try session.commit { try $0.confirm(draft) }
        XCTAssertEqual(session.engine.state.balance, 450)
        XCTAssertEqual(session.engine.state.fixtures.count, 1)
        XCTAssertEqual(try GameSession(store: store).engine.state, session.engine.state)
    }

    func testFailedOnboardingWriteDoesNotCompleteOrPersistName() throws {
        let store = FailingSessionStore()
        let session = try GameSession(store: store)
        store.failWrites = true
        XCTAssertThrowsError(try session.commit { try $0.completeOnboarding(shopName: "Moon & Mortar") })
        XCTAssertFalse(session.engine.state.onboardingCompleted)
        XCTAssertNil(session.engine.state.shopName)
        XCTAssertEqual(try store.load(), .initial)
    }

    func testInvalidCommandDoesNotWrite() throws {
        let store = FailingSessionStore()
        let session = try GameSession(store: store)
        XCTAssertThrowsError(try session.commit { try $0.completeOnboarding(shopName: "") })
        XCTAssertEqual(store.writeCount, 0)
    }

    func testInterruptedSaleRetryAndRelaunchCreditExactlyOnce() throws {
        let store = FailingSessionStore()
        let session = try GameSession(store: store)
        try session.commit { try $0.completeOnboarding(shopName: "Moon & Mortar") }
        let table = try session.commit {
            try $0.confirm($0.makePlacementDraft(kind: .basicDisplayTable, origin: GridPoint(x: 5, y: 4)))
        }
        try session.commit {
            try $0.confirm($0.makeStockDraft(product: .glowPotion, fixtureID: table.id, slotIndex: 0))
        }
        try session.commit { try $0.openDay() }
        let token = try XCTUnwrap(session.engine.state.currentDay?.nextVisit?.id)
        let before = session.engine.state
        store.failWrites = true
        XCTAssertThrowsError(try session.commit { try $0.advanceDay(expectedVisitID: token) })
        XCTAssertEqual(session.engine.state, before)

        let resumed = try GameSession(store: store)
        XCTAssertEqual(resumed.engine.state, before)
        store.failWrites = false
        try resumed.commit { try $0.advanceDay(expectedVisitID: token) }
        XCTAssertEqual(resumed.engine.state.balance, before.balance + 25)
        XCTAssertTrue(resumed.engine.state.stock.isEmpty)

        let afterSale = try GameSession(store: store)
        XCTAssertThrowsError(try afterSale.commit { try $0.advanceDay(expectedVisitID: token) })
        XCTAssertEqual(afterSale.engine.state.balance, before.balance + 25)
        XCTAssertEqual(afterSale.engine.state.currentDay?.outcomes.count, 1)
    }
    func testUnreadableSaveIsPreservedAndDoesNotStartNewSession() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("save.json")
        let damaged = Data("{ damaged save".utf8)
        try damaged.write(to: url)
        XCTAssertThrowsError(try GameSession(store: FileGameStateStore(fileURL: url)))
        XCTAssertEqual(try Data(contentsOf: url), damaged)
    }
}

// Deliberately single-threaded fault injection; the runtime owner is MainActor.
final class FailingSessionStore: GameStateStore, @unchecked Sendable {
    var failWrites = false
    var failReads = false
    var writeCount = 0
    private var saved: GameState = .initial
    enum Failure: Error { case unavailable }
    func load() throws -> GameState {
        if failReads { throw Failure.unavailable }
        return saved
    }
    func save(_ state: GameState) throws {
        if failWrites { throw Failure.unavailable }
        saved = state
        writeCount += 1
    }
}