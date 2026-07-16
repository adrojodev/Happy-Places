//
//  PlaceMapPreview.swift
//  Nice Places
//
//  Bottom sheet shown when a map marker is selected: name, photos, story,
//  jump to Apple Maps, or edit the place right here.
//

import SwiftUI
import SwiftData
import UIKit

struct PlaceMapPreview: View {
    let place: Place?
    @Binding var detent: PresentationDetent

    @State private var showEditor = false
    @State private var showMapsChooser = false

    var body: some View {
        if let place {
            NavigationStack {
                VStack(alignment: .leading, spacing: 20.0) {
                    HStack(alignment: .top, spacing: 12.0) {
                        Text(place.name)
                            .font(.system(size: 32.0, weight: .bold))
                        Spacer()
                        Button {
                            // The editor needs room — pop the sheet open.
                            detent = .large
                            showEditor = true
                        } label: {
                            Label("Edit", systemImage: "pencil")
                                .labelStyle(.iconOnly)
                        }
                        .secondaryActionStyle()
                        .buttonBorderShape(.circle)
                        .tint(place.uiColor)

                        Button("Let's go", systemImage: "location.fill") {
                            showMapsChooser = true
                        }
                        .tint(place.uiColor)
                        .prominentActionStyle()
                        .buttonBorderShape(.capsule)
                        .mapsChooser(isPresented: $showMapsChooser, name: place.name, coordinate: place.coordinate)
                    }

                    if let photos = place.photos, !photos.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(photos) { photo in
                                    if let imageData = photo.imageData,
                                       let uiImage = UIImage(data: imageData) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 96, height: 96)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                }
                            }
                        }
                    }

                    Text(place.text)

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 16.0)
                .padding(.top, 24.0)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(isPresented: $showEditor) {
                    PlaceView(place: place, isTabbarShowing: .constant(false), startsEditing: true)
                }
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Place.self, configurations: config)

    PlaceMapPreview(place: Place(color: "orange",
                                 createdDate: Date(),
                                 icon: "fork.knife",
                                 latitude: 25.761681,
                                 longitude: -80.191788,
                                 name: "Restaurante Doña Elvira",
                                 text: "Best mole in town."),
                    detent: .constant(.medium))
        .modelContainer(container)
}
