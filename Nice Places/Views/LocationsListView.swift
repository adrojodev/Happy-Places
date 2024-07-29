//
//  LocationsListView.swift
//  Nice Places
//
//  Created by Alan David Hernández Trujillo on 19/02/24.
//

import SwiftUI
import SwiftData

struct LocationsListView: View {
    @State var isTabbarShowing: Bool = true
    @State private var searchPrompt: String = ""
    
    @Environment(\.modelContext) var context
    @Query(sort: \Place.createdDate) var places: [Place]
    
    var body: some View {
        NavigationStack {
            VStack {
                List(searchResults) { place in
                    NavigationLink {
                        PlaceView(place: place, isTabbarShowing: $isTabbarShowing)
                    } label: {
                        PlaceItemView(icon: place.icon,
                                      name: place.name,
                                      latitude: place.latitude,
                                      longitude: place.longitude,
                                      date: place.createdDate,
                                      color: PlaceColor(rawValue: place.color)?.wrappedValue ?? .accentColor)
                        .toolbar(.hidden, for: .tabBar)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button("Delete", systemImage: "trash", role: .destructive) {
                            withAnimation {
                                context.delete(place)
                            }
                        }
                        .tint(.red)
                    }

                }
                .listStyle(.plain)
                .overlay {
                    if places.isEmpty {
                        ContentUnavailableView(label: {
                            Label("No Nice Places!", systemImage: "globe.americas.fill")
                        }, description: {
                            Text("Go and find new places!")
                        }, actions: {
                            Button(action: {}, label: {
                                NavigationLink(destination: NewLocationView(isTabbarShowing: $isTabbarShowing)) {
                                    Text("Add a new place!")
                                }
                            })
                        })
                        .ignoresSafeArea(.all)
                    }
                }
            }
            .onAppear(perform: {
                isTabbarShowing = true
            })
            .navigationTitle("Happy places")
            .navigationBarItems(trailing: Button(action: {}, label: {
                NavigationLink(destination: NewLocationView(isTabbarShowing: $isTabbarShowing)) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title)
                }
                
            }))
        }
        .toolbar(isTabbarShowing ? .visible : .hidden, for: .tabBar)
        .animation(.bouncy, value: isTabbarShowing)
        .searchable(text: $searchPrompt)
    }
    
    var searchResults: [Place] {
        if (searchPrompt.isEmpty) {
            return places
        }
        
        return places.filter({$0.name.contains(searchPrompt)})
    }
}

#Preview {
    LocationsListView()
}
