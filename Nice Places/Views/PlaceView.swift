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

    @Bindable var place: Place
    @Binding var isTabbarShowing: Bool
    
    @State private var region: MapCameraPosition = .automatic
    @State private var isEditing: Bool = false

    init(place: Place, isTabbarShowing: Binding<Bool>, startsEditing: Bool = false) {
        self.place = place
        self._isTabbarShowing = isTabbarShowing
        self._isEditing = State(initialValue: startsEditing)
    }
    @State private var selectedColor: PlaceColor = PlaceColor.green
    @State private var isGonnaDelete: Bool = false
    @State private var pendingImports: Int = 0
    
    @FocusState private var focusName: Bool
    @FocusState private var focusDescription: Bool
    
    
    var body: some View {
        let formattedDate: String = place.createdDate.formatted(.dateTime.day().month().year())
        
        ScrollView {
                VStack (alignment: .leading,
                        spacing: 16.0) {
                    NavigationLink(destination: MapView(place: place)) {
                    Map(position: $region) {
                        Marker(place.name,
                               systemImage: place.icon,
                               coordinate: place.coordinate)
                        .tint(selectedColor.color)
                    }
                    .aspectRatio(4/3, contentMode: .fit)
                    .cornerRadius(16.0)
                }

                // Photos section
                if isEditing || (place.photos != nil && !place.photos!.isEmpty) {
                    VStack(alignment: .leading, spacing: 8) {
                        if let photos = place.photos, !photos.isEmpty || pendingImports > 0 {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(photos) { photo in
                                        if let imageData = photo.imageData,
                                           let uiImage = UIImage(data: imageData) {
                                            ZStack(alignment: .topTrailing) {
                                                Image(uiImage: uiImage)
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 120, height: 120)
                                                    .cornerRadius(12)
                                                    .clipped()

                                                if isEditing {
                                                    Button(action: {
                                                        deletePhoto(photo)
                                                    }) {
                                                        Image(systemName: "xmark.circle.fill")
                                                            .foregroundStyle(.white, .red)
                                                            .font(.title2)
                                                    }
                                                    .padding(6)
                                                }
                                            }
                                        }
                                    }

                                    // Loading previews for photos still importing
                                    ForEach(0..<pendingImports, id: \.self) { _ in
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(.quaternary)
                                            .frame(width: 120, height: 120)
                                            .overlay { ProgressView() }
                                    }

                                    // Add button (square) when editing
                                    if isEditing {
                                        PhotoPickerButton(selectedPhotos: .init(
                                            get: { place.photos ?? [] },
                                            set: { place.photos = $0 }
                                        ),
                                        placeLatitude: place.latitude,
                                        placeLongitude: place.longitude,
                                        isEmpty: false,
                                        selectedColor: selectedColor,
                                        pendingImports: $pendingImports)
                                    }
                                }
                            }
                        } else if isEditing {
                            // Show full-width rectangle when no photos and editing
                            PhotoPickerButton(selectedPhotos: .init(
                                get: { place.photos ?? [] },
                                set: { place.photos = $0 }
                            ),
                            placeLatitude: place.latitude,
                            placeLongitude: place.longitude,
                            isEmpty: true,
                            selectedColor: selectedColor,
                            pendingImports: $pendingImports)
                        }
                    }
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
                            if isEditing,
                               let suggestion = PlaceClassifier.suggest(for: place.name),
                               suggestion.icon != place.icon || suggestion.color != selectedColor {
                                Button {
                                    withAnimation(.bouncy) {
                                        place.icon = suggestion.icon
                                        selectedColor = suggestion.color
                                    }
                                } label: {
                                    Image(systemName: "sparkles")
                                        .font(.body)
                                        .foregroundStyle(suggestion.color.color)
                                        .frame(width: 32, height: 32)
                                        .background(.ultraThinMaterial)
                                        .clipShape(Circle())
                                }
                                .transition(.scale.combined(with: .opacity))
                            }
                            SelectIconButton(selectedIcon: $place.icon, selectedColor: $selectedColor)
                                .opacity(isEditing ? 1.0 : 0.0)
                                .scaleEffect(isEditing ? CGSize(width: 0.8, height: 0.8) : CGSize(width: 0.0, height: 0.0))
                            Button(action: {
                                withAnimation(.spring(duration: 0.1)) {
                                    isTabbarShowing = false
                                    isEditing.toggle()
                                }}, label: {
                                    VStack {
                                        if (isEditing) {
                                            HStack {
                                                if pendingImports > 0 {
                                                    ProgressView()
                                                        .controlSize(.small)
                                                    Text("Adding…")
                                                } else {
                                                    Image(systemName: "checkmark.circle.fill")
                                                    Text("Done")
                                                }
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
                            .disabled(isEditing && pendingImports > 0)
                            .background()
                            .backgroundStyle(selectedColor.color.opacity(isEditing ? 0.2 : 1.0))
                            // Not .foregroundStyle(.background): that resolves to the
                            // custom backgroundStyle above (the pill color itself),
                            // which makes the label invisible.
                            .foregroundStyle(isEditing
                                             ? (selectedColor == .yellow ? Color.orange : selectedColor.color)
                                             : Color(uiColor: .systemBackground))
                            .cornerRadius(.infinity)
                            .tint(selectedColor.color)
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
                        .prominentActionStyle()
                        .alert("Sure you wanna delete this one?", isPresented: $isGonnaDelete) {
                            Button("Delete", role: .destructive, action: deletePlace)
                        }
                    }
                }
            }
        }
        .onAppear() {
            selectedColor = PlaceColor(rawValue: place.color) ?? PlaceColor.green
            isTabbarShowing = false
            region = .region(MKCoordinateRegion(center: place.coordinate,
                                                span: MKCoordinateSpan(latitudeDelta: 0.005,
                                                                       longitudeDelta: 0.005)))
        }
        .onChange(of: selectedColor) {
            // Persist immediately, like the icon: leaving the screen mid-edit
            // used to keep the new icon but silently drop the new color.
            if isEditing {
                place.color = selectedColor.rawValue
            }
        }
        .animation(.spring, value: isEditing)
        .padding([.horizontal], 16)
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func deletePlace() {
        context.delete(place)
        dismiss()
    }

    func deletePhoto(_ photo: PlacePhoto) {
        withAnimation {
            place.photos?.removeAll { $0 === photo }
            context.delete(photo)
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Place.self, configurations: config)
    
    return PlaceView(place: Place(color: "blue", createdDate: Date(), icon: "mappin", latitude: 25.761681, longitude: -80.191788, name: "Name", text: "hello hello buddies"), isTabbarShowing: .constant(false))
        .modelContainer(container)
}
