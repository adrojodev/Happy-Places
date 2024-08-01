//
//  SelectIconButton.swift
//  Nice Places
//
//  Created by Alan David Hernández Trujillo on 23/02/24.
//

import SwiftUI

struct SelectIconButton: View {
    @Environment(\.colorScheme) var colorScheme
    
    @Binding var selectedIcon: String
    @Binding var selectedColor: PlaceColor
    
    @State var isIconSheetOpen = false
    
    var body: some View {
        Image(systemName: selectedIcon)
            .frame(width: 40, height: 40)
            .foregroundColor(colorScheme == .dark ? .black : .white)
            .background(selectedColor.wrappedValue.gradient)
            .cornerRadius(.infinity)
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
