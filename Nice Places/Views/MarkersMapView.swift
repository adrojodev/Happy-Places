//
//  MarkersMapView.swift
//  Nice Places
//
//  Created by Alan David Hernández Trujillo on 19/02/24.
//

import SwiftUI
import MapKit
import SwiftData

struct MarkersMapView: View {
    @Query(sort: \Place.createdDate) var places: [Place]
    
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var selectedItem: MKMapItem?
    
    var body: some View {
        Map(position: $cameraPosition, selection: $selectedItem) {
            ForEach(places) { place in
                Marker(place.name, systemImage: place.icon, coordinate: CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude))
                    .tint(PlaceColor(rawValue: place.color)?.wrappedValue ?? .accentColor)
            }
        }
        .mapStyle(.standard(elevation: .realistic))
    }
}

#Preview {
    MarkersMapView()
}
