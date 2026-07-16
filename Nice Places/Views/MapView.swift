//
//  MapView.swift
//  Nice Places
//
//  Created by Alan David Hernández Trujillo on 10/02/24.
//

import SwiftUI
import MapKit
import SwiftData

struct MapView: View {
    let place: Place

    @State private var region: MapCameraPosition = .automatic
    @State private var showMapsChooser = false

    var body: some View {
        ZStack {
            Map(position: $region) {
                place.mapMarker
            }
            .mapControls {
                MapCompass()
            }
            .controlSize(.regular)

            VStack {
                Button("Open in Maps", systemImage: "map.fill") {
                    showMapsChooser = true
                }
                .tint(place.uiColor)
                .prominentActionStyle()
                .buttonBorderShape(.capsule)
                .controlSize(.large)
                .font(.body)
                .fontWeight(.semibold)
                .mapsChooser(isPresented: $showMapsChooser, name: place.name, coordinate: place.coordinate)
            }
            .padding([.bottom], 32)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .shadow(radius: 10, x: 0, y: 8)
        }
        .onAppear(perform: {
            region = .region(MKCoordinateRegion(center: place.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)))
        })
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Place.self, configurations: config)

    MapView(place: Place(color: "blue",
                         createdDate: Date(),
                         icon: "mappin",
                         latitude: 25.761681,
                         longitude: -80.191788,
                         name: "Name",
                         text: ""))
        .modelContainer(container)
}
