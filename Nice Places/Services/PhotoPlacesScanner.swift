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
import MapKit
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
                if representatives.count < 12 {
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
    /// True while a name is being looked up (and possibly refined by the
    /// on-device model) for this candidate.
    var isNaming: Bool = false
    /// Last name applied by the naming pipeline, so the row can tell a user
    /// edit apart from a programmatic one.
    var suggestedName: String = ""
}

// MARK: - Scanner

@Observable
final class PhotoPlacesScanner {

    enum Phase: Equatable {
        case idle, scanning, denied, empty, ready
    }

    private(set) var phase: Phase = .idle
    /// 0...1 while scanning the library.
    private(set) var scanProgress: Double = 0
    var candidates: [PlaceSuggestionCandidate] = []

    private let geocoder = CLGeocoder()

    static let maxSuggestions = 50

    @MainActor
    func start(existingPlaces: [CLLocationCoordinate2D]) async {
        guard phase == .idle else { return }
        phase = .scanning
        scanProgress = 0

        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        guard status == .authorized || status == .limited else {
            phase = .denied
            return
        }

        let started = Date()
        let onProgress: @Sendable (Int, Int) -> Void = { [weak self] processed, total in
            Task { @MainActor in
                self?.scanProgress = total > 0 ? Double(processed) / Double(total) : 1
            }
        }
        let clusters = await Task.detached(priority: .userInitiated) {
            let samples = Self.fetchSamples(onProgress: onProgress)
            let clustered = PhotoClustering.cluster(samples)
            return PhotoClustering.removeClusters(clustered, near: existingPlaces)
        }.value

        // Keep the progress screen up long enough to register — an instant
        // flash reads as "nothing happened".
        let elapsed = Date().timeIntervalSince(started)
        if elapsed < 1.2 {
            try? await Task.sleep(nanoseconds: UInt64((1.2 - elapsed) * 1_000_000_000))
        }
        scanProgress = 1

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

    private nonisolated static func fetchSamples(onProgress: @escaping @Sendable (Int, Int) -> Void) -> [PhotoClustering.Sample] {
        let options = PHFetchOptions()
        options.includeHiddenAssets = false
        let assets = PHAsset.fetchAssets(with: .image, options: options)
        let total = assets.count

        var samples: [PhotoClustering.Sample] = []
        samples.reserveCapacity(total)
        var processed = 0
        assets.enumerateObjects { asset, _, _ in
            processed += 1
            if processed % 200 == 0 || processed == total {
                onProgress(processed, total)
            }
            guard let location = asset.location else { return }
            samples.append(PhotoClustering.Sample(coordinate: location.coordinate,
                                                  date: asset.creationDate,
                                                  assetIdentifier: asset.localIdentifier))
        }
        return samples
    }

    // MARK: Naming (lazy, per visible row, serialized)

    /// Tail of the naming chain: each new request awaits the previous one, so
    /// CLGeocoder/MKLocalSearch (which reject concurrent requests) run one at
    /// a time while rows fill in progressively.
    private var namingChain: Task<Void, Never>?

    @MainActor
    func suggestNameIfNeeded(_ id: UUID) async {
        guard let index = candidates.firstIndex(where: { $0.id == id }),
              !candidates[index].geocodeRequested else { return }
        candidates[index].geocodeRequested = true
        candidates[index].isNaming = true

        let previous = namingChain
        let task = Task { [weak self] in
            await previous?.value
            await self?.performNaming(id)
        }
        namingChain = task
        await task.value
    }

    @MainActor
    private func performNaming(_ id: UUID) async {
        defer {
            if let index = candidates.firstIndex(where: { $0.id == id }) {
                candidates[index].isNaming = false
            }
        }
        guard let index = candidates.firstIndex(where: { $0.id == id }) else { return }
        let candidate = candidates[index]
        let coordinate = candidate.coordinate

        // CLGeocoder is rate-limited: keep requests spaced out.
        try? await Task.sleep(nanoseconds: 350_000_000)
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let placemark = try? await geocoder.reverseGeocodeLocation(location).first
        let pois = await PlaceNamer.nearbyPOIs(around: coordinate)

        let baseline = PlaceNamer.baselineName(pois: pois,
                                               areasOfInterest: placemark?.areasOfInterest ?? [],
                                               placemarkName: placemark?.name,
                                               locality: placemark?.locality)
        if let baseline {
            apply(name: baseline.name, poiCategory: baseline.poiCategory, to: id)
        }

        // On Apple Intelligence devices, let the on-device model pick the most
        // likely spot. Slower, but it never leaves the phone; everyone else
        // simply keeps the baseline name.
        if let aiName = await PlaceNamer.aiRefinedName(
            pois: pois,
            baseline: baseline?.name,
            locality: placemark?.locality,
            visit: PlaceNamer.VisitContext(photoCount: candidate.photoCount,
                                           distinctDays: candidate.distinctDays,
                                           earliestDate: candidate.earliestDate,
                                           latestDate: candidate.latestDate)) {
            let category = pois.first(where: { $0.name == aiName })?.category ?? baseline?.poiCategory
            apply(name: aiName, poiCategory: category, to: id)
        }
    }

    /// Applies a suggested name (plus icon+color) unless the user already
    /// typed their own.
    @MainActor
    private func apply(name: String, poiCategory: MKPointOfInterestCategory?, to id: UUID) {
        guard let index = candidates.firstIndex(where: { $0.id == id }),
              !candidates[index].userEditedName, !name.isEmpty else { return }

        candidates[index].suggestedName = name
        candidates[index].name = name
        if let suggestion = PlaceClassifier.suggest(for: name)
            ?? poiCategory.flatMap({ PlaceClassifier.suggest(for: $0) }) {
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

    /// Screen-sized, uncropped image for the full-screen carousel.
    nonisolated static func fullImage(for assetIdentifier: String) async -> UIImage? {
        let fetch = PHAsset.fetchAssets(withLocalIdentifiers: [assetIdentifier], options: nil)
        guard let asset = fetch.firstObject else { return nil }

        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true

        let target = await MainActor.run {
            let bounds = UIScreen.main.bounds
            let scale = UIScreen.main.scale
            return CGSize(width: bounds.width * scale, height: bounds.height * scale)
        }

        return await withCheckedContinuation { continuation in
            PHImageManager.default().requestImage(for: asset,
                                                  targetSize: target,
                                                  contentMode: .aspectFit,
                                                  options: options) { image, _ in
                continuation.resume(returning: image)
            }
        }
    }
}
