//
//  IconsValidityTests.swift
//  Nice PlacesTests
//

import XCTest
import UIKit
@testable import Happy_Places

final class IconsValidityTests: XCTestCase {

    /// Every icon offered in the picker must be a real SF Symbol on this OS.
    func testAllIconsResolve() {
        for icon in icons {
            XCTAssertNotNil(UIImage(systemName: icon.icon),
                            "'\(icon.icon)' is not a valid SF Symbol")
        }
    }

    func testNoDuplicateIcons() {
        let names = icons.map(\.icon)
        XCTAssertEqual(names.count, Set(names).count, "Duplicate icons in the picker list")
    }

    /// The model default must be selectable in the picker.
    func testDefaultIconIsInList() {
        XCTAssertTrue(icons.contains { $0.icon == "mappin" })
    }
}
