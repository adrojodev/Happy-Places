//
//  SelectIconButton.swift
//  Nice Places
//
//  Created by Alan David Hernández Trujillo on 23/02/24.
//

import SwiftUI
import MapKit

struct SelectIconButton: View {
    @Environment(\.colorScheme) var colorScheme
    
    @Binding var latitude: CLLocationDegrees
    @Binding var longitude: CLLocationDegrees
    
    @State var isIconSheetOpen = false
    
    var body: some View {
        HappyButton(icon: "mappin", cornerRadius: .infinity, paddingVertical: 12.0, paddingHorizontal: 13.0) {
            isIconSheetOpen = true
        }
        .sheet(isPresented: $isIconSheetOpen) {
            IconSelector(
                isIconSheetOpen: $isIconSheetOpen,
                latitude: $latitude,
                longitude: $longitude)
                .presentationCornerRadius(16.0)
                .presentationDragIndicator(.visible)
                .presentationDetents([.large])
        }
    }
}

#Preview {
    SelectIconButton(latitude: .constant(-11.274638), longitude: .constant(-77.380464))
}
