//
//  PlaceIconBadge.swift
//  Nice Places
//
//  The place icon in a colored circle, used everywhere an icon+color is shown.
//

import SwiftUI

struct PlaceIconBadge: View {
    let icon: String
    let color: Color
    var size: CGFloat = 40

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: size * 0.42))
            .foregroundStyle(.background)
            .frame(width: size, height: size)
            .background(color.gradient)
            .clipShape(Circle())
    }
}

#Preview {
    VStack(spacing: 16) {
        PlaceIconBadge(icon: "sun.max.fill", color: .orange, size: 80)
        PlaceIconBadge(icon: "tree.fill", color: .green, size: 52)
        PlaceIconBadge(icon: "mappin", color: .blue)
    }
}
