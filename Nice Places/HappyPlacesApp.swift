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
    @Environment(\.scenePhase) private var scenePhase

    init() {
        let schema = Schema([Place.self, PlacePhoto.self])

        // UI tests run on their own store file so they never read or touch
        // real data (and stop interfering with each other). "-uiTestReset"
        // additionally starts that store empty. Production launches never
        // carry these arguments and are completely unaffected.
        if CommandLine.arguments.contains("-uiTestStore") {
            let support = URL.applicationSupportDirectory
            try? FileManager.default.createDirectory(at: support, withIntermediateDirectories: true)
            let url = support.appending(path: "ui-test.store")
            if CommandLine.arguments.contains("-uiTestReset") {
                for suffix in ["", "-wal", "-shm"] {
                    try? FileManager.default.removeItem(at: URL(fileURLWithPath: url.path + suffix))
                }
            }
            do {
                let config = ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)
                container = try ModelContainer(for: schema, configurations: [config])
                return
            } catch {
                fatalError("Could not initialize UI-test ModelContainer: \(error)")
            }
        }

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
                .task { WidgetSync.publish(from: container.mainContext) }
        }
        .modelContainer(container)
        .onChange(of: scenePhase) {
            // Leaving the app is the one moment widgets are about to be
            // seen — refresh their snapshot with whatever changed.
            if scenePhase == .background {
                WidgetSync.publish(from: container.mainContext)
            }
        }
    }
}
