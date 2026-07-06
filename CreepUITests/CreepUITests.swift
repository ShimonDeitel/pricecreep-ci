import XCTest

final class CreepUITests: XCTestCase {
    private var interruptionMonitorToken: NSObjectProtocol?

    override func setUpWithError() throws {
        continueAfterFailure = false
        interruptionMonitorToken = addUIInterruptionMonitor(withDescription: "System alert dismissal") { alert in
            for label in ["Allow", "OK", "Don't Allow", "Cancel"] {
                let button = alert.buttons[label]
                if button.exists {
                    button.tap()
                    return true
                }
            }
            return false
        }
    }

    override func tearDownWithError() throws {
        if let token = interruptionMonitorToken {
            removeUIInterruptionMonitor(token)
        }
    }

    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestReset"]
        app.launch()
        return app
    }

    func testHomeShowsCreepIndexOnLaunch() throws {
        let app = launchApp()
        XCTAssertTrue(app.otherElements["creepIndexGauge"].waitForExistence(timeout: 12), "Creep index gauge did not appear on launch")
    }

    func testSeedItemsAppear() throws {
        let app = launchApp()
        XCTAssertTrue(app.staticTexts["Eggs (dozen)"].waitForExistence(timeout: 12))
        XCTAssertTrue(app.staticTexts["Milk (gallon)"].waitForExistence(timeout: 6))
    }

    func testAddItemFromHome() throws {
        let app = launchApp()
        // Seed data has 2 items (free limit is 3), so add is still allowed.
        let addButton = app.buttons["addItemButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 12))
        addButton.tap()

        let nameField = app.textFields["itemNameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 12))
        nameField.tap()
        nameField.typeText("Coffee")

        let priceField = app.textFields["itemPriceField"]
        priceField.tap()
        priceField.typeText("9.99")

        app.buttons["saveItemButton"].tap()

        XCTAssertTrue(app.staticTexts["Coffee"].waitForExistence(timeout: 12), "New item did not appear")
    }

    func testItemDetailShowsCreepPercent() throws {
        let app = launchApp()
        let eggsText = app.staticTexts["Eggs (dozen)"]
        XCTAssertTrue(eggsText.waitForExistence(timeout: 12))
        eggsText.tap()

        XCTAssertTrue(app.staticTexts["itemCreepPercent"].waitForExistence(timeout: 12), "Creep percent did not appear in item detail")
    }

    func testLogNewPriceUpdatesHistory() throws {
        let app = launchApp()
        let eggsText = app.staticTexts["Eggs (dozen)"]
        XCTAssertTrue(eggsText.waitForExistence(timeout: 12))
        eggsText.tap()

        let priceField = app.textFields["newPriceField"]
        XCTAssertTrue(priceField.waitForExistence(timeout: 12))
        priceField.tap()
        priceField.typeText("5.99")

        app.buttons["logPriceButton"].tap()

        XCTAssertTrue(app.staticTexts["$5.99"].waitForExistence(timeout: 12), "Newly logged price did not appear in history")
    }

    func testDeleteItemFromDetail() throws {
        let app = launchApp()
        let eggsText = app.staticTexts["Eggs (dozen)"]
        XCTAssertTrue(eggsText.waitForExistence(timeout: 12))
        eggsText.tap()

        app.buttons["deleteItemButton"].tap()

        XCTAssertFalse(app.staticTexts["Eggs (dozen)"].waitForExistence(timeout: 6), "Item was not deleted")
    }

    func testFreeLimitTriggersPaywallAtFourthItem() throws {
        let app = launchApp()
        let addButton = app.buttons["addItemButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 12))
        addButton.tap()

        let nameField = app.textFields["itemNameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 12))
        nameField.tap()
        nameField.typeText("Coffee")
        let priceField = app.textFields["itemPriceField"]
        priceField.tap()
        priceField.typeText("9.99")
        app.buttons["saveItemButton"].tap()

        XCTAssertTrue(app.staticTexts["Coffee"].waitForExistence(timeout: 12))

        // Now at the free limit (3 items) — next add should show paywall.
        addButton.tap()
        XCTAssertTrue(app.staticTexts["Creep Pro"].waitForExistence(timeout: 12), "Paywall did not appear after hitting the free item limit")
    }

    func testSettingsShowsCreepIndexStat() throws {
        let app = launchApp()
        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.staticTexts["Creep Index"].waitForExistence(timeout: 12))
    }

    func testKeyboardDismissesOnTapOutside() throws {
        let app = launchApp()
        let addButton = app.buttons["addItemButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 12))
        addButton.tap()

        let nameField = app.textFields["itemNameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 12))
        nameField.tap()
        nameField.typeText("Test")
        XCTAssertTrue(app.keyboards.element.exists)

        // Tap the form's section header (within the Form's own hit region,
        // where dismissKeyboardOnTap is actually attached) — "New Staple"
        // is distinct from the nav title "New Item" so this is unambiguous.
        app.staticTexts["New Staple"].tap()
        XCTAssertFalse(app.keyboards.element.exists, "Keyboard did not dismiss on tap-outside")
    }
}
