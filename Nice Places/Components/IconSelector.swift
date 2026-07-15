//
//  IconSelector.swift
//  Nice Places
//
//  Created by Alan David Hernández Trujillo on 23/02/24.
//

import SwiftUI

struct IconSelector: View {
    @Environment(\.colorScheme) var colorScheme
    
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
                Image(systemName: selectedIcon)
                    .font(.largeTitle)
                    .foregroundColor(colorScheme == .dark ? .black : .white)
                    .frame(width: 80, height: 80)
                    .background(selectedColor.wrappedValue.gradient)
                    .cornerRadius(.infinity)
                Spacer()
            }
            HStack {
                Button(action: {
                    selectedColor = PlaceColor.pink
                }, label: {
                    Circle()
                        .fill(.pink)
                        .frame(width: 40, height: 40)
                })
                Button(action: {
                    selectedColor = PlaceColor.red
                }, label: {
                    Circle()
                        .fill(.red)
                        .frame(width: 40, height: 40)
                })
                Button(action: {
                    selectedColor = PlaceColor.orange
                }, label: {
                    Circle()
                        .fill(.orange)
                        .frame(width: 40, height: 40)
                })
                Button(action: {
                    selectedColor = PlaceColor.yellow
                }, label: {
                    Circle()
                        .fill(.yellow)
                        .frame(width: 40, height: 40)
                })
                Button(action: {
                    selectedColor = PlaceColor.green
                }, label: {
                    Circle()
                        .fill(.green)
                        .frame(width: 40, height: 40)
                })
                Button(action: {
                    selectedColor = PlaceColor.blue
                }, label: {
                    Circle()
                        .fill(.blue)
                        .frame(width: 40, height: 40)
                })
                Button(action: {
                    selectedColor = PlaceColor.purple
                }, label: {
                    Circle()
                        .fill(.purple)
                        .frame(width: 40, height: 40)
                })
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
