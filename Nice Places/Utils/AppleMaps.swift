//
//  AppleMaps.swift
//  Nice Places
//
//  Opening places in Apple Maps or Google Maps.
//

import MapKit
import SwiftUI
import UIKit

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

enum GoogleMaps {
    /// Opens the Google Maps app when installed, its web version otherwise.
    static func open(name: String, coordinate: CLLocationCoordinate2D) {
        let query = "\(coordinate.latitude),\(coordinate.longitude)"
        if let appURL = URL(string: "comgooglemaps://?q=\(query)"),
           UIApplication.shared.canOpenURL(appURL) {
            UIApplication.shared.open(appURL)
        } else if let webURL = URL(string: "https://www.google.com/maps/search/?api=1&query=\(query)") {
            UIApplication.shared.open(webURL)
        }
    }
}

extension View {
    /// "Let's go" chooser: pick Apple Maps or Google Maps for a place.
    func mapsChooser(isPresented: Binding<Bool>, name: String, coordinate: CLLocationCoordinate2D) -> some View {
        confirmationDialog("How do we get there?", isPresented: isPresented, titleVisibility: .visible) {
            Button("Apple Maps") {
                AppleMaps.open(name: name, coordinate: coordinate)
            }
            Button("Google Maps") {
                GoogleMaps.open(name: name, coordinate: coordinate)
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}
