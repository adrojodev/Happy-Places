//
//  Place.swift
//  Nice Places
//
//  Created by Alan David Hernández Trujillo on 10/02/24.
//

import Foundation
import CoreTransferable

struct PlaceModel: Identifiable, Hashable, Codable {
    var id = UUID()
    let name: String
    let story: String
    let latitude: Double
    let longitude: Double
    let icon: String
    let date: Date
}

