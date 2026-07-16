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
    @Environment(CloudKitSyncMonitor.self) private var syncMonitor

    @State private var locationManager = LocationDataManager.shared
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var selectedItem: Place?
    @State private var showSheet: Bool = false
    @State private var sheetDetent: PresentationDetent = .fraction(0.3)
    @State private var centerOnUserWhenAuthorized: Bool = false
    @State private var showLocationDeniedAlert: Bool = false

    var body: some View {
        ZStack (alignment: .bottomTrailing) {
            Map(position: $cameraPosition, selection: $selectedItem) {
                UserAnnotation()
                ForEach(places, id: \.self) { place in
                    place.mapMarker
                        .tag(place)
                }
            }
            VStack(alignment: .trailing, spacing: 12) {
                SyncStatusView(syncMonitor: syncMonitor)
                    .shadow(radius: 4, x: 0, y: 2)

                Button(action: getBackToUserLocation, label: {
                    Label("", systemImage: "location.fill")
                        .labelStyle(.iconOnly)
                        .font(.title)
                        .foregroundStyle(.background)
                })
                .buttonBorderShape(.circle)
                .controlSize(.extraLarge)
                .padding(.horizontal, -6)
                .shadow(radius: 8, x: 0, y: 4)
                .prominentActionStyle()
                .accessibilityIdentifier("centerOnUserButton")
            }
            .padding(.all, 24.0)
            
        }
        .mapStyle(.standard(elevation: .realistic))
        .onChange(of: selectedItem) {
            showSheet = selectedItem != nil
            // Runs on every selection change, so switching between markers
            // while the sheet is open re-centers the camera too.
            animateMapToPin()
        }
        .sheet(isPresented: $showSheet, onDismiss: dismissSheet) {
            PlaceMapPreview(place: selectedItem, detent: $sheetDetent)
                .presentationDetents([.fraction(0.3), .medium, .large], selection: $sheetDetent)
                .presentationDragIndicator(.visible)
        }
        .onChange(of: locationManager.authorizationStatus) {
            guard centerOnUserWhenAuthorized else { return }
            switch locationManager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                centerOnUserWhenAuthorized = false
                animateToUserLocation()
            case .denied, .restricted:
                centerOnUserWhenAuthorized = false
            default:
                break
            }
        }
        .alert("Location is off", isPresented: $showLocationDeniedAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Allow location access in Settings so the map can find you.")
        }
    }

    func getBackToUserLocation() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            // Ask first; the onChange above finishes the jump once granted.
            centerOnUserWhenAuthorized = true
            locationManager.requestAuthorizationIfNeeded()
        case .denied, .restricted:
            showLocationDeniedAlert = true
        default:
            animateToUserLocation()
        }
    }

    func animateToUserLocation() {
        withAnimation(.spring) {
            cameraPosition = .userLocation(fallback: .automatic)
        }
    }
    
    func dismissSheet() {
        withAnimation(.bouncy) {
            selectedItem = nil
        }
        sheetDetent = .fraction(0.3)
    }
    
    func animateMapToPin() {
        if let selectedItem = selectedItem {
            withAnimation(.spring) {
                cameraPosition = .camera(MapCamera(centerCoordinate: CLLocationCoordinate2D(latitude: selectedItem.latitude, longitude: selectedItem.longitude), distance: 1200.0))
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Place.self, configurations: config)

    MarkersMapView()
        .modelContainer(container)
        .environment(CloudKitSyncMonitor())
}
