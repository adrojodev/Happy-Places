//
//  Place+UI.swift
//  Nice Places
//
//  Shared UI-facing accessors for Place.
//

import SwiftUI
import MapKit
import CoreLocation

extension Place {
    /// UI color for this place; falls back to green (the model default).
    var uiColor: Color {
        (PlaceColor(rawValue: color) ?? .green).color
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var formattedDate: String {
        createdDate.formatted(.dateTime.day().month().year())
    }

    /// Standard tinted map marker for this place.
    var mapMarker: some MapContent {
        Marker(name, systemImage: icon, coordinate: coordinate)
            .tint(uiColor)
    }
}
