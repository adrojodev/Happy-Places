//
//  IconSelector.swift
//  Nice Places
//
//  Created by Alan David Hernández Trujillo on 23/02/24.
//

import SwiftUI

struct IconSelector: View {
    @Environment(\.colorScheme) var colorScheme
    
    @Binding var selectedColor: PlaceColor
    @Binding var selectedIcon: String
    @Binding var isIconSheetOpen: Bool
    
    var body: some View {
        VStack(alignment: .center, spacing: 32.0) {
            ZStack {
                HStack {
                    Spacer()
                    Image(systemName: "xmark")
                        .fontWeight(.bold)
                        .frame(width: 32, height: 32)
                        .background(.ultraThinMaterial)
                        .foregroundColor(.secondary)
                        .cornerRadius(.infinity)
                        .onTapGesture(perform: {
                            isIconSheetOpen = false
                        })
                }
            }
            HStack {
                Spacer()
                Image(systemName: selectedIcon)
                    .font(.largeTitle)
                    .foregroundColor(colorScheme == .dark ? .black : .white)
                    .frame(width: 80, height: 80)
                    .background(selectedColor.wrappedValue.gradient)
                    .cornerRadius(.infinity)
                Spacer()
            }
            HStack {
                Button(action: {
                    selectedColor = PlaceColor.pink
                }, label: {
                    Circle()
                        .fill(.pink)
                        .frame(width: 40, height: 40)
                })
                Button(action: {
                    selectedColor = PlaceColor.red
                }, label: {
                    Circle()
                        .fill(.red)
                        .frame(width: 40, height: 40)
                })
                Button(action: {
                    selectedColor = PlaceColor.orange
                }, label: {
                    Circle()
                        .fill(.orange)
                        .frame(width: 40, height: 40)
                })
                Button(action: {
                    selectedColor = PlaceColor.yellow
                }, label: {
                    Circle()
                        .fill(.yellow)
                        .frame(width: 40, height: 40)
                })
                Button(action: {
                    selectedColor = PlaceColor.green
                }, label: {
                    Circle()
                        .fill(.green)
                        .frame(width: 40, height: 40)
                })
                Button(action: {
                    selectedColor = PlaceColor.blue
                }, label: {
                    Circle()
                        .fill(.blue)
                        .frame(width: 40, height: 40)
                })
                Button(action: {
                    selectedColor = PlaceColor.purple
                }, label: {
                    Circle()
                        .fill(.purple)
                        .frame(width: 40, height: 40)
                })
            }
            .padding(.horizontal, 16.0)
            .padding(.vertical, 8.0)
            .background(.ultraThinMaterial)
            .cornerRadius(16.0)
            ScrollView {
                LazyVGrid(columns: [GridItem(), GridItem(), GridItem(), GridItem(), GridItem()], content: {
                    ForEach(icons) { icon in
                        Image(systemName: icon.icon)
                            .font(.title3)
                            .frame(width: 48, height: 48)
                            .onTapGesture(perform: {
                                selectedIcon = icon.icon
                            })
                    }
                })
                .padding([.top], 16)
                .padding([.bottom], 32)
                .cornerRadius(16.0)
                .background(.ultraThinMaterial)
            }
            .cornerRadius(16.0)
        }
        .padding([.horizontal], 20)
        .padding([.top], 12)
    }
}

// MARK: - Sync Status Views
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

#Preview {
    IconSelector(selectedColor: .constant(PlaceColor.green), selectedIcon: .constant("mappin"), isIconSheetOpen: .constant(true))
}
