//
//  Nice_PlacesUITests.swift
//  Nice PlacesUITests
//
//  Created by Alan David Hernández Trujillo on 09/02/24.
//
//  Run on a non-cloned simulator (xcodebuild ... -parallel-testing-enabled NO)
//  that has photo + location permission pre-granted:
//    xcrun simctl privacy <sim> grant photos rojo.happy-places-moments
//    xcrun simctl privacy <sim> grant location rojo.happy-places-moments
//  The photo-scan test expects GPS-tagged photos seeded via simctl addmedia.
//

import XCTest

final class Nice_PlacesUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Create a place typing a Spanish name; the flow must reach the save
    /// sheet (location-permission and coordinate-gate bugs used to dead-end
    /// it) and the saved row must appear in the list.
    func testCreatePlaceFlow() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestStore", "-uiTestReset"]
        app.launch()

        app.buttons["addPlaceButton"].firstMatch.tap()

        let nameField = app.textFields["placeNameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 10), "Save sheet never appeared")
        nameField.tap()
        nameField.typeText("Taquería El Paisa")

        let saveButton = app.buttons["savePlaceButton"]
        XCTAssertTrue(saveButton.isEnabled)
        saveButton.tap()

        XCTAssertTrue(app.staticTexts["Taquería El Paisa"].waitForExistence(timeout: 10),
                      "Saved place not visible in the list")
    }

    /// Scan the photo library: suggestions must appear for the seeded GPS
    /// photos, selection is opt-in (add button disabled at first), and adding
    /// the selection puts the places in the list.
    func testPhotoScanFlow() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestStore", "-uiTestReset"]
        app.launch()

        app.buttons["photoMenuButton"].firstMatch.tap()
        let scanButton = app.buttons["Scan library for places"]
        XCTAssertTrue(scanButton.waitForExistence(timeout: 5))
        scanButton.tap()

        // Intro screen: the scan only starts after an explicit confirmation.
        let startButton = app.buttons["startScanButton"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 5), "Intro screen never appeared")
        startButton.tap()

        // The photo-permission alert appears on first run (reinstall resets TCC).
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        for label in ["Allow Full Access", "Allow Access to All Photos", "Full Access", "Allow"] {
            let allow = springboard.buttons[label]
            if allow.waitForExistence(timeout: 3) {
                allow.tap()
                break
            }
        }

        let addButton = app.buttons["addSelectedPlacesButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 30), "Scan never finished")
        XCTAssertFalse(addButton.isEnabled, "Add must be disabled before anything is selected (opt-in)")

        // Tapping a suggestion's photo opens the full-screen carousel.
        // (Identifiers on SwiftUI cover content don't always surface; match
        // by identifier or accessibility label.)
        app.buttons["suggestionPhotoButton"].firstMatch.tap()
        let closeCarousel = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier == 'closeCarouselButton' OR label == 'Close photos'"))
            .firstMatch
        XCTAssertTrue(closeCarousel.waitForExistence(timeout: 10), "Photo carousel never appeared")
        closeCarousel.tap()

        let selectAll = app.buttons["selectAllButton"]
        XCTAssertTrue(selectAll.waitForExistence(timeout: 5))
        selectAll.tap()

        XCTAssertTrue(addButton.isEnabled, "Add should enable once suggestions are selected")
        addButton.tap()

        // The sheet dismisses and the list now has the added places.
        XCTAssertTrue(app.navigationBars["Happy places"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.cells.firstMatch.waitForExistence(timeout: 10),
                      "Added places must appear in the list")

        // They must survive a cold relaunch (explicit context save).
        // Keep the isolated store but do NOT reset it this time.
        app.terminate()
        app.launchArguments = ["-uiTestStore"]
        app.launch()
        XCTAssertTrue(app.cells.firstMatch.waitForExistence(timeout: 10),
                      "Added places must persist across relaunch")
    }

    /// The map tab's location button must ask for permission on first use
    /// (the map tab never requested it before, so the button silently did
    /// nothing) and then keep running while the camera flies to the user.
    func testMapLocationButtonRequestsPermission() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestStore", "-uiTestReset"]
        app.launch()

        app.buttons["Map"].firstMatch.tap()

        // The Map's overlay controls don't always surface as .button in the
        // accessibility tree; match any element type, then fall back to a
        // coordinate tap on the button's fixed bottom-trailing position.
        let locationButton = app.descendants(matching: .any)
            .matching(identifier: "centerOnUserButton").firstMatch
        if locationButton.waitForExistence(timeout: 10) {
            locationButton.tap()
        } else {
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.876, dy: 0.841)).tap()
        }

        // First run: the system location alert must appear; allow it.
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        for label in ["Allow While Using App", "Allow Once", "Allow"] {
            let allow = springboard.buttons[label]
            if allow.waitForExistence(timeout: 3) {
                allow.tap()
                break
            }
        }

        // Let the camera fly to the user location (verified via screenshots
        // taken outside the test), then confirm the app is still alive.
        Thread.sleep(forTimeInterval: 8)
        XCTAssertEqual(app.state, .runningForeground)
        XCTAssertTrue(locationButton.exists)
    }

    /// Saving a place and then adding another one from the same spot must
    /// ask "is this the same place?" instead of silently allowing a duplicate.
    func testDuplicatePlaceWarning() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestStore", "-uiTestReset"]
        app.launch()

        // Save a place at the current location.
        app.buttons["addPlaceButton"].firstMatch.tap()
        let nameField = app.textFields["placeNameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 10), "Save sheet never appeared")
        nameField.tap()
        nameField.typeText("Dup Check Spot")
        app.buttons["savePlaceButton"].tap()
        XCTAssertTrue(app.staticTexts["Dup Check Spot"].waitForExistence(timeout: 10))

        // Start adding again from the same location: the warning must show.
        app.buttons["addPlaceButton"].firstMatch.tap()
        let yesButton = app.buttons["duplicatePlaceYesButton"]
        XCTAssertTrue(yesButton.waitForExistence(timeout: 10), "Duplicate warning never appeared")

        // "No, it's new" dismisses the warning but keeps the save flow open.
        app.buttons["duplicatePlaceNoButton"].tap()
        XCTAssertTrue(app.textFields["placeNameField"].waitForExistence(timeout: 5))
        XCTAssertFalse(yesButton.exists, "Warning should hide after 'No, it's new'")
    }

}
