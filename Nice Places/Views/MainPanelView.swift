//
//  MainPanelView.swift
//  Happy Places
//
//  Created by Alan David Hernández Trujillo on 10/09/25.
//

import SwiftUI
import MapKit
import SwiftData

struct MainPanelView: View {
    @Query(sort: \Place.createdDate) var places: [Place]
    
    @State private var region: MapCameraPosition = .automatic
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var selectedItem: Place?
    @State private var latitude: CLLocationDegrees = -11.919188
    @State private var longitude: CLLocationDegrees = -77.036648
    
    let color: Color = .accent
    
    var body: some View {
        VStack(alignment: .leading) {
            Map(position: $cameraPosition) {
                ForEach(places, id: \.self) { place in
                    Marker(place.name, systemImage: place.icon, coordinate: CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude))
                        .tint(PlaceColor(rawValue: place.color)?.wrappedValue ?? .accentColor)
                        .tag(place)
                    
                }
            }
            .mapStyle(.standard)
            .onMapCameraChange { camera in
                latitude = camera.region.center.latitude
                longitude = camera.region.center.longitude
            }
        }
        .navigationBarTitle("", displayMode: .inline)
        .onAppear {
            CLLocationManager().requestWhenInUseAuthorization()
        }
        .cornerRadius(12.0)
        .frame(width: 350.0, height: 600.0)
        .background(Gradient(colors: [.material, .materialDark]))
        .overlay(
            RoundedRectangle(cornerRadius: 16.0, style: .continuous)
                .stroke(.materialBlackDarker, lineWidth: 1.5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16.0)
                .stroke(Gradient(colors: [.material, .materialDark]), lineWidth: 12.0)
                .padding(-6.0)
                .overlay(
                    RoundedRectangle(cornerRadius: 22.0)
                        .stroke(Gradient(colors: [.materialDark, .materialDarker]), lineWidth: 1.0)
                        .padding(-12.0)
                )
        )
        .padding(.all, 12.0)
        SelectIconButton(latitude: $latitude, longitude: $longitude)
    }
}

#Preview {
    MainPanelView()
}
