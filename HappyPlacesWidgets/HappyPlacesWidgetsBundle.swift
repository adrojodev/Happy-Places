//
//  HappyPlacesWidgetsBundle.swift
//  HappyPlacesWidgets
//

import WidgetKit
import SwiftUI

@main
struct HappyPlacesWidgetsBundle: WidgetBundle {
    var body: some Widget {
        NearbyPlacesWidget()
        QuickAddWidget()
        SnapPlaceWidget()
        controls
    }

    /// Control Center controls need iOS 18; the rest of the bundle still
    /// serves iOS 17 users.
    @WidgetBundleBuilder
    private var controls: some Widget {
        if #available(iOSApplicationExtension 18.0, *) {
            SaveThisPlaceControl()
            SnapPlaceControl()
        }
    }
}
