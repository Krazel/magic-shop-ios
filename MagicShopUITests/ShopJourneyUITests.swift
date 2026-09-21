import XCTest

final class ShopJourneyUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor
    func testRealControlsBuildStockTradeAndStartTomorrow() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--visual-state", "onboarding"]
        app.launch()
        let name = app.textFields["shop-name-field"]
        XCTAssertTrue(name.waitForExistence(timeout: 10))
        name.tap()
        name.typeText("Moonlit Curios")
        app.buttons["open-the-door-button"].tap()
        XCTAssertTrue(app.buttons["nav-build"].waitForExistence(timeout: 5))
        app.buttons["nav-build"].tap()
        app.buttons["fixture-basicDisplayTable"].tap()
        let place = app.buttons["confirm-placement"]
        XCTAssertTrue(place.isEnabled)
        place.tap()
        app.buttons["nav-stock"].tap()
        let stock = app.buttons["confirm-stock"]
        XCTAssertTrue(stock.waitForExistence(timeout: 5))
        XCTAssertTrue(stock.isHittable)
        stock.tap()
        app.buttons["nav-open"].tap()
        XCTAssertTrue(app.buttons["Pause day"].waitForExistence(timeout: 5))
        app.buttons["Pause day"].tap()
        XCTAssertTrue(app.buttons["Resume day"].exists)
        app.buttons["Double speed"].tap()
        app.buttons["Resume day"].tap()
        let tomorrow = app.buttons["prepare-next-day"]
        XCTAssertTrue(tomorrow.waitForExistence(timeout: 60))
        XCTAssertTrue(tomorrow.isHittable)
        tomorrow.tap()
        XCTAssertTrue(app.staticTexts["Day 2 · Tuesday"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["nav-build"].isEnabled)
    }

    @MainActor
    func testStockConfirmationRemainsReachableWithLargeText() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--visual-state", "stock", "--large-text"]
        app.launch()
        let confirm = app.buttons["confirm-stock"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 10))
        XCTAssertTrue(confirm.isHittable)
        confirm.tap()
        XCTAssertTrue(app.buttons["Return for $10"].waitForExistence(timeout: 5))
    }
    @MainActor
    func testRestoredShopOpensItsCompletionJournal() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--visual-state", "restored"]
        app.launch()
        let journal = app.buttons["Shop journal and goals"]
        XCTAssertTrue(journal.waitForExistence(timeout: 10))
        journal.tap()
        XCTAssertTrue(app.staticTexts["A little shop, full of magic"].waitForExistence(timeout: 5))
        let capture = XCTAttachment(screenshot: app.screenshot())
        capture.name = "Restoration completion journal"
        capture.lifetime = .keepAlways
        add(capture)
    }
    @MainActor
    func testPriceControlsSaveAndRemainReachableWithLargeText() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--visual-state", "pricing", "--large-text"]
        app.launch()
        let apply = app.buttons["apply-price"]
        XCTAssertTrue(apply.waitForExistence(timeout: 10))
        XCTAssertTrue(apply.isHittable)
        let increase = app.buttons["Raise price"]
        if !increase.isHittable { app.scrollViews.firstMatch.swipeUp() }
        increase.tap()
        apply.tap()
        XCTAssertTrue(app.staticTexts["price-saved"].waitForExistence(timeout: 5))
        attach(app, "Price controls with large text")
    }

    @MainActor
    func testFurnitureLongPressDragMovesTheActualFixture() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--visual-state", "drag"]
        app.launch()
        let fixture = app.descendants(matching: .any)["fixture-world-00000000-0000-0000-0000-000000000003"].firstMatch
        XCTAssertTrue(fixture.waitForExistence(timeout: 10))
        let old = fixture.frame
        let start = fixture.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.65))
        start.press(forDuration: 0.3, thenDragTo: start.withOffset(CGVector(dx: 75, dy: 0)))
        XCTAssertTrue(fixture.waitForExistence(timeout: 5))
        XCTAssertGreaterThan(fixture.frame.midX, old.midX + 20)
        XCTAssertFalse(app.buttons["confirm-placement"].exists)
        attach(app, "Furniture after native drag")
    }

    @MainActor
    func testFloorStrokePreviewsThenAppliesWithoutHiddenCharge() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--visual-state", "care"]
        app.launch()
        XCTAssertTrue(app.buttons["care-floor"].waitForExistence(timeout: 10))
        app.buttons["care-floor"].tap()
        let first = app.descendants(matching: .any)["world-cell-3-7"].firstMatch
        let last = app.descendants(matching: .any)["world-cell-4-7"].firstMatch
        XCTAssertTrue(first.waitForExistence(timeout: 5))
        first.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).press(forDuration: 0.1,
            thenDragTo: last.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)))
        let apply = app.buttons["apply-floor"]
        XCTAssertTrue(apply.isEnabled)
        XCTAssertTrue(app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "Balance, 180 dollars")).firstMatch.exists)
        attach(app, "Floor stroke preview")
        apply.tap()
        XCTAssertTrue(app.staticTexts["care-feedback"].waitForExistence(timeout: 5))
        XCTAssertFalse(apply.isEnabled)
        XCTAssertTrue(app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "Balance, 176 dollars")).firstMatch.exists)
        attach(app, "Floor applied")
    }

    @MainActor
    func testCustomersOverlapAndCareWorksWhileOpen() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--visual-state", "living"]
        app.launch()
        let status = app.staticTexts["visitor-status"]
        XCTAssertTrue(status.waitForExistence(timeout: 10))
        XCTAssertTrue(status.label.contains("3 browsing") || status.label.contains("4 browsing"))
        XCTAssertTrue(app.buttons["nav-stock"].isEnabled)
        app.buttons["Care"].tap()
        XCTAssertTrue(app.buttons["care-clean"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["care-floor"].isEnabled)
        attach(app, "Care during overlapping visits")
    }

    @MainActor
    func testNextStepOpensTheMatchingManualCareTask() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--visual-state", "preparation"]
        app.launch()
        let next = app.buttons["next-step-action"]
        XCTAssertTrue(next.waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["next-step-title"].label.contains("1/3"))
        next.tap()
        XCTAssertTrue(app.buttons["care-clean"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["sweep-rubble"].isEnabled)
        app.buttons["sweep-brokenBoards"].tap()
        XCTAssertTrue(app.staticTexts["care-feedback"].label.contains("1/3"))
        attach(app, "Next step leads to manual care")
    }

    @MainActor
    func testClosingReportKeepsTomorrowReachableWithLargeText() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--visual-state", "living-summary", "--large-text"]
        app.launch()
        let next = app.buttons["prepare-next-day"]
        XCTAssertTrue(next.waitForExistence(timeout: 10))
        XCTAssertTrue(next.isHittable)
        let details = app.scrollViews["day-report-details"]
        details.swipeUp()
        XCTAssertTrue(app.staticTexts["Tomorrow"].waitForExistence(timeout: 5))
        XCTAssertTrue(next.isHittable)
        attach(app, "Closing report with large text")
        next.tap()
        XCTAssertTrue(app.staticTexts["Day 2 · Tuesday"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["next-step-action"].isHittable)
    }

    @MainActor
    func testRestockingWhilePausedDisplaysTheProductImmediately() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--visual-state", "living"]
        app.launch()
        XCTAssertTrue(app.buttons["Resume day"].waitForExistence(timeout: 10))
        app.buttons["nav-stock"].tap()
        let returnItem = app.buttons["Return for $20"]
        XCTAssertTrue(returnItem.waitForExistence(timeout: 5))
        returnItem.tap()
        app.buttons["confirm-stock"].tap()
        XCTAssertTrue(app.buttons["Resume day"].isHittable)
        let fixture = app.descendants(matching: .any)["fixture-world-00000000-0000-0000-0000-000000000003"].firstMatch
        let visible = NSPredicate(format: "value CONTAINS %@", "Glow Potion displayed")
        expectation(for: visible, evaluatedWith: fixture)
        waitForExpectations(timeout: 5)
        attach(app, "Product visible while the shop stays paused")
        app.buttons["Prices"].tap()
        XCTAssertTrue(app.buttons["Resume day"].isHittable)
        app.buttons["Raise price"].tap()
        app.buttons["apply-price"].tap()
        XCTAssertTrue(app.staticTexts["price-saved"].exists)
    }

    @MainActor
    func testCameraAccessibilityValueTracksNativePinchDuringPreparation() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--visual-state", "drag"]
        app.launch()
        let camera = app.descendants(matching: .any)["world-camera"].firstMatch
        XCTAssertTrue(camera.waitForExistence(timeout: 10))
        let before = camera.value as? String
        camera.pinch(withScale: 1.15, velocity: 0.8)
        XCTAssertNotEqual(camera.value as? String, before)
        XCTAssertTrue((camera.value as? String)?.contains("Zoom ") == true)
    }

    @MainActor
    func testDisplaysInEveryExpansionRemainSelectableAndStocked() throws {
        for direction in ["left", "right", "rear"] {
            let app = XCUIApplication()
            app.launchArguments = ["--visual-state", "expanded-\(direction)"]
            app.launch()
            let fixture = app.descendants(matching: .any)["fixture-world-10000000-0000-0000-0000-000000000001"].firstMatch
            XCTAssertTrue(fixture.waitForExistence(timeout: 10), direction)
            XCTAssertTrue((fixture.value as? String)?.contains("Glow Potion displayed") == true, direction)
            let overviewFrame = fixture.frame
            attach(app, "Occupied \(direction) expansion before interaction")
            fixture.tap()
            let returnItem = app.buttons["Return for $10"]
            XCTAssertTrue(returnItem.waitForExistence(timeout: 5), direction)
            returnItem.tap()
            XCTAssertTrue(app.buttons["confirm-stock"].waitForExistence(timeout: 5), direction)
            app.buttons["confirm-stock"].tap()
            XCTAssertTrue(returnItem.waitForExistence(timeout: 5), direction)
            expectation(for: NSPredicate(format: "value CONTAINS %@", "Glow Potion displayed"), evaluatedWith: fixture)
            waitForExpectations(timeout: 5)
            attach(app, "\(direction) expansion display restocked through native controls")
            // Holding a stocked expansion display without moving the finger must
            // not shift its saved position when the placement preview opens.
            fixture.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.65)).press(forDuration: 0.35)
            XCTAssertTrue(app.buttons["next-step-action"].waitForExistence(timeout: 5), direction)
            XCTAssertEqual(fixture.frame.midX, overviewFrame.midX, accuracy: 5, direction)
            XCTAssertEqual(fixture.frame.midY, overviewFrame.midY, accuracy: 5, direction)
            if direction == "right" {
                // The two displays are at (12,5) and (14,5). Measure the actual
                // projected cell width, then drag the stocked display to (9,5),
                // through the removed wall and back into the original room.
                let second = app.descendants(matching: .any)["fixture-world-10000000-0000-0000-0000-000000000002"].firstMatch
                XCTAssertTrue(second.exists)
                let cellWidth = (second.frame.midX - fixture.frame.midX) / 2
                XCTAssertGreaterThan(cellWidth, 5)
                let start = fixture.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.65))
                start.press(forDuration: 0.3,
                    thenDragTo: start.withOffset(CGVector(dx: -3 * cellWidth, dy: 0)))
                XCTAssertTrue(app.buttons["next-step-action"].waitForExistence(timeout: 5))
                XCTAssertEqual(fixture.frame.midX, overviewFrame.midX - 3 * cellWidth, accuracy: 5)
                XCTAssertEqual(fixture.frame.midY, overviewFrame.midY, accuracy: 5)
                XCTAssertTrue((fixture.value as? String)?.contains("Glow Potion displayed") == true)
                attach(app, "Stocked furniture dragged through the removed right wall")
            }
            app.terminate()
        }
    }

    @MainActor
    func testFloorPaintingCrossesTheRemovedRightWall() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--visual-state", "expanded-right"]
        app.launch()
        XCTAssertTrue(app.buttons["Care"].waitForExistence(timeout: 10))
        app.buttons["Care"].tap()
        app.buttons["care-floor"].tap()
        let original = app.descendants(matching: .any)["world-cell-10-7"].firstMatch
        let added = app.descendants(matching: .any)["world-cell-11-7"].firstMatch
        XCTAssertTrue(original.waitForExistence(timeout: 5))
        XCTAssertTrue(added.waitForExistence(timeout: 5))
        original.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).press(forDuration: 0.1,
            thenDragTo: added.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)))
        let apply = app.buttons["apply-floor"]
        XCTAssertTrue(apply.isEnabled)
        XCTAssertTrue(app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "Balance, 27 dollars")).firstMatch.exists)
        attach(app, "Floor preview crosses the removed wall")
        apply.tap()
        XCTAssertFalse(apply.isEnabled)
        XCTAssertTrue(app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "Balance, 23 dollars")).firstMatch.exists)
        attach(app, "Continuous floor applied across the old wall")
    }

    @MainActor private func attach(_ app: XCUIApplication, _ name: String) {
        let capture = XCTAttachment(screenshot: app.screenshot())
        capture.name = name; capture.lifetime = .keepAlways; add(capture)
    }

    @MainActor
    func testManualCleaningRequiresThreeSeparateWorldStrokes() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--visual-state", "care"]
        app.launch()
        let tile = app.descendants(matching: .any)["world-cell-1-5"].firstMatch
        XCTAssertTrue(tile.waitForExistence(timeout: 10))
        for expected in 1...3 {
            let start = tile.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.5))
            let end = tile.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5))
            start.press(forDuration: 0.1, thenDragTo: end)
            let feedback = app.staticTexts["care-feedback"]
            XCTAssertTrue(feedback.waitForExistence(timeout: 5))
            XCTAssertTrue(expected == 3 ? feedback.label.contains("complete") : feedback.label.contains("\(expected)/3"))
        }
        XCTAssertFalse(app.buttons["sweep-rubble"].isEnabled)
        attach(app, "Manual repair after three native strokes")
    }

}
