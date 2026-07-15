//
//  PlaceItemView.swift
//  Nice Places
//
//  Created by Alan David Hernández Trujillo on 10/02/24.
//

import SwiftUI
import SwiftData

struct PlaceItemView: View {
    let place: Place

    var body: some View {
        HStack {
            PlaceIconBadge(icon: place.icon, color: place.uiColor, size: 52)
            VStack (alignment: .leading) {
                Text(place.name)
                    .font(.title3)
                    .fontWeight(.bold)
                Text(place.formattedDate)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Place.self, configurations: config)

    PlaceItemView(place: Place(color: "red",
                               createdDate: Date(),
                               icon: "mappin",
                               latitude: 25.761681,
                               longitude: -80.191788,
                               name: "Name",
                               text: ""))
        .modelContainer(container)
}
