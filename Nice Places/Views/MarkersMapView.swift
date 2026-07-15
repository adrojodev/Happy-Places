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

    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var selectedItem: Place?
    @State private var showSheet: Bool = false
    
    var body: some View {
        ZStack (alignment: .bottomTrailing) {
            Map(position: $cameraPosition, selection: $selectedItem) {
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
                .buttonStyle(.borderedProminent)
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
            PlaceMapPreview(place: selectedItem)
                .presentationDetents([.fraction(0.3), .medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
    
    func getBackToUserLocation() {
        withAnimation(.spring) {
            cameraPosition = .userLocation(fallback: .automatic)
        }
    }
    
    func dismissSheet() {
        withAnimation(.bouncy) {
            selectedItem = nil
        }
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
