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
    let container: ModelContainer
    @State private var syncMonitor = CloudKitSyncMonitor()

    init() {
        let schema = Schema([Place.self, PlacePhoto.self])
        do {
            // Default configuration syncs through CloudKit (iCloud.rojo.happy-places).
            // The Place -> PlacePhoto change is additive, so SwiftData's lightweight
            // migration handles existing stores.
            container = try ModelContainer(for: schema)
        } catch {
            // Never crash-loop a live app on container init: retry with the same
            // store but without CloudKit so users keep access to their local data.
            do {
                let localOnly = ModelConfiguration(schema: schema, cloudKitDatabase: .none)
                container = try ModelContainer(for: schema, configurations: [localOnly])
            } catch {
                fatalError("Could not initialize ModelContainer: \(error)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            HappyPlacesView()
                .environment(syncMonitor)
        }
        .modelContainer(container)
    }
}
