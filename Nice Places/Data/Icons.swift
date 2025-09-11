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

let newIcons = (
    nature: [
        Icon(icon: "rainbow"),
        Icon(icon: "sun.max.fill"),
        Icon(icon: "sun.horizon.fill"),
        Icon(icon: "moon.fill"),
        Icon(icon: "cloud.fill"),
        Icon(icon: "cloud.bolt.fill"),
        Icon(icon: "snowflake"),
        Icon(icon: "tornado"),
        Icon(icon: "globe.americas.fill"),
        Icon(icon: "sparkles"),
        Icon(icon: "drop.fill"),
        Icon(icon: "flame.fill"),
        Icon(icon: "bolt.fill"),
        Icon(icon: "mountain.2.fill"),
        Icon(icon: "cat.fill"),
        Icon(icon: "dog.fill"),
    ],
    technology: [
        Icon(icon: "display"),
        Icon(icon: "ipod"),
        Icon(icon: "flipphone"),
        Icon(icon: "computermouse.fill"),
        Icon(icon: "earbuds"),
        Icon(icon: "hifispeaker.fill"),
        Icon(icon: "tv"),
        Icon(icon: "car.fill"),
        Icon(icon:  "gamecontroller.fill"),
        Icon(icon: "camera.fill"),
        Icon(icon: "fan.fill"),
        Icon(icon: "fuelpump.fill"),
        Icon(icon: "parkingsign.square.fill"),
        Icon(icon: "convertible.side.fill"),
        Icon(icon: "music.microphone"),
        Icon(icon: "flashlight.off.fill")
    ],
    objects: [
        Icon(icon: "bed.double.fill"),
        Icon(icon: "house.fill"),
        Icon(icon: "bag.fill"),
        Icon(icon: "cart.fill"),
        Icon(icon: "location.fill"),
        Icon(icon: "mappin"),
        Icon(icon: "bus.fill"),
        Icon(icon: "bicycle"),
        Icon(icon: "books.vertical.fill"),
        Icon(icon: "backpack.fill"),
        Icon(icon: "dumbbell.fill"),
        Icon(icon: "sportscourt.fill"),
        Icon(icon: "surfboard.fill"),
        Icon(icon: "skateboard.fill"),
        Icon(icon: "medal.fill"),
        Icon(icon: "flag.pattern.checkered.2.crossed"),
    ],
    activities: [
        Icon(icon: "figure.walk"),
        Icon(icon: "figure.run.treadmill"),
        Icon(icon: "figure.roll"),
        Icon(icon: "figure.american.football"),
        Icon(icon: "figure.baseball"),
        Icon(icon: "figure.basketball"),
        Icon(icon: "figure.boxing"),
        Icon(icon: "figure.core.training"),
        Icon(icon: "figure.strengthtraining.functional"),
        Icon(icon: "figure.hiking"),
        Icon(icon: "figure.jumprope"),
        Icon(icon: "figure.outdoor.cycle"),
        Icon(icon: "figure.indoor.soccer"),
        Icon(icon: "figure.skateboarding"),
        Icon(icon: "figure.socialdance"),
        Icon(icon: "figure.pool.swim")
    ]
)

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
    case pink, red, orange, yellow, green, blue, purple, teal, cyan, brown, indigo, mint
    
    var wrappedValue: Color {
        switch self {
        case .pink: return Color.pink
        case .red: return Color.red
        case .orange: return Color.orange
        case .yellow: return Color.yellow
        case .green: return Color.green
        case .blue: return Color.blue
        case .purple: return Color.purple
        case .teal: return Color.teal
        case .cyan: return Color.cyan
        case .brown: return Color.brown
        case .indigo: return Color.indigo
        case .mint: return Color.mint
        }
    }
}


