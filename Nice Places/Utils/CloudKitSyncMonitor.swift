//
//  CloudKitSyncMonitor.swift
//  Nice Places
//
//  Monitor iCloud sync status
//

import SwiftUI
import CoreData
import Combine

@Observable
class CloudKitSyncMonitor {
    var isSyncing: Bool = false
    var lastSyncDate: Date?
    // Import and export errors are tracked separately so a successful import
    // can't mask a persistent export failure (e.g. missing production schema).
    var syncError: String? { exportError ?? importError }

    private var importError: String?
    private var exportError: String?
    private var cancellables = Set<AnyCancellable>()

    init() {
        setupNotificationObservers()
    }

    private func setupNotificationObservers() {
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
            guard let self else { return }
            switch event.type {
            case .setup:
                self.isSyncing = false
            case .import:
                self.isSyncing = event.endDate == nil
                if let endDate = event.endDate {
                    self.lastSyncDate = endDate
                    self.importError = event.error?.localizedDescription
                }
            case .export:
                self.isSyncing = event.endDate == nil
                if let endDate = event.endDate {
                    self.lastSyncDate = endDate
                    self.exportError = event.error?.localizedDescription
                }
            @unknown default:
                break
            }
        }
    }
}
