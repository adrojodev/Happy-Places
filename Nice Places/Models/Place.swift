//
//  Place.swift
//  Nice Places
//
//  Created by Alan David Hernández Trujillo on 10/02/24.
//

import Foundation

struct PlaceModel: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let story: String
    let latitude: Double
    let longitude: Double
    let icon: String
    let date: Date
}
