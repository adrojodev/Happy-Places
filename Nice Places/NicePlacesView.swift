//
//  ContentView.swift
//  Nice Places
//
//  Created by Alan David Hernández Trujillo on 09/02/24.
//

import SwiftUI
import SwiftData

struct NicePlacesView: View {
    
    var body: some View {
        TabView(selection: .constant(1)) {
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
    NicePlacesView()
}
