//
//  PlaceMapPreview.swift
//  Happy Places
//
//  Created by Alan David Hernández Trujillo on 31/07/24.
//

import SwiftUI
import MapKit

struct PlaceMapPreview: View {
    let place: Place?
    
    var body: some View {
        VStack (alignment: .leading, spacing: 24.0) {
            HStack (alignment: .top, spacing: 16.0) {
                Text(place?.name ?? "Happy Place")
                    .font(.system(size: 32.0, weight: .bold))
                Spacer()
                Button("Let's go", systemImage: "location.fill") {
                    let regionDistance:CLLocationDistance = 10000
                    let coordinates = CLLocationCoordinate2DMake(place?.latitude ?? 12.64654, place?.longitude ?? -122.86453)
                    let regionSpan = MKCoordinateRegion(center: coordinates, latitudinalMeters: regionDistance, longitudinalMeters: regionDistance)
                    let options = [
                        MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: regionSpan.center),
                        MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: regionSpan.span)
                    ]
                    let placemark = MKPlacemark(coordinate: coordinates, addressDictionary: nil)
                    let mapItem = MKMapItem(placemark: placemark)
                    mapItem.name = place?.name ?? "Happy place"
                    mapItem.openInMaps(launchOptions: options)
                }
                .tint(PlaceColor(rawValue: place?.color ?? "green")?.wrappedValue ?? .accentColor)
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
            }
            Text(place?.text ?? "This is my happy place...")
        }
        .padding(.horizontal, 16.0)
        .padding(.top, 24.0)
    }
}
