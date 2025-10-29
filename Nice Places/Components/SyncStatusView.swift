//
//  SyncStatusView.swift
//  Nice Places
//
//  iCloud sync status indicator
//

import SwiftUI

struct SyncStatusView: View {
    let syncMonitor: CloudKitSyncMonitor

    var body: some View {
        HStack(spacing: 6) {
            if syncMonitor.isSyncing {
                ProgressView()
                    .scaleEffect(0.8)
                Text("Syncing...")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else if let error = syncMonitor.syncError {
                Image(systemName: "exclamationmark.icloud")
                    .font(.caption)
                    .foregroundStyle(.orange)
                Text("Sync Error")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else if let lastSync = syncMonitor.lastSyncDate {
                Image(systemName: "icloud.and.arrow.up")
                    .font(.caption)
                    .foregroundStyle(.green)
                Text(timeAgo(from: lastSync))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                Image(systemName: "icloud")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }

    private func timeAgo(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)

        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        }
    }
}

// Compact version for toolbar
struct CompactSyncStatusView: View {
    let syncMonitor: CloudKitSyncMonitor
    @State private var showingDetails = false

    var body: some View {
        Button(action: {
            showingDetails.toggle()
        }) {
            HStack(spacing: 4) {
                if syncMonitor.isSyncing {
                    ProgressView()
                        .scaleEffect(0.7)
                } else if syncMonitor.syncError != nil {
                    Image(systemName: "exclamationmark.icloud")
                        .font(.caption)
                        .foregroundStyle(.orange)
                } else {
                    Image(systemName: "icloud")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
        .alert("iCloud Sync Status", isPresented: $showingDetails) {
            Button("OK", role: .cancel) { }
        } message: {
            if syncMonitor.isSyncing {
                Text("Currently syncing with iCloud...")
            } else if let error = syncMonitor.syncError {
                Text("Sync error: \(error)")
            } else if let lastSync = syncMonitor.lastSyncDate {
                Text("Last synced: \(lastSync.formatted(date: .abbreviated, time: .shortened))")
            } else {
                Text("iCloud sync is enabled")
            }
        }
    }
}
