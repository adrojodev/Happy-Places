//
//  HappyKeyboard.swift
//  Nice Places
//
//  Created by Alan David Hernández Trujillo on 06/09/25.
//

import SwiftUI
import MapKit

struct HappyKeyboard: View {
    @Environment(\.modelContext) var context
    
    @Binding var newPlaceName: String
    @Binding var newPlaceDescription: String
    @Binding var selectedIcon: String
    @Binding var selectedColor: PlaceColor
    @Binding var latitude: CLLocationDegrees
    @Binding var longitude: CLLocationDegrees
    
    @State var showColorButtons: Bool = false
    @State var buttonSelection: String = "nature"
    @State var iconOptions: Array<Icon> = newIcons.nature
    
    @FocusState var isEditingName: Bool
    @FocusState var isEditingDescription: Bool
    
    let selectedGradient = Gradient(colors: [.accentBright, .accentShadow])
    let unselectedGradient = Gradient(colors: [.materialBlackBright, .materialBlackDark])
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12.0) {
            VStack {
                HappyInput(placeholder: "Name", textArea: false, text: $newPlaceName)
                    .focused($isEditingName)
                HappyInput(placeholder: "Description", textArea: true, text: $newPlaceDescription)
                    .focused($isEditingDescription)
            }
            VStack(alignment: .leading, spacing: 4.0) {
                HStack {
                    HStack(alignment: .center, spacing: 1.0) {
                        HappyButton(
                            color: buttonSelection == "nature" && !showColorButtons ? .accent : .materialBlack,
                            icon: "sun.max.fill",
                            cornerRadius: 8.0,
                            paddingVertical: 12.0,
                            paddingHorizontal: 12.0,
                            borderGradient: buttonSelection == "nature" && !showColorButtons ? selectedGradient : unselectedGradient) {
                                iconOptions = newIcons.nature
                                buttonSelection = "nature"
                                showColorButtons = false
                                isEditingName = false
                                isEditingDescription = false
                            }
                        HappyButton(
                            color: buttonSelection == "activities" && !showColorButtons ? .accent : .materialBlack,
                            icon: "figure.walk",
                            cornerRadius: 8.0,
                            paddingVertical: 11.5,
                            paddingHorizontal: 15.0,
                            borderGradient: buttonSelection == "activities" && !showColorButtons ? selectedGradient : unselectedGradient) {
                                iconOptions = newIcons.activities
                                buttonSelection = "activities"
                                showColorButtons = false
                                isEditingName = false
                                isEditingDescription = false
                            }
                        HappyButton(
                            color: buttonSelection == "objects" && !showColorButtons ? .accent : .materialBlack,
                            icon: "backpack",
                            cornerRadius: 8.0,
                            paddingVertical: 11.0,
                            paddingHorizontal: 15.0,
                            borderGradient: buttonSelection == "objects" && !showColorButtons ? selectedGradient : unselectedGradient) {
                                iconOptions = newIcons.objects
                                buttonSelection = "objects"
                                showColorButtons = false
                                isEditingName = false
                                isEditingDescription = false
                            }
                        HappyButton(
                            color: buttonSelection == "technology" && !showColorButtons ? .accent : .materialBlack,
                            icon: "flipphone",
                            cornerRadius: 8.0,
                            paddingVertical: 12.5,
                            paddingHorizontal: 15.0,
                            borderGradient: buttonSelection == "technology" && !showColorButtons ? selectedGradient : unselectedGradient) {
                                iconOptions = newIcons.technology
                                buttonSelection = "technology"
                                showColorButtons = false
                                isEditingName = false
                                isEditingDescription = false
                            }
                    }
                    .padding(.all, 1.0)
                    .background(.materialBlackDarker)
                    .cornerRadius(10.0)
                    HappyButton(
                        color: .material,
                        icon: "rainbow",
                        multicolorIcon: true,
                        cornerRadius: 8.0,
                        paddingVertical: 14.0,
                        paddingHorizontal: 10.0,
                        borderGradient: Gradient(colors: [.materialBright, .materialDark])) {
                            showColorButtons = true
                            isEditingName = false
                            isEditingDescription = false
                    }
                }
                VStack {
                    if (showColorButtons) {
                        HappyColorsKeyboard(selectedColor: $selectedColor)
                    } else {
                        LazyVGrid(
                            columns: [GridItem(),
                                      GridItem(),
                                      GridItem(),
                                      GridItem()],
                            spacing: 2.0,
                            content: {
                                ForEach(iconOptions) { selection in
                                    HappyKey(icon: selection.icon) {
                                        selectedIcon = selection.icon
                                        isEditingName = false
                                        isEditingDescription = false
                                    }
                                }
                            })
                        .frame(width: 321.0)
                        .padding([.top], 2)
                        .padding([.bottom], 2)
                        .padding(.horizontal, 5.5)
                    }
                }
                .background(.materialBlackDarker)
                .cornerRadius(10.0)
                HappyButton(text: "Save new place") {
                    let place = Place(color: selectedColor.rawValue,
                                      createdDate: Date(),
                                      icon: selectedIcon,
                                      latitude: latitude,
                                      longitude: longitude,
                                      name: newPlaceName,
                                      text: newPlaceDescription)
                    
                    context.insert(place)
                }
            }
        }
        .background(Gradient(colors: [.material, .materialDark]))
        .overlay(
            RoundedRectangle(cornerRadius: 16.0)
                .stroke(Gradient(colors: [.material, .materialDark]), lineWidth: 12.0)
                .padding(-6.0)
                .overlay(
                    RoundedRectangle(cornerRadius: 22.0)
                        .stroke(Gradient(colors: [.materialDark, .materialDarker]), lineWidth: 1.0)
                        .padding(-12.0)
                )
        )
        .padding(.all, 12.0)
    }
}

#Preview {
    HappyKeyboard(newPlaceName: .constant(""), newPlaceDescription: .constant(""), selectedIcon: .constant("plus"), selectedColor: .constant(.blue), latitude: .constant(-11.273464), longitude: .constant(-11.273464))
}

