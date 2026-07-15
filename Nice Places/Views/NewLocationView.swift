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
        ZStack {
            Map(position: $cameraPosition)
            .mapStyle(.standard)
            .ignoresSafeArea(.all)
            .allowsHitTesting(false)
            .onMapCameraChange { camera in
                // The map is non-interactive: its center (user location, or the
                // photo's location) is where the new place goes. No coordinate
                // "validity" filtering — that used to dead-end the save sheet
                // when location was denied or near lat/lon 0.
                latitude = camera.region.center.latitude
                longitude = camera.region.center.longitude
                if !hasValidLocation {
                    hasValidLocation = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isSheetOpen = true
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
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            isTabbarShowing = false
            if let photoLat = photoLatitude, let photoLon = photoLongitude {
                // Center on the photo's location instead of the user.
                cameraPosition = .region(MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: photoLat, longitude: photoLon),
                    span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                ))
                latitude = photoLat
                longitude = photoLon
            } else {
                LocationDataManager.shared.requestAuthorizationIfNeeded()
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}


#Preview {
    NewLocationView(isTabbarShowing:  .constant(false))
}
