//
//  PlacesWidgetSnapshotTests.swift
//  Nice PlacesTests
//
//  Covers the app <-> widget bridge: snapshot JSON, nearest-place ordering,
//  and quick-action deep links.
//

import XCTest
import CoreLocation
@testable import Happy_Places

final class PlacesWidgetSnapshotTests: XCTestCase {

    private func item(_ name: String, lat: Double, lon: Double) -> WidgetPlacesSnapshot.Item {
        WidgetPlacesSnapshot.Item(id: name, name: name, icon: "mappin", color: "green",
                                  latitude: lat, longitude: lon)
    }

    func testNearestPlacesSortsByDistance() {
        var snapshot = WidgetPlacesSnapshot()
        snapshot.places = [
            item("far", lat: 1.0, lon: 0),
            item("close", lat: 0.001, lon: 0),
            item("middle", lat: 0.1, lon: 0)
        ]

        let nearest = snapshot.nearestPlaces(to: CLLocationCoordinate2D(latitude: 0, longitude: 0), limit: 2)
        XCTAssertEqual(nearest.map(\.name), ["close", "middle"])
    }

    func testNearestPlacesFallsBackToRecencyWithoutLocation() {
        var snapshot = WidgetPlacesSnapshot()
        snapshot.places = [
            item("newest", lat: 1, lon: 1),
            item("older", lat: 2, lon: 2),
            item("oldest", lat: 3, lon: 3)
        ]

        let fallback = snapshot.nearestPlaces(to: nil, limit: 2)
        XCTAssertEqual(fallback.map(\.name), ["newest", "older"])
    }

    func testSnapshotRoundTripsThroughJSON() throws {
        var snapshot = WidgetPlacesSnapshot()
        snapshot.places = [item("pier", lat: 25.76, lon: -80.19)]
        snapshot.lastLatitude = 25.7
        snapshot.lastLongitude = -80.2

        let data = try JSONEncoder().encode(snapshot)
        let decoded = try JSONDecoder().decode(WidgetPlacesSnapshot.self, from: data)

        XCTAssertEqual(decoded.places, snapshot.places)
        XCTAssertEqual(decoded.lastLatitude, snapshot.lastLatitude)
        XCTAssertEqual(decoded.lastLongitude, snapshot.lastLongitude)
    }

    func testQuickActionDeepLinksRoundTrip() {
        for action in QuickAction.allCases {
            XCTAssertEqual(QuickAction(url: action.url), action)
        }
        XCTAssertNil(QuickAction(url: URL(string: "happyplaces://unknown")!))
        XCTAssertNil(QuickAction(url: URL(string: "https://add-place")!))
    }
}
