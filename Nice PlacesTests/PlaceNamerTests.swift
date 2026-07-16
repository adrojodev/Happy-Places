//
//  PlaceNamerTests.swift
//  Nice PlacesTests
//

import XCTest
import MapKit
@testable import Happy_Places

final class PlaceNamerTests: XCTestCase {

    private func poi(_ name: String, _ meters: Double,
                     _ category: MKPointOfInterestCategory? = nil) -> PlaceNamer.POICandidate {
        PlaceNamer.POICandidate(name: name, category: category, distanceMeters: meters)
    }

    func testClosestPOIWins() {
        let result = PlaceNamer.baselineName(pois: [poi("Farther Café", 70), poi("Museo Nacional", 20, .museum)],
                                             areasOfInterest: ["Centro"],
                                             placemarkName: "Calle 5 de Mayo 12",
                                             locality: "CDMX")
        XCTAssertEqual(result?.name, "Museo Nacional")
        XCTAssertEqual(result?.poiCategory, .museum)
    }

    func testFarPOIsAreIgnored() {
        let result = PlaceNamer.baselineName(pois: [poi("Stadium", 500)],
                                             areasOfInterest: ["Parque México"],
                                             placemarkName: "Av. México 51",
                                             locality: "CDMX")
        XCTAssertEqual(result?.name, "Parque México")
        XCTAssertNil(result?.poiCategory)
    }

    func testFallsBackToPlacemarkNameThenLocality() {
        XCTAssertEqual(PlaceNamer.baselineName(pois: [],
                                               areasOfInterest: [],
                                               placemarkName: "Av. México 51",
                                               locality: "CDMX")?.name,
                       "Av. México 51")
        XCTAssertEqual(PlaceNamer.baselineName(pois: [],
                                               areasOfInterest: [],
                                               placemarkName: nil,
                                               locality: "CDMX")?.name,
                       "CDMX")
    }

    func testNothingKnownReturnsNil() {
        XCTAssertNil(PlaceNamer.baselineName(pois: [],
                                             areasOfInterest: [],
                                             placemarkName: nil,
                                             locality: nil))
        XCTAssertNil(PlaceNamer.baselineName(pois: [],
                                             areasOfInterest: [""],
                                             placemarkName: "",
                                             locality: ""))
    }

    func testAIAvailabilityFlagDoesNotCrashAnywhere() {
        // On simulators/old devices this must simply be false, never throw.
        _ = PlaceNamer.isAINamingAvailable
    }
}
