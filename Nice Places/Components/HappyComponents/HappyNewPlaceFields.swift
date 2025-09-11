//
//  HappyNewPlaceFields.swift
//  Nice Places
//
//  Created by Alan David Hernández Trujillo on 09/09/25.
//
import SwiftUI

struct HappyNewPlaceFields: View {
    @Binding var newPlaceName: String
    @Binding var newPlaceDescription: String
    
    var body: some View {
        VStack(spacing: 8.0) {
            HappyInput(placeholder: "Name", textArea: false, text: $newPlaceName)
            HappyInput(placeholder: "Description", textArea: true, text: $newPlaceName)
        }
        .background(.material)
        .overlay(
            RoundedRectangle(cornerRadius: 12.0)
                .stroke(Gradient(colors: [.materialBright, .materialDark]), lineWidth: 12.0)
                .overlay(
                    RoundedRectangle(cornerRadius: 16.0)
                        .stroke(Gradient(colors: [.materialBright, .materialDark]), lineWidth: 12.0)
                )
        )
    }
}

#Preview {
    HappyNewPlaceFields(newPlaceName: .constant(""), newPlaceDescription: .constant("Description..."))
}
