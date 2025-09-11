//
//  IconSelector.swift
//  Nice Places
//
//  Created by Alan David Hernández Trujillo on 23/02/24.
//

import SwiftUI
import MapKit

struct IconSelector: View {
    @Environment(\.modelContext) var context
    @Environment(\.colorScheme) var colorScheme
    
    @Binding var isIconSheetOpen: Bool
    @Binding var latitude: CLLocationDegrees
    @Binding var longitude: CLLocationDegrees
    
    @State var selectedColor: PlaceColor = .green
    @State var selectedIcon: String = "mappin"
    @State var newPlaceName: String = ""
    @State var newPlaceDescription: String = ""
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 32.0) {
        VStack(alignment: .center, spacing: 20.0) {
            ZStack {
                    isIconSheetOpen = false
                }
                .buttonStyle(.borderedProminent)
            }
            VStack(alignment: .center) {
                HStack {
                    Spacer()
                    Image(systemName: selectedIcon)
                        .font(.largeTitle)
                        .foregroundColor(colorScheme == .dark ? .black : .white)
                        .frame(width: 80, height: 80)
                        .background(selectedColor.wrappedValue.gradient)
                RoundedRectangle(cornerRadius: .infinity)
                    .stroke(
                        Gradient(colors: [.materialBright, .materialDarker]),
                        lineWidth: 12.0
                    )
                    .frame(width: 80, height: 80)
                RoundedRectangle(cornerRadius: .infinity)
                    .stroke(
                        RadialGradient(
                            colors: [.white, .materialBright],
                            center: UnitPoint(x: 20.0, y: 20.0),
                            startRadius: 10.0,
                            endRadius: 20.0),
                        lineWidth: 1.0
                    )
                    .frame(width: 80, height: 80)
                Image(systemName: selectedIcon)
                    .font(.largeTitle)
                    .foregroundColor(colorScheme == .dark ? .black : .white)
                    .frame(width: 80, height: 80)
                    .background(selectedColor.wrappedValue.gradient)
                    .cornerRadius(.infinity)
                    .padding(6.0)
                    .shadow(color: selectedColor.wrappedValue, radius: 20)
            }
            HappyKeyboard(
                newPlaceName: $newPlaceName,
                newPlaceDescription: $newPlaceDescription,
                selectedIcon: $selectedIcon,
                selectedColor: $selectedColor,
                latitude: $latitude,
                longitude: $longitude)
        }
        .padding(.top, 24.0)
        .background(Color.materialBackground)
    }
}

#Preview {
    IconSelector(isIconSheetOpen: .constant(true), latitude: .constant(-33.8688), longitude: .constant(151.2093))
}
