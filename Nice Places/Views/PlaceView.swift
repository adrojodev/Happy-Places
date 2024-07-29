//
//  PlaceView.swift
//  Nice Places
//
//  Created by Alan David Hernández Trujillo on 10/02/24.
//

import SwiftUI
import MapKit

struct PlaceView: View {
    @Bindable var place: Place
    @Binding var isTabbarShowing: Bool
    
    @State private var region: MapCameraPosition = .automatic
    @State private var isEditing: Bool = false
    @State private var selectedColor: PlaceColor = PlaceColor.green
    
    
    var body: some View {
        let formattedDate: String = place.createdDate.formatted(.dateTime.day().month().year())
        
        NavigationStack {
            VStack (alignment: .leading, 
                    spacing: 16.0) {
                NavigationLink(destination: MapView(latitude: place.latitude,
                                                    longitude: place.longitude,
                                                    name: place.name,
                                                    icon: place.icon,
                                                    color: PlaceColor(rawValue: place.color)?.wrappedValue ?? .accentColor)) {
                    Map(position: $region) {
                        Marker(place.name,
                               systemImage: place.icon,
                               coordinate: CLLocationCoordinate2D(latitude: place.latitude,
                                                                  longitude: place.longitude))
                        .tint(selectedColor.wrappedValue)
                    }
                    .frame(maxWidth: .infinity, maxHeight: 300)
                    .cornerRadius(16.0)
                }

                VStack (alignment: .leading, 
                        spacing: 8.0) {
                    if (isEditing) {
                        VStack (alignment: .leading, 
                                spacing: 2.0) {
                            HStack {
                                TextField(place.name, text: $place.name, axis: .vertical)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.title)
                                    .fontWeight(.bold)
                                Spacer()
                                SelectIconButton(selectedIcon: $place.icon, selectedColor: $selectedColor)
                                Button("Done", systemImage: "checkmark.circle.fill") {
                                    place.color = selectedColor.rawValue
                                    isEditing = false
                                }
                                .buttonStyle(.bordered)
                                .buttonBorderShape(.capsule)
                                .tint(selectedColor.wrappedValue)
                            }
                            Text(formattedDate)
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                        TextField(place.text, text: $place.text, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .font(.body)
                    } else {
                        VStack (alignment: .leading, 
                                spacing: 2.0) {
                            HStack {
                                Text(place.name)
                                    .font(.title)
                                    .fontWeight(.bold)
                                Spacer()
                                Button("Edit", systemImage: "pencil") {
                                    isEditing = true
                                }
                                .buttonStyle(.borderedProminent)
                                .buttonBorderShape(.capsule)
                                .tint(selectedColor.wrappedValue)
                                .foregroundColor(PlaceColor(rawValue: place.color)?.wrappedValue == .yellow ? .black : .white)
                            }
                            Text(formattedDate)
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                        Text(place.text)
                            .font(.body)
                    }
                }
                Spacer()
            }
            .onAppear(perform: {
                selectedColor = PlaceColor(rawValue: place.color) ?? PlaceColor.green
                isTabbarShowing = false
                region = .region(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: place.latitude,
                                                                                   longitude: place.longitude),
                                                    span: MKCoordinateSpan(latitudeDelta: 0.005,
                                                                           longitudeDelta: 0.005)))
            })
            .animation(.spring, value: isEditing)
            .padding([.horizontal], 16)
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationBarTitle("", displayMode: .inline)
        }
    }
}

#Preview {
    PlaceView(place: Place(color: "blue", createdDate: Date(), icon: "mappin", latitude: 25.761681, longitude: -80.191788, name: "Name", text: "hello hello buddies"), isTabbarShowing: .constant(false))
}
