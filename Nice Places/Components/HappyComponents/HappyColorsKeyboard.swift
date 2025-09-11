//
//  HappyColorsKeyboard.swift
//  Nice Places
//
//  Created by Alan David Hernández Trujillo on 09/09/25.
//

import SwiftUI

struct HappyColorsKeyboard: View {
    @Binding var selectedColor: PlaceColor
    
    var body: some View {
        LazyVGrid(
            columns: [GridItem(),
                      GridItem()],
            spacing: 2.0,
            content: {
                HappyKey(lightColor: .red, width: 162) {
                    selectedColor = .red
                }
                HappyKey(lightColor: .orange, width: 162) {
                    selectedColor = .orange
                }
                HappyKey(lightColor: .yellow, width: 162) {
                    selectedColor = .yellow
                }
                HappyKey(lightColor: .green, width: 162) {
                    selectedColor = .green
                }
                HappyKey(lightColor: .teal, width: 162) {
                    selectedColor = .teal
                }
                HappyKey(lightColor: .blue, width: 162) {
                    selectedColor = .blue
                }
                HappyKey(lightColor: .indigo, width: 162) {
                    selectedColor = .indigo
                }
                HappyKey(lightColor: .purple, width: 162) {
                    selectedColor = .purple
                }
            })
        .frame(width: 321.0)
        .padding([.top], 2)
        .padding([.bottom], 2)
        .padding(.horizontal, 5.5)
    }
}

#Preview {
    HappyColorsKeyboard(selectedColor: .constant(PlaceColor.red))
}
