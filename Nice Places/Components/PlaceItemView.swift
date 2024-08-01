//
//  PlaceItemView.swift
//  Nice Places
//
//  Created by Alan David Hernández Trujillo on 10/02/24.
//

import SwiftUI

struct PlaceItemView: View {
    @Environment(\.colorScheme) var colorScheme
    
    let icon: String
    let name: String
    let latitude: Double
    let longitude: Double
    let date: Date
    let color: Color
    
    var body: some View {
        let formattedDate: String = date.formatted(.dateTime.day().month().year())
        
        HStack {
            Image(systemName: icon)
                .frame(width: 52, height: 52)
                .font(.title2)
                .foregroundColor(colorScheme == .dark ? .black : .white)
                .background(color)
                .cornerRadius(.infinity)
            VStack (alignment: .leading) {
                Text(name)
                    .font(.title3)
                    .fontWeight(.bold)
                Text(formattedDate)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    PlaceItemView(icon: "mappin", 
                  name: "Name",
                  latitude: 25.761681,
                  longitude: -80.191788, 
                  date: Date(),
                  color: .red)
}
