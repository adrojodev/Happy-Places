//
//  NewLocationView.swift
//  Nice Places
//
//  Created by Alan David Hernández Trujillo on 09/02/24.
//

import SwiftUI
import MapKit
import CoreLocation


struct NewLocationView: View {
    @Binding var isTabbarShowing: Bool
    var preloadedPhoto: PlacePhoto?
    var photoLatitude: Double?
    var photoLongitude: Double?

    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var isSheetOpen: Bool = false
    @State private var latitude: Double?
    @State private var longitude: Double?
    @State private var hasValidLocation: Bool = false

    @State var selectedColor: PlaceColor = PlaceColor.green

    init(isTabbarShowing: Binding<Bool>, preloadedPhoto: PlacePhoto? = nil, photoLatitude: Double? = nil, photoLongitude: Double? = nil) {
        self._isTabbarShowing = isTabbarShowing
        self.preloadedPhoto = preloadedPhoto
        self.photoLatitude = photoLatitude
        self.photoLongitude = photoLongitude
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Map(position: $cameraPosition)
                .mapStyle(.standard)
                .ignoresSafeArea(.all)
                .allowsHitTesting(/*@START_MENU_TOKEN@*/false/*@END_MENU_TOKEN@*/)
                .onMapCameraChange { camera in
                    let newLat = camera.region.center.latitude
                    let newLon = camera.region.center.longitude

                    // Only update if we have a photo location OR if the location looks valid (not default)
                    if photoLatitude != nil {
                        // Photo location - use it immediately
                        latitude = newLat
                        longitude = newLon
                        if !hasValidLocation {
                            hasValidLocation = true
                        }
                    } else {
                        // User location - validate it's not a default/zero location
                        // Default coordinates are often 0,0 or very round numbers
                        if abs(newLat) > 0.1 && abs(newLon) > 0.1 {
                            latitude = newLat
                            longitude = newLon
                            if !hasValidLocation {
                                hasValidLocation = true
                                // Only open sheet once we have valid location
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    isSheetOpen = true
                                }
                            }
                        }
                    }
                }

                if hasValidLocation {
                    EditNewLocationSheet(latitude: $latitude,
                                         longitude: $longitude,
                                         isShowing: $isSheetOpen,
                                         selectedColor: $selectedColor,
                                         preloadedPhoto: preloadedPhoto)
                }
            }
            .navigationBarTitle("", displayMode: .inline)
            .onAppear {
                // If we have a photo location, set the camera position to that location
                if let photoLat = photoLatitude, let photoLon = photoLongitude {
                    let photoCoordinate = CLLocationCoordinate2D(latitude: photoLat, longitude: photoLon)
                    cameraPosition = .region(MKCoordinateRegion(
                        center: photoCoordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                    ))
                    latitude = photoLat
                    longitude = photoLon
                    hasValidLocation = true
                    // Photo location is set immediately, can open sheet sooner
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isSheetOpen = true
                    }
                } else {
                    CLLocationManager().requestWhenInUseAuthorization()
                    // For user location, sheet will open when hasValidLocation becomes true
                    // (triggered by onMapCameraChange once we get real coordinates)
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
