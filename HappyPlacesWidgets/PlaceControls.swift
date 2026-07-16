//
//  PlaceControls.swift
//  HappyPlacesWidgets
//
//  Control Center buttons (iOS 18+). Their intents run in this extension's
//  process, so they hand the action to the app through the App Group
//  channel right before the system opens it.
//

import WidgetKit
import SwiftUI
import AppIntents

struct SavePlaceControlIntent: AppIntent {
    static let title: LocalizedStringResource = "Save This Place"
    // Hidden from Shortcuts — the app target exposes the Siri-facing twin.
    static let isDiscoverable: Bool = false
    static let openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        QuickActionChannel.post(.addPlace)
        return .result()
    }
}

struct SnapPlaceControlIntent: AppIntent {
    static let title: LocalizedStringResource = "Snap a Happy Place"
    static let isDiscoverable: Bool = false
    static let openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        QuickActionChannel.post(.snapPlace)
        return .result()
    }
}

@available(iOS 18.0, *)
struct SaveThisPlaceControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "rojo.happy-places-moments.control.save-place") {
            ControlWidgetButton(action: SavePlaceControlIntent()) {
                Label("Save This Place", systemImage: "mappin.and.ellipse")
            }
        }
        .displayName("Save This Place")
        .description("Save where you are as a happy place.")
    }
}

@available(iOS 18.0, *)
struct SnapPlaceControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "rojo.happy-places-moments.control.snap-place") {
            ControlWidgetButton(action: SnapPlaceControlIntent()) {
                Label("Snap a Place", systemImage: "camera.fill")
            }
        }
        .displayName("Snap a Place")
        .description("Open the camera and save this spot with a photo.")
    }
}
