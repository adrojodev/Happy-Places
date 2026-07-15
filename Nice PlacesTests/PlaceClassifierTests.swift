//
//  PlaceClassifierTests.swift
//  Nice PlacesTests
//

import XCTest
@testable import Happy_Places

final class PlaceClassifierTests: XCTestCase {

    private func icon(for name: String) -> String? {
        PlaceClassifier.suggest(for: name)?.icon
    }

    // MARK: Spanish names

    func testSpanishNames() {
        XCTAssertEqual(icon(for: "Playa del Carmen"), "beach.umbrella")
        XCTAssertEqual(icon(for: "Café con Luna"), "cup.and.saucer.fill")
        XCTAssertEqual(icon(for: "Taquería El Paisa"), "fork.knife")
        XCTAssertEqual(icon(for: "Los tacos de la esquina"), "fork.knife")
        XCTAssertEqual(icon(for: "Museo de Antropología"), "building.columns.fill")
        XCTAssertEqual(icon(for: "Cerro de la Silla"), "mountain.2.fill")
        XCTAssertEqual(icon(for: "Casa de los abuelos"), "house.fill")
        XCTAssertEqual(icon(for: "Estadio Azteca"), "sportscourt.fill")
        XCTAssertEqual(icon(for: "Catedral Metropolitana"), "cross.fill")
        XCTAssertEqual(icon(for: "Parque México"), "tree.fill")
        XCTAssertEqual(icon(for: "Mercado de Coyoacán"), "cart.fill")
        XCTAssertEqual(icon(for: "El mirador de Chipinque"), "binoculars.fill")
    }

    // MARK: English names

    func testEnglishNames() {
        XCTAssertEqual(icon(for: "Santa Monica Beach"), "beach.umbrella")
        XCTAssertEqual(icon(for: "Central Park"), "tree.fill")
        XCTAssertEqual(icon(for: "Blue Bottle Coffee"), "cup.and.saucer.fill")
        XCTAssertEqual(icon(for: "JFK Airport"), "airplane.departure")
        XCTAssertEqual(icon(for: "Stanford University"), "graduationcap.fill")
        XCTAssertEqual(icon(for: "The Grand Hotel"), "bed.double.fill")
    }

    // MARK: Diacritics, case, plurals

    func testNormalization() {
        // Accented and unaccented spellings match the same category.
        XCTAssertEqual(icon(for: "CAFÉ"), icon(for: "cafe"))
        XCTAssertEqual(icon(for: "montaña"), icon(for: "montana"))
        // Plural via prefix matching.
        XCTAssertEqual(icon(for: "Tacos El Güero"), "fork.knife")
    }

    // MARK: No match

    func testUnknownNamesReturnNil() {
        XCTAssertNil(PlaceClassifier.suggest(for: ""))
        XCTAssertNil(PlaceClassifier.suggest(for: "X"))
        XCTAssertNil(PlaceClassifier.suggest(for: "Zzyzx"))
        // "bar" must not fire on substrings of unrelated words.
        XCTAssertNil(PlaceClassifier.suggest(for: "Barbara"))
    }

    // MARK: Colors ride along

    func testSuggestionIncludesColor() {
        XCTAssertEqual(PlaceClassifier.suggest(for: "Playa Norte")?.color, .yellow)
        XCTAssertEqual(PlaceClassifier.suggest(for: "Bar La Ópera")?.color, .purple)
    }

    // MARK: POI categories

    func testPOISuggestions() {
        XCTAssertEqual(PlaceClassifier.suggest(for: .restaurant)?.icon, "fork.knife")
        XCTAssertEqual(PlaceClassifier.suggest(for: .beach)?.icon, "beach.umbrella")
        XCTAssertEqual(PlaceClassifier.suggest(for: .museum)?.icon, "building.columns.fill")
        XCTAssertNil(PlaceClassifier.suggest(for: .restroom))
    }

    // MARK: Every category icon must exist in the picker list

    func testCategoryIconsAreInPickerList() {
        let available = Set(icons.map(\.icon))
        for category in PlaceClassifier.categories {
            XCTAssertTrue(available.contains(category.icon),
                          "Category '\(category.name)' uses icon '\(category.icon)' that is not in Icons.swift")
        }
    }
}
