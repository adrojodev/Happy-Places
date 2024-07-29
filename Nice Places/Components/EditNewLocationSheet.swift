//
//  CustomSheetView.swift
//  Nice Places
//
//  Created by Alan David Hernández Trujillo on 09/02/24.
//

import SwiftUI
import PhotosUI
import CoreLocation

struct EditNewLocationSheet: View {
    let latitude: CLLocationDegrees
    let longitude: CLLocationDegrees
    
    @Binding var isShowing: Bool
    @Binding var isTabbarShowing: Bool
    @Binding var selectedColor: PlaceColor
    
    @FocusState private var isNameFocused: Bool
    @FocusState private var isStoryFocused: Bool
    
    @State private var placeName: String = ""
    @State private var placeStory: String = ""
    @State private var selectedIcon: String = "mappin"
    
    @Environment(\.modelContext) var context
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack (alignment: .bottom) {
            if isShowing {
                VStack (spacing: 16) {
                    HStack {
                        Text(placeName == "" ? "Save this place" : placeName)
                            .font(.title2)
                            .fontWeight(.bold)
                        Spacer()
                        SelectIconButton(selectedIcon: $selectedIcon, selectedColor: $selectedColor)
                    }
                    Form {
                        VStack (spacing: 16) {
                            VStack {
                                TextField("Name of this place", text: $placeName)
                                    .textFieldStyle(.plain)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(.foreground.opacity(0.15))
                                    .cornerRadius(16.0)
                                    .focused($isNameFocused)
                                
                                TextField("Tell your story here", text: $placeStory, axis: .vertical)
                                    .lineLimit(3...5)
                                    .textFieldStyle(.plain)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(.foreground.opacity(0.15))
                                    .cornerRadius(16.0)
                                    .focused($isStoryFocused)
                            }
                            Button {
                                let place = Place(color: selectedColor.rawValue,
                                                  createdDate: Date(),
                                                  icon: selectedIcon,
                                                  latitude: latitude,
                                                  longitude: longitude,
                                                  name: placeName,
                                                  text: placeStory)
                                
                                context.insert(place)
                                dismiss()
                            } label: {
                                Text("Save Place")
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding([.vertical], 12)
                                    .background(selectedColor.wrappedValue)
                                    .foregroundColor(selectedColor == .yellow ? .black : .white)
                                    .cornerRadius(16.0)
                                
                            }
                            .buttonStyle(.plain)
        
                        }
                    }
                    .formStyle(.columns)
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, isNameFocused || isStoryFocused ? 16 : 48)
                .frame(maxWidth: .infinity)
                .background(.thickMaterial)
                .clipShape(.rect(topLeadingRadius: 16.0, bottomLeadingRadius: 0.0, bottomTrailingRadius: 0.0, topTrailingRadius: 16.0))
                .transition(.move(edge: .bottom))
                .animation(.easeInOut, value: isNameFocused)
                .animation(.easeInOut, value: isStoryFocused)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .background(isNameFocused || isStoryFocused ? .black.opacity(0.4) : .clear)
        .ignoresSafeArea(.container)
        .animation(.bouncy, value: isShowing)
        .animation(.easeInOut, value: isNameFocused)
        .animation(.easeInOut, value: isStoryFocused)
    }
}




#Preview {
    EditNewLocationSheet(latitude: 12.64654, longitude: -122.86453, isShowing: .constant(true), isTabbarShowing: .constant(false), selectedColor: .constant(PlaceColor.green))
}
