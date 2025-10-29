//
//  CloudKitSyncMonitor.swift
//  Nice Places
//
//  Monitor iCloud sync status
//

import SwiftUI
import SwiftData
import Combine

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
                // Initial setup
                self?.isSyncing = false
            case .import:
                // Importing from cloud
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
                // Exporting to cloud
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
