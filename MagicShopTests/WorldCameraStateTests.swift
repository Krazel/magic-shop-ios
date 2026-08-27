import XCTest

#if SWIFT_PACKAGE
@testable import MagicShopCore
#else
@testable import MagicShop
#endif

final class WorldCameraStateTests: XCTestCase {
    func testPinchZoomIsClamped() {
        var state = WorldCameraState()

        state.applyPinch(multiplier: 100)
        XCTAssertEqual(state.zoom, WorldCameraState.minimumZoom)

        state.applyPinch(multiplier: 0.001)
        XCTAssertEqual(state.zoom, WorldCameraState.maximumZoom)
    }

    func testVerticalPanIsClampedAndNeverMovesHorizontally() {
        var state = WorldCameraState()

        state.panVertically(by: 10_000)
        XCTAssertEqual(state.verticalOffset, WorldCameraState.maximumVerticalOffset)

        state.panVertically(by: -20_000)
        XCTAssertEqual(state.verticalOffset, -WorldCameraState.maximumVerticalOffset)
    }
}
