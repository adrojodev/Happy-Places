//
//  PlaceNamer.swift
//  Nice Places
//
//  Names a photo cluster from what's actually around it:
//  1. Nearby POI lookup + reverse geocoding (works on every device).
//  2. On Apple Intelligence hardware (iOS 26+), the on-device foundation
//     model picks the most likely spot from the candidates. No network AI,
//     no third-party APIs — older devices just keep the baseline name.
//

import Foundation
import MapKit
import CoreLocation
#if canImport(FoundationModels)
import FoundationModels
#endif

enum PlaceNamer {

    struct POICandidate: Equatable {
        let name: String
        let category: MKPointOfInterestCategory?
        let distanceMeters: Double
    }

    struct NamedSuggestion: Equatable {
        let name: String
        let poiCategory: MKPointOfInterestCategory?
    }

    /// Everything we know about the visit, for the model to reason over.
    struct VisitContext {
        let photoCount: Int
        let distinctDays: Int
        let earliestDate: Date?
        let latestDate: Date?
    }

    // MARK: - Baseline (all devices, pure & unit-tested)

    /// The closest named POI wins; otherwise fall back to the geocoded
    /// area / address / town, in that order.
    static func baselineName(pois: [POICandidate],
                             areasOfInterest: [String],
                             placemarkName: String?,
                             locality: String?,
                             within meters: Double = 80) -> NamedSuggestion? {
        if let poi = pois
            .filter({ $0.distanceMeters <= meters })
            .min(by: { $0.distanceMeters < $1.distanceMeters }) {
            return NamedSuggestion(name: poi.name, poiCategory: poi.category)
        }
        if let area = areasOfInterest.first, !area.isEmpty {
            return NamedSuggestion(name: area, poiCategory: nil)
        }
        if let placemarkName, !placemarkName.isEmpty {
            return NamedSuggestion(name: placemarkName, poiCategory: nil)
        }
        if let locality, !locality.isEmpty {
            return NamedSuggestion(name: locality, poiCategory: nil)
        }
        return nil
    }

    // MARK: - Nearby POIs

    static func nearbyPOIs(around coordinate: CLLocationCoordinate2D,
                           radius: CLLocationDistance = 150) async -> [POICandidate] {
        let request = MKLocalPointsOfInterestRequest(center: coordinate, radius: radius)
        guard let response = try? await MKLocalSearch(request: request).start() else { return [] }

        let here = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return response.mapItems.compactMap { item in
            guard let name = item.name, !name.isEmpty,
                  let location = item.placemark.location else { return nil }
            return POICandidate(name: name,
                                category: item.pointOfInterestCategory,
                                distanceMeters: location.distance(from: here))
        }
        .sorted { $0.distanceMeters < $1.distanceMeters }
    }

    // MARK: - On-device AI refinement (Apple Intelligence hardware only)

    /// Whether the on-device foundation model can run here (iPhone 15 Pro or
    /// newer with Apple Intelligence enabled). Everyone else gets the baseline.
    static var isAINamingAvailable: Bool {
        #if canImport(FoundationModels)
        guard #available(iOS 26.0, *) else { return false }
        return SystemLanguageModel.default.availability == .available
        #else
        return false
        #endif
    }

    /// Asks the on-device model which nearby spot the user most likely
    /// visited. Returns nil whenever the model is unavailable or unsure, so
    /// callers can always fall back to the baseline.
    static func aiRefinedName(pois: [POICandidate],
                              baseline: String?,
                              locality: String?,
                              visit: VisitContext) async -> String? {
        #if canImport(FoundationModels)
        guard #available(iOS 26.0, *),
              SystemLanguageModel.default.availability == .available,
              !pois.isEmpty else { return nil }

        var facts: [String] = []
        facts.append("The user took \(visit.photoCount) photo\(visit.photoCount == 1 ? "" : "s") at one spot" +
                     (visit.distinctDays > 1 ? " across \(visit.distinctDays) different days." : "."))
        if let earliest = visit.earliestDate {
            let range = [earliest, visit.latestDate ?? earliest]
                .map { $0.formatted(.dateTime.month(.wide).year()) }
            facts.append(range[0] == range[1] ? "Taken in \(range[0])." : "Taken between \(range[0]) and \(range[1]).")
        }
        if let locality, !locality.isEmpty {
            facts.append("The town/area is \(locality).")
        }
        let poiLines = pois.prefix(8).map { poi in
            let category = poi.category.map { $0.rawValue.replacingOccurrences(of: "MKPOICategory", with: "") } ?? "unknown type"
            return "- \(poi.name) (\(category), \(Int(poi.distanceMeters))m away)"
        }

        let session = LanguageModelSession(instructions: """
            You name saved places in a personal map app. Given nearby points of \
            interest and visit facts, pick the single most likely place the user \
            actually visited. Prefer the spot whose type matches the visit pattern. \
            Return the place's real name, short and clean — no addresses, no \
            explanations. If a provided candidate fits, use its exact name.
            """)
        let prompt = """
            \(facts.joined(separator: " "))
            Nearby places:
            \(poiLines.joined(separator: "\n"))
            \(baseline.map { "Current guess: \($0)" } ?? "")
            Which place did the user visit?
            """

        guard let response = try? await session.respond(to: prompt, generating: PlaceNamePick.self) else {
            return nil
        }
        let name = response.content.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, name.count <= 60 else { return nil }
        return name
        #else
        return nil
        #endif
    }
}

#if canImport(FoundationModels)
@available(iOS 26.0, *)
@Generable
private struct PlaceNamePick {
    @Guide(description: "The short human name of the place, at most a few words, no street numbers")
    var name: String
}
#endif
