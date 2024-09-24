//
//  PlaceView.swift
//  Nice Places
//
//  Created by Alan David Hernández Trujillo on 10/02/24.
//

import SwiftUI
import MapKit
import SwiftData

struct PlaceView: View {
    @Environment(\.modelContext) var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @Bindable var place: Place
    @Binding var isTabbarShowing: Bool
    
    @State private var region: MapCameraPosition = .automatic
    @State private var isEditing: Bool = false
    @State private var selectedColor: PlaceColor = PlaceColor.green
    @State private var isGonnaDelete: Bool = false
    
    @FocusState private var focusName: Bool
    @FocusState private var focusDescription: Bool
    
    
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

                VStack (alignment: .leading, spacing: 8.0) {
                    HStack (alignment: .top) {
                        TextField("Happy place", text: $place.name, axis: .vertical)
                            .focused($focusName)
                            .textFieldStyle(.plain)
                            .font(.title)
                            .fontWeight(.bold)
                            .disabled(!isEditing)
                            .padding(.horizontal, isEditing ? 8.0 : 0.0)
                            .padding(.vertical, 2.0)
                            .background()
                            .backgroundStyle(.ultraThinMaterial.opacity(isEditing ? 1.0 : 0.0))
                            .cornerRadius(8.0)
                            .lineLimit(2)
                            .onChange(of: isEditing) {
                                focusName = isEditing
                            }
                        Spacer()
                        HStack (alignment: .center , spacing: 0.2) {
                            SelectIconButton(selectedIcon: $place.icon, selectedColor: $selectedColor)
                                .opacity(isEditing ? 1.0 : 0.0)
                                .scaleEffect(isEditing ? CGSize(width: 0.8, height: 0.8) : CGSize(width: 0.0, height: 0.0))
                            Button(action: {
                                withAnimation(.spring(duration: 0.1)) {
                                    isTabbarShowing = false
                                    place.color = selectedColor.rawValue
                                    isEditing.toggle()
                                }}, label: {
                                    VStack {
                                        if (isEditing) {
                                            HStack {
                                                Image(systemName: "checkmark.circle.fill")
                                                Text("Done")
                                            }
                                            .transition(.asymmetric(insertion: .push(from: .top), removal: .push(from: .bottom)))
                                            
                                        } else {
                                            HStack {
                                                Image(systemName: "pencil")
                                                Text("Edit")
                                            }
                                            .transition(.asymmetric(insertion: .push(from: .bottom), removal: .push(from: .top)))
                                        }
                                    }
                                    .padding(.horizontal, 12.0)
                                    .padding(.vertical, 8.0)
                                })
                            .background()
                            .backgroundStyle(selectedColor.wrappedValue.opacity(isEditing ? 0.2 : 1.0))
                            .foregroundColor(isEditing ? selectedColor.rawValue == "yellow" ? .orange : selectedColor.wrappedValue : colorScheme == .dark ? .black : .white)
                            .cornerRadius(.infinity)
                            .tint(selectedColor.wrappedValue)
                        }
                        
                    }
                    if (!isEditing) {
                        Text(formattedDate)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .zIndex(1)
                    }
                    if (isEditing || !place.text.isEmpty) {
                        TextField("This is my happy place...", text: $place.text, axis: .vertical)
                            .focused($focusDescription)
                            .textFieldStyle(.plain)
                            .font(.body)
                            .disabled(!isEditing)
                            .frame(minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
                            .padding(.vertical, 8.0)
                            .padding(.horizontal, isEditing ? 8.0 : 0.0)
                            .background()
                            .backgroundStyle(.ultraThinMaterial.opacity(isEditing ? 1.0 : 0.0))
                            .cornerRadius(8.0)
                            .onTapGesture {
                                focusDescription = true
                            }
                            .zIndex(10)
                    }
                    if (isEditing) {
                        Button(role: .destructive) {
                            isGonnaDelete = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .alert("Sure you wanna delete this one?", isPresented: $isGonnaDelete) {
                            Button("Delete", role: .destructive, action: deletePlace)
                        }
                    }
                }
                Spacer()
            }
            .onAppear() {
                selectedColor = PlaceColor(rawValue: place.color) ?? PlaceColor.green
                isTabbarShowing = false
                region = .region(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: place.latitude,
                                                                                   longitude: place.longitude),
                                                    span: MKCoordinateSpan(latitudeDelta: 0.005,
                                                                           longitudeDelta: 0.005)))
            }
            .animation(.spring, value: isEditing)
            .padding([.horizontal], 16)
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationBarTitle("", displayMode: .inline)
        }
    }
    
    func deletePlace() {
        context.delete(place)
        dismiss()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Place.self, configurations: config)
    
    return PlaceView(place: Place(color: "blue", createdDate: Date(), icon: "mappin", latitude: 25.761681, longitude: -80.191788, name: "Name", text: "hello hello buddies"), isTabbarShowing: .constant(false))
        .modelContainer(container)
}
