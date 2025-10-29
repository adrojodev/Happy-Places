//
//  CustomSheetView.swift
//  Nice Places
//
//  Created by Alan David Hernández Trujillo on 09/02/24.
//

import SwiftUI
import PhotosUI
import Photos
import CoreLocation
import SwiftData
import UIKit

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
    @State private var selectedPhotos: [PlacePhoto] = []

    @Environment(\.modelContext) var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    
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

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Photos")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.secondary)

                                PhotoPickerView(selectedPhotos: $selectedPhotos,
                                              placeLatitude: latitude,
                                              placeLongitude: longitude)

                                if !selectedPhotos.isEmpty {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 8) {
                                            ForEach(Array(selectedPhotos.enumerated()), id: \.offset) { index, photo in
                                                if let imageData = photo.imageData,
                                                   let uiImage = UIImage(data: imageData) {
                                                    ZStack(alignment: .topTrailing) {
                                                        Image(uiImage: uiImage)
                                                            .resizable()
                                                            .scaledToFill()
                                                            .frame(width: 80, height: 80)
                                                            .cornerRadius(8)
                                                            .clipped()

                                                        Button(action: {
                                                            selectedPhotos.remove(at: index)
                                                        }) {
                                                            Image(systemName: "xmark.circle.fill")
                                                                .foregroundStyle(.white, .red)
                                                                .font(.title3)
                                                        }
                                                        .padding(4)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            Button {
                                let place = Place(color: selectedColor.rawValue,
                                                  createdDate: Date(),
                                                  icon: selectedIcon,
                                                  latitude: latitude,
                                                  longitude: longitude,
                                                  name: placeName,
                                                  text: placeStory,
                                                  photos: selectedPhotos)

                                context.insert(place)
                                dismiss()
                            } label: {
                                Text("Save Place")
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding([.vertical], 12)
                                    .foregroundColor(colorScheme == .dark ? .black : .white)
                                    .cornerRadius(16)
                                
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(selectedColor.wrappedValue)
        
                        }
                    }
                    .formStyle(.columns)
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, isNameFocused || isStoryFocused ? 16 : 48)
                .frame(maxWidth: .infinity)
                .background(.thinMaterial)
                .clipShape(.rect(topLeadingRadius: 32.0, bottomLeadingRadius: 0.0, bottomTrailingRadius: 0.0, topTrailingRadius: 20.0))
                .transition(.move(edge: .bottom))
                .animation(.easeInOut, value: isNameFocused)
                .animation(.easeInOut, value: isStoryFocused)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .background(isNameFocused || isStoryFocused ? .black.opacity(0.4) : .clear)
        .ignoresSafeArea(.container)
        .padding(.horizontal, 8)
        .animation(.bouncy, value: isShowing)
        .animation(.easeInOut, value: isNameFocused)
        .animation(.easeInOut, value: isStoryFocused)
    }
}




//MARK: - PhotoPickerView
struct PhotoPickerView: View {
    @Binding var selectedPhotos: [PlacePhoto]
    let placeLatitude: Double
    let placeLongitude: Double
    let locationTolerance: Double = 500.0 // meters

    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var showingCamera = false
    @State private var showingLocationAlert = false
    @State private var locationAlertMessage = ""

    var body: some View {
        HStack(spacing: 12) {
            Button(action: {
                showingCamera = true
            }) {
                Label("Camera", systemImage: "camera.fill")
                    .font(.subheadline)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.blue.opacity(0.15))
                    .foregroundStyle(.blue)
                    .cornerRadius(12)
            }

            PhotosPicker(selection: $selectedItems,
                        maxSelectionCount: 10,
                        matching: .images) {
                Label("Library", systemImage: "photo.on.rectangle")
                    .font(.subheadline)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.green.opacity(0.15))
                    .foregroundStyle(.green)
                    .cornerRadius(12)
            }
        }
        .onChange(of: selectedItems) {
            Task {
                await loadPhotos()
            }
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraView(placeLatitude: placeLatitude,
                      placeLongitude: placeLongitude,
                      locationTolerance: locationTolerance) { photo in
                if let photo = photo {
                    selectedPhotos.append(photo)
                } else {
                    // Camera photo was rejected - show alert
                    locationAlertMessage = "Photo rejected. Make sure you're at this location and location services are enabled."
                    showingLocationAlert = true
                }
                showingCamera = false
            }
        }
        .alert("Location Mismatch", isPresented: $showingLocationAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(locationAlertMessage)
        }
    }

    private func loadPhotos() async {
        for item in selectedItems {
            guard let data = try? await item.loadTransferable(type: Data.self),
                  let _ = UIImage(data: data) else { continue }

            // Try multiple approaches to get location
            if let photoLocation = await extractLocation(from: item, imageData: data) {
                let distance = calculateDistance(
                    lat1: placeLatitude,
                    lon1: placeLongitude,
                    lat2: photoLocation.latitude,
                    lon2: photoLocation.longitude
                )

                if distance <= locationTolerance {
                    let photo = PlacePhoto(
                        imageData: data,
                        addedDate: Date(),
                        photoLatitude: photoLocation.latitude,
                        photoLongitude: photoLocation.longitude
                    )
                    selectedPhotos.append(photo)
                } else {
                    locationAlertMessage = "This photo was taken \(Int(distance))m away from this place. Only photos taken within \(Int(locationTolerance))m can be added."
                    showingLocationAlert = true
                }
            } else {
                // Photo has no GPS data - reject it
                locationAlertMessage = "This photo has no location data. Please select photos taken at this place."
                showingLocationAlert = true
            }
        }

        selectedItems.removeAll()
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

    private func calculateDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let coordinate1 = CLLocation(latitude: lat1, longitude: lon1)
        let coordinate2 = CLLocation(latitude: lat2, longitude: lon2)
        return coordinate1.distance(from: coordinate2)
    }
}

//MARK: - CameraView
struct CameraView: UIViewControllerRepresentable {
    let placeLatitude: Double
    let placeLongitude: Double
    let locationTolerance: Double
    let completion: (PlacePhoto?) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView

        init(_ parent: CameraView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            guard let image = info[.originalImage] as? UIImage,
                  let imageData = image.jpegData(compressionQuality: 0.8) else {
                parent.completion(nil)
                return
            }

            let locationManager = CLLocationManager()
            if let currentLocation = locationManager.location {
                let distance = currentLocation.distance(
                    from: CLLocation(latitude: parent.placeLatitude, longitude: parent.placeLongitude)
                )

                if distance <= parent.locationTolerance {
                    let photo = PlacePhoto(
                        imageData: imageData,
                        addedDate: Date(),
                        photoLatitude: currentLocation.coordinate.latitude,
                        photoLongitude: currentLocation.coordinate.longitude
                    )
                    parent.completion(photo)
                } else {
                    // Photo is too far - reject it
                    parent.completion(nil)
                }
            } else {
                // No location available - reject the photo
                parent.completion(nil)
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.completion(nil)
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Place.self, configurations: config)

    return EditNewLocationSheet(latitude: 12.64654, longitude: -122.86453, isShowing: .constant(true), isTabbarShowing: .constant(false), selectedColor: .constant(PlaceColor.green))
        .modelContainer(container)
}
