//
//  QuickActionFlowView.swift
//  Nice Places
//
//  Full-screen flow launched from widgets, Control Center, or Siri.
//

import SwiftUI
import UIKit

struct QuickActionFlowView: View {
    let action: QuickAction

    @Environment(\.dismiss) private var dismiss
    // NewLocationView hides the tab bar through this binding; in this
    // full-screen flow there is no tab bar, so it's just a landing spot.
    @State private var isTabbarShowing = false
    @State private var capturedPhoto: PlacePhoto?
    @State private var cameraFinished = false

    var body: some View {
        switch action {
        case .addPlace:
            addPlaceFlow(photo: nil)
        case .snapPlace:
            snapPlaceFlow
        }
    }

    /// Camera first, save sheet after — the magic path. No distance gate:
    /// wherever the photo was taken IS the new place.
    @ViewBuilder
    private var snapPlaceFlow: some View {
        if !cameraFinished && UIImagePickerController.isSourceTypeAvailable(.camera) {
            CameraView(placeLatitude: 0,
                       placeLongitude: 0,
                       locationTolerance: .greatestFiniteMagnitude) { result in
                switch result {
                case .captured(let photo):
                    capturedPhoto = photo
                    cameraFinished = true
                case .rejected:
                    // Unreachable with an infinite tolerance; keep going anyway.
                    cameraFinished = true
                case .cancelled:
                    dismiss()
                }
            }
            .ignoresSafeArea()
        } else {
            // Simulator / no camera: fall through to the regular add flow,
            // with the photo (and its GPS) when we got one.
            addPlaceFlow(photo: capturedPhoto)
        }
    }

    private func addPlaceFlow(photo: PlacePhoto?) -> some View {
        NavigationStack {
            NewLocationView(isTabbarShowing: $isTabbarShowing,
                            preloadedPhoto: photo,
                            photoLatitude: photo?.photoLatitude,
                            photoLongitude: photo?.photoLongitude)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityLabel("Cancel")
                        .accessibilityIdentifier("quickActionCancelButton")
                    }
                }
        }
    }
}

#Preview {
    QuickActionFlowView(action: .addPlace)
}
