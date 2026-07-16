//
//  ClusteringTests.swift
//  Nice PlacesTests
//

import XCTest
import CoreLocation
@testable import Happy_Places

final class ClusteringTests: XCTestCase {

    private func sample(_ lat: Double, _ lon: Double, day: Int = 1, id: String = "a") -> PhotoClustering.Sample {
        let date = Calendar.current.date(from: DateComponents(year: 2025, month: 6, day: day))!
        return PhotoClustering.Sample(coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                                      date: date,
                                      assetIdentifier: id)
    }

    func testTwoDistantGroupsMakeTwoClusters() {
        // ~1km apart (0.01 deg latitude ≈ 1.1km)
        let samples = [
            sample(19.4326, -99.1332), sample(19.4327, -99.1333), sample(19.4325, -99.1331),
            sample(19.4426, -99.1332), sample(19.4427, -99.1333),
        ]
        let clusters = PhotoClustering.cluster(samples)
        XCTAssertEqual(clusters.count, 2)
        XCTAssertEqual(clusters.map(\.photoCount).sorted(), [2, 3])
    }

    func testTightSpreadIsOneCluster() {
        // ~50m spread (0.0005 deg ≈ 55m)
        let samples = [
            sample(19.4326, -99.1332),
            sample(19.4329, -99.1330),
            sample(19.4323, -99.1335),
        ]
        XCTAssertEqual(PhotoClustering.cluster(samples).count, 1)
    }

    func testCellBoundaryStillMerges() {
        // Two points ~30m apart that could land in adjacent grid cells must
        // still merge thanks to 8-neighbor union.
        let samples = [
            sample(19.43299, -99.1332),
            sample(19.43301, -99.1332),
        ]
        XCTAssertEqual(PhotoClustering.cluster(samples).count, 1)
    }

    func testDistinctDaysCounting() {
        let samples = [
            sample(19.4326, -99.1332, day: 1),
            sample(19.4326, -99.1332, day: 1),
            sample(19.4326, -99.1332, day: 8),
        ]
        let clusters = PhotoClustering.cluster(samples)
        XCTAssertEqual(clusters.count, 1)
        XCTAssertEqual(clusters[0].distinctDays, 2)
        XCTAssertEqual(clusters[0].photoCount, 3)
    }

    func testDateRange() {
        let samples = [
            sample(19.4326, -99.1332, day: 3),
            sample(19.4326, -99.1332, day: 15),
        ]
        let cluster = PhotoClustering.cluster(samples)[0]
        XCTAssertLessThan(cluster.earliestDate!, cluster.latestDate!)
    }

    func testClustersNearExistingPlacesAreRemoved() {
        let clusters = PhotoClustering.cluster([
            sample(19.4326, -99.1332),
            sample(19.5326, -99.1332), // ~11km away
        ])
        XCTAssertEqual(clusters.count, 2)

        // An existing place right on top of the first cluster.
        let existing = [CLLocationCoordinate2D(latitude: 19.4326, longitude: -99.1332)]
        let filtered = PhotoClustering.removeClusters(clusters, near: existing)
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered[0].coordinate.latitude, 19.5326, accuracy: 0.001)
    }

    func testEmptyInput() {
        XCTAssertTrue(PhotoClustering.cluster([]).isEmpty)
    }

    func testRepresentativeAssetsCappedAtTwelve() {
        let samples = (0..<20).map { sample(19.4326, -99.1332, id: "asset-\($0)") }
        let cluster = PhotoClustering.cluster(samples)[0]
        XCTAssertEqual(cluster.assetIdentifiers.count, 12)
        XCTAssertEqual(cluster.photoCount, 20)
    }
}
