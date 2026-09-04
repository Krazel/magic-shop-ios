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
        XCTAssertTrue(tomorrow.waitForExistence(timeout: 35))
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
}