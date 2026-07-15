//
//  SelectIconButton.swift
//  Nice Places
//
//  Created by Alan David Hernández Trujillo on 23/02/24.
//

import SwiftUI

struct SelectIconButton: View {
    @Binding var selectedIcon: String
    @Binding var selectedColor: PlaceColor

    @State var isIconSheetOpen = false

    var body: some View {
        PlaceIconBadge(icon: selectedIcon, color: selectedColor.color, size: 40)
            .onTapGesture(perform: {
                isIconSheetOpen = true
            })
            .sheet(isPresented: $isIconSheetOpen) {
                IconSelector(selectedColor: $selectedColor,
                             selectedIcon: $selectedIcon,
                             isIconSheetOpen: $isIconSheetOpen)
                    .presentationCornerRadius(16.0)
                    .presentationDragIndicator(.visible)
                    .presentationDetents([.fraction(0.8)])
            }
    }
}

#Preview {
    SelectIconButton(selectedIcon: .constant("mappin"), selectedColor: .constant(PlaceColor.green))
}
