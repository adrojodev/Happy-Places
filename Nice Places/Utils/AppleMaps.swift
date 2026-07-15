//
//  AppleMaps.swift
//  Nice Places
//
//  Opening places in the Maps app.
//

import MapKit

enum AppleMaps {
    /// Opens the Maps app centered on the coordinate with a ~10km span.
    static func open(name: String, coordinate: CLLocationCoordinate2D) {
        let regionDistance: CLLocationDistance = 10000
        let region = MKCoordinateRegion(center: coordinate,
                                        latitudinalMeters: regionDistance,
                                        longitudinalMeters: regionDistance)
        let options = [
            MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: region.center),
            MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: region.span),
        ]
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        mapItem.name = name
        mapItem.openInMaps(launchOptions: options)
    }
}
