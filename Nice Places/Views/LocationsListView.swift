//
//  LocationsListView.swift
//  Nice Places
//
//  Created by Alan David Hernández Trujillo on 19/02/24.
//

import SwiftUI
import SwiftData
import PhotosUI
import Photos
import CoreLocation
import UIKit

struct LocationsListView: View {
    @State var isTabbarShowing: Bool = true
    @State private var searchPrompt: String = ""
    @State private var showingPhotoImport = false
    @State private var navigateToPhotoBasedLocation = false
    @State private var photoImportData: PhotoImportData?

    @Environment(\.modelContext) var context
    @Environment(CloudKitSyncMonitor.self) private var syncMonitor
    @Query(sort: \Place.createdDate, order: .reverse) var places: [Place]
    
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
                            Label("No Happy Places!", systemImage: "globe.americas.fill")
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
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    CompactSyncStatusView(syncMonitor: syncMonitor)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingPhotoImport = true
                    }) {
                        Image(systemName: "photo.badge.plus")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: NewLocationView(isTabbarShowing: $isTabbarShowing)) {
                        Image(systemName: "plus")
                            .font(.title3)
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.circle)
                }
            }
            .sheet(isPresented: $showingPhotoImport) {
                PhotoImportSheet(onPhotoSelected: { photo, latitude, longitude in
                    photoImportData = PhotoImportData(photo: photo, latitude: latitude, longitude: longitude)
                    navigateToPhotoBasedLocation = true
                })
            }
            .navigationDestination(isPresented: $navigateToPhotoBasedLocation) {
                if let data = photoImportData {
                    NewLocationView(isTabbarShowing: $isTabbarShowing,
                                  preloadedPhoto: data.photo,
                                  photoLatitude: data.latitude,
                                  photoLongitude: data.longitude)
                }
            }
        }
        .toolbar(isTabbarShowing ? .visible : .hidden, for: .tabBar)
        .animation(.bouncy, value: isTabbarShowing)
        .searchable(text: $searchPrompt)
    }
    
    var searchResults: [Place] {
        if (searchPrompt.isEmpty) {
            return places
        }

        return places.filter({$0.name.lowercased().contains(searchPrompt.lowercased())})
    }
}

// MARK: - PhotoImportData
struct PhotoImportData {
    let photo: PlacePhoto
    let latitude: Double
    let longitude: Double
}

// MARK: - PhotoImportSheet
struct PhotoImportSheet: View {
    let onPhotoSelected: (PlacePhoto, Double, Double) -> Void

    @State private var selectedItem: PhotosPickerItem?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 60))
                    .foregroundStyle(.primary)

                Text("Add Place from Photo")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Select a photo with GPS data to create a place at that location")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)

                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Label("Choose Photo", systemImage: "photo.on.rectangle")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
            .onChange(of: selectedItem) {
                Task {
                    await loadPhotoLocation()
                }
            }
            .alert("Photo Import", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }

    private func loadPhotoLocation() async {
        guard let item = selectedItem else { return }

        guard let data = try? await item.loadTransferable(type: Data.self),
              let _ = UIImage(data: data) else {
            alertMessage = "Failed to load photo"
            showingAlert = true
            return
        }

        // Try to extract location using both methods
        if let photoLocation = await extractLocation(from: item, imageData: data) {
            let photo = PlacePhoto(
                imageData: data,
                addedDate: Date(),
                photoLatitude: photoLocation.latitude,
                photoLongitude: photoLocation.longitude
            )
            onPhotoSelected(photo, photoLocation.latitude, photoLocation.longitude)
            dismiss()
        } else {
            alertMessage = "This photo has no location data. Please select a photo with GPS information."
            showingAlert = true
        }
    }

    private func extractLocation(from item: PhotosPickerItem, imageData: Data) async -> CLLocationCoordinate2D? {
        // Method 1: Try to get PHAsset via identifier
        if let identifier = item.itemIdentifier {
            let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
            if let asset = fetchResult.firstObject, let location = asset.location {
                return location.coordinate
            }
        }

        // Method 2: Try to extract from EXIF data directly
        if let imageSource = CGImageSourceCreateWithData(imageData as CFData, nil),
           let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any],
           let gpsData = imageProperties[kCGImagePropertyGPSDictionary as String] as? [String: Any],
           let latitude = gpsData[kCGImagePropertyGPSLatitude as String] as? Double,
           let longitude = gpsData[kCGImagePropertyGPSLongitude as String] as? Double,
           let latitudeRef = gpsData[kCGImagePropertyGPSLatitudeRef as String] as? String,
           let longitudeRef = gpsData[kCGImagePropertyGPSLongitudeRef as String] as? String {

            // Adjust for hemisphere
            let finalLatitude = latitudeRef == "S" ? -latitude : latitude
            let finalLongitude = longitudeRef == "W" ? -longitude : longitude

            return CLLocationCoordinate2D(latitude: finalLatitude, longitude: finalLongitude)
        }

        return nil
    }
}

#Preview {
    LocationsListView()
}
