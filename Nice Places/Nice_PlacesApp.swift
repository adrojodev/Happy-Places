//
//  Nice_PlacesApp.swift
//  Nice Places
//
//  Created by Alan David Hernández Trujillo on 09/02/24.
//

import SwiftUI
import SwiftData

@main
struct Nice_PlacesApp: App {
    var body: some Scene {
        WindowGroup {
            NicePlacesView()
        }
        .modelContainer(for: [Place.self])
    }
}
