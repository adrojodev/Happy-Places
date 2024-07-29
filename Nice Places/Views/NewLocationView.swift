//
//  NewLocationView.swift
//  Nice Places
//
//  Created by Alan David Hernández Trujillo on 09/02/24.
//

import SwiftUI
import MapKit


struct NewLocationView: View {
    @Binding var isTabbarShowing: Bool
    
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var isSheetOpen: Bool = false
    @State private var placeName: String = ""
    @State private var placeDescription: String = ""
    @State private var latitude: Double = 19.432608
    @State private var longitude: Double = -99.133209
    
    @State var selectedColor: PlaceColor = PlaceColor.green
    
    var body: some View {
        NavigationStack {
            ZStack {
                Map(position: $cameraPosition) {
                    Marker(coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude)) {
                        Image(systemName: "mappin")
                    }
                    .tint(selectedColor.wrappedValue)
                }
                    .mapStyle(.standard)
                    .ignoresSafeArea(.all)
                    .allowsHitTesting(/*@START_MENU_TOKEN@*/false/*@END_MENU_TOKEN@*/)
                    .onMapCameraChange { mapCameraUpdateContext in
                        latitude = mapCameraUpdateContext.camera.centerCoordinate.latitude
                        longitude = mapCameraUpdateContext.camera.centerCoordinate.longitude
                    }
                
                EditNewLocationSheet(latitude: latitude,
                                     longitude: longitude,
                                     isShowing: $isSheetOpen, 
                                     isTabbarShowing: $isTabbarShowing,
                                     selectedColor: $selectedColor)
            }
            .navigationBarTitle("", displayMode: .inline)
            .onAppear {
                CLLocationManager().requestWhenInUseAuthorization()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isSheetOpen = true
                }
            }
        }
        .onAppear(perform: {
            isTabbarShowing = false
        })
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}


#Preview {
    NewLocationView(isTabbarShowing:  .constant(false))
}
