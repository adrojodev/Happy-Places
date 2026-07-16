//
//  WidgetPlacesStore.swift
//  Nice Places
//
//  Compiled into BOTH the app and the widget extension.
//

import Foundation
import CoreLocation

/// Lightweight snapshot of saved places the app shares with its widgets
/// through the App Group container. The widget never opens the SwiftData
/// store — this JSON file is the only bridge, so the CloudKit-synced store
/// URL and schema stay untouched.
struct WidgetPlacesSnapshot: Codable {
    struct Item: Codable, Identifiable, Hashable {
        var id: String
        var name: String
        var icon: String
        var color: String
        var latitude: Double
        var longitude: Double

        var coordinate: CLLocationCoordinate2D {
            CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }

        func distanceMeters(from coordinate: CLLocationCoordinate2D) -> CLLocationDistance {
            CLLocation(latitude: latitude, longitude: longitude)
                .distance(from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
        }
    }

    /// Most recently created first (the fallback order when location is unknown).
    var places: [Item] = []
    var lastLatitude: Double?
    var lastLongitude: Double?
    var updatedAt: Date = Date()

    /// Where the user was when the app last published the snapshot.
    var lastKnownCoordinate: CLLocationCoordinate2D? {
        guard let lastLatitude, let lastLongitude else { return nil }
        return CLLocationCoordinate2D(latitude: lastLatitude, longitude: lastLongitude)
    }

    /// The `limit` places closest to `coordinate`; most recent ones when
    /// no coordinate is available.
    func nearestPlaces(to coordinate: CLLocationCoordinate2D?, limit: Int) -> [Item] {
        guard let coordinate else { return Array(places.prefix(limit)) }
        return Array(
            places
                .sorted { $0.distanceMeters(from: coordinate) < $1.distanceMeters(from: coordinate) }
                .prefix(limit)
        )
    }
}

enum WidgetPlacesStore {
    private static var fileURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: QuickActionChannel.appGroupID)?
            .appending(path: "widget-places.json")
    }

    static func read() -> WidgetPlacesSnapshot {
        guard let fileURL,
              let data = try? Data(contentsOf: fileURL),
              let snapshot = try? JSONDecoder().decode(WidgetPlacesSnapshot.self, from: data) else {
            return WidgetPlacesSnapshot()
        }
        return snapshot
    }

    static func write(_ snapshot: WidgetPlacesSnapshot) {
        guard let fileURL, let data = try? JSONEncoder().encode(snapshot) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
