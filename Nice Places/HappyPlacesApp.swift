//
//  Nice_PlacesApp.swift
//  Nice Places
//
//  Created by Alan David Hernández Trujillo on 09/02/24.
//

import SwiftUI
import SwiftData

@main
struct HappyPlacesApp: App {
    var body: some Scene {
        WindowGroup {
            MainPanelView()
        }
        .modelContainer(for: [Place.self])
    }
}
