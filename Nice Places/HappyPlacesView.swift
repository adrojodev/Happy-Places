//
//  ContentView.swift
//  Nice Places
//
//  Created by Alan David Hernández Trujillo on 09/02/24.
//

import SwiftUI
import SwiftData

struct HappyPlacesView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var router = QuickActionRouter.shared

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
        .onOpenURL { url in
            router.handle(url)
        }
        .task {
            router.consumeChannelAction()
        }
        .onChange(of: scenePhase) {
            // Control Center intents run in the widget extension and leave
            // their action in the App Group channel before opening the app.
            if scenePhase == .active {
                router.consumeChannelAction()
            }
        }
        .fullScreenCover(item: pendingAction) { action in
            QuickActionFlowView(action: action)
        }
    }

    private var pendingAction: Binding<QuickAction?> {
        Binding(get: { router.pending }, set: { router.pending = $0 })
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Place.self, configurations: config)
    
    return HappyPlacesView()
        .modelContainer(container)
}
