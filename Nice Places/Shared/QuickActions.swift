//
//  QuickActions.swift
//  Nice Places
//
//  Compiled into BOTH the app and the widget extension.
//

import Foundation

/// Actions that widgets, Control Center, and Siri can ask the app to start.
enum QuickAction: String, CaseIterable, Identifiable {
    case addPlace = "add-place"
    case snapPlace = "snap-place"

    var id: String { rawValue }

    /// Deep link used by widget taps (widgets can only open URLs).
    var url: URL {
        URL(string: "happyplaces://\(rawValue)")!
    }

    init?(url: URL) {
        guard url.scheme == "happyplaces", let host = url.host() else { return nil }
        self.init(rawValue: host)
    }
}

/// Cross-process mailbox for quick actions. Intents that run outside the app
/// process (Control Center buttons live in the widget extension) post here
/// right before the system opens the app; the app consumes it on activation.
/// Intents that already run in the app process use QuickActionRouter directly.
enum QuickActionChannel {
    static let appGroupID = "group.rojo.happy-places-moments"
    private static let pendingKey = "pendingQuickAction"

    static func post(_ action: QuickAction) {
        UserDefaults(suiteName: appGroupID)?.set(action.rawValue, forKey: pendingKey)
    }

    /// Returns the pending action (if any) and clears it.
    static func consume() -> QuickAction? {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let raw = defaults.string(forKey: pendingKey) else { return nil }
        defaults.removeObject(forKey: pendingKey)
        return QuickAction(rawValue: raw)
    }
}
