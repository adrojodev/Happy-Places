//
//  HappyKey.swift
//  Nice Places
//
//  Created by Alan David Hernández Trujillo on 06/09/25.
//

import SwiftUI

struct HappyKey: View {
    private let icon: String
    private let action: () -> Void
    private let lightColor: PlaceColor?
    private let opacity: CGFloat
    private let width: CGFloat
    private let height: CGFloat
    
    let size: CGFloat = 80.0
        
    // Basic initializer - only required parameters
    init(action: @escaping () -> Void) {
        self.icon = "plus"
        self.lightColor = nil
        self.action = action
        self.opacity = 1.0
        self.width = size
        self.height = size
    }
        
    // Full initializer - with default values for optional parameters
    init(
        icon: String = "",
        lightColor: PlaceColor? = nil,
        width: CGFloat = 80.0,
        height: CGFloat = 80.0,
        action: @escaping () -> Void)
    {
        self.icon = icon
        self.width = width
        self.height = height
        self.action = action
        self.lightColor = lightColor
        self.opacity = lightColor != nil ? 0.2 : 1.0
    }
    
    @State private var isPressed: Bool = false
    
    var body: some View {
        ZStack {
            if (lightColor != nil) {
                RoundedRectangle(cornerRadius: 8.0)
                    .fill(lightColor?.wrappedValue.opacity(0.7) ?? .accent)
                    .shadow(
                        color: lightColor?.wrappedValue ?? .accent,
                        radius: isPressed ? 9.0 : 10.0,
                        x: 0,
                        y: 0)
                    .frame(width: width, height: height)
                Circle()
                    .fill(lightColor?.wrappedValue.opacity(0.7) ?? .accent)
                    .frame(width: width, height: height)
                    .scaleEffect(0.5)
                RoundedRectangle(cornerRadius: 8.0)
                    .fill(.ultraThinMaterial)
                    .frame(width: width, height: height)
            }
            Rectangle()
                .fill(.materialBlack)
                .cornerRadius(8.0)
                .frame(width: width, height: height)
                .padding(-10.0)
                .opacity(opacity)
            Rectangle()
                .cornerRadius(8.0)
                .frame(width: width, height: height)
                .foregroundStyle(
                    .linearGradient(
                        colors: isPressed ?
                        [.materialBlack.opacity(0.8), .materialBlack.opacity(0.8)]
                        :
                        [.materialBlack.opacity(0.3), .materialBlackBright.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing)
                    .shadow(.inner(
                        color: isPressed ? .materialDark : .materialDarker,
                        radius: 4,
                        x: -1,
                        y: -1))
                    .shadow(.inner(
                        color: .materialBlackDark,
                        radius: isPressed ? 8 : 2,
                        x: isPressed ? 8 : 4,
                        y: isPressed ? 8 : 4))
                    )
                .opacity(opacity)
            Circle()
                .fill(Gradient(colors: isPressed ? [.materialBlackDark, .materialBlack] : [.materialBlackDark, .materialBlack]))
                .frame(width: width, height: height)
                .scaleEffect(isPressed ? 0.79 : 0.8)
                .opacity(opacity)
            Image(systemName: icon)
                .foregroundStyle(isPressed ? .white.opacity(0.6) : .white)
                .scaleEffect(isPressed ? 0.99 : 1.0)
            Button(action: { action() }) {
                Image(systemName: icon)
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(width: width, height: height)
                    .scaleEffect(isPressed ? 0.99 : 1.0)
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged({ _ in
                        withAnimation(.spring(duration: 0.05)) { isPressed = true }
                    })
                    .onEnded({ _ in
                        withAnimation(.spring(duration: 0.05)) { isPressed = false }
                    })
            )
            .sensoryFeedback(.impact(flexibility: .rigid), trigger: isPressed)
        }
    }
}

#Preview {
    HappyKey(icon: "plus", lightColor: PlaceColor.blue, action: {})
}
