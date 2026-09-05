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