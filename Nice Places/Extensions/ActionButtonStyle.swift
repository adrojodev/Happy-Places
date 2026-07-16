//
//  ActionButtonStyle.swift
//  Nice Places
//
//  One place for the app's action-button look: Liquid Glass (tinted) on
//  iOS 26+, the classic bordered styles on older systems. Apply the tint
//  at the call site — glass takes the color just like borderedProminent.
//

import SwiftUI

extension View {
    /// Primary action button: tinted Liquid Glass on iOS 26+,
    /// bordered-prominent before.
    @ViewBuilder
    func prominentActionStyle() -> some View {
        if #available(iOS 26.0, *) {
            self.buttonStyle(.glassProminent)
        } else {
            self.buttonStyle(.borderedProminent)
        }
    }

    /// Secondary action button: clear Liquid Glass on iOS 26+,
    /// bordered before.
    @ViewBuilder
    func secondaryActionStyle() -> some View {
        if #available(iOS 26.0, *) {
            self.buttonStyle(.glass)
        } else {
            self.buttonStyle(.bordered)
        }
    }
}
