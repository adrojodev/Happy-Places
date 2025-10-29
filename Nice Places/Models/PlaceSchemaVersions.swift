//
//  PlaceSchemaVersions.swift
//  Nice Places
//
//  Schema versioning for SwiftData migration
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - Schema V1 (Original without photos)
enum PlaceSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version = .init(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Place.self]
    }

    @Model
    class Place {
        var color: String = "green"
        var createdDate: Date = Date()
        var icon: String = "pin"
        var latitude: Double = 12.64654
        var longitude: Double = -122.86453
        var name: String = "Happy Place"
        var text: String = ""

        init(color: String, createdDate: Date, icon: String, latitude: Double, longitude: Double, name: String, text: String) {
            self.color = color
            self.createdDate = createdDate
            self.icon = icon
            self.latitude = latitude
            self.longitude = longitude
            self.name = name
            self.text = text
        }
    }
}

// MARK: - Schema V2 (Current with photos)
enum PlaceSchemaV2: VersionedSchema {
    static var versionIdentifier: Schema.Version = .init(1, 1, 0)

    static var models: [any PersistentModel.Type] {
        [Place.self, PlacePhoto.self]
    }

    @Model
    class Place {
        var color: String = "green"
        var createdDate: Date = Date()
        var icon: String = "pin"
        var latitude: Double = 12.64654
        var longitude: Double = -122.86453
        var name: String = "Happy Place"
        var text: String = ""
        var photos: [PlacePhoto] = []

        init(color: String, createdDate: Date, icon: String, latitude: Double, longitude: Double, name: String, text: String, photos: [PlacePhoto] = []) {
            self.color = color
            self.createdDate = createdDate
            self.icon = icon
            self.latitude = latitude
            self.longitude = longitude
            self.name = name
            self.text = text
            self.photos = photos
        }
    }

    @Model
    class PlacePhoto {
        var imageData: Data
        var addedDate: Date
        var photoLatitude: Double?
        var photoLongitude: Double?

        init(imageData: Data, addedDate: Date = Date(), photoLatitude: Double? = nil, photoLongitude: Double? = nil) {
            self.imageData = imageData
            self.addedDate = addedDate
            self.photoLatitude = photoLatitude
            self.photoLongitude = photoLongitude
        }
    }
}

// MARK: - Migration Plan
enum PlaceMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [PlaceSchemaV1.self, PlaceSchemaV2.self]
    }

    static var stages: [MigrationStage] {
        [migrateV1toV2]
    }

    static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: PlaceSchemaV1.self,
        toVersion: PlaceSchemaV2.self
    )
}
