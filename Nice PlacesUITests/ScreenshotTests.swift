//
//  ScreenshotTests.swift
//  Nice PlacesUITests
//
//  Seeds pretty demo data (isolated -uiTestStore) and captures App Store
//  screenshots as attachments. Run on the device size App Store Connect
//  wants (iPhone 17 Pro Max for 6.9"), non-cloned:
//    xcodebuild test ... -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' \
//      -only-testing:"Nice PlacesUITests/ScreenshotTests" -parallel-testing-enabled NO \
//      -resultBundlePath screenshots.xcresult
//  Then: xcrun xcresulttool export attachments --path screenshots.xcresult --output-path <dir>
//

import XCTest
import CoreLocation

final class ScreenshotTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func allowLocationIfAsked() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        for label in ["Allow While Using App", "Allow Once", "Allow"] {
            let allow = springboard.buttons[label]
            if allow.waitForExistence(timeout: 3) {
                allow.tap()
                return
            }
        }
    }

    func testCaptureAppStoreScreenshots() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestStore", "-uiTestReset"]
        app.launch()

        // (name, story, lat, lon) — spread around San Francisco so the map
        // tab and the pins look alive.
        let spots: [(String, String, Double, Double)] = [
            ("Sunset pier", "Where the city slows down and the sky shows off.", 37.8087, -122.4098),
            ("Best tacos in town", "Al pastor with extra pineapple. Always.", 37.7986, -122.4076),
            ("Our little café", "First date. Last table by the window.", 37.7925, -122.4147),
            ("Golden hour lookout", "Bring a blanket, trust me.", 37.8025, -122.4058),
            ("Secret picnic spot", "The grass really is softer here.", 37.8008, -122.4211)
        ]

        for (index, spot) in spots.enumerated() {
            XCUIDevice.shared.location = XCUILocation(
                location: CLLocation(latitude: spot.2, longitude: spot.3))
            Thread.sleep(forTimeInterval: 2)

            app.buttons["addPlaceButton"].firstMatch.tap()
            if index == 0 { allowLocationIfAsked() }

            let nameField = app.textFields["placeNameField"]
            XCTAssertTrue(nameField.waitForExistence(timeout: 15), "Save sheet never appeared")

            // If the simulated location didn't move far enough, dismiss the
            // duplicate warning and keep going.
            let noButton = app.buttons["duplicatePlaceNoButton"]
            if noButton.waitForExistence(timeout: 2) {
                noButton.tap()
            }

            nameField.tap()
            nameField.typeText(spot.0)

            // The story field is a vertical-axis TextField; it can surface as
            // either a text field or a text view. Best effort — skip if absent.
            let storyByPlaceholder = app.textFields["Tell your story here"]
            let storyField = storyByPlaceholder.exists ? storyByPlaceholder : app.textViews.firstMatch
            if storyField.exists {
                storyField.tap()
                storyField.typeText(spot.1)
            }

            if index == 2 {
                // A filled-in save sheet makes the best "saving a place" shot.
                capture(app, "04-save-sheet")
            }

            app.buttons["savePlaceButton"].tap()
            XCTAssertTrue(app.staticTexts[spot.0].waitForExistence(timeout: 10),
                          "\(spot.0) not visible in the list")
        }

        // 1: the list, full of happy places.
        Thread.sleep(forTimeInterval: 1)
        capture(app, "01-list")

        // 2: the map tab with all the pins (give tiles time to load).
        app.buttons["Map"].firstMatch.tap()
        Thread.sleep(forTimeInterval: 8)
        capture(app, "02-map")

        // 3: a place detail with its story.
        app.buttons["List"].firstMatch.tap()
        let row = app.staticTexts["Sunset pier"]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        Thread.sleep(forTimeInterval: 6)
        capture(app, "03-detail")
    }
}
