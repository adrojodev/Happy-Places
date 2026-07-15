//
//  PlaceMapPreview.swift
//  Happy Places
//
//  Created by Alan David Hernández Trujillo on 31/07/24.
//

import SwiftUI
import MapKit

struct PlaceMapPreview: View {
    let place: Place?

    var body: some View {
        if let place {
            VStack (alignment: .leading, spacing: 24.0) {
                HStack (alignment: .top, spacing: 16.0) {
                    Text(place.name)
                        .font(.system(size: 32.0, weight: .bold))
                    Spacer()
                    Button("Let's go", systemImage: "location.fill") {
                        AppleMaps.open(name: place.name, coordinate: place.coordinate)
                    }
                    .tint(place.uiColor)
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                }
                Text(place.text)
            }
            .padding(.horizontal, 16.0)
            .padding(.top, 24.0)
        }
    }
}
