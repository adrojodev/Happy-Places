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
