//
//  ContentView.swift
//  Nice Places
//
//  Created by Alan David Hernández Trujillo on 09/02/24.
//

import SwiftUI
import SwiftData

struct HappyPlacesView: View {
    
    var body: some View {
        TabView {
            LocationsListView()
                .tabItem {
                    Label("List", systemImage: "list.bullet")
                }
                .toolbarBackground(.visible, for: .tabBar)
            MarkersMapView()
                .tabItem {
                    Label("Map", systemImage: "map")
                }
                .toolbarBackground(.visible, for: .tabBar)

        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Place.self, configurations: config)
    
    return HappyPlacesView()
        .modelContainer(container)
}
