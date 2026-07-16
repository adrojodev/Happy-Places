//
//  WidgetSync.swift
//  Nice Places
//
//  App-side publisher for the widget snapshot (app target only).
//

import Foundation
import SwiftData
import WidgetKit
import CoreLocation

/// Publishes the shared widget snapshot whenever app data may have changed
/// (called from the app root on launch and when the app goes to background).
enum WidgetSync {
    @MainActor
    static func publish(from context: ModelContext) {
        let descriptor = FetchDescriptor<Place>(sortBy: [SortDescriptor(\.createdDate, order: .reverse)])
        guard let places = try? context.fetch(descriptor) else { return }

        var snapshot = WidgetPlacesSnapshot()
        snapshot.places = places.prefix(200).map { place in
            WidgetPlacesSnapshot.Item(
                id: "\(place.latitude)|\(place.longitude)|\(place.name)",
                name: place.name,
                icon: place.icon,
                color: place.color,
                latitude: place.latitude,
                longitude: place.longitude
            )
        }

        // Cached fix from the app's own location use; nil is fine — the
        // widget falls back to its own cached location or recent places.
        if let coordinate = CLLocationManager().location?.coordinate {
            snapshot.lastLatitude = coordinate.latitude
            snapshot.lastLongitude = coordinate.longitude
        }

        WidgetPlacesStore.write(snapshot)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
