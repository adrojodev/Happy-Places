//
//  PhotoPlacesScanner.swift
//  Nice Places
//
//  Scans the photo library for GPS-tagged photos, clusters them into
//  visited places, and prepares reviewable suggestions.
//

import Foundation
import Photos
import CoreLocation
import Observation
import UIKit

// MARK: - Clustering (pure, unit-tested)

enum PhotoClustering {

    struct Sample {
        let coordinate: CLLocationCoordinate2D
        let date: Date?
        let assetIdentifier: String
    }

    struct Cluster {
        var coordinate: CLLocationCoordinate2D
        var photoCount: Int
        var distinctDays: Int
        var earliestDate: Date?
        var latestDate: Date?
        var assetIdentifiers: [String]
    }

    /// Grid-hash clustering with 8-neighbor merging (union-find). O(n) in the
    /// number of samples; a cell is ~150m, so photos taken at the same spot
    /// across visits collapse into one cluster.
    static func cluster(_ samples: [Sample], cellSizeMeters: Double = 150) -> [Cluster] {
        guard !samples.isEmpty else { return [] }

        let cellDegrees = cellSizeMeters / 111_320.0 // ~meters per degree latitude

        struct CellKey: Hashable { let x: Int; let y: Int }
        var cellSamples: [CellKey: [Int]] = [:]
        for (index, sample) in samples.enumerated() {
            let key = CellKey(x: Int(floor(sample.coordinate.longitude / cellDegrees)),
                              y: Int(floor(sample.coordinate.latitude / cellDegrees)))
            cellSamples[key, default: []].append(index)
        }

        // Union-find over occupied cells; adjacent (8-neighbor) cells merge.
        let keys = Array(cellSamples.keys)
        var keyIndex: [CellKey: Int] = [:]
        for (i, key) in keys.enumerated() { keyIndex[key] = i }
        var parent = Array(0..<keys.count)

        func find(_ i: Int) -> Int {
            var root = i
            while parent[root] != root { root = parent[root] }
            var current = i
            while parent[current] != root {
                let next = parent[current]
                parent[current] = root
                current = next
            }
            return root
        }
        func union(_ a: Int, _ b: Int) {
            let ra = find(a), rb = find(b)
            if ra != rb { parent[ra] = rb }
        }

        for (i, key) in keys.enumerated() {
            for dx in -1...1 {
                for dy in -1...1 where !(dx == 0 && dy == 0) {
                    if let j = keyIndex[CellKey(x: key.x + dx, y: key.y + dy)] {
                        union(i, j)
                    }
                }
            }
        }

        var grouped: [Int: [Int]] = [:] // root -> sample indices
        for (i, key) in keys.enumerated() {
            grouped[find(i), default: []].append(contentsOf: cellSamples[key]!)
        }

        let calendar = Calendar.current
        return grouped.values.map { indices in
            var latSum = 0.0, lonSum = 0.0
            var days = Set<Date>()
            var earliest: Date?, latest: Date?
            var representatives: [String] = []
            for i in indices {
                let sample = samples[i]
                latSum += sample.coordinate.latitude
                lonSum += sample.coordinate.longitude
                if let date = sample.date {
                    days.insert(calendar.startOfDay(for: date))
                    if earliest == nil || date < earliest! { earliest = date }
                    if latest == nil || date > latest! { latest = date }
                }
                if representatives.count < 4 {
                    representatives.append(sample.assetIdentifier)
                }
            }
            let count = Double(indices.count)
            return Cluster(coordinate: CLLocationCoordinate2D(latitude: latSum / count, longitude: lonSum / count),
                           photoCount: indices.count,
                           distinctDays: max(days.count, 1),
                           earliestDate: earliest,
                           latestDate: latest,
                           assetIdentifiers: representatives)
        }
    }

    /// Drops clusters whose center is within `meters` of an already-saved place.
    static func removeClusters(_ clusters: [Cluster], near existing: [CLLocationCoordinate2D], meters: Double = 150) -> [Cluster] {
        guard !existing.isEmpty else { return clusters }
        return clusters.filter { cluster in
            let center = CLLocation(latitude: cluster.coordinate.latitude, longitude: cluster.coordinate.longitude)
            return !existing.contains { place in
                center.distance(from: CLLocation(latitude: place.latitude, longitude: place.longitude)) <= meters
            }
        }
    }
}

// MARK: - Suggestion model

struct PlaceSuggestionCandidate: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let photoCount: Int
    let distinctDays: Int
    let earliestDate: Date?
    let latestDate: Date?
    let assetIdentifiers: [String]

    var name: String = ""
    var icon: String = "mappin"
    var color: PlaceColor = .green
    var isSelected: Bool = false
    var geocodeRequested: Bool = false
    var userEditedName: Bool = false
}

// MARK: - Scanner

@Observable
final class PhotoPlacesScanner {

    enum Phase: Equatable {
        case idle, scanning, denied, empty, ready
    }

    private(set) var phase: Phase = .idle
    var candidates: [PlaceSuggestionCandidate] = []

    private let geocoder = CLGeocoder()

    static let maxSuggestions = 50

    @MainActor
    func start(existingPlaces: [CLLocationCoordinate2D]) async {
        guard phase == .idle else { return }
        phase = .scanning

        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        guard status == .authorized || status == .limited else {
            phase = .denied
            return
        }

        let clusters = await Task.detached(priority: .userInitiated) {
            let samples = Self.fetchSamples()
            let clustered = PhotoClustering.cluster(samples)
            return PhotoClustering.removeClusters(clustered, near: existingPlaces)
        }.value

        candidates = clusters
            .sorted {
                ($0.distinctDays, $0.photoCount) > ($1.distinctDays, $1.photoCount)
            }
            .prefix(Self.maxSuggestions)
            .map {
                PlaceSuggestionCandidate(coordinate: $0.coordinate,
                                         photoCount: $0.photoCount,
                                         distinctDays: $0.distinctDays,
                                         earliestDate: $0.earliestDate,
                                         latestDate: $0.latestDate,
                                         assetIdentifiers: $0.assetIdentifiers)
            }
        phase = candidates.isEmpty ? .empty : .ready
    }

    private nonisolated static func fetchSamples() -> [PhotoClustering.Sample] {
        let options = PHFetchOptions()
        options.includeHiddenAssets = false
        let assets = PHAsset.fetchAssets(with: .image, options: options)

        var samples: [PhotoClustering.Sample] = []
        samples.reserveCapacity(assets.count)
        assets.enumerateObjects { asset, _, _ in
            guard let location = asset.location else { return }
            samples.append(PhotoClustering.Sample(coordinate: location.coordinate,
                                                  date: asset.creationDate,
                                                  assetIdentifier: asset.localIdentifier))
        }
        return samples
    }

    // MARK: Reverse geocoding (lazy, per visible row, serialized)

    @MainActor
    func geocodeIfNeeded(_ id: UUID) async {
        guard let index = candidates.firstIndex(where: { $0.id == id }),
              !candidates[index].geocodeRequested else { return }
        candidates[index].geocodeRequested = true
        let coordinate = candidates[index].coordinate

        // CLGeocoder is rate-limited: keep requests serial and spaced out.
        try? await Task.sleep(nanoseconds: 350_000_000)
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        guard let placemark = try? await geocoder.reverseGeocodeLocation(location).first else { return }

        let name = placemark.areasOfInterest?.first ?? placemark.name ?? placemark.locality ?? ""
        guard let index = candidates.firstIndex(where: { $0.id == id }),
              !candidates[index].userEditedName else { return }

        candidates[index].name = name
        if let suggestion = PlaceClassifier.suggest(for: name) {
            candidates[index].icon = suggestion.icon
            candidates[index].color = suggestion.color
        }
    }

    // MARK: Thumbnails

    nonisolated static func thumbnail(for assetIdentifier: String, side: CGFloat) async -> UIImage? {
        let fetch = PHAsset.fetchAssets(withLocalIdentifiers: [assetIdentifier], options: nil)
        guard let asset = fetch.firstObject else { return nil }

        let options = PHImageRequestOptions()
        // highQualityFormat calls the handler exactly once, which keeps the
        // continuation safe (opportunistic mode can call back multiple times).
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true

        let scale = await MainActor.run { UIScreen.main.scale }
        let target = CGSize(width: side * scale, height: side * scale)

        return await withCheckedContinuation { continuation in
            PHImageManager.default().requestImage(for: asset,
                                                  targetSize: target,
                                                  contentMode: .aspectFill,
                                                  options: options) { image, _ in
                continuation.resume(returning: image)
            }
        }
    }
}
