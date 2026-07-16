//
//  HappyPlacesAppIntents.swift
//  Nice Places
//
//  App Intents + Siri App Shortcuts (app target only).
//

import Foundation
import AppIntents
import Observation

/// In-process pending quick action. The root view observes this and presents
/// the matching flow. Fed by three sources: deep links (widget taps), the
/// App Group channel (Control Center), and same-process intents (Siri).
@Observable
final class QuickActionRouter {
    static let shared = QuickActionRouter()

    var pending: QuickAction?

    func trigger(_ action: QuickAction) {
        pending = action
    }

    func handle(_ url: URL) {
        if let action = QuickAction(url: url) {
            pending = action
        }
    }

    /// Picks up actions posted by intents that ran outside the app process.
    func consumeChannelAction() {
        if let action = QuickActionChannel.consume() {
            pending = action
        }
    }
}

struct SaveThisPlaceIntent: AppIntent {
    static let title: LocalizedStringResource = "Save This Place"
    static let description = IntentDescription("Save where you are right now as a happy place.")
    static let openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        QuickActionRouter.shared.trigger(.addPlace)
        return .result()
    }
}

struct SnapThisPlaceIntent: AppIntent {
    static let title: LocalizedStringResource = "Snap a Happy Place"
    static let description = IntentDescription("Open the camera, take a photo, and save this spot as a happy place.")
    static let openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        QuickActionRouter.shared.trigger(.snapPlace)
        return .result()
    }
}

/// "Hey Siri, save this place in Happy Places". Phrases must include the
/// app name token — Siri won't match a bare "save this place".
struct HappyPlacesShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: SaveThisPlaceIntent(),
            phrases: [
                "Save this place in \(.applicationName)",
                "Save this place with \(.applicationName)",
                "Save my location in \(.applicationName)",
                "Add a place in \(.applicationName)",
                "Add a happy place in \(.applicationName)"
            ],
            shortTitle: "Save This Place",
            systemImageName: "mappin.and.ellipse"
        )
        AppShortcut(
            intent: SnapThisPlaceIntent(),
            phrases: [
                "Snap a place in \(.applicationName)",
                "Snap a happy place in \(.applicationName)",
                "Take a photo of this place in \(.applicationName)"
            ],
            shortTitle: "Snap a Place",
            systemImageName: "camera.fill"
        )
    }
}
