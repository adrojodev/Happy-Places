//
//  NearbyPlacesWidget.swift
//  HappyPlacesWidgets
//
//  Home-screen widget: a real map of your happy places around you,
//  with a one-tap way to add a new one.
//

import WidgetKit
import SwiftUI
import MapKit
import CoreLocation

// MARK: - Entry

struct NearbyPlaceStub: Identifiable {
    let id: String
    let name: String
    let icon: String
    let color: Color
    let distanceText: String?
}

struct NearbyPlacesEntry: TimelineEntry {
    let date: Date
    let mapImage: UIImage?
    let places: [NearbyPlaceStub]
    let totalCount: Int

    static let sample = NearbyPlacesEntry(
        date: .now,
        mapImage: nil,
        places: [
            NearbyPlaceStub(id: "1", name: "Sunset pier", icon: "sun.max.fill", color: .orange, distanceText: "350 m"),
            NearbyPlaceStub(id: "2", name: "First-date café", icon: "cup.and.saucer.fill", color: .pink, distanceText: "1.2 km"),
            NearbyPlaceStub(id: "3", name: "Our tree", icon: "tree.fill", color: .green, distanceText: "2 km")
        ],
        totalCount: 3
    )
}

// MARK: - Provider

struct NearbyPlacesProvider: TimelineProvider {
    func placeholder(in context: Context) -> NearbyPlacesEntry {
        .sample
    }

    func getSnapshot(in context: Context, completion: @escaping (NearbyPlacesEntry) -> Void) {
        // The gallery preview wants an instant answer; skip the map render.
        if context.isPreview {
            completion(.sample)
            return
        }
        Task { completion(await entry(for: context)) }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NearbyPlacesEntry>) -> Void) {
        Task {
            let entry = await entry(for: context)
            // The app also reloads timelines whenever it goes to background.
            completion(Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(30 * 60))))
        }
    }

    private func entry(for context: Context) async -> NearbyPlacesEntry {
        let snapshot = WidgetPlacesStore.read()
        // Widgets may read the cached location fix when the app is
        // authorized (NSWidgetWantsLocation); fall back to where the app
        // last saw the user.
        let here = CLLocationManager().location?.coordinate ?? snapshot.lastKnownCoordinate

        let limit = context.family == .systemSmall ? 4 : (context.family == .systemMedium ? 3 : 5)
        let nearest = snapshot.nearestPlaces(to: here, limit: limit)

        let formatter = MKDistanceFormatter()
        formatter.unitStyle = .abbreviated
        let stubs = nearest.map { item in
            NearbyPlaceStub(
                id: item.id,
                name: item.name,
                icon: item.icon,
                color: (PlaceColor(rawValue: item.color) ?? .green).color,
                distanceText: here.map { formatter.string(fromDistance: item.distanceMeters(from: $0)) }
            )
        }

        let mapImage = await renderMap(places: nearest, userCoordinate: here, size: context.displaySize)
        return NearbyPlacesEntry(date: .now, mapImage: mapImage, places: stubs, totalCount: snapshot.places.count)
    }

    // MARK: Map rendering

    private func renderMap(places: [WidgetPlacesSnapshot.Item],
                           userCoordinate: CLLocationCoordinate2D?,
                           size: CGSize) async -> UIImage? {
        var coordinates = places.map(\.coordinate)
        if let userCoordinate {
            coordinates.append(userCoordinate)
        }
        guard !coordinates.isEmpty, size.width > 0, size.height > 0 else { return nil }

        let options = MKMapSnapshotter.Options()
        options.region = Self.region(fitting: coordinates)
        options.size = size
        options.pointOfInterestFilter = .excludingAll
        options.showsBuildings = false

        guard let snapshot = try? await MKMapSnapshotter(options: options).start() else { return nil }
        return draw(places: places, userCoordinate: userCoordinate, on: snapshot, size: size)
    }

    static func region(fitting coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
        var minLat = coordinates[0].latitude, maxLat = coordinates[0].latitude
        var minLon = coordinates[0].longitude, maxLon = coordinates[0].longitude
        for c in coordinates {
            minLat = min(minLat, c.latitude); maxLat = max(maxLat, c.latitude)
            minLon = min(minLon, c.longitude); maxLon = max(maxLon, c.longitude)
        }
        let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2,
                                            longitude: (minLon + maxLon) / 2)
        // 1.6x padding so pins don't sit on the edge; floor keeps a lone
        // pin from zooming in to street level.
        let span = MKCoordinateSpan(latitudeDelta: max((maxLat - minLat) * 1.6, 0.012),
                                    longitudeDelta: max((maxLon - minLon) * 1.6, 0.012))
        return MKCoordinateRegion(center: center, span: span)
    }

    private func draw(places: [WidgetPlacesSnapshot.Item],
                      userCoordinate: CLLocationCoordinate2D?,
                      on snapshot: MKMapSnapshotter.Snapshot,
                      size: CGSize) -> UIImage {
        let bounds = CGRect(origin: .zero, size: size)
        return UIGraphicsImageRenderer(size: size).image { _ in
            snapshot.image.draw(at: .zero)

            if let userCoordinate {
                let point = snapshot.point(for: userCoordinate)
                if bounds.contains(point) {
                    let dot = CGRect(x: point.x - 7, y: point.y - 7, width: 14, height: 14)
                    UIColor.white.setFill()
                    UIBezierPath(ovalIn: dot).fill()
                    UIColor.systemBlue.setFill()
                    UIBezierPath(ovalIn: dot.insetBy(dx: 2.5, dy: 2.5)).fill()
                }
            }

            for place in places {
                let point = snapshot.point(for: place.coordinate)
                guard bounds.insetBy(dx: -12, dy: -12).contains(point) else { continue }

                let pinColor = UIColor((PlaceColor(rawValue: place.color) ?? .green).color)
                let circle = CGRect(x: point.x - 11, y: point.y - 11, width: 22, height: 22)

                UIColor.white.setFill()
                UIBezierPath(ovalIn: circle.insetBy(dx: -2, dy: -2)).fill()
                pinColor.setFill()
                UIBezierPath(ovalIn: circle).fill()

                let config = UIImage.SymbolConfiguration(pointSize: 10, weight: .semibold)
                if let symbol = UIImage(systemName: place.icon, withConfiguration: config)?
                    .withTintColor(.white, renderingMode: .alwaysOriginal) {
                    let symbolSize = symbol.size
                    symbol.draw(at: CGPoint(x: point.x - symbolSize.width / 2,
                                            y: point.y - symbolSize.height / 2))
                }
            }
        }
    }
}

// MARK: - Views

struct NearbyPlacesWidgetView: View {
    @Environment(\.widgetFamily) private var family
    // The widget disables content margins so the map can bleed to the
    // edges; re-apply the system margins to the overlaid content only.
    @Environment(\.widgetContentMargins) private var contentMargins
    let entry: NearbyPlacesEntry

    var body: some View {
        content
            .padding(contentMargins)
            .containerBackground(for: .widget) { background }
            .widgetURL(family == .systemSmall || entry.places.isEmpty ? QuickAction.addPlace.url : nil)
    }

    @ViewBuilder
    private var background: some View {
        if let image = entry.mapImage {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            LinearGradient(colors: [.green.opacity(0.55), .teal.opacity(0.6)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    @ViewBuilder
    private var content: some View {
        if entry.places.isEmpty {
            emptyState
        } else {
            switch family {
            case .systemMedium:
                mediumContent
            case .systemLarge:
                largeContent
            default:
                smallContent
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Image(systemName: "globe.americas.fill")
                .font(.title2)
            Text("No happy places yet")
                .font(.footnote)
                .fontWeight(.semibold)
            Text("Tap to save your first")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var smallContent: some View {
        VStack {
            HStack {
                Spacer()
                addBadge
            }
            Spacer()
            HStack {
                countPill
                Spacer()
            }
        }
    }

    private var mediumContent: some View {
        HStack {
            VStack(alignment: .leading) {
                Spacer()
                countPill
            }
            Spacer()
            placesPanel(showsAddRow: true)
                .frame(maxWidth: 150)
        }
    }

    private var largeContent: some View {
        VStack(alignment: .leading) {
            HStack {
                countPill
                Spacer()
                Link(destination: QuickAction.snapPlace.url) {
                    Image(systemName: "camera.fill")
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .frame(width: 30, height: 30)
                        .background(.ultraThinMaterial, in: Circle())
                }
                addBadge
            }
            Spacer()
            placesPanel(showsAddRow: false)
        }
    }

    private func placesPanel(showsAddRow: Bool) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            ForEach(entry.places) { place in
                HStack(spacing: 6) {
                    Image(systemName: place.icon)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 18, height: 18)
                        .background(place.color, in: Circle())
                    Text(place.name)
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    Spacer(minLength: 4)
                    if let distance = place.distanceText {
                        Text(distance)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            if showsAddRow {
                Link(destination: QuickAction.addPlace.url) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 18, height: 18)
                            .background(.tint, in: Circle())
                        Text("Save this place")
                            .font(.caption)
                            .fontWeight(.semibold)
                        Spacer(minLength: 0)
                    }
                }
            }
        }
        .padding(10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    private var countPill: some View {
        Label("\(entry.totalCount) \(entry.totalCount == 1 ? "place" : "places")",
              systemImage: "heart.fill")
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(.ultraThinMaterial, in: Capsule())
    }

    private var addBadge: some View {
        Link(destination: QuickAction.addPlace.url) {
            Image(systemName: "plus")
                .font(.footnote)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(.tint, in: Circle())
                .shadow(radius: 2, y: 1)
        }
    }
}

// MARK: - Widget

struct NearbyPlacesWidget: Widget {
    let kind: String = "NearbyPlacesWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NearbyPlacesProvider()) { entry in
            NearbyPlacesWidgetView(entry: entry)
        }
        .configurationDisplayName("Happy Places Nearby")
        .description("A peek at your happy places around you — and one tap to save a new one.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}
