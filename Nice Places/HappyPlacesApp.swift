//
//  Nice_PlacesApp.swift
//  Nice Places
//
//  Created by Alan David Hernández Trujillo on 09/02/24.
//

import SwiftUI
import SwiftData
import CoreData
import Combine

// MARK: - CloudKit Sync Monitor
@Observable
class CloudKitSyncMonitor {
    var isSyncing: Bool = false
    var lastSyncDate: Date?
    var syncError: String?

    private var cancellables = Set<AnyCancellable>()

    init() {
        setupNotificationObservers()
    }

    private func setupNotificationObservers() {
        // Listen for CloudKit notifications
        NotificationCenter.default.publisher(for: NSPersistentCloudKitContainer.eventChangedNotification)
            .sink { [weak self] notification in
                self?.handleCloudKitEvent(notification)
            }
            .store(in: &cancellables)
    }

    private func handleCloudKitEvent(_ notification: Notification) {
        guard let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey] as? NSPersistentCloudKitContainer.Event else {
            return
        }

        DispatchQueue.main.async { [weak self] in
            switch event.type {
            case .setup:
                self?.isSyncing = false
            case .import:
                self?.isSyncing = event.endDate == nil
                if event.endDate != nil {
                    self?.lastSyncDate = event.endDate
                }
                if let error = event.error {
                    self?.syncError = error.localizedDescription
                } else {
                    self?.syncError = nil
                }
            case .export:
                self?.isSyncing = event.endDate == nil
                if event.endDate != nil {
                    self?.lastSyncDate = event.endDate
                }
                if let error = event.error {
                    self?.syncError = error.localizedDescription
                } else {
                    self?.syncError = nil
                }
            @unknown default:
                break
            }
        }
    }
}

@main
struct HappyPlacesApp: App {
    let container: ModelContainer
    @State private var syncMonitor = CloudKitSyncMonitor()

    init() {
        do {
            // Now with photos support - SwiftData handles lightweight migration
            container = try ModelContainer(for: Place.self, PlacePhoto.self)
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
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
