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
    @State private var selectedItem: Place?
    @State private var showSheet: Bool = false
    
    var body: some View {
        ZStack (alignment: .bottomTrailing) {
            Map(position: $cameraPosition, selection: $selectedItem) {
                ForEach(places, id: \.self) { place in
                    Marker(place.name, systemImage: place.icon, coordinate: CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude))
                        .tint(PlaceColor(rawValue: place.color)?.wrappedValue ?? .accentColor)
                        .tag(place)
                        
                }
            }
            VStack(alignment: .trailing) {
                Button(action: getBackToUserLocation, label: {
                    Label("", systemImage: "location.fill")
                        .labelStyle(.iconOnly)
                        .font(.title)
                        .foregroundStyle(.background)
                })
                .buttonBorderShape(.circle)
                .buttonStyle(.borderedProminent)
                .controlSize(.extraLarge)
                .padding(.all, 24.0)
                .shadow(radius: 10, x: 0, y: 8)
            }
            
        }
        .mapStyle(.standard(elevation: .realistic))
        .onChange(of: selectedItem) {
            showSheet = selectedItem != nil
        }
        .sheet(isPresented: $showSheet, onDismiss: dismissSheet) {
            PlaceMapPreview(place: selectedItem)
                .presentationDetents([.fraction(0.3), .medium, .large])
            .presentationDragIndicator(.visible)
            .onAppear() {
                animateMapToPin()
            }
            Spacer()
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
    MarkersMapView()
}
