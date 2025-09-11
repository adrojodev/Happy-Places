//
//  HappyButton.swift
//  Nice Places
//
//  Created by Alan David Hernández Trujillo on 05/09/25.
//

//
//  Button.swift
//  Nice Places
//
//  Created by Alan David Hernández Trujillo on 04/09/25.
//


import SwiftUI

struct TextButton: ButtonStyle {
    let cornerRadius: Double
    let fullWidth: Bool
    let color: Color
    let paddingVertical: Double
    let paddingHorizontal: Double
    let borderGradient: Gradient
    let foregroundColor: Color

    
    func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed
        
        configuration.label
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .padding(.horizontal, paddingHorizontal)
            .padding(.vertical, paddingVertical)
            .fontWeight(.semibold)
            .scaleEffect(isPressed ? 0.99 : 1)
            .overlay(
                RoundedRectangle(cornerSize: CGSize(width: cornerRadius, height: cornerRadius))
                    .stroke(
                        LinearGradient(
                            gradient: borderGradient,
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: isPressed ? 6.5 : 8.0
                    )
                    .scaleEffect(isPressed ? 1.01 : 1.0)
            )
            .background(color)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(
                    cornerSize: CGSize(width: cornerRadius, height: cornerRadius))
                    .stroke(
                        .black.opacity(0.5),
                        lineWidth: isPressed ? 1.4 : 0.8
                    )
            )
            .foregroundStyle(foregroundColor.opacity(isPressed ? 0.9 : 1))
            .animation(.spring(duration: 0.1), value: isPressed)
            .sensoryFeedback(.impact(flexibility: .solid), trigger: isPressed)
    }
}

struct HappyButton: View {
    private let text: String
    private let fullWidth: Bool
    private let color: Color
    private let foregroundColor: Color
    private let fontSize: CGFloat
    private let icon: String
    private let iconOnly: Bool
    private let multicolorIcon: Bool
    private let cornerRadius: Double
    private let paddingVertical: Double
    private let paddingHorizontal: Double
    private let borderGradient: Gradient
    
    let action: () -> Void
        
    @State private var isPressed: Bool = false
        
    // Basic initializer - only required parameters
    init(action: @escaping () -> Void) {
        self.text = ""
        self.action = action
        self.fullWidth = false
        self.color = .accent
        self.foregroundColor = .white
        self.fontSize = 16.0
        self.icon = ""
        self.iconOnly = false
        self.multicolorIcon = false
        self.cornerRadius = 12.0
        self.paddingVertical = 12.0
        self.paddingHorizontal = 16.0
        self.borderGradient = Gradient(colors: [.accentBright, .accentShadow])
    }
        
    // Full initializer - with default values for optional parameters
    init(text: String = "",
         fullWidth: Bool = false,
         color: Color = .accent,
         foregroundColor: Color = .white,
         fontSize: CGFloat = 16.0,
         icon: String = "",
         iconOnly: Bool = false,
         multicolorIcon: Bool = false,
         cornerRadius: Double = 12.0,
         paddingVertical: Double = 12.0,
         paddingHorizontal: Double = 16.0,
         borderGradient: Gradient = Gradient(colors: [.accentBright, .accentShadow]),
         action: @escaping () -> Void)
    {
        self.text = text
        self.action = action
        self.fullWidth = fullWidth
        self.color = color
        self.foregroundColor = foregroundColor
        self.fontSize = fontSize
        self.icon = icon
        self.iconOnly = iconOnly
        self.multicolorIcon = multicolorIcon
        self.cornerRadius = cornerRadius
        self.paddingVertical = paddingVertical
        self.paddingHorizontal = paddingHorizontal
        self.borderGradient = borderGradient
    }
    
    var body: some View {
        Group {
            if icon != "" {
                if text != "" {
                    Button(text, systemImage: icon, action: {
                        action()
                    })
                } else {
                    Button(action: { action() }) {
                        Image(systemName: icon)
                            .symbolRenderingMode(multicolorIcon ? .multicolor : .monochrome)
                    }
                }
            } else {
                Button(text, action: {
                    action()
                })
            }
        }
        .font(.system(size: fontSize))
        .foregroundStyle(foregroundColor)
        .buttonStyle(
            TextButton(
                cornerRadius: cornerRadius,
                fullWidth: fullWidth,
                color: color,
                paddingVertical: paddingVertical,
                paddingHorizontal: paddingHorizontal,
                borderGradient: borderGradient,
                foregroundColor: foregroundColor))
    }
}

#Preview {
    HappyButton(text: "Hello", action: {})
}
