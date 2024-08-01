//
//  Place.swift
//  Nice Places
//
//  Created by Alan David Hernández Trujillo on 10/02/24.
//

import Foundation
import CoreTransferable

struct PlaceModel: Identifiable, Hashable, Codable {
    let id = UUID()
    let name: String
    let story: String
    let latitude: Double
    let longitude: Double
    let icon: String
    let date: Date
    
    private enum CodingKeys: String, Double, Date, CodingKey {
        case name
        case story
        case latitude
    }
}

extension PlaceModel: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        
    }
}
