//
//  QuickAddWidgets.swift
//  HappyPlacesWidgets
//
//  Lock-screen quick-add widget and the home-screen "snap a place" widget.
//

import WidgetKit
import SwiftUI
import CoreLocation

// MARK: - Shared provider

struct QuickAddEntry: TimelineEntry {
    let date: Date
    let nearestPlaceName: String?
    let totalCount: Int
}

struct QuickAddProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuickAddEntry {
        QuickAddEntry(date: .now, nearestPlaceName: "Sunset pier", totalCount: 3)
    }

    func getSnapshot(in context: Context, completion: @escaping (QuickAddEntry) -> Void) {
        completion(entry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuickAddEntry>) -> Void) {
        // Refreshed by the app on every background transition too.
        completion(Timeline(entries: [entry()], policy: .after(.now.addingTimeInterval(60 * 60))))
    }

    private func entry() -> QuickAddEntry {
        let snapshot = WidgetPlacesStore.read()
        let here = CLLocationManager().location?.coordinate ?? snapshot.lastKnownCoordinate
        let nearest = snapshot.nearestPlaces(to: here, limit: 1).first
        return QuickAddEntry(date: .now, nearestPlaceName: nearest?.name, totalCount: snapshot.places.count)
    }
}

// MARK: - Lock screen: Save This Place

struct QuickAddWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: QuickAddEntry

    var body: some View {
        Group {
            if family == .accessoryRectangular {
                rectangular
            } else {
                circular
            }
        }
        .containerBackground(for: .widget) { Color.clear }
        .widgetURL(QuickAction.addPlace.url)
    }

    private var circular: some View {
        ZStack {
            AccessoryWidgetBackground()
            Image(systemName: "plus")
                .font(.title2)
                .fontWeight(.bold)
        }
    }

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 2) {
            Label("Save this place", systemImage: "plus.circle.fill")
                .font(.headline)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var subtitle: String {
        if let name = entry.nearestPlaceName {
            return "Nearest: \(name)"
        }
        return entry.totalCount == 0 ? "Your first happy place" : "\(entry.totalCount) happy places"
    }
}

struct QuickAddWidget: Widget {
    let kind: String = "QuickAddWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuickAddProvider()) { entry in
            QuickAddWidgetView(entry: entry)
        }
        .configurationDisplayName("Save This Place")
        .description("One tap to save where you are as a happy place.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular])
    }
}

// MARK: - Snap a place (camera-first)

struct SnapPlaceWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: QuickAddEntry

    var body: some View {
        Group {
            if family == .accessoryCircular {
                ZStack {
                    AccessoryWidgetBackground()
                    Image(systemName: "camera.fill")
                        .font(.title3)
                }
                .containerBackground(for: .widget) { Color.clear }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "camera.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.white)
                    Text("Snap a place")
                        .font(.footnote)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    Text("Photo first, saved right here")
                        .font(.caption2)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.85))
                }
                .padding(4)
                .containerBackground(for: .widget) {
                    LinearGradient(colors: [.pink, .orange],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                }
            }
        }
        .widgetURL(QuickAction.snapPlace.url)
    }
}

struct SnapPlaceWidget: Widget {
    let kind: String = "SnapPlaceWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuickAddProvider()) { entry in
            SnapPlaceWidgetView(entry: entry)
        }
        .configurationDisplayName("Snap a Place")
        .description("Jump straight into the camera and save this spot with a photo.")
        .supportedFamilies([.systemSmall, .accessoryCircular])
    }
}
