//
//  MapView.swift
//  Nice Places
//
//  Created by Alan David Hernández Trujillo on 10/02/24.
//

import SwiftUI
import MapKit

struct MapView: View {
    let latitude: Double
    let longitude: Double
    let name: String
    let icon: String
    let color: Color
    
    @State private var region: MapCameraPosition = .automatic
    
    var body: some View {
        NavigationStack {
            ZStack {
                Map(position: $region) {
                    Marker(name, systemImage: icon, coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
                        .tint(color)
                }
                .mapControls {
                    MapCompass()
                }
                .controlSize(.regular)
                
                VStack {
                    Button("Take me here", systemImage: "location.fill") {
                        let regionDistance:CLLocationDistance = 10000
                        let coordinates = CLLocationCoordinate2DMake(latitude, longitude)
                        let regionSpan = MKCoordinateRegion(center: coordinates, latitudinalMeters: regionDistance, longitudinalMeters: regionDistance)
                        let options = [
                            MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: regionSpan.center),
                            MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: regionSpan.span)
                        ]
                        let placemark = MKPlacemark(coordinate: coordinates, addressDictionary: nil)
                        let mapItem = MKMapItem(placemark: placemark)
                        mapItem.name = name
                        mapItem.openInMaps(launchOptions: options)
                    }
                    .buttonStyle(.plain)
                    .font(.body)
                    .fontWeight(.semibold)
                    .padding([.horizontal], 32)
                    .padding([.vertical],16)
                    .background(color)
                    .foregroundColor(color == .yellow ? .black : .white)
                    .cornerRadius(.infinity)
                }
                .padding([.bottom], 32)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .shadow(radius: 10, x: 0, y: 8)
            }
        }
        .onAppear(perform: {
            region = .region(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude), span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)))
        })
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

#Preview {
    MapView(latitude: 25.761681, longitude: -80.191788, name: "Name", icon: "mappin", color: .accentColor)
}
