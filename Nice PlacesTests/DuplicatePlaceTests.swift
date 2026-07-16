//
//  DuplicatePlaceTests.swift
//  Nice PlacesTests
//

import XCTest
import CoreLocation
@testable import Happy_Places

final class DuplicatePlaceTests: XCTestCase {

    private func place(_ name: String, _ lat: Double, _ lon: Double) -> Place {
        Place(color: "green",
              createdDate: Date(),
              icon: "mappin",
              latitude: lat,
              longitude: lon,
              name: name,
              text: "")
    }

    func testFindsPlaceWithinRadius() {
        // ~55m away (0.0005 deg latitude)
        let saved = [place("Taquería", 19.4326, -99.1332)]
        let here = CLLocationCoordinate2D(latitude: 19.4331, longitude: -99.1332)
        XCTAssertEqual(EditNewLocationSheet.nearestSavedPlace(to: here, in: saved)?.name, "Taquería")
    }

    func testIgnoresPlaceOutsideRadius() {
        // ~550m away (0.005 deg latitude)
        let saved = [place("Taquería", 19.4326, -99.1332)]
        let here = CLLocationCoordinate2D(latitude: 19.4376, longitude: -99.1332)
        XCTAssertNil(EditNewLocationSheet.nearestSavedPlace(to: here, in: saved))
    }

    func testPicksTheClosestOfSeveral() {
        let saved = [
            place("Farther", 19.4334, -99.1332),   // ~90m
            place("Closer", 19.4328, -99.1332),    // ~20m
        ]
        let here = CLLocationCoordinate2D(latitude: 19.4326, longitude: -99.1332)
        XCTAssertEqual(EditNewLocationSheet.nearestSavedPlace(to: here, in: saved)?.name, "Closer")
    }

    func testEmptyListReturnsNil() {
        let here = CLLocationCoordinate2D(latitude: 19.4326, longitude: -99.1332)
        XCTAssertNil(EditNewLocationSheet.nearestSavedPlace(to: here, in: []))
    }

    func testExactRadiusBoundaryCounts() {
        let here = CLLocationCoordinate2D(latitude: 19.4326, longitude: -99.1332)
        let saved = [place("Edge", 19.4326, -99.1332)]
        XCTAssertNotNil(EditNewLocationSheet.nearestSavedPlace(to: here, in: saved, within: 0))
    }
}
