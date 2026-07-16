//
//  PlacesDataModel.swift
//  Nice Places
//
//  Created by Alan David Hernández Trujillo on 19/02/24.
//

import Foundation
import SwiftData
import SwiftUI

@Model
class Place {
    var color: String = "green"
    var createdDate: Date = Date()
    var icon: String = "mappin"
    var latitude: Double = 12.64654
    var longitude: Double = -122.86453
    var name: String = "Happy Place"
    var text: String = ""

    @Relationship(deleteRule: .cascade, inverse: \PlacePhoto.place)
    var photos: [PlacePhoto]? = []

    init(color: String, createdDate: Date, icon: String, latitude: Double, longitude: Double, name: String, text: String, photos: [PlacePhoto]? = []) {
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
    @Attribute(.externalStorage) var imageData: Data?
    var addedDate: Date?
    var photoLatitude: Double?
    var photoLongitude: Double?
    /// Photo-library asset this photo came from (nil for camera captures).
    /// Lets the picker preselect photos that are already added.
    /// Optional + additive, so the CloudKit schema stays compatible.
    var assetIdentifier: String?

    var place: Place?

    init(imageData: Data, addedDate: Date = Date(), photoLatitude: Double? = nil, photoLongitude: Double? = nil, assetIdentifier: String? = nil, place: Place? = nil) {
        self.imageData = imageData
        self.addedDate = addedDate
        self.photoLatitude = photoLatitude
        self.photoLongitude = photoLongitude
        self.assetIdentifier = assetIdentifier
        self.place = place
    }
}
