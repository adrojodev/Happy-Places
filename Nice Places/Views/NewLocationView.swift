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
    @State private var latitude: Double?
    @State private var longitude: Double?
    
    @State var selectedColor: PlaceColor = PlaceColor.green
    
    var body: some View {
        NavigationStack {
            ZStack {
                Map(position: $cameraPosition)
                .mapStyle(.standard)
                .ignoresSafeArea(.all)
                .allowsHitTesting(/*@START_MENU_TOKEN@*/false/*@END_MENU_TOKEN@*/)
                .onMapCameraChange { camera in
                    latitude = camera.region.center.latitude
                    longitude = camera.region.center.longitude
                }
                
                if let lat = latitude, let lon = longitude {
                    EditNewLocationSheet(latitude: lat,
                                         longitude: lon,
                                         isShowing: $isSheetOpen,
                                         isTabbarShowing: $isTabbarShowing,
                                         selectedColor: $selectedColor)
                }
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
