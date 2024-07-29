//
//  Icons.swift
//  Nice Places
//
//  Created by Alan David Hernández Trujillo on 10/02/24.
//

import Foundation
import SwiftUI

struct Icon: Identifiable {
    let icon: String
    let id = UUID()
}

let icons = [
    Icon(icon: "sun.max.fill"),
    Icon(icon: "moon.stars.fill"),
    Icon(icon: "cloud.fill"),
    Icon(icon: "snowflake"),
    Icon(icon: "rainbow"),
    Icon(icon: "bicycle"),
    Icon(icon: "pencil.and.outline"),
    Icon(icon: "books.vertical.fill"),
    Icon(icon: "bookmark.fill"),
    Icon(icon: "backpack.fill"),
    Icon(icon: "basketball.fill"),
    Icon(icon: "medal.fill"),
    Icon(icon: "umbrella.fill"),
    Icon(icon: "flag.fill"),
    Icon(icon: "handbag.fill"),
    Icon(icon: "suitcase.fill"),
    Icon(icon: "theatermasks.fill"),
    Icon(icon: "lamp.ceiling.inverse"),
    Icon(icon: "party.popper.fill"),
    Icon(icon: "fireworks"),
    Icon(icon: "balloon.2.fill"),
    Icon(icon: "sofa.fill"),
    Icon(icon: "tent.fill"),
    Icon(icon: "teddybear.fill"),
    Icon(icon: "tree.fill"),
    Icon(icon: "gamecontroller.fill"),
    Icon(icon: "paintpalette.fill"),
    Icon(icon: "cup.and.saucer.fill"),
    Icon(icon: "birthday.cake.fill"),
    Icon(icon: "fork.knife"),
    Icon(icon: "fossil.shell.fill"),
    Icon(icon: "binoculars.fill"),
    Icon(icon: "bolt.fill"),
    Icon(icon: "camera.macro"),
    Icon(icon: "airplane.departure"),
    Icon(icon: "house.fill"),
    Icon(icon: "football.fill"),
    Icon(icon: "cat.fill"),
    Icon(icon: "bird.fill"),
    Icon(icon: "dog.fill"),
    Icon(icon: "fish.fill"),
    Icon(icon: "ladybug.fill"),
    Icon(icon: "pawprint.fill"),
    Icon(icon: "leaf.fill"),
    Icon(icon: "atom"),
    Icon(icon: "figure.2"),
    Icon(icon: "movieclapper.fill"),
    Icon(icon: "sunglasses"),
    Icon(icon: "heart.fill"),
    Icon(icon: "paperplane.fill")
]

@propertyWrapper
enum PlaceColor: String, CaseIterable {
    case pink, red, orange, yellow, green, blue, purple
    
    var wrappedValue: Color {
        switch self {
            case .pink: return Color.pink
            case .red: return Color.red
            case .orange: return Color.orange
            case .yellow: return Color.yellow
            case .green: return Color.green
            case .blue: return Color.blue
            case .purple: return Color.purple
        }
    }
}


