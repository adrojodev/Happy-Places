//
//  IconSelector.swift
//  Nice Places
//
//  Created by Alan David Hernández Trujillo on 23/02/24.
//

import SwiftUI

struct IconSelector: View {
    @Binding var selectedColor: PlaceColor
    @Binding var selectedIcon: String
    @Binding var isIconSheetOpen: Bool
    
    var body: some View {
        VStack(alignment: .center, spacing: 32.0) {
            ZStack {
                HStack {
                    Spacer()
                    Image(systemName: "xmark")
                        .fontWeight(.bold)
                        .frame(width: 32, height: 32)
                        .background(.ultraThinMaterial)
                        .foregroundColor(.secondary)
                        .cornerRadius(.infinity)
                        .onTapGesture(perform: {
                            isIconSheetOpen = false
                        })
                }
            }
            HStack {
                Spacer()
                PlaceIconBadge(icon: selectedIcon, color: selectedColor.color, size: 80)
                Spacer()
            }
            HStack {
                ForEach(PlaceColor.allCases, id: \.self) { placeColor in
                    Button(action: {
                        selectedColor = placeColor
                    }, label: {
                        Circle()
                            .fill(placeColor.color)
                            .frame(width: 40, height: 40)
                    })
                }
            }
            .padding(.horizontal, 16.0)
            .padding(.vertical, 8.0)
            .background(.ultraThinMaterial)
            .cornerRadius(16.0)
            ScrollView {
                LazyVGrid(columns: [GridItem(), GridItem(), GridItem(), GridItem(), GridItem()], content: {
                    ForEach(icons) { icon in
                        Image(systemName: icon.icon)
                            .font(.title3)
                            .frame(width: 48, height: 48)
                            .onTapGesture(perform: {
                                selectedIcon = icon.icon
                            })
                    }
                })
                .padding([.top], 16)
                .padding([.bottom], 32)
                .cornerRadius(16.0)
                .background(.ultraThinMaterial)
            }
            .cornerRadius(16.0)
        }
        .padding([.horizontal], 20)
        .padding([.top], 12)
    }
}

#Preview {
    IconSelector(selectedColor: .constant(PlaceColor.green), selectedIcon: .constant("mappin"), isIconSheetOpen: .constant(true))
}
